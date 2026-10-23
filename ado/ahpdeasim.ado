*! version 0.1.1 24oct2026 | Monte Carlo sensitivity for ahpdea
*! Code author: Lee, Choonjoo
*! Methodological basis: Saaty (1987); Lee (2026, forthcoming);
*!                       judgment-perturbation sensitivity wrapper
program define ahpdeasim, rclass
    version 16.0
    local cmdline `"`0'"'
    local inputs
    gettoken word 0 : 0, parse("=,")
    while `"`word'"' != "=" & `"`word'"' != "" {
        if `"`word'"' == "," exit 198
        local inputs `inputs' `word'
        gettoken word 0 : 0, parse("=,")
    }
    if `"`word'"' != "=" | `"`inputs'"' == "" {
        di as error "syntax is: ahpdeasim inputvars = outputvars, dmu(varname) ..."
        exit 198
    }
    syntax varlist(min=1 numeric) [if] [in], DMU(varname) ///
        [INPUTMatrix(name) OUTPUTMatrix(name) REPS(integer 200) ///
         SIGMA(real .10) SEED(integer 12345) BAND(real 0) ///
         LOWERBAND(real -1) UPPERBAND(real -1) ///
         INPUTScale(name) OUTPUTScale(name) AHPMETHOD(string) ///
         RTS(string) ORIentation(string)]
    if missing(`reps', `sigma', `seed', `band', `lowerband', `upperband') {
        di as error "replication, perturbation, seed, and band options must be finite"
        exit 198
    }
    if (`lowerband'<0 & `lowerband'!=-1) | (`upperband'<0 & `upperband'!=-1) {
        di as error "asymmetric bands must be nonnegative when specified"
        exit 198
    }

    local outputs `varlist'
    if `reps'<2 {
        di as error "reps() must be at least 2"
        exit 198
    }
    if `sigma'<0 {
        di as error "sigma() must be nonnegative"
        exit 198
    }
    if `seed'<0 {
        di as error "seed() must be a nonnegative integer"
        exit 198
    }
    if `band'<0 {
        di as error "band() must be nonnegative"
        exit 198
    }
    local asymmetric=(`lowerband'>=0 | `upperband'>=0)
    if `asymmetric' & (`lowerband'<0 | `upperband'<0) {
        di as error "specify both lowerband() and upperband()"
        exit 198
    }
    if `asymmetric' & (`lowerband'>1 | `upperband'<0) {
        di as error "lowerband() must be in [0,1] and upperband() must be nonnegative"
        exit 198
    }
    if `asymmetric' & `band'!=0 {
        di as error "band() may not be combined with lowerband() and upperband()"
        exit 198
    }
    if `"`ahpmethod'"'=="" local ahpmethod eigen
    if !inlist(lower(`"`ahpmethod'"'),"eigen","geomean") {
        di as error "ahpmethod() must be eigen or geomean"
        exit 198
    }
    if `"`rts'"'=="" local rts crs
    if `"`orientation'"'=="" local orientation input

    local m : word count `inputs'
    local s : word count `outputs'
    if `m'>1 & `"`inputmatrix'"'=="" {
        di as error "multiple inputs require inputmatrix()"
        exit 198
    }
    if `s'>1 & `"`outputmatrix'"'=="" {
        di as error "multiple outputs require outputmatrix()"
        exit 198
    }
    if `m'==1 & `"`inputmatrix'"'!="" {
        di as error "inputmatrix() is unnecessary when there is one input"
        exit 198
    }
    if `s'==1 & `"`outputmatrix'"'!="" {
        di as error "outputmatrix() is unnecessary when there is one output"
        exit 198
    }

    marksample touse
    markout `touse' `inputs' `outputs'
    quietly count if `touse'
    local N=r(N)
    if `N'<2 {
        di as error "at least two complete DMUs are required"
        exit 2001
    }

    tempname AXb AYb Eref Ebase Draws Summary PX PY IX IY
    local inopt
    local outopt
    if `m'>1 local inopt inputmatrix(`inputmatrix')
    if `s'>1 local outopt outputmatrix(`outputmatrix')
    local scaleopt
    if `"`inputscale'"'!="" local scaleopt `scaleopt' inputscale(`inputscale')
    if `"`outputscale'"'!="" local scaleopt `scaleopt' outputscale(`outputscale')
    local bandopt band(`band')
    if `asymmetric' local bandopt lowerband(`lowerband') upperband(`upperband')

    quietly ahpdea `inputs' = `outputs' if `touse', dmu(`dmu') ///
        `inopt' `outopt' `scaleopt' `bandopt' ahpmethod(`ahpmethod') ///
        rts(`rts') orientation(`orientation')
    matrix `Eref'=r(efficiency)
    matrix `Ebase'=r(baseline_efficiency)
    matrix `PX'=r(input_priority)
    matrix `PY'=r(output_priority)
    local rts `"`r(rts)'"'
    local orientation `"`r(orientation)'"'
    if `m'>1 scalar `IX'=r(input_cr)
    if `s'>1 scalar `IY'=r(output_cr)
    local dmunames : rownames `Eref'
    matrix `Draws'=J(`N',`reps',.)

    quietly _ahpdeasim_load
    set seed `seed'
    forvalues b=1/`reps' {
        local binopt
        local boutopt
        if `m'>1 {
            mata: ahpdeasim__perturb("`inputmatrix'",`sigma',"`AXb'")
            matrix rownames `AXb'=`inputs'
            matrix colnames `AXb'=`inputs'
            local binopt inputmatrix(`AXb')
        }
        if `s'>1 {
            mata: ahpdeasim__perturb("`outputmatrix'",`sigma',"`AYb'")
            matrix rownames `AYb'=`outputs'
            matrix colnames `AYb'=`outputs'
            local boutopt outputmatrix(`AYb')
        }
        quietly ahpdea `inputs' = `outputs' if `touse', dmu(`dmu') ///
            `binopt' `boutopt' `scaleopt' `bandopt' ahpmethod(`ahpmethod') ///
            rts(`rts') orientation(`orientation')
        matrix `Draws'[1,`b']=r(efficiency)
    }
    mata: ahpdeasim__summarize("`Draws'","`Summary'")
    matrix rownames `Draws'=`dmunames'
    matrix rownames `Summary'=`dmunames'
    matrix colnames `Summary'=mean sd p05 p50 p95 mean_rank pr_best
    local drawnames
    forvalues b=1/`reps' {
        local drawnames `drawnames' rep`b'
    }
    matrix colnames `Draws'=`drawnames'

    di as text "Monte Carlo AHP-DEA sensitivity analysis"
    di as text "Replications: " as result `reps' as text ///
        "   log-judgment sigma: " as result %9.4g `sigma' ///
        as text "   seed: " as result `seed'
    matlist `Summary', names(rows) format(%9.5f) ///
        title("Efficiency and rank sensitivity summary")

    return matrix summary=`Summary'
    return matrix efficiency_draws=`Draws'
    return matrix unrestricted_efficiency=`Ebase'
    return matrix reference_efficiency=`Eref'
    return matrix output_priority=`PY'
    return matrix input_priority=`PX'
    if `m'>1 return scalar input_cr=`IX'
    if `s'>1 return scalar output_cr=`IY'
    return scalar reps=`reps'
    return scalar sigma=`sigma'
    return scalar seed=`seed'
    return local perturbation "reciprocal_lognormal"
    return local orientation "`orientation'"
    return local rts "`rts'"
    return local cmdline `"ahpdeasim `cmdline'"'
    return local cmd "ahpdeasim"
end
