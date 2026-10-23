*! version 0.3.1 24oct2026 | AHP-derived assurance-region DEA
*! Code author: Lee, Choonjoo
*! Methodological basis: Saaty (1987); Takamura and Tone (2003);
*!                       DEA v2.0 in Lee (forthcoming)
program define ahpdea, rclass
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
        di as error "syntax is: ahpdea inputvars = outputvars, dmu(varname)"
        exit 198
    }
    syntax varlist(min=1 numeric) [if] [in], DMU(varname) ///
        [INPUTMatrix(name) OUTPUTMatrix(name) INPUTWeights(name) ///
         OUTPUTWeights(name) INPUTGroup(namelist) OUTPUTGroup(namelist) ///
         INPUTScale(name) OUTPUTScale(name) ///
         INPUTLower(name) INPUTUpper(name) OUTPUTLower(name) OUTPUTUpper(name) ///
         BAND(real 0) LOWERBAND(real -1) UPPERBAND(real -1) ///
         BOUNDS(string) AHPMETHOD(string) ///
         MODEL(string) RTS(string) ORIentation(string) ///
         GENerate(name) BASEline(name)]
    if missing(`band', `lowerband', `upperband') {
        di as error "band options must be finite"
        exit 198
    }
    if (`lowerband'<0 & `lowerband'!=-1) | (`upperband'<0 & `upperband'!=-1) {
        di as error "asymmetric bands must be nonnegative when specified"
        exit 198
    }

    local outputs `varlist'
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
    if !`asymmetric' {
        local lowerband=`band'
        local upperband=`band'
    }
    if `"`bounds'"'=="" local bounds band
    local bounds=lower(`"`bounds'"')
    if !inlist(`"`bounds'"',"band","groupminmax","pairwise") {
        di as error "bounds() must be band, groupminmax, or pairwise"
        exit 198
    }
    if `"`bounds'"'=="groupminmax" & (`band'!=0 | `asymmetric') {
        di as error "band options may not be combined with bounds(groupminmax)"
        exit 198
    }
    local anypair = (`"`inputlower'`inputupper'`outputlower'`outputupper'"'!="")
    if `anypair' & `"`bounds'"'!="pairwise" {
        di as error "pair-specific bound matrices require bounds(pairwise)"
        exit 198
    }
    if `"`bounds'"'=="pairwise" & !`anypair' {
        di as error "bounds(pairwise) requires an input or output lower/upper pair"
        exit 198
    }
    if `"`bounds'"'=="pairwise" & (`band'!=0 | `asymmetric') {
        di as error "band options may not be combined with bounds(pairwise)"
        exit 198
    }
    if (`"`inputlower'"'=="") != (`"`inputupper'"'=="") {
        di as error "specify both inputlower() and inputupper()"
        exit 198
    }
    if (`"`outputlower'"'=="") != (`"`outputupper'"'=="") {
        di as error "specify both outputlower() and outputupper()"
        exit 198
    }
    if `"`model'"'=="" local model ar
    if lower(`"`model'"')!="ar" {
        di as error "ahpdea supports model(ar) only"
        exit 198
    }
    if `"`rts'"'=="" local rts crs
    local rts=lower(`"`rts'"')
    if !inlist(`"`rts'"',"crs","vrs") {
        di as error "rts() must be crs or vrs"
        exit 198
    }
    if `"`orientation'"'=="" local orientation input
    local orientation=lower(`"`orientation'"')
    if inlist(`"`orientation'"',"i") local orientation input
    if inlist(`"`orientation'"',"o") local orientation output
    if !inlist(`"`orientation'"',"input","output") {
        di as error "orientation() must be input or output"
        exit 198
    }
    if `"`inputmatrix'"'!="" & `"`inputweights'"'!="" {
        di as error "specify only one of inputmatrix() or inputweights()"
        exit 198
    }
    if `"`outputmatrix'"'!="" & `"`outputweights'"'!="" {
        di as error "specify only one of outputmatrix() or outputweights()"
        exit 198
    }
    if (`"`inputgroup'"'!="") + (`"`inputmatrix'"'!="") + (`"`inputweights'"'!="") > 1 {
        di as error "specify only one of inputgroup(), inputmatrix(), or inputweights()"
        exit 198
    }
    if (`"`outputgroup'"'!="") + (`"`outputmatrix'"'!="") + (`"`outputweights'"'!="") > 1 {
        di as error "specify only one of outputgroup(), outputmatrix(), or outputweights()"
        exit 198
    }
    if `"`bounds'"'=="groupminmax" & `"`inputgroup'`outputgroup'"'=="" {
        di as error "bounds(groupminmax) requires inputgroup() or outputgroup()"
        exit 198
    }
    if `"`bounds'"'=="pairwise" & `"`inputgroup'`outputgroup'"'!="" {
        di as error "inputgroup() and outputgroup() require bounds(groupminmax) or bounds(band)"
        exit 198
    }
    if `"`ahpmethod'"'=="" local ahpmethod eigen
    if !inlist(lower(`"`ahpmethod'"'),"eigen","geomean") {
        di as error "ahpmethod() must be eigen or geomean"
        exit 198
    }
    if `"`generate'"'!="" & `"`generate'"'==`"`baseline'"' {
        di as error "generate() and baseline() must name different variables"
        exit 198
    }
    if `"`generate'"'!="" confirm new variable `generate'
    if `"`baseline'"'!="" confirm new variable `baseline'
    capture which dea
    if _rc {
        di as error "ahpdea requires dea version 2 and _dea_simplex.ado on the ado-path"
        exit 601
    }

    marksample touse
    markout `touse' `inputs' `outputs'
    quietly count if `touse'
    local N=r(N)
    if `N'<2 {
        di as error "at least two complete DMUs are required"
        exit 2001
    }
    quietly count if `touse' & missing(`dmu')
    if r(N)>0 {
        di as error "dmu() must be unique and nonmissing in the estimation sample"
        exit 459
    }
    tempvar dupdmu deawork dmukey dupkey
    quietly duplicates tag `dmu' if `touse', generate(`dupdmu')
    quietly count if `touse' & `dupdmu'>0
    if r(N)>0 {
        di as error "dmu() must be unique and nonmissing in the estimation sample"
        exit 459
    }
    capture confirm string variable `dmu'
    if !_rc quietly gen str32 `dmukey'=strtoname(`dmu') if `touse'
    else quietly gen str32 `dmukey'=strtoname("dmu_"+string(`dmu',"%18.0g")) if `touse'
    quietly duplicates tag `dmukey' if `touse', generate(`dupkey')
    quietly count if `touse' & `dupkey'>0
    if r(N)>0 {
        di as error "dmu() identifiers are not unique after conversion to Stata matrix names"
        exit 459
    }
    local dmunames
    quietly count
    forvalues obs=1/`r(N)' {
        if `touse'[`obs'] {
            quietly levelsof `dmukey' if _n==`obs', local(onekey) clean
            local dmunames `dmunames' `onekey'
        }
    }
    foreach z of varlist `inputs' `outputs' {
        quietly count if (`z'<=0 | missing(`z')) & `touse'
        if r(N) {
            di as error "ahpdea requires strictly positive data"
            exit 459
        }
    }

    local m : word count `inputs'
    local s : word count `outputs'
    if `m'==1 & `"`inputgroup'"'!="" {
        di as error "inputgroup() is unnecessary when there is one input"
        exit 198
    }
    if `s'==1 & `"`outputgroup'"'!="" {
        di as error "outputgroup() is unnecessary when there is one output"
        exit 198
    }
    tempname PX PY SX SY LX HX LY HY GWX GWY E0 E V U W ST DX DY IX IY

    if `m'==1 {
        if `"`inputmatrix'"'!="" {
            local rn : rownames `inputmatrix'
            local cn : colnames `inputmatrix'
            if rowsof(`inputmatrix')!=1 | colsof(`inputmatrix')!=1 | ///
               `"`rn'"'!=`"`inputs'"' | `"`cn'"'!=`"`inputs'"' {
                di as error "inputmatrix() names must match input variables"
                exit 503
            }
            if abs(el(`inputmatrix',1,1)-1)>1e-10 {
                di as error "a singleton inputmatrix() must equal 1"
                exit 459
            }
            matrix `PX'=(1)
            matrix rownames `PX'=`inputs'
            scalar `IX'=0
        }
        else if `"`inputweights'"'!="" matrix `PX'=`inputweights'
        else {
            matrix `PX'=(1)
            matrix rownames `PX'=`inputs'
        }
    }
    else {
        if `"`inputmatrix'`inputweights'`inputgroup'"'=="" {
            di as error "multiple inputs require inputmatrix(), inputweights(), or inputgroup()"
            exit 198
        }
        if `"`inputgroup'"'!="" {
            local first 1
            foreach M of local inputgroup {
                local rn : rownames `M'
                local cn : colnames `M'
                if `"`rn'"'!=`"`inputs'"' | `"`cn'"'!=`"`inputs'"' {
                    di as error "each inputgroup() matrix must be named for the input variables"
                    exit 503
                }
                quietly ahp `M', method(`ahpmethod')
                if `first' matrix `GWX'=r(weights)'
                else matrix `GWX'=`GWX',r(weights)'
                local first 0
            }
            quietly ahp `inputgroup', method(`ahpmethod') aggregate(aij)
            matrix `PX'=r(weights)'
            scalar `IX'=r(cr)
        }
        else if `"`inputmatrix'"'!="" {
            local rn : rownames `inputmatrix'
            local cn : colnames `inputmatrix'
            if `"`rn'"'!=`"`inputs'"' | `"`cn'"'!=`"`inputs'"' {
                di as error "inputmatrix() names must match input variables"
                exit 503
            }
            quietly ahp `inputmatrix', method(`ahpmethod')
            matrix `PX'=r(weights)'
            scalar `IX'=r(cr)
        }
        else matrix `PX'=`inputweights'
    }
    if `s'==1 {
        if `"`outputmatrix'"'!="" {
            local rn : rownames `outputmatrix'
            local cn : colnames `outputmatrix'
            if rowsof(`outputmatrix')!=1 | colsof(`outputmatrix')!=1 | ///
               `"`rn'"'!=`"`outputs'"' | `"`cn'"'!=`"`outputs'"' {
                di as error "outputmatrix() names must match output variables"
                exit 503
            }
            if abs(el(`outputmatrix',1,1)-1)>1e-10 {
                di as error "a singleton outputmatrix() must equal 1"
                exit 459
            }
            matrix `PY'=(1)
            matrix rownames `PY'=`outputs'
            scalar `IY'=0
        }
        else if `"`outputweights'"'!="" matrix `PY'=`outputweights'
        else {
            matrix `PY'=(1)
            matrix rownames `PY'=`outputs'
        }
    }
    else {
        if `"`outputmatrix'`outputweights'`outputgroup'"'=="" {
            di as error "multiple outputs require outputmatrix(), outputweights(), or outputgroup()"
            exit 198
        }
        if `"`outputgroup'"'!="" {
            local first 1
            foreach M of local outputgroup {
                local rn : rownames `M'
                local cn : colnames `M'
                if `"`rn'"'!=`"`outputs'"' | `"`cn'"'!=`"`outputs'"' {
                    di as error "each outputgroup() matrix must be named for the output variables"
                    exit 503
                }
                quietly ahp `M', method(`ahpmethod')
                if `first' matrix `GWY'=r(weights)'
                else matrix `GWY'=`GWY',r(weights)'
                local first 0
            }
            quietly ahp `outputgroup', method(`ahpmethod') aggregate(aij)
            matrix `PY'=r(weights)'
            scalar `IY'=r(cr)
        }
        else if `"`outputmatrix'"'!="" {
            local rn : rownames `outputmatrix'
            local cn : colnames `outputmatrix'
            if `"`rn'"'!=`"`outputs'"' | `"`cn'"'!=`"`outputs'"' {
                di as error "outputmatrix() names must match output variables"
                exit 503
            }
            quietly ahp `outputmatrix', method(`ahpmethod')
            matrix `PY'=r(weights)'
            scalar `IY'=r(cr)
        }
        else matrix `PY'=`outputweights'
    }

    foreach side in X Y {
        local P = cond("`side'"=="X","`PX'","`PY'")
        local vars = cond("`side'"=="X","`inputs'","`outputs'")
        local dim = cond("`side'"=="X",`m',`s')
        * Do not transpose a generated 1 x 1 singleton: Stata would replace
        * its declared row name by the column name c1.
        if `dim'>1 & rowsof(`P')==1 & colsof(`P')==`dim' matrix `P'=`P''
        if rowsof(`P')!=`dim' | colsof(`P')!=1 {
            di as error "priority vector has incompatible dimensions"
            exit 503
        }
        local pn : rownames `P'
        if `"`pn'"'!=`"`vars'"' {
            di as error "`=cond("`side'"=="X","input","output")' priority-vector names must match variable names"
            di as error "declared: `vars'"
            di as error "received: `pn'"
            exit 503
        }
        mata: st_numscalar("`DX'",min(st_matrix("`P'")))
        if missing(`DX') | `DX'<=0 {
            di as error "priority values must be positive and finite"
            exit 459
        }
        mata: st_matrix("`P'",st_matrix("`P'"):/sum(st_matrix("`P'")))
    }

    if `"`inputscale'"'=="" {
        mata: st_matrix("`SX'",mean(st_data(.,tokens("`inputs'"),"`touse'"))')
        local input_scale_source sample_mean
    }
    else {
        local sr : rownames `inputscale'
        if rowsof(`inputscale')!=`m' | colsof(`inputscale')!=1 | `"`sr'"'!=`"`inputs'"' {
            di as error "inputscale() must be a named column vector matching input variables"
            exit 503
        }
        matrix `SX'=`inputscale'
        mata: st_numscalar("`DX'",sum(missing(st_matrix("`SX'")))+sum(st_matrix("`SX'"):<=0))
        if `DX'>0 {
            di as error "inputscale() values must be positive and finite"
            exit 459
        }
        local input_scale_source user
    }
    if `"`outputscale'"'=="" {
        mata: st_matrix("`SY'",mean(st_data(.,tokens("`outputs'"),"`touse'"))')
        local output_scale_source sample_mean
    }
    else {
        local sr : rownames `outputscale'
        if rowsof(`outputscale')!=`s' | colsof(`outputscale')!=1 | `"`sr'"'!=`"`outputs'"' {
            di as error "outputscale() must be a named column vector matching output variables"
            exit 503
        }
        matrix `SY'=`outputscale'
        mata: st_numscalar("`DX'",sum(missing(st_matrix("`SY'")))+sum(st_matrix("`SY'"):<=0))
        if `DX'>0 {
            di as error "outputscale() values must be positive and finite"
            exit 459
        }
        local output_scale_source user
    }
    matrix rownames `SX'=`inputs'
    matrix rownames `SY'=`outputs'

    quietly _ahpdea_load
    if `"`bounds'"'=="pairwise" {
        foreach side in input output {
            local vars = cond("`side'"=="input","`inputs'","`outputs'")
            local dim = cond("`side'"=="input",`m',`s')
            local lo = cond("`side'"=="input","`inputlower'","`outputlower'")
            local hi = cond("`side'"=="input","`inputupper'","`outputupper'")
            if `"`lo'"'!="" {
                local lrn : rownames `lo'
                local lcn : colnames `lo'
                local hrn : rownames `hi'
                local hcn : colnames `hi'
                if rowsof(`lo')!=`dim' | colsof(`lo')!=`dim' | ///
                   rowsof(`hi')!=`dim' | colsof(`hi')!=`dim' | ///
                   `"`lrn'"'!=`"`vars'"' | `"`lcn'"'!=`"`vars'"' | ///
                   `"`hrn'"'!=`"`vars'"' | `"`hcn'"'!=`"`vars'"' {
                    di as error "`side' lower/upper matrices must be square and named for the `side' variables"
                    exit 503
                }
                mata: st_numscalar("`DX'",ahpdea_ar__invalid_pair_bounds(st_matrix("`lo'"),st_matrix("`hi'")))
                if `DX'>0 {
                    di as error "`side' pair bounds must be finite, nonnegative/positive, ordered, reciprocal-feasible, and have unit diagonals"
                    exit 459
                }
            }
        }
    }

    if `"`bounds'"'=="pairwise" & `"`inputlower'"'!="" {
        matrix `LX'=`inputlower'
        matrix `HX'=`inputupper'
    }
    else if `"`bounds'"'=="groupminmax" & `"`inputgroup'"'!="" {
        mata: ahpdea_ar__group_bounds("`GWX'","`LX'","`HX'")
    }
    else mata: ahpdea_ar__band_bounds("`PX'",`lowerband',`upperband',"`LX'","`HX'")
    if `"`bounds'"'=="pairwise" & `"`outputlower'"'!="" {
        matrix `LY'=`outputlower'
        matrix `HY'=`outputupper'
    }
    else if `"`bounds'"'=="groupminmax" & `"`outputgroup'"'!="" {
        mata: ahpdea_ar__group_bounds("`GWY'","`LY'","`HY'")
    }
    else mata: ahpdea_ar__band_bounds("`PY'",`lowerband',`upperband',"`LY'","`HY'")
    matrix rownames `LX'=`inputs'
    matrix colnames `LX'=`inputs'
    matrix rownames `HX'=`inputs'
    matrix colnames `HX'=`inputs'
    matrix rownames `LY'=`outputs'
    matrix colnames `LY'=`outputs'
    matrix rownames `HY'=`outputs'
    matrix colnames `HY'=`outputs'

    quietly dea `inputs' = `outputs' if `touse', dmu(`dmu') model(te) ///
        rts(`rts') orientation(`orientation') engine(simplex) generate(`deawork')
    matrix `E0'=r(efficiency)
    mata: ahpdea_ar__solve("`inputs'","`outputs'","`touse'","`PX'","`PY'","`SX'","`SY'","`LX'","`HX'","`LY'","`HY'","`orientation'","`rts'","`E'","`V'","`U'","`W'","`ST'")
    mata: st_numscalar("`DX'",sum(st_matrix("`ST'"):!=0))
    if `DX'>0 {
        di as error "restricted DEA failed for " %9.0g `DX' " DMU(s)"
        exit 430
    }
    matrix colnames `E'=efficiency
    matrix rownames `E'=`dmunames'
    matrix rownames `E0'=`dmunames'
    matrix rownames `ST'=`dmunames'
    matrix rownames `V'=`dmunames'
    matrix rownames `U'=`dmunames'
    matrix rownames `W'=`dmunames'
    matrix colnames `V'=`inputs'
    matrix colnames `U'=`outputs'

    if `"`generate'"'!="" {
        quietly gen double `generate'=.
    }
    if `"`baseline'"'!="" {
        quietly gen double `baseline'=.
    }
    local k=0
    quietly count
    forvalues i=1/`r(N)' {
        if `touse'[`i'] {
            local ++k
            if `"`generate'"'!="" quietly replace `generate'=`E'[`k',1] in `i'
            if `"`baseline'"'!="" quietly replace `baseline'=`E0'[`k',1] in `i'
        }
    }

    local rtslabel=upper("`rts'")
    if `"`bounds'"'=="pairwise" local bandtype pairwise
    else if `asymmetric' local bandtype asymmetric
    else local bandtype symmetric
    di as text "AHP-constrained DEA (scaled virtual-share assurance regions)"
    di as text "Model: " as result "`rtslabel' `orientation'-oriented" ///
        as text "   bounds: " as result "`bounds'"
    if `"`bounds'"'=="band" {
        if `asymmetric' di as text "Lower / upper band: " as result ///
            %9.4g `lowerband' " / " %9.4g `upperband'
        else di as text "Band: " as result %9.4g `band'
    }
    di as text "DMUs: " as result `N'
    return matrix status=`ST'
    return matrix intercept=`W'
    return matrix output_multiplier=`U'
    return matrix input_multiplier=`V'
    return matrix output_scale=`SY'
    return matrix input_scale=`SX'
    return matrix output_lower=`LY'
    return matrix output_upper=`HY'
    return matrix input_lower=`LX'
    return matrix input_upper=`HX'
    return matrix output_priority=`PY'
    return matrix input_priority=`PX'
    if `"`inputgroup'"'!="" return matrix input_evaluator_priority=`GWX'
    if `"`outputgroup'"'!="" return matrix output_evaluator_priority=`GWY'
    return matrix baseline_efficiency=`E0'
    return matrix efficiency=`E'
    if `"`inputmatrix'`inputgroup'"'!="" return scalar input_cr=`IX'
    if `"`outputmatrix'`outputgroup'"'!="" return scalar output_cr=`IY'
    return scalar N=`N'
    return local methodological_foundation "Thompson et al. (1986); Allen et al. (1997)"
    return local application_precedent "Takamura and Tone (2003)"
    return local model "ar"
    return local method_definition "scaled virtual-share assurance regions"
    return local bounds "`bounds'"
    return scalar band=`band'
    return scalar lowerband=`lowerband'
    return scalar upperband=`upperband'
    return local band_type "`bandtype'"
    return local input_scale_source "`input_scale_source'"
    return local output_scale_source "`output_scale_source'"
    return local outputs "`outputs'"
    return local inputs "`inputs'"
    return local dmu "`dmu'"
    return local orientation "`orientation'"
    return local rts "`rts'"
    return local method "ar"
    return local cmdline `"ahpdea `cmdline'"'
    return local cmd "ahpdea"
end
