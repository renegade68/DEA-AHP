*! version 0.2.1 24oct2026 | classical within-context AHP; project dynamic extension
*! Code author: Lee, Choonjoo
*! Methodological basis: Saaty (1980, 1987); explicit context pooling extension
program define dahp, rclass
    version 16.0
    syntax namelist(min=1), CONTEXTS(integer) [EVALuators(integer 1) METHOD(string) AGGregate(string) POOL(string) TIMEPOOL(string) EVALuatorweights(numlist >0) CONTEXTweights(numlist >0) TOLerance(real 1e-6)]

    if missing(`contexts', `evaluators', `tolerance') {
        di as error "contexts(), evaluators(), and tolerance() must be finite"
        exit 198
    }

    if ("`method'" == "") local method eigen
    if ("`aggregate'" == "") local aggregate aij
    if ("`pool'" == "") local pool arithmetic
    if ("`timepool'" == "") local timepool arithmetic
    if (`contexts' < 1 | `evaluators' < 1) {
        di as error "contexts() and evaluators() must be positive"
        exit 198
    }
    if (`tolerance' < 0) {
        di as error "tolerance() must be nonnegative"
        exit 198
    }
    local nmats : word count `namelist'
    if (`nmats' != `contexts'*`evaluators') {
        di as error "contexts() times evaluators() must equal the number of matrices"
        exit 198
    }
    local first : word 1 of `namelist'
    local names : rownames `first'
    local cnames : colnames `first'
    if (`"`names'"' != `"`cnames'"') {
        di as error "each comparison matrix must have identical row and column names"
        exit 503
    }
    foreach M of local namelist {
        local rn : rownames `M'
        local cn : colnames `M'
        if (`"`rn'"' != `"`names'"' | `"`cn'"' != `"`names'"') {
            di as error "all context/evaluator matrices must use identical row and column names in the same order"
            exit 503
        }
    }

    quietly _ahp_load
    tempname W CW D
    mata: dahp__run("`namelist'", `contexts', `evaluators', "`method'", "`aggregate'", "`pool'", "`evaluatorweights'", "`contextweights'", "`timepool'", `tolerance', "`W'", "`CW'", "`D'")

    local cn : colnames `first'
    matrix colnames `W' = `cn'
    matrix rownames `W' = integrated
    matrix colnames `CW' = `cn'
    matrix colnames `D' = lambda_max CI CR consistent reciprocal_error
    local rn
    forvalues i=1/`contexts' {
        local rn `rn' context`i'
    }
    matrix rownames `CW' = `rn'
    matrix rownames `D' = `rn'

    di as text "Dynamic analytic hierarchy process"
    di as text "  contexts: " as result `contexts' as text "   evaluators/context: " as result `evaluators'
    di as text "  method: " as result "`method'" as text "   evaluator aggregation: " as result "`aggregate'" as text "   context pooling: " as result "`timepool'"
    matlist `CW', names(rows) format(%9.6f) title("Context-specific priority weights")
    matlist `W', names(rows) format(%9.6f) title("Integrated dynamic priority weights")
    matlist `D', names(rows) format(%9.6f) title("Context consistency diagnostics")

    return matrix details = `D'
    return matrix context_weights = `CW'
    return matrix weights = `W'
    return scalar N_contexts = `contexts'
    return scalar N_evaluators = `evaluators'
    return local method "`method'"
    return local aggregate "`aggregate'"
    return local pool "`pool'"
    return local timepool "`timepool'"
end
