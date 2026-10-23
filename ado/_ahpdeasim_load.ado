*! version 0.1.0 03aug2026
*! Code author: Lee, Choonjoo | loader for ahpdeasim.mata
program define _ahpdeasim_load
    version 16.0
    capture mata: mata which ahpdeasim__perturb()
    if _rc {
        quietly findfile ahpdeasim.mata
        quietly run "`r(fn)'"
    }
end
