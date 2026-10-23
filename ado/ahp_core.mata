/* Code author: Lee, Choonjoo.
   Mata computational core for ahp and dahp.
   The default classical AHP path follows Saaty (1987, 1990): positive
   reciprocal matrices, the normalized principal right eigenvector,
   CI=(lambda_max-n)/(n-1), CR=CI/RI, and the 0.10 diagnostic convention.
   method(geomean), group aggregation, and context pooling are explicitly
   identified extensions and do not replace that default path.
   Methodological basis: Saaty (1980, 1987), Aczel and Saaty (1983), and
   Crawford and Williams (1985). */
version 16.0
mata:

struct ahp_result {
    real colvector w
    real scalar lambda
    real scalar ci
    real scalar cr
    real scalar reciprocal_error
}

real scalar ahp__ri(real scalar n)
{
    real rowvector ri
    /* n=1,...,10: Saaty (1987, p. 171), 500 random reciprocal matrices. */
    ri = (0, 0, 0.58, 0.90, 1.12, 1.24, 1.32, 1.41, 1.45, 1.49, 1.51, 1.48, 1.56, 1.57, 1.59)
    if (n <= cols(ri)) return(ri[n])
    /* Large-n approximation 1.98(n-2)/n; reported explicitly in the manuscript. */
    return(1.98 * (n - 2) / n)
}

