/* Code author: Choonjoo Lee. ANP supermatrices and class-aware limits.
   GTH reference: Grassmann, Taksar, and Heyman (1985),
   doi:10.1287/opre.33.5.1107. Independently implemented in Mata. */
version 16.0
capture mata: mata drop ahpn__version()
capture mata: mata drop ahpn__uniq()
capture mata: mata drop ahpn__pos()
capture mata: mata drop ahpn__stationary()
capture mata: mata drop ahpn__gcd()
capture mata: mata drop ahpn__period()
capture mata: mata drop ahpn__absorption()
capture mata: mata drop ahpn__projection()
capture mata: mata drop ahpn__run()
mata:

real scalar ahpn__version() return(2)

string colvector ahpn__uniq(string colvector x)
{
    if (rows(x)==0) return(J(0,1,""))
    return(uniqrows(sort(x,1)))
}

real scalar ahpn__pos(string colvector x, string scalar value)
{
    real colvector z
    z=selectindex(x:==value)
    return(length(z) ? z[1] : 0)
}

/* Closed communicating classes use the subtraction-free state-reduction
   method of Grassmann, Taksar, and Heyman (1985). This is an independent
   Mata implementation. Transient absorption uses nonnegative elimination. */
real colvector ahpn__stationary(real matrix W)
{
    real matrix A
    real colvector p
    real scalar n,k,i,s
    n=rows(W)
    if (n==1) return(1)
    A=W'
    for (k=n;k>=2;k--) {
        s=sum(A[k,1..(k-1)])
        if (s<=0 | missing(s)) ahp__fail("stationary reduction lost a positive exit; check numerical range")
        for (i=1;i<k;i++) {
            A[i,k]=A[i,k]/s
            A[i,1..(k-1)]=A[i,1..(k-1)]+A[i,k]*A[k,1..(k-1)]
        }
        if (any(missing(A))) ahp__fail("stationary reduction overflow; respecify extreme input weights")
    }
    p=J(n,1,0); p[1]=1
    for (k=2;k<=n;k++) {
        p[k]=sum(p[1..(k-1)]:*A[1..(k-1),k])
        if (missing(p[k])) ahp__fail("stationary back substitution overflow")
        p=p/max(p)
    }
    return(p/sum(p))
}

real scalar ahpn__gcd(real scalar a, real scalar b)
{
    real scalar c
    a=abs(a); b=abs(b)
    while (b!=0) {
        c=mod(a,b); a=b; b=c
    }
    return(a)
}

real scalar ahpn__period(real matrix W)
{
    real colvector d
    real scalar n,pass,i,j,g
    n=rows(W)
    if (any(diagonal(W):>0)) return(1)
    d=J(n,1,.); d[1]=0
    for (pass=1;pass<=n;pass++) {
        for (j=1;j<=n;j++) if (!missing(d[j]))
            for (i=1;i<=n;i++) if (W[i,j]>0 & missing(d[i])) d[i]=d[j]+1
        if (!any(missing(d))) break
    }
    if (any(missing(d))) ahp__fail("internal communicating-class traversal failed")
    g=0
    for (j=1;j<=n;j++) for (i=1;i<=n;i++)
        if (W[i,j]>0) g=ahpn__gcd(g,d[j]+1-d[i])
    if (g<1) ahp__fail("internal period calculation failed")
    return(g)
}

real matrix ahpn__absorption(real matrix Q, real matrix B)
{
    real scalar m,k,i,s,a
    m=rows(Q)
    /* Remove self-loops by summing exits, never by subtracting Q[k,k]
       from one. Previously eliminated destinations have already been
       replaced by their remaining transitions and absorption chances. */
    for (k=1;k<=m;k++) {
        s=sum(B[k,.])
        if (k<m) s=s+sum(Q[k,(k+1)..m])
        if (s<=0 | missing(s)) ahp__fail("transient reduction lost a positive exit; check numerical range")
        B[k,.]=B[k,.]/s
        if (k<m) {
            Q[k,(k+1)..m]=Q[k,(k+1)..m]/s
            for (i=k+1;i<=m;i++) {
                a=Q[i,k]
                B[i,.]=B[i,.]+a*B[k,.]
                Q[i,(k+1)..m]=Q[i,(k+1)..m]+a*Q[k,(k+1)..m]
                Q[i,k]=0
            }
        }
    }
    for (k=m-1;k>=1;k--) B[k,.]=B[k,.]+Q[k,(k+1)..m]*B[(k+1)..m,.]
    return(B)
}

