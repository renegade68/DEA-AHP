*! version 0.2.1 24oct2026
*! Code author: Lee, Choonjoo
*! Methodological basis: Saaty (1980, 1987), hierarchical synthesis
program define ahpsynth, rclass
    version 16.0
    syntax namelist(min=2 max=2), [TOLerance(real 1e-8)]

    if missing(`tolerance') | `tolerance'<0 {
        di as error "tolerance() must be finite and nonnegative"
        exit 198
    }

    local parent : word 1 of `namelist'
    local localw : word 2 of `namelist'
    if (rowsof(`parent') == 1) local parent_nodes : colnames `parent'
    else if (colsof(`parent') == 1) local parent_nodes : rownames `parent'
    else {
        di as error "the parent-priority matrix must be a row or column vector"
        exit 498
    }
    local local_nodes : colnames `localw'
    if ("`parent_nodes'" != "`local_nodes'") {
        di as error "parent node names and local-priority column names must match in the same order"
        exit 498
    }
    quietly _ahp_load

    tempname W C
    mata: ahp__synthesize("`parent'", "`localw'", `tolerance', "`W'", "`C'")

    local alternatives : rownames `localw'
    local criteria : colnames `localw'
    matrix rownames `W' = integrated
    matrix colnames `W' = `alternatives'
    matrix rownames `C' = `alternatives'
    matrix colnames `C' = `criteria'

    di as text "AHP hierarchical synthesis"
    matlist `C', names(rows) format(%9.6f) title("Path contributions: local priority x parent priority")
    matlist `W', names(rows) format(%9.6f) title("Synthesized global priorities")

    return matrix contributions = `C'
    return matrix weights = `W'
end
