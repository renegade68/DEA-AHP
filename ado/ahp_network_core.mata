/* Long-format ANP supermatrix construction and limiting priorities. */
version 16.0
capture mata: mata drop ahpn__version()
capture mata: mata drop ahpn__uniq()
capture mata: mata drop ahpn__pos()
capture mata: mata drop ahpn__run()
mata:

real scalar ahpn__version() return(1)

string colvector ahpn__uniq(string colvector x)
{
    if (rows(x)==0) return(J(0,1,""))
    return(uniqrows(sort(x,1)))
}

real scalar ahpn__pos(string colvector x, string scalar value)
{
    real colvector z
    z=selectindex(x:==value)
    return(rows(z) ? z[1] : 0)
}

void ahpn__run(
    string scalar weightvar, string scalar sourcevar, string scalar targetvar,
    string scalar sourceclustervar, string scalar targetclustervar,
    string scalar clusterweightvar, string scalar tousevar, string scalar limittype,
    real scalar maxiter, real scalar tol, string scalar out_super,
    string scalar out_limit, string scalar out_priority, string scalar out_membership,
    string scalar out_nodes_local, string scalar out_clusters_local)
{
    real colvector use, weight, cw, idx, membership, p
    string colvector source, target, sourcecluster, targetcluster, nodes, clusters, active
    real matrix W, X, Xnew, avg, oldavg
    real scalar i,j,k,n,K,iter,err,blocksum,cwij,spread

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
        if (rows(idx)>1) ahp__fail(sprintf("duplicate network edge %s -> %s",source[i],target[i]))
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
            for (i=1;i<=rows(idx);i++)
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

    X=W; avg=W; err=.
    for (iter=1;iter<=maxiter;iter++) {
        Xnew=W*X
        if (limittype=="power") err=max(abs(Xnew-X))
        else {
            oldavg=avg
            avg=(iter*avg+Xnew)/(iter+1)
            err=max(abs(avg-oldavg))
        }
        X=Xnew
        if (err<=tol) break
    }
    if (iter>maxiter) ahp__fail(sprintf("ANP limit did not converge within %g iterations; consider limit(cesaro) or a larger maxiter()",maxiter))
    if (limittype=="cesaro") X=avg
    p=rowsum(X)/n
    p=p/sum(p)
    spread=max(abs(X:-p*J(1,n,1)))

    st_matrix(out_super,W)
    st_matrix(out_limit,X)
    st_matrix(out_priority,p)
    st_matrix(out_membership,membership)
    st_local(out_nodes_local,invtokens(nodes'))
    st_local(out_clusters_local,invtokens(clusters'))
    st_local("network_N",strofreal(n))
    st_local("network_K",strofreal(K))
    st_local("network_iterations",strofreal(iter))
    st_local("network_error",strofreal(err))
    st_local("network_spread",strofreal(spread))
}

end
