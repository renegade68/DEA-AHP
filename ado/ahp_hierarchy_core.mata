/* Data-first hierarchy orchestration.  Node estimation and synthesis are
   deliberately separate so additional judgment and synthesis modules can be
   introduced without changing the public data contract. */
version 16.0
capture mata: mata drop ahph__version()
capture mata: mata drop ahph__uniq()
capture mata: mata drop ahph__uniqpreserve()
capture mata: mata drop ahph__pos()
capture mata: mata drop ahph__check_names()
capture mata: mata drop ahph__run()
mata:

real scalar ahph__version() return(6)

string colvector ahph__uniq(string colvector x)
{
    if (rows(x)==0) return(J(0,1,""))
    return(uniqrows(sort(x,1)))
}

string colvector ahph__uniqpreserve(string colvector x)
{
    string colvector out
    real scalar i
    out=J(0,1,"")
    for (i=1;i<=rows(x);i++) if (!ahph__pos(out,x[i])) out=out\x[i]
    return(out)
}

real scalar ahph__pos(string colvector x, string scalar value)
{
    real vector z
    z=selectindex(x:==value)
    return(length(z)==0 ? 0 : z[1])
}

void ahph__check_names(string colvector x)
{
    real scalar i
    for (i=1;i<=rows(x);i++) {
        if (x[i]=="" | strtoname(x[i])!=x[i])
            ahp__fail(sprintf("node and evaluator identifiers must be valid Stata names; invalid value: %s",x[i]))
    }
}