void ahp__synthesize(
    string scalar parent_name,
    string scalar local_name,
    real scalar tol,
    string scalar out_w,
    string scalar out_contributions)
{
    real matrix P, L, C
    real colvector p, w

    P = st_matrix(parent_name)
    L = st_matrix(local_name)
    if (rows(P) == 1) p = P'
    else if (cols(P) == 1) p = P
    else ahp__fail("the parent-priority matrix must be a row or column vector")
    if (rows(L) < 1 | cols(L) != rows(p)) ahp__fail("local-priority columns must match the number of parent priorities")
    if (any(missing(p)) | any(p :< 0) | sum(p) <= 0) ahp__fail("parent priorities must be nonnegative, nonmissing, and have a positive sum")
    if (any(missing(L)) | any(L :< 0)) ahp__fail("local priorities must be nonnegative and nonmissing")
    p = p / sum(p)
    if (max(abs(colsum(L) :- J(1, cols(L), 1))) > tol) ahp__fail("each local-priority column must sum to one within tolerance")

    C = L :* p'
    w = C * J(cols(C), 1, 1)
    w = w / sum(w)
    st_matrix(out_contributions, C)
    st_matrix(out_w, w')
}

void dahp__integrate_synth(
    string scalar context_matrix,
    string scalar context_weights,
    string scalar pool,
    string scalar out_w)
{
    real matrix CW
    real rowvector q
    real colvector w

    CW = st_matrix(context_matrix)
    q = ahp__normalize_weights(strtoreal(tokens(context_weights)), rows(CW))
    w = ahp__pool_priorities(CW', q, pool)
    st_matrix(out_w, w')
}

void dahp__map_priority(
    string scalar local_weights,
    string scalar mapping_matrix,
    real scalar tol,
    string scalar out_w)
{
    real matrix W, M
    real colvector w, mapped

    W = st_matrix(local_weights)
    if (rows(W) == 1) w = W'
    else if (cols(W) == 1) w = W
    else ahp__fail("local weights for mapping must be a vector")
    M = st_matrix(mapping_matrix)
    if (rows(M) < 1 | cols(M) != rows(w)) ahp__fail("mapping columns must equal the number of local alternatives")
    if (any(missing(M)) | any(M :< 0)) ahp__fail("mapping entries must be nonnegative and nonmissing")
    if (max(abs(colsum(M) :- J(1, cols(M), 1))) > tol) ahp__fail("each mapping column must sum to one within tolerance")
    if (any(missing(w)) | any(w :< 0) | sum(w) <= 0) ahp__fail("local priorities must be nonnegative, nonmissing, and have positive mass")

    w = w / sum(w)
    mapped = M * w
    if (abs(sum(mapped) - 1) > tol) ahp__fail("mapping failed the priority-mass conservation check")
    st_matrix(out_w, mapped')
}

real scalar ahp__empirical_quantile(real colvector x, real scalar p)
{
    real colvector z
    real scalar k
    z = sort(x, 1)
    k = ceil(p * rows(z))
    if (k < 1) k = 1
    if (k > rows(z)) k = rows(z)
    return(z[k])
}

void ahp__montecarlo(string scalar matrix_name, real scalar reps, real scalar sigma,
    string scalar method, real scalar seed, real scalar tol,
    string scalar out_draws, string scalar out_ranks,
    string scalar out_summary, string scalar out_diagnostics)
{
    real matrix A, B, draws, ranks, summary, diagnostics
    real colvector ord, rankv
    real scalar n, r, i, j
    struct ahp_result scalar z
    A = st_matrix(matrix_name)
    ahp__validate(A, tol)
    n = rows(A)
    if (seed >= 0) rseed(seed)
    draws = J(reps, n, .)
    ranks = J(reps, n, .)
    diagnostics = J(reps, 2, .)
    for (r=1; r<=reps; r++) {
        B = A
        for (i=1; i<=n; i++) {
            B[i,i] = 1
            for (j=i+1; j<=n; j++) {
                B[i,j] = A[i,j] * exp(rnormal(1,1,0,sigma))
                B[j,i] = 1 / B[i,j]
            }
        }
        z = ahp__priority(B, method, tol)
        draws[r,.] = z.w'
        ord = order(-z.w, 1)
        rankv = J(n, 1, .)
        rankv[ord] = (1..n)'
        ranks[r,.] = rankv'
        diagnostics[r,.] = (z.cr, z.cr <= .10)
    }
    summary = J(n, 7, .)
    for (i=1; i<=n; i++) {
        summary[i,1] = mean(draws[,i])
        summary[i,2] = sqrt(variance(draws[,i]))
        summary[i,3] = ahp__empirical_quantile(draws[,i], .025)
        summary[i,4] = ahp__empirical_quantile(draws[,i], .50)
        summary[i,5] = ahp__empirical_quantile(draws[,i], .975)
        summary[i,6] = mean(ranks[,i] :== 1)
        summary[i,7] = mean(ranks[,i])
    }
    st_matrix(out_draws, draws)
    st_matrix(out_ranks, ranks)
    st_matrix(out_summary, summary)
    st_matrix(out_diagnostics, diagnostics)
}

real colvector ahp__perturb_simplex(real colvector x, real scalar sigma)
{
    real colvector z
    if (any(missing(x)) | any(x :< 0) | sum(x) <= 0) ahp__fail("simplex inputs must be nonnegative, nonmissing, and have positive mass")
    z = x
    if (sigma > 0) z = z :* exp(rnormal(rows(z), 1, 0, sigma))
    return(z / sum(z))
}

real matrix ahp__perturb_columns(real matrix X, real scalar sigma, real scalar tol)
{
    real matrix Z
    real scalar j
    if (any(missing(X)) | any(X :< 0)) ahp__fail("column-simplex inputs must be nonnegative and nonmissing")
    if (max(abs(colsum(X) :- J(1, cols(X), 1))) > tol) ahp__fail("each column-simplex input must sum to one")
    Z = X
    for (j=1; j<=cols(Z); j++) Z[,j] = ahp__perturb_simplex(Z[,j], sigma)
    return(Z)
}

void dahp__joint_montecarlo(string scalar matrix_names, real scalar contexts,
    string scalar context_weights, real scalar reps, real scalar psigma,
    real scalar lsigma, real scalar msigma, real scalar csigma,
    string scalar pool, real scalar seed, real scalar tol,
    string scalar out_draws, string scalar out_ranks,
    string scalar out_summary, string scalar out_context_draws)
{
    string rowvector names
    real matrix P, L, M, Lt, Mt, V, draws, ranks, summary, qdraws
    real colvector p, w, mapped, q, qbase, integrated, ord, rankv
    real scalar r, t, i, k
    names = tokens(matrix_names)
    qbase = ahp__normalize_weights(strtoreal(tokens(context_weights)), contexts)'
    M = st_matrix(names[3])
    k = rows(M)
    if (seed >= 0) rseed(seed)
    draws = J(reps, k, .)
    ranks = J(reps, k, .)
    qdraws = J(reps, contexts, .)
    for (r=1; r<=reps; r++) {
        V = J(k, contexts, .)
        for (t=1; t<=contexts; t++) {
            P = st_matrix(names[3*t-2])
            L = st_matrix(names[3*t-1])
            M = st_matrix(names[3*t])
            if (rows(P)==1) p = P'
            else if (cols(P)==1) p = P
            else ahp__fail("each parent-priority input must be a vector")
            if (rows(M) != k | cols(L) != rows(p) | cols(M) != rows(L)) ahp__fail("incompatible hierarchy or mapping dimensions")
            p = ahp__perturb_simplex(p, psigma)
            Lt = ahp__perturb_columns(L, lsigma, tol)
            Mt = ahp__perturb_columns(M, msigma, tol)
            w = Lt * p
            mapped = Mt * w
            V[,t] = mapped / sum(mapped)
        }
        q = ahp__perturb_simplex(qbase, csigma)
        qdraws[r,.] = q'
        if (strlower(pool)=="arithmetic") integrated = V * q
        else if (strlower(pool)=="geometric") {
            if (any(V :<= 0)) ahp__fail("geometric context pooling requires strictly positive mapped priorities")
            integrated = exp(ln(V) * q)
            integrated = integrated / sum(integrated)
        }
        else ahp__fail("timepool() must be arithmetic or geometric")
        draws[r,.] = integrated'
        ord = order(-integrated, 1)
        rankv = J(k, 1, .)
        rankv[ord] = (1..k)'
        ranks[r,.] = rankv'
    }
    summary = J(k, 7, .)
    for (i=1; i<=k; i++) {
        summary[i,1] = mean(draws[,i])
        summary[i,2] = sqrt(variance(draws[,i]))
        summary[i,3] = ahp__empirical_quantile(draws[,i], .025)
        summary[i,4] = ahp__empirical_quantile(draws[,i], .50)
        summary[i,5] = ahp__empirical_quantile(draws[,i], .975)
        summary[i,6] = mean(ranks[,i] :== 1)
        summary[i,7] = mean(ranks[,i])
    }
    st_matrix(out_draws, draws)
    st_matrix(out_ranks, ranks)
    st_matrix(out_summary, summary)
    st_matrix(out_context_draws, qdraws)
}

real colvector ahp__rank_vector(real colvector w)
{
    real colvector ord, rankv
    ord = order(-w, 1)
    rankv = J(rows(w), 1, .)
    rankv[ord] = (1..rows(w))'
    return(rankv)
}

real scalar ahp__rank_correlation(real colvector a, real colvector b)
{
    real scalar da, db
    da = sqrt(sum((a :- mean(a)):^2))
    db = sqrt(sum((b :- mean(b)):^2))
    if (da == 0 | db == 0) return(1)
    return(sum((a :- mean(a)) :* (b :- mean(b))) / (da*db))
}

void ahp__rank_diagnostics(string scalar draw_name, string scalar baseline_name,
    real scalar tol, string scalar out_rep, string scalar out_winners,
    string scalar out_summary)
{
    real matrix D, R, winners, S
    real colvector b, br, dr
    real scalar r, i, j, n, reversed
    D = st_matrix(draw_name)
    b = st_matrix(baseline_name)
    if (rows(b)==1) b = b'
    if (cols(D)!=rows(b) | rows(D)<1) ahp__fail("draw and baseline dimensions are incompatible")
    if (any(missing(D)) | any(D:<0) | any(missing(b)) | any(b:<0)) ahp__fail("priorities must be nonnegative and nonmissing")
    n = rows(b)
    b = b/sum(b)
    br = ahp__rank_vector(b)
    R = J(rows(D),3,.)
    winners = J(rows(D),n,0)
    for (r=1; r<=rows(D); r++) {
        if (abs(sum(D[r,.])-1)>tol) ahp__fail("each draw must sum to one within tolerance")
        dr = ahp__rank_vector(D[r,.]')
        winners[r,selectindex(dr:==1)] = 1
        reversed = 0
        for (i=1; i<n; i++) for (j=i+1; j<=n; j++) {
            if (abs(b[i]-b[j])>tol & (b[i]-b[j])*(D[r,i]-D[r,j]) < 0) reversed = 1
        }
        R[r,.] = (ahp__rank_correlation(br,dr), dr[selectindex(br:==1)]!=1, reversed)
    }
    S = (mean(R[,1]), ahp__empirical_quantile(R[,1],.025), mean(R[,2]), mean(R[,3]))
    st_matrix(out_rep,R)
    st_matrix(out_winners,winners)
    st_matrix(out_summary,S)
}

void dahp__responsiveness(string scalar context_name, real scalar tol,
    string scalar out_transitions, string scalar out_summary)
{
    real matrix C, T, S
    real colvector a, b, ar, br
    real scalar t
    C = st_matrix(context_name)
    if (rows(C)<2 | cols(C)<2) ahp__fail("responsiveness requires at least two contexts and two alternatives")
    if (any(missing(C)) | any(C:<0)) ahp__fail("context priorities must be nonnegative and nonmissing")
    T = J(rows(C)-1,5,.)
    for (t=1;t<rows(C);t++) {
        a=C[t,.]'; b=C[t+1,.]'
        if (abs(sum(a)-1)>tol | abs(sum(b)-1)>tol) ahp__fail("each context-priority row must sum to one")
        ar=ahp__rank_vector(a); br=ahp__rank_vector(b)
        T[t,.] = (.5*sum(abs(b-a)), max(abs(b-a)), ahp__rank_correlation(ar,br),
            br[selectindex(ar:==1)]!=1, sum(ar:!=br))
    }
    S=(mean(T[,1]),max(T[,1]),mean(T[,3]),mean(T[,4]),mean(T[,5]))
    st_matrix(out_transitions,T)
    st_matrix(out_summary,S)
}

void dahp__markov(string scalar transition_name, string scalar state_weight_name,
    string scalar initial_values, real scalar horizon, real scalar discount,
    real scalar maxiter, real scalar tol, string scalar out_occupancy,
    string scalar out_path, string scalar out_finite, string scalar out_longocc,
    string scalar out_longweights, string scalar out_diagnostics)
{
    real matrix P, W, O, V
    real rowvector q, qnext, q0, avg, d, finite, longw
    real scalar s, k, err, converged
    P=st_matrix(transition_name)
    W=st_matrix(state_weight_name)
    s=rows(P)
    if (s<1 | cols(P)!=s | rows(W)!=s) ahp__fail("incompatible transition and state-priority dimensions")
    if (any(missing(P)) | any(P:<0) | max(abs(rowsum(P):-J(s,1,1)))>tol) ahp__fail("transition matrix must be nonnegative and row-stochastic")
    if (any(missing(W)) | any(W:<0) | max(abs(rowsum(W):-J(s,1,1)))>tol) ahp__fail("each state-priority row must be nonnegative and sum to one")
    q0=strtoreal(tokens(initial_values))
    if (cols(q0)==0) q0=J(1,s,1/s)
    if (cols(q0)!=s | any(missing(q0)) | any(q0:<0) | sum(q0)<=0) ahp__fail("initial distribution must have one nonnegative value per state and positive mass")
    q0=q0/sum(q0)
    O=J(horizon+1,s,.)
    q=q0
    O[1,.]=q
    for (k=1;k<=horizon;k++) {
        q=q*P
        O[k+1,.]=q
    }
    V=O*W
    d=J(1,horizon+1,.)
    for (k=0;k<=horizon;k++) d[k+1]=discount^k
    d=d/sum(d)
    finite=d*V

    q=q0
    avg=q0
    converged=0
    for (k=1;k<=maxiter;k++) {
        qnext=q*P
        if (max(abs(qnext-q))<=tol) {
            q=qnext
            avg=q
            err=max(abs(avg*P-avg))
            converged=1
            break
        }
        q=qnext
        avg=(avg*k+q)/(k+1)
        err=max(abs(avg*P-avg))
        if (err<=tol) {
            converged=1
            break
        }
    }
    if (k>maxiter) k=maxiter
    longw=avg*W
    st_matrix(out_occupancy,O)
    st_matrix(out_path,V)
    st_matrix(out_finite,finite)
    st_matrix(out_longocc,avg)
    st_matrix(out_longweights,longw)
    st_matrix(out_diagnostics,(k,err,converged))
}

real matrix ahp__perturb_rows(real matrix X, real scalar sigma, real scalar tol)
{
    real matrix Z
    real scalar i
    if (any(missing(X)) | any(X:<0) | max(abs(rowsum(X):-J(rows(X),1,1)))>tol) ahp__fail("row-simplex inputs must be nonnegative and sum to one")
    Z=X
    for (i=1;i<=rows(Z);i++) Z[i,.]=ahp__perturb_simplex(Z[i,.]',sigma)'
    return(Z)
}

real rowvector dahp__markov_longrun(real rowvector q0, real matrix P,
    real scalar maxiter, real scalar tol, real rowvector diagnostics)
{
    real rowvector q, qnext, avg
    real scalar k, err, converged
    q=q0; avg=q0; converged=0; err=.
    for (k=1;k<=maxiter;k++) {
        qnext=q*P
        if (max(abs(qnext-q))<=tol) {
            q=qnext; avg=q; err=max(abs(avg*P-avg)); converged=1
            break
        }
        q=qnext
        avg=(avg*k+q)/(k+1)
        err=max(abs(avg*P-avg))
        if (err<=tol) {
            converged=1
            break
        }
    }
    if (k>maxiter) k=maxiter
    diagnostics=(k,err,converged)
    return(avg)
}

real matrix ahp__draw_summary(real matrix D)
{
    real matrix S, R
    real colvector rv
    real scalar i, r, n
    n=cols(D); R=J(rows(D),n,.)
    for (r=1;r<=rows(D);r++) R[r,.]=ahp__rank_vector(D[r,.]')'
    S=J(n,7,.)
    for (i=1;i<=n;i++) {
        S[i,1]=mean(D[,i]); S[i,2]=sqrt(variance(D[,i]))
        S[i,3]=ahp__empirical_quantile(D[,i],.025)
        S[i,4]=ahp__empirical_quantile(D[,i],.50)
        S[i,5]=ahp__empirical_quantile(D[,i],.975)
        S[i,6]=mean(R[,i]:==1); S[i,7]=mean(R[,i])
    }
    return(S)
}

void dahp__markov_mc(string scalar transition_name, string scalar weight_name,
    string scalar initial_values, real scalar horizon, real scalar discount,
    real scalar reps, real scalar tsigma, real scalar wsigma, real scalar isigma,
    real scalar seed, real scalar maxiter, real scalar tol,
    string scalar out_finite_draws, string scalar out_long_draws,
    string scalar out_finite_summary, string scalar out_long_summary,
    string scalar out_transition_draws, string scalar out_sensitivity,
    string scalar out_convergence)
{
    real matrix P0,W0,P,W,O,V,FD,LD,TD,SEN,CD
    real rowvector q0,q,d,finite,lo,diag
    real colvector x,y
    real scalar r,k,i,j,sdx,sdy
    P0=st_matrix(transition_name); W0=st_matrix(weight_name)
    if (rows(P0)!=cols(P0) | rows(W0)!=rows(P0)) ahp__fail("incompatible Markov dimensions")
    P0=ahp__perturb_rows(P0,0,tol); W0=ahp__perturb_rows(W0,0,tol)
    q0=strtoreal(tokens(initial_values))
    if (cols(q0)==0) q0=J(1,rows(P0),1/rows(P0))
    if (cols(q0)!=rows(P0) | any(q0:<0) | any(missing(q0)) | sum(q0)<=0) ahp__fail("invalid initial distribution")
    q0=q0/sum(q0)
    if (seed>=0) rseed(seed)
    FD=J(reps,cols(W0),.); LD=FD
    TD=J(reps,rows(P0)*cols(P0),.); CD=J(reps,3,.)
    d=J(1,horizon+1,.)
    for (k=0;k<=horizon;k++) d[k+1]=discount^k
    d=d/sum(d)
    for (r=1;r<=reps;r++) {
        P=ahp__perturb_rows(P0,tsigma,tol)
        W=ahp__perturb_rows(W0,wsigma,tol)
        q=ahp__perturb_simplex(q0',isigma)'
        O=J(horizon+1,cols(q),.); O[1,.]=q
        for (k=1;k<=horizon;k++) O[k+1,.]=O[k,.]*P
        V=O*W; finite=d*V
        lo=dahp__markov_longrun(q,P,maxiter,tol,diag)*W
        FD[r,.]=finite; LD[r,.]=lo; TD[r,.]=rowshape(P,1); CD[r,.]=diag
    }
    SEN=J(cols(TD),cols(FD),.)
    for (i=1;i<=cols(TD);i++) for (j=1;j<=cols(FD);j++) {
        x=TD[,i]; y=FD[,j]; sdx=sqrt(variance(x)); sdy=sqrt(variance(y))
        if (sdx>0 & sdy>0) SEN[i,j]=sum((x:-mean(x)):*(y:-mean(y))) / sqrt(sum((x:-mean(x)):^2)*sum((y:-mean(y)):^2))
    }
    st_matrix(out_finite_draws,FD); st_matrix(out_long_draws,LD)
    st_matrix(out_finite_summary,ahp__draw_summary(FD))
    st_matrix(out_long_summary,ahp__draw_summary(LD))
    st_matrix(out_transition_draws,TD); st_matrix(out_sensitivity,SEN)
    st_matrix(out_convergence,(mean(CD[,3]),mean(CD[,1]),max(CD[,2])))
}

real matrix dahp__shock_transition(real matrix P, real scalar from,
    real scalar to, real scalar delta, real scalar tol)
{
    real matrix Q
    real scalar oldp, newp, othermass, j
    Q=P; oldp=P[from,to]; newp=oldp+delta
    if (oldp<=tol & abs(delta)>tol) ahp__fail("the selected transition is a structural zero and cannot be shocked without an explicit support change")
    if (newp < -tol | newp > 1+tol) ahp__fail("a requested transition shock leaves the [0,1] interval")
    newp=max((0,newp)); newp=min((1,newp))
    othermass=1-oldp
    if (othermass<=tol & abs(newp-oldp)>tol) ahp__fail("the selected row has no existing support to compensate this shock")
    for (j=1;j<=cols(P);j++) {
        if (j!=to) Q[from,j]=P[from,j]*(1-newp)/othermass
    }
    Q[from,to]=newp
    return(Q)
}

void dahp__transition_shock(string scalar transition_name, string scalar weight_name,
    real scalar from, real scalar to, string scalar delta_values,
    string scalar initial_values, real scalar horizon, real scalar discount,
    real scalar maxiter, real scalar tol, string scalar out_finite,
    string scalar out_long, string scalar out_fchange, string scalar out_lchange,
    string scalar out_diagnostics)
{
    real matrix P0,P,W,O,V,FW,LW,FC,LC,SD
    real rowvector deltas,q0,q,d,finite,lo,diag,br,fr,lr
    real scalar z,k,nsc
    P0=st_matrix(transition_name); W=st_matrix(weight_name)
    P0=ahp__perturb_rows(P0,0,tol); W=ahp__perturb_rows(W,0,tol)
    q0=strtoreal(tokens(initial_values))
    if (cols(q0)==0) q0=J(1,rows(P0),1/rows(P0))
    if (cols(q0)!=rows(P0) | any(q0:<0) | any(missing(q0)) | sum(q0)<=0) ahp__fail("invalid initial distribution")
    q0=q0/sum(q0); deltas=strtoreal(tokens(delta_values)); nsc=cols(deltas)+1
    d=J(1,horizon+1,.)
    for (k=0;k<=horizon;k++) d[k+1]=discount^k
    d=d/sum(d)
    FW=J(nsc,cols(W),.); LW=FW; SD=J(nsc,8,.)
    for (z=1;z<=nsc;z++) {
        P=(z==1 ? P0 : dahp__shock_transition(P0,from,to,deltas[z-1],tol))
        O=J(horizon+1,rows(P),.); O[1,.]=q0
        for (k=1;k<=horizon;k++) O[k+1,.]=O[k,.]*P
        V=O*W; finite=d*V
        lo=dahp__markov_longrun(q0,P,maxiter,tol,diag)*W
        FW[z,.]=finite; LW[z,.]=lo
        if (z==1) SD[z,.]=(0,P0[from,to],0,0,0,0,diag[2],diag[3])
        else {
            br=ahp__rank_vector(FW[1,.]')'; fr=ahp__rank_vector(finite')'
            lr=ahp__rank_vector(lo')'
            SD[z,.]=(deltas[z-1],P[from,to],.5*sum(abs(finite-FW[1,.])),
                .5*sum(abs(lo-LW[1,.])),fr[selectindex(br:==1)]!=1,
                lr[selectindex(ahp__rank_vector(LW[1,.]'):==1)]!=1,diag[2],diag[3])
        }
    }
    FC=FW:-J(nsc,1,1)*FW[1,.]; LC=LW:-J(nsc,1,1)*LW[1,.]
    st_matrix(out_finite,FW); st_matrix(out_long,LW)
    st_matrix(out_fchange,FC); st_matrix(out_lchange,LC); st_matrix(out_diagnostics,SD)
}

void dahp__transition_optimize(string scalar transition_name, string scalar weight_name,
    real scalar from, real scalar to, real scalar alternative, string scalar mode,
    string scalar objective, real scalar goal, string scalar initial_values,
    real scalar horizon, real scalar discount, real scalar lower, real scalar upper,
    real scalar grids, real scalar maxiter, real scalar tol,
    string scalar out_curve, string scalar out_optimum)
{
    real matrix P0,P,W,O,V,C,OPT
    real rowvector q0,d,finite,lo,diag,basef,basel
    real colvector candidates, eligible
    real scalar g,k,delta,oldp,idx,val,best,goalout
    P0=st_matrix(transition_name); W=st_matrix(weight_name)
    P0=ahp__perturb_rows(P0,0,tol); W=ahp__perturb_rows(W,0,tol)
    oldp=P0[from,to]
    if (oldp<=tol | oldp>=1-tol) ahp__fail("optimization requires a selected transition strictly between zero and one")
    if (lower<=-999) lower=-oldp
    if (upper>=999) upper=1-oldp
    if (lower>upper | lower < -oldp-tol | upper > 1-oldp+tol) ahp__fail("optimization bounds exceed the feasible shock interval")
    q0=strtoreal(tokens(initial_values))
    if (cols(q0)==0) q0=J(1,rows(P0),1/rows(P0))
    if (cols(q0)!=rows(P0) | any(q0:<0) | any(missing(q0)) | sum(q0)<=0) ahp__fail("invalid initial distribution")
    q0=q0/sum(q0)
    d=J(1,horizon+1,.)
    for (k=0;k<=horizon;k++) d[k+1]=discount^k
    d=d/sum(d); C=J(grids,6,.)
    for (g=1;g<=grids;g++) {
        delta=lower+(g-1)*(upper-lower)/(grids-1)
        if (lower<=0 & upper>=0 & abs(delta)<=(upper-lower)/(2*(grids-1))) delta=0
        P=dahp__shock_transition(P0,from,to,delta,tol)
        O=J(horizon+1,rows(P),.); O[1,.]=q0
        for (k=1;k<=horizon;k++) O[k+1,.]=O[k,.]*P
        V=O*W; finite=d*V; lo=dahp__markov_longrun(q0,P,maxiter,tol,diag)*W
        if (g==1) {
            /* Baselines are calculated separately because the lower bound need not be zero. */
            O[1,.]=q0
        }
        C[g,.]=(delta,P[from,to],finite[alternative],lo[alternative],.,.)
    }
    O=J(horizon+1,rows(P0),.); O[1,.]=q0
    for (k=1;k<=horizon;k++) O[k+1,.]=O[k,.]*P0
    basef=d*(O*W); basel=dahp__markov_longrun(q0,P0,maxiter,tol,diag)*W
    for (g=1;g<=grids;g++) {
        P=dahp__shock_transition(P0,from,to,C[g,1],tol)
        O=J(horizon+1,rows(P),.); O[1,.]=q0
        for (k=1;k<=horizon;k++) O[k+1,.]=O[k,.]*P
        finite=d*(O*W); lo=dahp__markov_longrun(q0,P,maxiter,tol,diag)*W
        C[g,5]=.5*sum(abs(finite-basef)); C[g,6]=.5*sum(abs(lo-basel))
    }
    objective=strlower(objective); mode=strlower(mode)
    if (objective=="finite") candidates=C[,3]
    else if (objective=="longrun") candidates=C[,4]
    else ahp__fail("objective() must be finite or longrun")
    if (mode=="maximize") idx=selectindex(candidates:==max(candidates))[1]
    else if (mode=="target") {
        eligible=selectindex(candidates:>=goal)
        if (rows(eligible)==0) ahp__fail("the requested goal is not reached within the search bounds")
        best=1; idx=eligible[1]
        for (g=2;g<=rows(eligible);g++) if (abs(C[eligible[g],1])<abs(C[idx,1])) idx=eligible[g]
    }
    else ahp__fail("mode() must be maximize or target")
    val=candidates[idx]
    goalout=(mode=="maximize" ? . : goal)
    OPT=(C[idx,1],C[idx,2],val,goalout,(mode=="maximize" ? 1 : val>=goal),idx)
    st_matrix(out_curve,C); st_matrix(out_optimum,OPT)
}

void dahp__cost_select(string scalar curve_name, string scalar mode,
    string scalar objective, real scalar goal, real scalar budget, real scalar value,
    real scalar fixedcost, real scalar linearcost, real scalar quadcost,
    real scalar tol, string scalar out_curve, string scalar out_optimum)
{
    real matrix C,A,OPT
    real colvector priority,cost,incr,net,feasible,goalmet,eligible
    real scalar baseidx,i,idx,best,budgetout,goalout
    C=st_matrix(curve_name); mode=strlower(mode); objective=strlower(objective)
    baseidx=selectindex(abs(C[,1]):<=tol)[1]
    if (objective=="finite") priority=C[,3]
    else if (objective=="longrun") priority=C[,4]
    else ahp__fail("objective() must be finite or longrun")
    cost=J(rows(C),1,.); incr=J(rows(C),1,.); net=J(rows(C),1,.)
    for (i=1;i<=rows(C);i++) {
        cost[i]=(abs(C[i,1])<=tol ? 0 : fixedcost+linearcost*abs(C[i,1])+quadcost*C[i,1]^2)
        incr[i]=value*(priority[i]-priority[baseidx])
        net[i]=incr[i]-cost[i]
    }
    feasible=(budget<0 ? J(rows(C),1,1) : cost:<=budget+tol)
    goalmet=(goal<0 ? J(rows(C),1,1) : priority:>=goal-tol)
    if (mode=="netbenefit") idx=selectindex(net:==max(net))[1]
    else if (mode=="budgetmax") {
        eligible=selectindex(feasible)
        if (rows(eligible)==0) ahp__fail("no grid point satisfies the budget")
        idx=eligible[1]
        for (i=2;i<=rows(eligible);i++) if (priority[eligible[i]]>priority[idx]) idx=eligible[i]
    }
    else if (mode=="targetmincost") {
        eligible=selectindex(goalmet)
        if (rows(eligible)==0) ahp__fail("no grid point reaches the target")
        idx=eligible[1]
        for (i=2;i<=rows(eligible);i++) {
            if (cost[eligible[i]]<cost[idx] | (cost[eligible[i]]==cost[idx] & abs(C[eligible[i],1])<abs(C[idx,1]))) idx=eligible[i]
        }
    }
    else ahp__fail("mode() must be netbenefit, budgetmax, or targetmincost")
    A=(C,cost,incr,net,feasible,goalmet)
    budgetout=(budget<0 ? . : budget); goalout=(goal<0 ? . : goal)
    OPT=(C[idx,1],C[idx,2],priority[idx],cost[idx],incr[idx],net[idx],budgetout,
        feasible[idx],goalout,goalmet[idx],idx)
    st_matrix(out_curve,A); st_matrix(out_optimum,OPT)
}

void dahp__pareto(string scalar transition_name, string scalar weight_name,
    string scalar from_values, string scalar to_values, real scalar alternative,
    string scalar lower_values, string scalar upper_values, real scalar levels,
    real scalar budget, real scalar fixedcost, real scalar linearcost,
    real scalar quadcost, string scalar initial_values, real scalar horizon,
    real scalar discount, real scalar maxpoints, real scalar maxiter, real scalar tol,
    string scalar out_curve, string scalar out_frontier, string scalar out_optimum)
{
    real matrix P0,P,W,O,V,C,F,OPT
    real rowvector from,to,lower,upper,q0,d,finite,basef,diag,deltas
    real colvector efficient,feasible,eligible
    real scalar m,npoints,r,j,k,code,level,delta,cost,idx,i,dominated
    P0=ahp__perturb_rows(st_matrix(transition_name),0,tol)
    W=ahp__perturb_rows(st_matrix(weight_name),0,tol)
    from=strtoreal(tokens(from_values)); to=strtoreal(tokens(to_values)); m=cols(from)
    lower=strtoreal(tokens(lower_values)); upper=strtoreal(tokens(upper_values))
    if (cols(lower)==0) lower=J(1,m,.)
    if (cols(upper)==0) upper=J(1,m,.)
    for (j=1;j<=m;j++) {
        if (missing(lower[j])) lower[j]=-P0[from[j],to[j]]
        if (missing(upper[j])) upper[j]=1-P0[from[j],to[j]]
        if (P0[from[j],to[j]]<=tol | P0[from[j],to[j]]>=1-tol) ahp__fail("each optimized transition must be strictly between zero and one")
        if (lower[j] < -P0[from[j],to[j]]-tol | upper[j] > 1-P0[from[j],to[j]]+tol | lower[j]>upper[j]) ahp__fail("Pareto bounds exceed a feasible shock interval")
    }
    npoints=levels^m
    if (npoints>maxpoints) ahp__fail("Cartesian grid exceeds maxpoints(); reduce interventions or levels")
    q0=strtoreal(tokens(initial_values))
    if (cols(q0)==0) q0=J(1,rows(P0),1/rows(P0))
    if (cols(q0)!=rows(P0) | any(q0:<0) | any(missing(q0)) | sum(q0)<=0) ahp__fail("invalid initial distribution")
    q0=q0/sum(q0); d=J(1,horizon+1,.)
    for (k=0;k<=horizon;k++) d[k+1]=discount^k
    d=d/sum(d)
    O=J(horizon+1,rows(P0),.); O[1,.]=q0
    for (k=1;k<=horizon;k++) O[k+1,.]=O[k,.]*P0
    basef=d*(O*W); C=J(npoints,m+5,.); deltas=J(1,m,.)
    for (r=1;r<=npoints;r++) {
        code=r-1; P=P0; cost=0
        for (j=1;j<=m;j++) {
            level=mod(code,levels); code=floor(code/levels)
            delta=lower[j]+level*(upper[j]-lower[j])/(levels-1)
            if (lower[j]<=0 & upper[j]>=0 & abs(delta)<=(upper[j]-lower[j])/(2*(levels-1))) delta=0
            deltas[j]=delta
            P=dahp__shock_transition(P,from[j],to[j],delta,tol)
            if (abs(delta)>tol) cost=cost+fixedcost+linearcost*abs(delta)+quadcost*delta^2
        }
        O=J(horizon+1,rows(P),.); O[1,.]=q0
        for (k=1;k<=horizon;k++) O[k+1,.]=O[k,.]*P
        finite=d*(O*W)
        C[r,1..m]=deltas
        C[r,m+1]=finite[alternative]; C[r,m+2]=cost
        C[r,m+3]=.5*sum(abs(finite-basef)); C[r,m+4]=(budget<0 | cost<=budget+tol)
    }
    efficient=J(npoints,1,1)
    for (r=1;r<=npoints;r++) {
        dominated=0
        for (i=1;i<=npoints;i++) if (i!=r) {
            if (C[i,m+2]<=C[r,m+2]+tol & C[i,m+1]>=C[r,m+1]-tol &
                (C[i,m+2]<C[r,m+2]-tol | C[i,m+1]>C[r,m+1]+tol)) dominated=1
        }
        efficient[r]=!dominated; C[r,m+5]=efficient[r]
    }
    eligible=selectindex(efficient:==1)
    if (rows(eligible)==0) ahp__fail("internal Pareto search produced an empty frontier")
    F=C[eligible,.]
    feasible=selectindex(C[,m+4]:==1)
    if (rows(feasible)==0) ahp__fail("no grid point satisfies the budget")
    idx=feasible[1]
    for (i=2;i<=rows(feasible);i++) if (C[feasible[i],m+1]>C[idx,m+1]) idx=feasible[i]
    OPT=(C[idx,1..m],C[idx,m+1],C[idx,m+2],C[idx,m+3],C[idx,m+4],idx)
    st_matrix(out_curve,C); st_matrix(out_frontier,F); st_matrix(out_optimum,OPT)
}

void ahp__fail(string scalar message)
{
    errprintf("AHP error: %s\n", message)
    exit(498)
}

real rowvector ahp__normalize_weights(real rowvector q, real scalar expected)
{
    if (cols(q) == 0) q = J(1, expected, 1)
    if (cols(q) != expected) ahp__fail("the number of supplied weights does not match the requested dimension")
    if (any(missing(q)) | any(q :<= 0)) ahp__fail("all aggregation weights must be positive and nonmissing")
    return(q / sum(q))
}

void ahp__validate(real matrix A, real scalar tol)
{
    real scalar n, err
    n = rows(A)
    if (n < 2 | cols(A) != n) ahp__fail("each pairwise-comparison matrix must be square and at least 2 x 2")
    if (any(missing(A))) ahp__fail("pairwise-comparison matrices may not contain missing values")
    if (any(A :<= 0)) ahp__fail("pairwise-comparison matrices must be strictly positive")
    err = max(abs(A :* A' :- J(n, n, 1)))
    if (err > tol) ahp__fail(sprintf("matrix is not reciprocal within tolerance; maximum error = %9.3g", err))
}

struct ahp_result scalar ahp__priority(real matrix A, string scalar method, real scalar tol)
{
    struct ahp_result scalar out
    real scalar n, k, ri
    real colvector gm, wold

    ahp__validate(A, tol)
    n = rows(A)
    method = strlower(method)

    if (method == "eigen") {
        /* Perron power iteration avoids destructive LAPACK calls on inputs. */
        out.w = J(n, 1, 1/n)
        for (k=1; k<=10000; k++) {
            wold = out.w
            out.w = A * wold
            out.w = out.w / sum(out.w)
            if (max(abs(out.w - wold)) < 1e-13) break
        }
        if (k > 10000) ahp__fail("principal-eigenvector iteration did not converge")
        out.lambda = mean((A * out.w) :/ out.w)
    }
    else if (method == "geomean" | method == "llsm") {
        gm = exp(mean(ln(A)')')
        out.w = gm / sum(gm)
        out.lambda = mean((A * out.w) :/ out.w)
    }
    else ahp__fail("method() must be eigen or geomean")

    out.ci = (out.lambda - n) / (n - 1)
    ri = ahp__ri(n)
    out.cr = (ri == 0 ? 0 : out.ci / ri)
    out.reciprocal_error = max(abs(A :* A' :- J(n, n, 1)))
    return(out)
}

real matrix ahp__aggregate_aij(real matrix stack, real rowvector q)
{
    real scalar e, n, h
    real matrix G
    e = cols(q)
    n = cols(stack)
    G = J(n, n, 0)
    for (h=1; h<=e; h++) G = G :+ q[h] :* ln(stack[((h-1)*n+1)..(h*n), .])
    return(exp(G))
}

real colvector ahp__pool_priorities(real matrix W, real rowvector q, string scalar pool)
{
    real colvector w
    pool = strlower(pool)
    if (pool == "arithmetic") w = W * q'
    else if (pool == "geometric") w = exp(ln(W) * q')
    else ahp__fail("pool() must be arithmetic or geometric")
    return(w / sum(w))
}

void ahp__run(
    string scalar matrix_names,
    string scalar method,
    string scalar aggregation,
    string scalar pool,
    string scalar evaluator_weights,
    real scalar tol,
    string scalar out_w,
    string scalar out_details,
    string scalar out_group)
{
    string rowvector names
    real scalar e, n, h
    real rowvector q
    real matrix A, stack, W, details, G
    struct ahp_result scalar r

    names = tokens(matrix_names)
    e = cols(names)
    if (e == 0) ahp__fail("at least one matrix is required")
    A = st_matrix(names[1])
    n = rows(A)
    stack = J(e*n, n, .)
    W = J(n, e, .)
    details = J(e+1, 5, .)
    q = ahp__normalize_weights(strtoreal(tokens(evaluator_weights)), e)

    for (h=1; h<=e; h++) {
        A = st_matrix(names[h])
        if (rows(A) != n | cols(A) != n) ahp__fail("all evaluator matrices must have identical dimensions")
        r = ahp__priority(A, method, tol)
        W[,h] = r.w
        details[h,.] = (r.lambda, r.ci, r.cr, r.cr <= .10, r.reciprocal_error)
        stack[((h-1)*n+1)..(h*n), .] = st_matrix(names[h])
    }

    aggregation = strlower(aggregation)
    if (e == 1 | aggregation == "aij") {
        G = (e == 1 ? stack[1..n,.] : ahp__aggregate_aij(stack, q))
        r = ahp__priority(G, method, tol)
        details[e+1,.] = (r.lambda, r.ci, r.cr, r.cr <= .10, r.reciprocal_error)
        st_matrix(out_w, r.w')
        st_matrix(out_group, G)
    }
    else if (aggregation == "aip") {
        r.w = ahp__pool_priorities(W, q, pool)
        st_matrix(out_w, r.w')
        st_matrix(out_group, J(1,1,.))
    }
    else ahp__fail("aggregate() must be aij or aip")

    st_matrix(out_details, details)
}

void dahp__run(
    string scalar matrix_names,
    real scalar contexts,
    real scalar evaluators,
    string scalar method,
    string scalar aggregation,
    string scalar pool,
    string scalar evaluator_weights,
    string scalar context_weights,
    string scalar timepool,
    real scalar tol,
    string scalar out_w,
    string scalar out_context,
    string scalar out_details)
{
    string rowvector names
    real scalar t, e, n, h, idx
    real rowvector qe, qt
    real matrix A, stack, W, contextW, details, G
    struct ahp_result scalar r

    names = tokens(matrix_names)
    if (contexts < 1 | evaluators < 1) ahp__fail("contexts() and evaluators() must be positive")
    if (cols(names) != contexts*evaluators) ahp__fail("matrix count must equal contexts() times evaluators()")
    A = st_matrix(names[1])
    n = rows(A)
    qe = ahp__normalize_weights(strtoreal(tokens(evaluator_weights)), evaluators)
    qt = ahp__normalize_weights(strtoreal(tokens(context_weights)), contexts)
    contextW = J(n, contexts, .)
    details = J(contexts, 5, .)

    for (t=1; t<=contexts; t++) {
        stack = J(evaluators*n, n, .)
        W = J(n, evaluators, .)
        for (e=1; e<=evaluators; e++) {
            idx = (t-1)*evaluators + e
            A = st_matrix(names[idx])
            if (rows(A) != n | cols(A) != n) ahp__fail("all matrices must have identical dimensions")
            r = ahp__priority(A, method, tol)
            W[,e] = r.w
            stack[((e-1)*n+1)..(e*n),.] = st_matrix(names[idx])
        }
        if (evaluators == 1 | strlower(aggregation) == "aij") {
            G = (evaluators == 1 ? stack[1..n,.] : ahp__aggregate_aij(stack, qe))
            r = ahp__priority(G, method, tol)
            contextW[,t] = r.w
            details[t,.] = (r.lambda, r.ci, r.cr, r.cr <= .10, r.reciprocal_error)
        }
        else if (strlower(aggregation) == "aip") contextW[,t] = ahp__pool_priorities(W, qe, pool)
        else ahp__fail("aggregate() must be aij or aip")
    }

    r.w = ahp__pool_priorities(contextW, qt, timepool)
    st_matrix(out_w, r.w')
    st_matrix(out_context, contextW')
    st_matrix(out_details, details)
}

end
