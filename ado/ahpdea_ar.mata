/* Code author: Lee, Choonjoo.
   Methodological basis: Takamura and Tone (2003), with DEA v2.0 described
   in Lee (2026, forthcoming). */
version 16.0

capture mata: mata drop ahpdea_ar__probe()
capture mata: mata drop ahpdea_ar__solver_probe()
capture mata: mata drop ahpdea_ar__solve()
capture mata: mata drop ahpdea_ar__band_bounds()
capture mata: mata drop ahpdea_ar__group_bounds()
capture mata: mata drop ahpdea_ar__invalid_pair_bounds()

mata:
mata set matastrict on

real scalar ahpdea_ar__probe() return(1)

real scalar ahpdea_ar__solver_probe()
{
    struct RSM_Result scalar ans
    ans=_rsm_solve_lp(J(0,1,.),J(0,1,.),(1),(1),(1),1e-8)
    return(ans.status==0 & abs(ans.objval-1)<1e-8 &
        rows(ans.x)>=1 & abs(ans.x[1]-1)<1e-8)
}

void ahpdea_ar__band_bounds(string scalar pname, real scalar lowerband,
    real scalar upperband,
    string scalar lname, string scalar hname)
{
    real colvector p
    real matrix L, H
    real scalar i, j, n
    p=st_matrix(pname); n=rows(p); L=J(n,n,1); H=J(n,n,1)
    for (i=1;i<=n;i++) for (j=1;j<=n;j++) if (i!=j) {
        L[i,j]=max((0,(1-lowerband)*p[i]/p[j]))
        H[i,j]=(1+upperband)*p[i]/p[j]
    }
    st_matrix(lname,L); st_matrix(hname,H)
}

void ahpdea_ar__group_bounds(string scalar wname,
    string scalar lname, string scalar hname)
{
    real matrix W, R, L, H
    real scalar i, j, n
    W=st_matrix(wname); n=rows(W); L=J(n,n,1); H=J(n,n,1)
    if (cols(W)<1 | any(W:<=0) | any(missing(W)))
        _error(3498,"group priority matrix must contain positive finite weights")
    for (i=1;i<=n;i++) for (j=1;j<=n;j++) if (i!=j) {
        R=W[i,.]:/W[j,.]
        L[i,j]=min(R); H[i,j]=max(R)
    }
    st_matrix(lname,L); st_matrix(hname,H)
}

real scalar ahpdea_ar__invalid_pair_bounds(real matrix L, real matrix H)
{
    real scalar n
    n = rows(L)
    if (rows(H)!=n | cols(L)!=n | cols(H)!=n) return(1)
    if (sum(missing(L)) | sum(missing(H))) return(1)
    if (sum(L:<0) | sum(H:<=0) | sum(L:>H)) return(1)
    if (max(abs(diagonal(L):-1))>1e-10 | max(abs(diagonal(H):-1))>1e-10) return(1)
    if (sum((L:*L'):>1+1e-10) | sum((H:*H'):<1-1e-10)) return(1)
    return(0)
}

void ahpdea_ar__solve(
    string scalar inputs, string scalar outputs, string scalar touse,
    string scalar pxname, string scalar pyname,
    string scalar sxname, string scalar syname,
    string scalar lxname, string scalar hxname,
    string scalar lyname, string scalar hyname,
    string scalar orientation, string scalar rts,
    string scalar ename, string scalar vname, string scalar uname,
    string scalar interceptname, string scalar statusname)
{
    real matrix X, Y, Aiq, Aeq, V, U, LX, HX, LY, HY
    real colvector px, py, sx, sy, biq, beq, eff, intercept, status
    real rowvector c, row
    real scalar n, m, s, nv, k, i, h, L, H, hasintercept
    struct RSM_Result scalar ans

    X=st_data(.,tokens(inputs),touse); Y=st_data(.,tokens(outputs),touse)
    px=st_matrix(pxname); py=st_matrix(pyname)
    sx=st_matrix(sxname); sy=st_matrix(syname)
    LX=st_matrix(lxname); HX=st_matrix(hxname)
    LY=st_matrix(lyname); HY=st_matrix(hyname)
    n=rows(X); m=cols(X); s=cols(Y); hasintercept=(rts=="vrs")
    nv=m+s+2*hasintercept
    eff=J(n,1,.); V=J(n,m,.); U=J(n,s,.)
    intercept=J(n,1,0); status=J(n,1,.)

    for (k=1; k<=n; k++) {
        /* Variables are [v,u,u0+,u0-] for VRS and [v,u] for CRS. */
        Aiq=(-X,Y,J(n,2*hasintercept,0)); biq=J(n,1,0)
        if (hasintercept) {
            if (orientation=="input") Aiq[.,(m+s+1)..(m+s+2)]=(J(n,1,1),J(n,1,-1))
            else Aiq[.,(m+s+1)..(m+s+2)]=(J(n,1,-1),J(n,1,1))
        }

        for (i=1; i<=m-1; i++) for (h=i+1; h<=m; h++) {
            L=LX[i,h]; H=HX[i,h]
            row=J(1,nv,0); row[i]=sx[i]; row[h]=-H*sx[h]
            Aiq=Aiq\row; biq=biq\0
            row=J(1,nv,0); row[i]=-sx[i]; row[h]=L*sx[h]
            Aiq=Aiq\row; biq=biq\0
        }
        for (i=1; i<=s-1; i++) for (h=i+1; h<=s; h++) {
            L=LY[i,h]; H=HY[i,h]
            row=J(1,nv,0); row[m+i]=sy[i]; row[m+h]=-H*sy[h]
            Aiq=Aiq\row; biq=biq\0
            row=J(1,nv,0); row[m+i]=-sy[i]; row[m+h]=L*sy[h]
            Aiq=Aiq\row; biq=biq\0
        }

        if (orientation=="input") {
            Aeq=(X[k,.],J(1,s+2*hasintercept,0)); beq=1
            c=(J(1,m,0),-Y[k,.],J(1,2*hasintercept,0))
            if (hasintercept) c[(m+s+1)..(m+s+2)]=(-1,1)
        }
        else {
            Aeq=(J(1,m,0),Y[k,.],J(1,2*hasintercept,0)); beq=1
            c=(X[k,.],J(1,s+2*hasintercept,0))
            if (hasintercept) c[(m+s+1)..(m+s+2)]=(1,-1)
        }
        ans=_rsm_solve_lp(Aiq,biq,Aeq,beq,c,1e-8)
        status[k]=ans.status
        if (ans.status==0) {
            if (orientation=="input") eff[k]=-ans.objval
            else if (abs(ans.objval)>1e-12) eff[k]=1/ans.objval
            V[k,.]=ans.x[1..m]'
            U[k,.]=ans.x[m+1..m+s]'
            if (hasintercept) intercept[k]=ans.x[m+s+1]-ans.x[m+s+2]
        }
    }
    st_matrix(ename,eff); st_matrix(vname,V); st_matrix(uname,U)
    st_matrix(interceptname,intercept)
    st_matrix(statusname,status)
}

end
