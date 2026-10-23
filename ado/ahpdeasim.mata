/* Code author: Lee, Choonjoo.
   Judgment-perturbation sensitivity routines for the Saaty (1987) AHP and
   Lee (2026, forthcoming) DEA bridge. */
version 16.0

capture mata: mata drop ahpdeasim__perturb()
capture mata: mata drop ahpdeasim__summarize()

mata:
mata set matastrict on

void ahpdeasim__perturb(string scalar aname, real scalar sigma,
    string scalar outname)
{
    real matrix A, B
    real scalar i, j, n, z
    A=st_matrix(aname); n=rows(A); B=I(n)
    for (i=1;i<=n;i++) for (j=i+1;j<=n;j++) {
        z=rnormal(1,1,0,1)
        B[i,j]=A[i,j]*exp(sigma*z)
        B[j,i]=1/B[i,j]
    }
    st_matrix(outname,B)
}

void ahpdeasim__summarize(string scalar ename, string scalar sname)
{
    real matrix E, S
    real colvector x, ord, ranks
    real scalar i, b, n, B, k, h, pos, avgrank, top
    E=st_matrix(ename); n=rows(E); B=cols(E); S=J(n,7,0)
    for (i=1;i<=n;i++) {
        x=sort(E[i,.]',1)
        S[i,1]=mean(x)
        S[i,2]=sqrt(variance(x))
        S[i,3]=x[max((1,ceil(.05*B)))]
        S[i,4]=x[max((1,ceil(.50*B)))]
        S[i,5]=x[max((1,ceil(.95*B)))]
    }
    for (b=1;b<=B;b++) {
        ord=order(-E[,b],1); ranks=J(n,1,.)
        k=1
        while (k<=n) {
            h=k
            while (h<n) {
                if (abs(E[ord[h+1],b]-E[ord[k],b])>1e-10) break
                h++
            }
            avgrank=(k+h)/2
            for (pos=k;pos<=h;pos++) ranks[ord[pos]]=avgrank
            k=h+1
        }
        S[,6]=S[,6]+ranks
        top=max(E[,b])
        S[,7]=S[,7]+(abs(E[,b]:-top):<=1e-10)
    }
    S[,6..7]=S[,6..7]:/B
    st_matrix(sname,S)
}

end
