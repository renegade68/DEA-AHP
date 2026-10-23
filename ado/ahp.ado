*! version 0.2.2 24oct2026 | classical core: Saaty (1987, 1990)
*! Code author: Lee, Choonjoo
*! Methodological basis: Saaty (1980, 1987); Aczel and Saaty (1983);
*!                       Crawford and Williams (1985)
program define ahp, rclass
    version 16.0
    syntax namelist(min=1), [METHOD(string) AGGregate(string) POOL(string) EVALuatorweights(numlist >0) TOLerance(real 1e-6)]

    if missing(`tolerance') | `tolerance'<0 {
        di as error "tolerance() must be finite and nonnegative"
        exit 198
    }

    if ("`method'" == "") local method eigen
    if ("`aggregate'" == "") local aggregate aij
    if ("`pool'" == "") local pool arithmetic
    if (`tolerance' < 0) {
        di as error "tolerance() must be nonnegative"
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
            di as error "all evaluator matrices must use identical row and column names in the same order"
            exit 503
        }
    }

    quietly _ahp_load
    tempname W D G
    mata: ahp__run("`namelist'", "`method'", "`aggregate'", "`pool'", "`evaluatorweights'", `tolerance', "`W'", "`D'", "`G'")

    local cn : colnames `first'
    local ne : word count `namelist'
    local group_row = `ne' + 1
    matrix rownames `W' = weights
    matrix colnames `W' = `cn'
    matrix colnames `D' = lambda_max CI CR consistent reciprocal_error
    local rn
    forvalues i=1/`ne' {
        local rn `rn' evaluator`i'
    }
    local rn `rn' group
    matrix rownames `D' = `rn'
    if (!missing(`G'[1,1])) {
        matrix rownames `G' = `cn'
        matrix colnames `G' = `cn'
    }
    local lambda_max = `D'[`group_row',1]
    local ci = `D'[`group_row',2]
    local cr = `D'[`group_row',3]
    local consistent = `D'[`group_row',4]
    local reciprocal_error = `D'[`group_row',5]

    di as text "Analytic hierarchy process"
    di as text "  method: " as result "`method'" as text "   evaluator aggregation: " as result "`aggregate'"
    matlist `W', names(rows) format(%9.6f) title("Priority weights")
    matlist `D', names(rows) format(%9.6f) title("Consistency diagnostics")

    if (!missing(`G'[1,1])) return matrix group_matrix = `G'
    return matrix details = `D'
    return matrix weights = `W'
    return scalar lambda_max = `lambda_max'
    return scalar ci = `ci'
    return scalar cr = `cr'
    return scalar consistent = `consistent'
    return scalar reciprocal_error = `reciprocal_error'
    return scalar N_evaluators = `ne'
    return local method "`method'"
    return local aggregate "`aggregate'"
    return local pool "`pool'"
    return local foundation "Saaty (1987, 1990) principal-eigenvector AHP"
    return local scale_convention "Saaty fundamental 1--9 scale or measured ratios"
end
