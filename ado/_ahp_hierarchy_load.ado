*! version 0.5.2 24oct2026 | loader for ahp_hierarchy_core.mata
program define _ahp_hierarchy_load
    version 16.0
    capture mata: assert(ahph__version()>=6)
    if (_rc) {
        quietly findfile ahp_hierarchy_core.mata
        quietly do "`r(fn)'"
    }
end
