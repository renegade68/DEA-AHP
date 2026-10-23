*! version 0.1.0 02aug2026
*! Code author: Lee, Choonjoo | loader for ahp_core.mata
program define _ahp_load
    version 16.0
    capture mata: ahp__ri(3)
    if (_rc) {
        quietly findfile ahp_core.mata
        quietly do "`r(fn)'"
    }
end
