*! version 0.2.0 24oct2026 | loader for ahp_network_core.mata
program define _ahp_network_load
    version 16.0
    capture mata: assert(ahpn__version()>=2)
    if (_rc) {
        quietly findfile ahp_network_core.mata
        quietly do "`r(fn)'"
    }
end
