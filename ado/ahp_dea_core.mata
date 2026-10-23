/* Code author: Lee, Choonjoo.
   Methodological basis: Sinuany-Stern, Mehrez, and Hadad (2000). */
version 16.0

mata:
mata set matastrict on
real scalar ahpdea__probe()
{
    return(1)
}

/* Sinuany-Stern, Mehrez, and Hadad (2000), equations (1)--(4). */
void ahpdea__pairwise_sums(
    string scalar inputs, string scalar outputs, string scalar touse,
    string scalar comparison_name, string scalar self_name,
    string scalar cross_name, string scalar status_name)
{
    real matrix X, Y, Aiq, Aeq, C, S, K, status
    real colvector biq, beq
    real rowvector c, pair
    real scalar n, m, s, j, k, ii, hh, value, self
    struct RSM_Result scalar ans

    X=st_data(.,tokens(inputs),touse); Y=st_data(.,tokens(outputs),touse)
    n=rows(X); m=cols(X); s=cols(Y)
    C=I(n); S=I(n); K=I(n); status=J(n,n,0)
    for (j=1; j<=n-1; j++) for (k=j+1; k<=n; k++) {
        pair=(j,k)
        for (hh=1; hh<=2; hh++) {
            /* Primary CCR score for the anchor DMU. */
            Aiq=(-X[pair,.],Y[pair,.]); biq=J(2,1,0)
            Aeq=(X[pair[hh],.],J(1,s,0)); beq=1
            c=(J(1,m,0),-Y[pair[hh],.])
            ans=_rsm_solve_lp(Aiq,biq,Aeq,beq,c,1e-9)
            status[pair[hh],pair[3-hh]]=ans.status
            if (ans.status!=0) value=.
            else value=-ans.objval
            S[pair[hh],pair[3-hh]]=value

            /* Benevolent cross score: retain the anchor's optimal primary
               score and maximize the other DMU, as in equation (2). */
            self=value; ii=3-hh
            Aiq=(J(1,m,0),Y[pair[ii],.]); biq=1
            Aeq=(X[pair[ii],.],J(1,s,0)) \
                (-self*X[pair[hh],.],Y[pair[hh],.])
            beq=(1\0)
            c=(J(1,m,0),-Y[pair[ii],.])
            ans=_rsm_solve_lp(Aiq,biq,Aeq,beq,c,1e-9)
            status[pair[ii],pair[hh]]=ans.status
            if (ans.status!=0) value=.
            else value=-ans.objval
            K[pair[ii],pair[hh]]=value
        }
        if (any(missing((S[j,k],K[j,k],S[k,j],K[k,j])))) {
            C[j,k]=.; C[k,j]=.
        }
        else {
            C[j,k]=(S[j,k]+K[j,k])/(S[k,j]+K[k,j])
            C[k,j]=1/C[j,k]
        }
    }
    st_matrix(comparison_name,C); st_matrix(self_name,S)
    st_matrix(cross_name,K); st_matrix(status_name,status)
}

void ahpdea__hybrid_rank(
    string scalar efficiency_name,
    string scalar tie_name,
    string scalar tiepriority_name,
    real scalar tolerance,
    string scalar dearank_name,
    string scalar hybridrank_name)
{
    real colvector e, tied, p, dr, hr
    real scalar i, j, k, n, base

    e = st_matrix(efficiency_name)
    tied = st_matrix(tie_name)
    p = st_matrix(tiepriority_name)
    n = rows(e)
    if (cols(e)!=1 | rows(tied)!=n | cols(tied)!=1)
        _error(3200, "incompatible DEA/tie dimensions")
    if (sum(tied)>0 & (sum(tied)!=rows(p) | cols(p)!=1))
        _error(3200, "tie priority dimension does not match tie set")

    dr = J(n,1,.)
    for (i=1; i<=n; i++) {
        dr[i] = 1
        for (j=1; j<=n; j++) if (e[j] > e[i] + tolerance) dr[i]=dr[i]+1
    }
    hr = dr
    if (sum(tied)>0) {
        base = min(select(dr,tied))
        k = 0
        for (i=1; i<=n; i++) if (tied[i]) {
            k=k+1
            hr[i] = base
            for (j=1; j<=rows(p); j++) if (p[j] > p[k] + tolerance) hr[i]=hr[i]+1
        }
    }
    st_matrix(dearank_name, dr)
    st_matrix(hybridrank_name, hr)
}

end