real matrix ahpn__projection(real matrix W, real matrix classinfo)
{
    real matrix R,V,H,B,Q,L
    real colvector component,closed,period,idx,outside,transient
    real scalar n,k,i,j,c,nclosed,d,numtol
    n=rows(W)
    /* A positive edge stays present even when smaller than tolerance(). */
    R=((W:>0)+I(n)):>0
    for (k=1;k<=n;k++) R=R :| ((R[,k]*R[k,.]):>0)
    component=J(n,1,0); closed=period=J(n,1,0); c=nclosed=0
    for (j=1;j<=n;j++) if (component[j]==0) {
        c++
        idx=selectindex(R[,j]:&R[j,.]')
        component[idx]=J(length(idx),1,c)
    }
    for (k=1;k<=c;k++) {
        idx=selectindex(component:==k); outside=selectindex(component:!=k)
        if (length(outside)) {
            if (any(W[outside,idx]:>0)) continue
        }
        nclosed++
        closed[idx]=J(length(idx),1,nclosed)
        d=ahpn__period(W[idx,idx])
        period[idx]=J(length(idx),1,d)
    }
    if (nclosed==0) ahp__fail("network has no closed communicating class")
    V=J(n,nclosed,0); H=J(nclosed,n,0)
    for (k=1;k<=nclosed;k++) {
        idx=selectindex(closed:==k)
        V[idx,k]=ahpn__stationary(W[idx,idx])
        H[k,idx]=J(1,length(idx),1)
    }
    transient=selectindex(closed:==0)
    if (length(transient)) {
        Q=W[transient,transient]'
        B=J(length(transient),nclosed,0)
        for (k=1;k<=nclosed;k++) {
            idx=selectindex(closed:==k)
            B[,k]=colsum(W[idx,transient])'
        }
        B=ahpn__absorption(Q,B)
        numtol=max((1e-12,100*n*epsilon(1)))
        if (any(missing(B)) | any(B:<0) | max(abs(rowsum(B):-1))>numtol)
            ahp__fail("absorption probabilities failed numerical validation")
        for (i=1;i<=rows(B);i++) B[i,.]=B[i,.]/sum(B[i,.])
        H[,transient]=B'
    }
    L=V*H
    numtol=max((1e-12,100*n*epsilon(1)))
    if (any(missing(L)) | any(L:<0) | max(abs(colsum(L):-1))>numtol |
        max(abs(W*L-L))>numtol | max(abs(L*W-L))>numtol | max(abs(L*L-L))>numtol)
        ahp__fail("direct limit failed numerical validation")
    classinfo=(component,closed,period)
    return(L)
}

void ahpn__run(
    string scalar weightvar, string scalar sourcevar, string scalar targetvar,
    string scalar sourceclustervar, string scalar targetclustervar,
    string scalar clusterweightvar, string scalar tousevar, string scalar limittype,
    string scalar solver, real scalar maxiter, real scalar tol, string scalar out_super,
    string scalar out_limit, string scalar out_priority, string scalar out_membership,
    string scalar out_classes,
    string scalar out_nodes_local, string scalar out_clusters_local)
{
    real colvector use, weight, cw, idx, membership, p
    string colvector source, target, sourcecluster, targetcluster, nodes, clusters, active
    real matrix W, X, Xnew, avg, oldavg, L, classinfo
    real scalar i,j,k,n,K,iter,err,blocksum,cwij,spread,referr,residual,projectionerr,adjustment

    use=st_data(.,tousevar)
    weight=select(st_data(.,weightvar),use:==1)
    source=select(st_sdata(.,sourcevar),use:==1)
    target=select(st_sdata(.,targetvar),use:==1)
    if (sourceclustervar=="") {
        sourcecluster=targetcluster=J(rows(weight),1,"network")
    }
    else {
        sourcecluster=select(st_sdata(.,sourceclustervar),use:==1)
        targetcluster=select(st_sdata(.,targetclustervar),use:==1)
    }
    cw=(clusterweightvar=="" ? J(rows(weight),1,.) : select(st_data(.,clusterweightvar),use:==1))

    if (any(missing(weight)) | any(weight:<=0)) ahp__fail("network local weights must be positive and nonmissing")
    if (any(source:=="") | any(target:=="") | any(sourcecluster:=="") | any(targetcluster:==""))
        ahp__fail("network node and cluster identifiers may not be empty")
    nodes=ahpn__uniq(source\target)
    clusters=ahpn__uniq(sourcecluster\targetcluster)
    for (i=1;i<=rows(nodes);i++) if (strtoname(nodes[i])!=nodes[i])
        ahp__fail(sprintf("network node identifiers must be valid Stata names; invalid value: %s",nodes[i]))
    for (i=1;i<=rows(clusters);i++) if (strtoname(clusters[i])!=clusters[i])
        ahp__fail(sprintf("network cluster identifiers must be valid Stata names; invalid value: %s",clusters[i]))
    n=rows(nodes); K=rows(clusters)

    membership=J(n,1,.)
    for (i=1;i<=rows(weight);i++) {
        j=ahpn__pos(nodes,source[i]); k=ahpn__pos(clusters,sourcecluster[i])
        if (missing(membership[j])) membership[j]=k
        else if (membership[j]!=k) ahp__fail(sprintf("node %s has inconsistent cluster membership",source[i]))
        j=ahpn__pos(nodes,target[i]); k=ahpn__pos(clusters,targetcluster[i])
        if (missing(membership[j])) membership[j]=k
        else if (membership[j]!=k) ahp__fail(sprintf("node %s has inconsistent cluster membership",target[i]))
        idx=selectindex((source:==source[i]) :& (target:==target[i]))
        if (length(idx)>1) ahp__fail(sprintf("duplicate network edge %s -> %s",source[i],target[i]))
    }
    for (i=1;i<=n;i++) if (!ahpn__pos(source,nodes[i]))
        ahp__fail(sprintf("node %s has no outgoing influence column",nodes[i]))

    W=J(n,n,0)
    for (j=1;j<=n;j++) {
        active=ahpn__uniq(select(targetcluster,source:==nodes[j]))
        if (!rows(active)) ahp__fail(sprintf("source node %s has no targets",nodes[j]))
        for (k=1;k<=rows(active);k++) {
            idx=selectindex((source:==nodes[j]) :& (targetcluster:==active[k]))
            blocksum=sum(weight[idx])
            if (abs(blocksum-1)>tol)
                ahp__fail(sprintf("local weights from source %s to cluster %s must sum to one",nodes[j],active[k]))
            if (clusterweightvar=="") cwij=1/rows(active)
            else {
                if (any(missing(cw[idx])) | any(cw[idx]:<=0))
                    ahp__fail("cluster weights must be positive and nonmissing")
                if (max(cw[idx])-min(cw[idx])>tol)
                    ahp__fail(sprintf("clusterweight() must be constant for source %s and target cluster %s",nodes[j],active[k]))
                cwij=cw[idx[1]]
            }
            for (i=1;i<=length(idx);i++)
                W[ahpn__pos(nodes,target[idx[i]]),j]=weight[idx[i]]*cwij
        }
        if (clusterweightvar!="") {
            cwij=0
            for (k=1;k<=rows(active);k++) {
                idx=selectindex((source:==nodes[j]) :& (targetcluster:==active[k]))
                cwij=cwij+cw[idx[1]]
            }
            if (abs(cwij-1)>tol) ahp__fail(sprintf("cluster weights for source %s must sum to one",nodes[j]))
        }
        if (abs(sum(W[,j])-1)>tol) ahp__fail("weighted supermatrix columns must sum to one")
    }

    /* Accepted rounding discrepancies are normalized before limit analysis. */
    adjustment=0
    for (j=1;j<=n;j++) {
        blocksum=sum(W[,j])
        adjustment=max((adjustment,max(abs(W[,j]/blocksum-W[,j]))))
        W[,j]=W[,j]/blocksum
    }
    classinfo=J(0,3,.)
    L=ahpn__projection(W,classinfo)
    if (limittype=="power" & max(classinfo[,3])>1)
        ahp__fail("ordinary powers have no limit: a closed class is periodic; specify limit(cesaro)")
    iter=0; err=.; referr=0
    if (solver=="direct") X=L
    else {
        X=W; avg=W
        for (iter=1;iter<=maxiter;iter++) {
            Xnew=W*X
            if (limittype=="power") {
                err=max(abs(Xnew-X))
                referr=max(abs(Xnew-L))
            }
            else {
                oldavg=avg
                avg=(iter*avg+Xnew)/(iter+1)
                err=max(abs(avg-oldavg))
                referr=max(abs(avg-L))
            }
            X=Xnew
            if (err<=tol & referr<=tol) break
        }
        if (iter>maxiter)
            ahp__fail(sprintf("ANP iteration failed the direct-reference check within %g iterations; use solver(direct) or increase maxiter()",maxiter))
        if (limittype=="cesaro") X=avg
    }
    residual=max((max(abs(W*X-X)),max(abs(X*W-X))))
    projectionerr=max(abs(X*X-X))
    p=rowsum(X)/n
    p=p/sum(p)
    spread=max(abs(X:-p*J(1,n,1)))

    st_matrix(out_super,W)
    st_matrix(out_limit,X)
    st_matrix(out_priority,p)
    st_matrix(out_membership,membership)
    st_matrix(out_classes,classinfo)
    st_local(out_nodes_local,invtokens(nodes'))
    st_local(out_clusters_local,invtokens(clusters'))
    st_local("network_N",strofreal(n))
    st_local("network_K",strofreal(K))
    st_local("network_iterations",strofreal(iter))
    st_local("network_error",strofreal(err))
    st_local("network_spread",strofreal(spread))
    st_local("network_reference_error",strofreal(referr,"%21.15g"))
    st_local("network_residual",strofreal(residual,"%21.15g"))
    st_local("network_projection_error",strofreal(projectionerr,"%21.15g"))
    st_local("network_adjustment",strofreal(adjustment,"%21.15g"))
    st_local("network_closed",strofreal(max(classinfo[,2])))
    st_local("network_transient",strofreal(sum(classinfo[,2]:==0)))
    st_local("network_period",strofreal(max(classinfo[,3])))
}

end
