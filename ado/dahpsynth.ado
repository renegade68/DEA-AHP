*! version 0.3.1 24oct2026 | dynamic-structure extension over classical AHP synthesis
*! Code author: Lee, Choonjoo
*! Methodological basis: Saaty (1980, 1987); context-varying synthesis extension
program define dahpsynth, rclass
    version 16.0
    syntax namelist(min=2), CONTEXTS(integer) [CONTEXTweights(numlist >0) TIMEPOOL(string) TOLerance(real 1e-8)]

    if missing(`contexts', `tolerance') | `tolerance'<0 {
        di as error "contexts() must be finite and tolerance() finite and nonnegative"
        exit 198
    }

    if (`contexts' < 1) {
        di as error "contexts() must be positive"
        exit 198
    }
    local nmats : word count `namelist'
    if (`nmats' != 2*`contexts') {
        di as error "supply exactly two matrices per context: parent priorities followed by local priorities"
        exit 198
    }
    if ("`timepool'" == "") local timepool arithmetic

    quietly _ahp_load
    tempname CW IW
    local contribution_names
    local alternatives

    forvalues t=1/`contexts' {
        local ppos = 2*`t' - 1
        local lpos = 2*`t'
        local parent : word `ppos' of `namelist'
        local localw : word `lpos' of `namelist'

        quietly ahpsynth `parent' `localw', tolerance(`tolerance')
        tempname WT CT
        matrix `WT' = r(weights)
        matrix `CT' = r(contributions)
        local contribution_names `contribution_names' `CT'

        local current : colnames `WT'
        if (`t' == 1) {
            local alternatives `current'
            matrix `CW' = `WT'
        }
        else {
            if ("`current'" != "`alternatives'") {
                di as error "all contexts must contain the same alternatives in the same row order"
                exit 498
            }
            matrix `CW' = `CW' \ `WT'
        }
    }

    mata: dahp__integrate_synth("`CW'", "`contextweights'", "`timepool'", "`IW'")
    matrix rownames `IW' = integrated
    matrix colnames `IW' = `alternatives'
    local context_names
    forvalues t=1/`contexts' {
        local context_names `context_names' context`t'
    }
    matrix rownames `CW' = `context_names'
    matrix colnames `CW' = `alternatives'

    di as text "Dynamic-structure AHP synthesis"
    di as text "  contexts: " as result `contexts' as text "   context pooling: " as result "`timepool'"
    matlist `CW', names(rows) format(%9.6f) title("Context-specific synthesized priorities")
    matlist `IW', names(rows) format(%9.6f) title("Integrated dynamic priorities")

    local t 0
    foreach CT of local contribution_names {
        local ++t
        return matrix contributions`t' = `CT'
    }
    return matrix context_weights = `CW'
    return matrix weights = `IW'
    return scalar N_contexts = `contexts'
    return local timepool "`timepool'"
    return local structure_rule "contextwise_renormalization"
end
