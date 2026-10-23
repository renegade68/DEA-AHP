*! version 0.1.1 24oct2026 | long-format ANP weighted and limit supermatrices
*! Code author: Lee, Choonjoo
program define ahpnetwork, rclass
    version 16.0
    local cmdline ahpnetwork `0'
    syntax varname(numeric) [if] [in], SOURCE(varname string) TARGET(varname string) ///
        [SOURCECLuster(varname string) TARGETCLuster(varname string) ///
         CLUSTERWeight(varname numeric) LIMit(string) MAXIter(integer 10000) ///
         TOLerance(real 1e-8)]

    if missing(`maxiter', `tolerance') {
        di as error "maxiter() and tolerance() must be finite"
        exit 198
    }

    marksample touse, strok
    if ("`limit'" == "") local limit power
    local limit=lower("`limit'")
    if !inlist("`limit'", "power", "cesaro") {
        di as error "limit() must be power or cesaro"
        exit 198
    }
    if (`maxiter' < 1) {
        di as error "maxiter() must be positive"
        exit 198
    }
    if (`tolerance' <= 0) {
        di as error "tolerance() must be positive"
        exit 198
    }
    if ("`sourcecluster'" == "") != ("`targetcluster'" == "") {
        di as error "specify both sourcecluster() and targetcluster()"
        exit 198
    }
    if ("`clusterweight'" != "" & "`sourcecluster'" == "") {
        di as error "clusterweight() requires sourcecluster() and targetcluster()"
        exit 198
    }
    if ("`clusterweight'" != "") markout `touse' `clusterweight'
    quietly count if `touse'
    if (r(N)==0) error 2000

    quietly _ahp_load
    quietly _ahp_network_load
    tempname W L P B
    mata: ahpn__run("`varlist'", "`source'", "`target'", "`sourcecluster'", ///
        "`targetcluster'", "`clusterweight'", "`touse'", "`limit'", ///
        `maxiter', `tolerance', "`W'", "`L'", "`P'", "`B'", ///
        "network_nodes", "network_clusters")

    matrix rownames `W' = `network_nodes'
    matrix colnames `W' = `network_nodes'
    matrix rownames `L' = `network_nodes'
    matrix colnames `L' = `network_nodes'
    matrix rownames `P' = `network_nodes'
    matrix colnames `P' = priority
    matrix rownames `B' = `network_nodes'
    matrix colnames `B' = cluster_id

    di as text "Analytic network process"
    di as text "  nodes: " as result `network_N' as text ///
        "   clusters: " as result `network_K' as text ///
        "   limit: " as result "`limit'" as text ///
        "   iterations: " as result `network_iterations'
    matlist `P', names(rows) format(%9.6f) title("ANP limiting priorities")

    return matrix membership = `B'
    return matrix priorities = `P'
    return matrix limit_matrix = `L'
    return matrix supermatrix = `W'
    return scalar limit_spread = `network_spread'
    return scalar convergence_error = `network_error'
    return scalar iterations = `network_iterations'
    return scalar N_clusters = `network_K'
    return scalar N_nodes = `network_N'
    return local clusters "`network_clusters'"
    return local nodes "`network_nodes'"
    return local limit "`limit'"
    return local cluster_weight_source "`=cond("`clusterweight'"=="","equal_active_clusters","variable")'"
    return local model "column-stochastic ANP weighted supermatrix and limiting priorities"
    return local cmdline `"`cmdline'"'
    return local cmd "ahpnetwork"
end
