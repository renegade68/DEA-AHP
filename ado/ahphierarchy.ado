*! version 0.5.2 24oct2026 | data-first recursive AHP hierarchy
*! Code author: Lee, Choonjoo
program define ahphierarchy, rclass
    version 16.0
    local cmdline ahphierarchy `0'
    syntax varname(numeric) [if] [in], PARENT(varname string) LEFT(varname string) RIGHT(varname string) ///
        [EVALuator(varname string) EVALuatorweight(varname numeric) METHOD(string) ///
         AGGregate(string) POOL(string) JUDGment(string) SYNTHesis(string) ///
         LOWER(varname numeric) UPPER(varname numeric) STRUCTure(name) TOLerance(real 1e-6)]

    if missing(`tolerance') {
        di as error "tolerance() must be finite"
        exit 198
    }

    marksample touse, strok
    if ("`method'" == "") local method eigen
    if ("`aggregate'" == "") local aggregate aij
    if ("`pool'" == "") local pool arithmetic
    if ("`judgment'" == "") local judgment crisp
    if ("`synthesis'" == "") local synthesis distributive

    local method = lower("`method'")
    local aggregate = lower("`aggregate'")
    local pool = lower("`pool'")
    local judgment = lower("`judgment'")
    local synthesis = lower("`synthesis'")

    if !inlist("`method'", "eigen", "geomean", "llsm") {
        di as error "method() must be eigen, geomean, or llsm"
        exit 198
    }
    if !inlist("`aggregate'", "aij", "aip") {
        di as error "aggregate() must be aij or aip"
        exit 198
    }
    if !inlist("`pool'", "arithmetic", "geometric") {
        di as error "pool() must be arithmetic or geometric"
        exit 198
    }
    if !inlist("`judgment'", "crisp", "interval", "fuzzy") {
        di as error "judgment() must be crisp, interval, or fuzzy"
        exit 198
    }
    if ("`judgment'" == "interval" & "`upper'" == "") {
        di as error "judgment(interval) requires upper()"
        exit 198
    }
    if ("`judgment'" == "crisp" & "`upper'" != "") {
        di as error "upper() requires judgment(interval)"
        exit 198
    }
    if ("`judgment'" != "fuzzy" & "`lower'" != "") {
        di as error "lower() requires judgment(fuzzy)"
        exit 198
    }
    if ("`judgment'" == "fuzzy" & ("`lower'" == "" | "`upper'" == "")) {
        di as error "judgment(fuzzy) requires lower() and upper()"
        exit 198
    }
    if (inlist("`judgment'", "interval", "fuzzy") & "`method'" == "eigen") {
        di as error "judgment(`judgment') requires method(geomean) or method(llsm)"
        exit 198
    }
    if (inlist("`judgment'", "interval", "fuzzy") & "`aggregate'" != "aij") {
        di as error "judgment(`judgment') currently requires aggregate(aij)"
        exit 198
    }
    if (inlist("`judgment'", "interval", "fuzzy") & "`synthesis'" != "distributive") {
        di as error "judgment(`judgment') currently requires synthesis(distributive)"
        exit 198
    }
    if ("`judgment'" == "interval") markout `touse' `upper'
    if ("`judgment'" == "fuzzy") markout `touse' `lower' `upper'
    if !inlist("`synthesis'", "distributive", "ideal") {
        di as error "synthesis() must be distributive or ideal"
        exit 198
    }
    if (`tolerance' < 0) {
        di as error "tolerance() must be nonnegative"
        exit 198
    }
    if ("`evaluatorweight'" != "" & "`evaluator'" == "") {
        di as error "evaluatorweight() requires evaluator()"
        exit 198
    }

    quietly count if `touse'
    if (r(N) == 0 & "`structure'" == "") error 2000

    quietly _ahp_load
    quietly _ahp_hierarchy_load
    tempname W R IW IE FW FE N E D S
    tempvar oneeval
    local evalvar `evaluator'
    if ("`evalvar'" == "") {
        quietly generate str8 `oneeval' = "single" if `touse'
        local evalvar `oneeval'
    }

    mata: ahph__run("`varlist'", "`lower'", "`upper'", "`parent'", "`left'", "`right'", "`evalvar'", ///
        "`evaluatorweight'", "`touse'", "`method'", "`aggregate'", "`pool'", ///
        "`judgment'", "`synthesis'", `tolerance', "`structure'", "`W'", "`R'", ///
        "`IW'", "`IE'", "`FW'", "`FE'", "`N'", "`E'", "`D'", "`S'", ///
        "hier_root", "hier_alternatives", "hier_edge_parents", ///
        "hier_edge_children", "hier_structure_nodes", "hier_structure_parents")

    matrix rownames `W' = integrated
    matrix colnames `W' = `hier_alternatives'
    matrix rownames `R' = raw
    matrix colnames `R' = `hier_alternatives'
    if ("`judgment'" == "interval") {
        matrix rownames `IW' = lower upper
        matrix colnames `IW' = `hier_alternatives'
        matrix rownames `IE' = `hier_edge_ids'
        matrix colnames `IE' = local_lower local_upper contribution_lower contribution_upper
    }
    if ("`judgment'" == "fuzzy") {
        matrix rownames `FW' = lower mode upper
        matrix colnames `FW' = `hier_alternatives'
        matrix rownames `FE' = `hier_edge_ids'
        matrix colnames `FE' = local_lower local_upper contribution_lower contribution_upper
    }
    matrix rownames `N' = `hier_nodes'
    matrix colnames `N' = level global_weight terminal
    matrix rownames `E' = `hier_edge_ids'
    matrix colnames `E' = parent_level local_weight parent_global contribution
    matrix rownames `D' = `hier_parents'
    matrix colnames `D' = children evaluators lambda_max CI CR consistent reciprocal_error
    if ("`structure'" != "") {
        matrix rownames `S' = `hier_structure_ids'
        matrix colnames `S' = level type order
    }

    di as text "Recursive AHP hierarchy"
    di as text "  root: " as result "`hier_root'" as text ///
        "   levels: " as result `hier_levels' as text ///
        "   method: " as result "`method'" as text ///
        "   synthesis: " as result "`synthesis'"
    matlist `W', names(rows) format(%9.6f) title("Synthesized alternative priorities")
    matlist `D', names(rows) format(%9.6f) title("Parent-node diagnostics")

    return matrix diagnostics = `D'
    if ("`structure'" != "") return matrix structure = `S'
    return matrix edges = `E'
    return matrix nodes = `N'
    if ("`judgment'" == "interval") {
        return matrix interval_edges = `IE'
        return matrix interval_weights = `IW'
    }
    if ("`judgment'" == "fuzzy") {
        return matrix fuzzy_edges = `FE'
        return matrix fuzzy_weights = `FW'
    }
    return matrix scores = `R'
    return matrix weights = `W'
    return scalar levels = `hier_levels'
    return scalar N_evaluators = `hier_evaluators'
    return local edge_children "`hier_edge_children'"
    return local edge_parents "`hier_edge_parents'"
    return local alternatives "`hier_alternatives'"
    return local root "`hier_root'"
    return local structure_parents "`hier_structure_parents'"
    return local structure_nodes "`hier_structure_nodes'"
    return local structure_frame "`structure'"
    return local structure_source "`=cond("`structure'"=="","inferred","frame")'"
    return local synthesis "`synthesis'"
    return local interval_rule "`=cond("`judgment'"=="interval","geometric_midpoint_llsm_envelope","")'"
    return local fuzzy_rule "`=cond("`judgment'"=="fuzzy","buckley_tfn_centroid","")'"
    return local judgment "`judgment'"
    return local pool "`pool'"
    return local aggregate "`aggregate'"
    return local method "`method'"
    return local cmdline `"`cmdline'"'
    return local cmd "ahphierarchy"
end
