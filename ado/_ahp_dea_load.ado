*! version 0.1.0 02aug2026
*! Code author: Lee, Choonjoo | loader for ahp_dea_core.mata
program define _ahp_dea_load
    version 16.0
    capture mata: ahpdea__probe()
    if _rc {
        quietly findfile ahp_dea_core.mata
        quietly run "`r(fn)'"
    }
end