void ahph__run(
    string scalar valuevar, string scalar lowervar, string scalar uppervar,
    string scalar parentvar, string scalar leftvar,
    string scalar rightvar, string scalar evalvar, string scalar evalweightvar,
    string scalar tousevar, string scalar method, string scalar aggregation,
    string scalar pool, string scalar judgment, string scalar synthesis, real scalar tol,
    string scalar structureframe, string scalar out_weights, string scalar out_scores,
    string scalar out_interval_weights, string scalar out_interval_edges,
    string scalar out_fuzzy_weights, string scalar out_fuzzy_edges,
    string scalar out_nodes, string scalar out_edges,
    string scalar out_diag, string scalar out_structure,
    string scalar out_root_local, string scalar out_alt_local,
    string scalar out_edge_parent_local, string scalar out_edge_child_local,
    string scalar out_structure_node_local, string scalar out_structure_parent_local)
{
    real colvector use, value, lowerjudg, uppervalue, ew, idx, seen, plev, nglobal, terminal, altlev
    real colvector ngloball, nglobalm, nglobalu, locall, localm, localu, gl, gu, rawl, rawm, rawu
    string colvector parent, left, right, evaluator, parents, evaluators, nodes
    string colvector children, internalchildren, roots, alternatives, allchildren
    string colvector edgep, edgec
    string colvector snode, sparent, sparentout, stype, oldframe
    real colvector sorder, stypecode, structlevel
    real matrix A, AL, AU, stack, lstack, ustack, indiv, G, diagnostics, edges
    real matrix intervaledges, intervalweights, fuzzyweights, nodetable, structuretable
    real rowvector q
    real colvector localw, rawscores
    real scalar i,j,h,k,np,ne,n,ii,jj,obs,pass,changed,rooti,pi,ci,ei
    real scalar pg, pgl, pgu, contribution, maxlev, nodelevel, hasstructure, vtype, vorder, nterminal
    struct ahp_result scalar z

    use=st_data(.,tousevar)
    idx=selectindex(use:==1)
    value=select(st_data(.,valuevar),use:==1)
    lowerjudg=(lowervar=="" ? value : select(st_data(.,lowervar),use:==1))
    uppervalue=(uppervar=="" ? value : select(st_data(.,uppervar),use:==1))
    parent=select(st_sdata(.,parentvar),use:==1)
    left=select(st_sdata(.,leftvar),use:==1)
    right=select(st_sdata(.,rightvar),use:==1)
    evaluator=select(st_sdata(.,evalvar),use:==1)
    if (evalweightvar!="") ew=select(st_data(.,evalweightvar),use:==1)
    else ew=J(rows(value),1,1)
    if (rows(value)==0) {
        value=lowerjudg=uppervalue=ew=J(0,1,.)
        parent=left=right=evaluator=J(0,1,"")
    }

    if (any(missing(value)) | any(value:<=0)) ahp__fail("judgment values must be positive and nonmissing")
    if (any(missing(uppervalue)) | any(uppervalue:<=0)) ahp__fail("upper judgment values must be positive and nonmissing")
    if (judgment=="interval" & any(value:>uppervalue)) ahp__fail("interval lower judgments may not exceed upper judgments")
    if (judgment=="interval") value=sqrt(value:*uppervalue)
    if (judgment=="fuzzy" & (any(lowerjudg:>value) | any(value:>uppervalue)))
        ahp__fail("fuzzy judgments must satisfy lower <= mode <= upper")
    if (any(parent:=="") | any(left:=="") | any(right:=="") | any(evaluator:==""))
        ahp__fail("parent(), left(), right(), and evaluator() values may not be empty")
    if (any(left:==right)) ahp__fail("a node cannot be compared with itself")
    if (any(missing(ew)) | any(ew:<=0)) ahp__fail("evaluator weights must be positive and nonmissing")

    hasstructure=(structureframe!="")
    parents=ahph__uniq(parent)
    evaluators=ahph__uniq(evaluator)
    if (rows(evaluators)==0 & hasstructure) evaluators="single"
    allchildren=ahph__uniq(left\right)
    nodes=ahph__uniq(parents\allchildren)

    if (hasstructure) {
        oldframe=st_framecurrent()
        if (!st_frameexists(structureframe)) ahp__fail(sprintf("structure frame %s not found",structureframe))
        st_framecurrent(structureframe)
        if (!st_varindex("node")) {
            st_framecurrent(oldframe)
            ahp__fail("structure() frame must contain string variable node")
        }
        if (!st_varindex("parent")) {
            st_framecurrent(oldframe)
            ahp__fail("structure() frame must contain string variable parent")
        }
        if (!st_isstrvar(st_varindex("node")) | !st_isstrvar(st_varindex("parent"))) {
            st_framecurrent(oldframe)
            ahp__fail("structure node and parent variables must be strings")
        }
        if (st_varindex("type") & !st_isstrvar(st_varindex("type"))) {
            st_framecurrent(oldframe)
            ahp__fail("structure type variable must be string")
        }
        if (st_varindex("order") & st_isstrvar(st_varindex("order"))) {
            st_framecurrent(oldframe)
            ahp__fail("structure order variable must be numeric")
        }
        snode=st_sdata(.,"node"); sparent=st_sdata(.,"parent")
        vtype=st_varindex("type"); vorder=st_varindex("order")
        stype=(!vtype ? J(rows(snode),1,"") : strlower(strtrim(st_sdata(.,"type"))))
        sorder=(!vorder ? (1..rows(snode))' : st_data(.,"order"))
        st_framecurrent(oldframe)
        if (rows(snode)==0 | any(snode:=="")) ahp__fail("structure node values may not be empty")
        if (any(missing(sorder))) ahp__fail("structure order values must be nonmissing")
        if (any((stype:!="") :& (stype:!="goal") :& (stype:!="criterion") :& (stype:!="alternative")))
            ahp__fail("structure type values must be goal, criterion, or alternative")
        ahph__check_names(ahph__uniq(snode\select(sparent,sparent:!="")))
        roots=select(snode,sparent:=="")
        if (rows(roots)!=1) ahp__fail("structure() must declare exactly one root with empty parent")
        parents=ahph__uniqpreserve(select(sparent,sparent:!=""))
        nodes=ahph__uniqpreserve(snode)
        allchildren=ahph__uniqpreserve(select(snode,sparent:!=""))
        if (!ahph__pos(nodes,roots[1])) ahp__fail("invalid structure root")
        if (!rows(parents)) ahp__fail("structure() root must have at least one child")
        for (i=1;i<=rows(parents);i++) if (!ahph__pos(nodes,parents[i]))
            ahp__fail(sprintf("structure parent %s has no node declaration",parents[i]))
        for (i=1;i<=rows(snode);i++) {
            idx=selectindex((snode:==snode[i]) :& (sparent:==sparent[i]))
            if (length(idx)>1) ahp__fail(sprintf("duplicate structure edge %s -> %s",sparent[i],snode[i]))
            if (sparent[i]!="") {
                idx=selectindex((sparent:==sparent[i]) :& (sorder:==sorder[i]))
                if (length(idx)>1) ahp__fail(sprintf("structure order must be unique within parent %s",sparent[i]))
            }
            if (stype[i]!="") {
                if (sparent[i]=="" & stype[i]!="goal") ahp__fail("the structure root must have type goal")
                if (ahph__pos(parents,snode[i]) & snode[i]!=roots[1] & stype[i]!="criterion")
                    ahp__fail(sprintf("internal node %s must have type criterion",snode[i]))
                if (!ahph__pos(parents,snode[i]) & stype[i]!="alternative")
                    ahp__fail(sprintf("terminal node %s must have type alternative",snode[i]))
            }
        }
        for (i=1;i<=rows(parent);i++) {
            if (!ahph__pos(parents,parent[i])) ahp__fail(sprintf("comparison parent %s is absent from structure()",parent[i]))
            idx=selectindex((sparent:==parent[i]) :& (snode:==left[i]))
            if (!length(idx)) ahp__fail(sprintf("child %s is not declared under parent %s",left[i],parent[i]))
            idx=selectindex((sparent:==parent[i]) :& (snode:==right[i]))
            if (!length(idx)) ahp__fail(sprintf("child %s is not declared under parent %s",right[i],parent[i]))
        }
    }
    ahph__check_names(nodes)
    ahph__check_names(evaluators)
    np=rows(parents); ne=rows(evaluators)

    q=J(1,ne,.)
    for (h=1;h<=ne;h++) {
        idx=selectindex(evaluator:==evaluators[h])
        if (!length(idx)) q[h]=1
        else {
            if (max(ew[idx])-min(ew[idx])>tol) ahp__fail("evaluatorweight() must be constant within evaluator")
            q[h]=ew[idx[1]]
        }
    }
    q=q/sum(q)

    /* Internal nodes have their own comparison group.  They must form a
       rooted tree; terminal alternatives may occur below many criteria. */
    internalchildren=J(0,1,"")
    for (i=1;i<=rows(allchildren);i++) if (ahph__pos(parents,allchildren[i]))
        internalchildren=internalchildren\allchildren[i]
    internalchildren=ahph__uniq(internalchildren)
    if (!hasstructure) {
        roots=J(0,1,"")
        for (i=1;i<=np;i++) if (!ahph__pos(internalchildren,parents[i])) roots=roots\parents[i]
        if (rows(roots)!=1) ahp__fail("the inferred hierarchy must have exactly one root")
    }
    for (i=1;i<=rows(internalchildren);i++) {
        k=0
        for (j=1;j<=np;j++) {
            idx=(hasstructure ? selectindex((sparent:==parents[j]) :& (snode:==internalchildren[i])) :
                selectindex((parent:==parents[j]) :& ((left:==internalchildren[i]) :| (right:==internalchildren[i]))))
            if (length(idx)>0) k++
        }
        if (k!=1) ahp__fail(sprintf("internal node %s must have exactly one parent",internalchildren[i]))
    }

    plev=J(np,1,.)
    plev[ahph__pos(parents,roots[1])]=1
    for (pass=1;pass<=np;pass++) {
        changed=0
        for (i=1;i<=np;i++) if (!missing(plev[i])) {
            if (hasstructure) {
                idx=selectindex(sparent:==parents[i]); idx=idx[order(sorder[idx],1)]
                children=ahph__uniqpreserve(snode[idx])
            }
            else children=ahph__uniq(select(left,parent:==parents[i])\select(right,parent:==parents[i]))
            for (j=1;j<=rows(children);j++) {
                k=ahph__pos(parents,children[j])
                if (k) {
                    if (missing(plev[k])) {
                        plev[k]=plev[i]+1
                        changed=1
                    }
                    else if (plev[k]!=plev[i]+1) ahp__fail("the hierarchy contains a cycle or inconsistent internal-node depth")
                }
            }
        }
        if (!changed) break
    }
    if (any(missing(plev))) ahp__fail("all comparison groups must be connected to the inferred root")

    diagnostics=J(np,7,.)
    edges=J(0,4,.)
    intervaledges=J(0,4,.)
    edgep=edgec=J(0,1,"")
    nglobal=J(rows(nodes),1,0)
    ngloball=nglobalm=nglobalu=J(rows(nodes),1,0)
    terminal=J(rows(nodes),1,0)
    altlev=J(rows(nodes),1,.)
    nglobal[ahph__pos(nodes,roots[1])]=1
    ngloball[ahph__pos(nodes,roots[1])]=nglobalm[ahph__pos(nodes,roots[1])]=nglobalu[ahph__pos(nodes,roots[1])]=1

    /* Parents are evaluated in level order, so every parent global weight is
       available before its outgoing contributions are propagated. */
    maxlev=max(plev)
    for (pass=1;pass<=maxlev;pass++) for (i=1;i<=np;i++) if (plev[i]==pass) {
        if (hasstructure) {
            idx=selectindex(sparent:==parents[i]); idx=idx[order(sorder[idx],1)]
            children=ahph__uniqpreserve(snode[idx])
        }
        else children=ahph__uniq(select(left,parent:==parents[i])\select(right,parent:==parents[i]))
        n=rows(children)
        if (n<1) ahp__fail(sprintf("parent %s has no children",parents[i]))
        if (n==1) {
            idx=selectindex(parent:==parents[i])
            if (length(idx)) ahp__fail(sprintf("unary parent %s must not have comparison rows",parents[i]))
            localw=1
            locall=localm=localu=1
            diagnostics[i,.]=(1,ne,1,0,0,1,0)
        }
        else {
          stack=J(ne*n,n,.)
          if (judgment!="crisp") {
              lstack=J(ne*n,n,.)
              ustack=J(ne*n,n,.)
          }
          indiv=J(n,ne,.)
          for (h=1;h<=ne;h++) {
            A=I(n); seen=J(n,n,0)
            if (judgment!="crisp") AL=AU=I(n)
            idx=selectindex((parent:==parents[i]) :& (evaluator:==evaluators[h]))
            for (k=1;k<=length(idx);k++) {
                obs=idx[k]
                ii=ahph__pos(children,left[obs]); jj=ahph__pos(children,right[obs])
                if (ii==0 | jj==0 | ii==jj) ahp__fail("internal comparison-index error")
                if (seen[ii,jj] | seen[jj,ii])
                    ahp__fail(sprintf("duplicate comparison under parent %s for evaluator %s",parents[i],evaluators[h]))
                A[ii,jj]=value[obs]; A[jj,ii]=1/value[obs]
                if (judgment!="crisp") {
                    AL[ii,jj]=lowerjudg[obs]; AU[ii,jj]=uppervalue[obs]
                    AL[jj,ii]=1/uppervalue[obs]; AU[jj,ii]=1/lowerjudg[obs]
                }
                seen[ii,jj]=seen[jj,ii]=1
            }
            if (sum(seen)/2 != n*(n-1)/2)
                ahp__fail(sprintf("incomplete comparisons under parent %s for evaluator %s",parents[i],evaluators[h]))
            z=ahp__priority(A,method,tol)
            indiv[,h]=z.w
            stack[((h-1)*n+1)..(h*n),.]=A
            if (judgment!="crisp") {
                lstack[((h-1)*n+1)..(h*n),.]=AL
                ustack[((h-1)*n+1)..(h*n),.]=AU
            }
          }
          if (ne==1 | aggregation=="aij") {
            G=(ne==1 ? stack[1..n,.] : ahp__aggregate_aij(stack,q))
            z=ahp__priority(G,method,tol)
            localw=z.w
            diagnostics[i,.]=(n,ne,z.lambda,z.ci,z.cr,z.cr<=.10,z.reciprocal_error)
          }
          else if (aggregation=="aip") {
            localw=ahp__pool_priorities(indiv,q,pool)
            diagnostics[i,.]=(n,ne,.,.,.,.,.)
          }
          else ahp__fail("aggregate() must be aij or aip")

          if (judgment!="crisp") {
              AL=AU=J(n,n,1)
              for (h=1;h<=ne;h++) {
                  AL=AL:*exp(q[h]:*ln(lstack[((h-1)*n+1)..(h*n),.]))
                  AU=AU:*exp(q[h]:*ln(ustack[((h-1)*n+1)..(h*n),.]))
              }
              gl=gu=J(n,1,.)
              for (j=1;j<=n;j++) {
                  gl[j]=exp(sum(ln(AL[j,.]))/n)
                  gu[j]=exp(sum(ln(AU[j,.]))/n)
              }
              locall=localu=J(n,1,.)
              if (judgment=="interval") for (j=1;j<=n;j++) {
                      locall[j]=gl[j]/(gl[j]+sum(gu)-gu[j])
                      localu[j]=gu[j]/(gu[j]+sum(gl)-gl[j])
                  }
              else {
                  locall=gl/sum(gu)
                  localu=gu/sum(gl)
                  localm=localw
              }
          }
        }

        nterminal=0
        for (j=1;j<=n;j++) if (!ahph__pos(parents,children[j])) nterminal++
        if (synthesis=="ideal") {
            if (nterminal>0 & nterminal<n)
                ahp__fail(sprintf("synthesis(ideal) requires parent %s to contain either only internal nodes or only terminal alternatives",parents[i]))
            if (nterminal==n) localw=localw/max(localw)
        }

        pi=ahph__pos(nodes,parents[i]); pg=nglobal[pi]
        pgl=ngloball[pi]; pgu=nglobalu[pi]
        for (j=1;j<=n;j++) {
            ci=ahph__pos(nodes,children[j]); contribution=pg*localw[j]
            if (ahph__pos(parents,children[j])) {
                nglobal[ci]=contribution
                if (judgment!="crisp") {
                    ngloball[ci]=pgl*locall[j]
                    if (judgment=="fuzzy") nglobalm[ci]=nglobalm[pi]*localm[j]
                    nglobalu[ci]=pgu*localu[j]
                }
            }
            else {
                nglobal[ci]=nglobal[ci]+contribution
                if (judgment!="crisp") {
                    ngloball[ci]=ngloball[ci]+pgl*locall[j]
                    if (judgment=="fuzzy") nglobalm[ci]=nglobalm[ci]+nglobalm[pi]*localm[j]
                    nglobalu[ci]=nglobalu[ci]+pgu*localu[j]
                }
                terminal[ci]=1
                altlev[ci]=(missing(altlev[ci]) ? plev[i]+1 : max((altlev[ci],plev[i]+1)))
            }
            edgep=edgep\parents[i]; edgec=edgec\children[j]
            edges=edges\(plev[i],localw[j],pg,contribution)
            if (judgment!="crisp")
                intervaledges=intervaledges\(locall[j],localu[j],pgl*locall[j],pgu*localu[j])
        }
    }

    alternatives=ahph__uniq(select(nodes,terminal:==1))
    if (rows(alternatives)<1) ahp__fail("the hierarchy has no terminal alternatives")
    localw=J(rows(alternatives),1,.)
    for (i=1;i<=rows(alternatives);i++) localw[i]=nglobal[ahph__pos(nodes,alternatives[i])]
    rawscores=localw
    if (synthesis=="distributive" & abs(sum(localw)-1)>tol)
        ahp__fail("terminal priorities do not conserve unit mass")
    if (sum(localw)<=0) ahp__fail("terminal synthesis scores must have positive sum")
    localw=localw/sum(localw)

    if (judgment=="interval") {
        rawl=rawu=J(rows(alternatives),1,.)
        for (i=1;i<=rows(alternatives);i++) {
            rawl[i]=ngloball[ahph__pos(nodes,alternatives[i])]
            rawu[i]=nglobalu[ahph__pos(nodes,alternatives[i])]
        }
        intervalweights=J(2,rows(alternatives),.)
        for (i=1;i<=rows(alternatives);i++) {
            intervalweights[1,i]=rawl[i]/(rawl[i]+sum(rawu)-rawu[i])
            intervalweights[2,i]=rawu[i]/(rawu[i]+sum(rawl)-rawl[i])
            if (localw[i]<intervalweights[1,i]-tol | localw[i]>intervalweights[2,i]+tol)
                ahp__fail("central interval priority lies outside its computed enclosure")
        }
        st_matrix(out_interval_weights,intervalweights)
        st_matrix(out_interval_edges,intervaledges)
    }
    else if (judgment=="fuzzy") {
        rawl=rawm=rawu=J(rows(alternatives),1,.)
        for (i=1;i<=rows(alternatives);i++) {
            rawl[i]=ngloball[ahph__pos(nodes,alternatives[i])]
            rawm[i]=nglobalm[ahph__pos(nodes,alternatives[i])]
            rawu[i]=nglobalu[ahph__pos(nodes,alternatives[i])]
        }
        fuzzyweights=J(3,rows(alternatives),.)
        fuzzyweights[1,.]=rawl'
        fuzzyweights[2,.]=rawm'
        fuzzyweights[3,.]=rawu'
        localw=(fuzzyweights[1,.]'+fuzzyweights[2,.]'+fuzzyweights[3,.]')/3
        rawscores=localw
        localw=localw/sum(localw)
        st_matrix(out_fuzzy_weights,fuzzyweights)
        st_matrix(out_fuzzy_edges,intervaledges)
    }

    nodetable=J(rows(nodes),3,.)
    for (i=1;i<=rows(nodes);i++) {
        pi=ahph__pos(parents,nodes[i])
        if (pi) nodelevel=plev[pi]
        else nodelevel=altlev[i]
        nodetable[i,.]=(nodelevel,nglobal[i],terminal[i])
    }
    st_matrix(out_weights,localw')
    st_matrix(out_scores,rawscores')
    st_matrix(out_nodes,nodetable)
    st_matrix(out_edges,edges)
    st_matrix(out_diag,diagnostics)

    if (hasstructure) {
        structuretable=J(rows(snode),3,.)
        stypecode=J(rows(snode),1,.)
        for (i=1;i<=rows(snode);i++) {
            pi=ahph__pos(parents,snode[i])
            if (sparent[i]=="") structlevel=1
            else structlevel=plev[ahph__pos(parents,sparent[i])]+1
            stypecode[i]=(stype[i]=="goal" ? 1 : (stype[i]=="criterion" ? 2 : (stype[i]=="alternative" ? 3 : 0)))
            structuretable[i,.]=(structlevel,stypecode[i],sorder[i])
        }
        st_matrix(out_structure,structuretable)
        st_local(out_structure_node_local,invtokens(snode'))
        sparentout=sparent
        sparentout[selectindex(sparentout:=="")]="."
        st_local(out_structure_parent_local,invtokens(sparentout'))
        st_local("hier_structure_ids",invtokens(("structure":+strofreal((1..rows(snode))'))'))
    }

    st_local(out_root_local,roots[1])
    st_local(out_alt_local,invtokens(alternatives'))
    st_local(out_edge_parent_local,invtokens(edgep'))
    st_local(out_edge_child_local,invtokens(edgec'))
    st_local("hier_nodes",invtokens(nodes'))
    st_local("hier_parents",invtokens(parents'))
    st_local("hier_edge_ids",invtokens(("edge":+strofreal((1..rows(edges))'))'))
    st_local("hier_levels",strofreal(max((max(plev),max(select(altlev,terminal:==1))))))
    st_local("hier_evaluators",strofreal(ne))
}

end
