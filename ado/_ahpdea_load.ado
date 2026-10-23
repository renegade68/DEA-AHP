*! version 0.1.1 24oct2026
*! Code author: Lee, Choonjoo | loader for DEA v2 and ahpdea_ar.mata
program define _ahpdea_load
    version 16.0
    capture mata: mata which _rsm_solve_lp()
    if _rc {
        capture findfile _dea_simplex.ado
        if _rc {
            di as error "ahpdea requires _dea_simplex.ado from dea version 2"
            exit 601
        }
        quietly run "`r(fn)'"
    }
    capture mata: mata which ahpdea_ar__probe()
    if _rc {
        quietly findfile ahpdea_ar.mata
        quietly run "`r(fn)'"
    }
    tempname api_ok
    capture mata: st_numscalar("`api_ok'",ahpdea_ar__solver_probe())
    if _rc {
        di as error "installed DEA simplex layer does not provide the required version-2 LP API"
        exit 9
    }
    if scalar(`api_ok')!=1 {
        di as error "installed DEA simplex layer does not provide the required version-2 LP API"
        exit 9
    }
end
