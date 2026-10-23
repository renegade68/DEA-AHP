*! version 0.2.1 24oct2026 | DEA-first AHP tie and pairwise methods
*! Code author: Lee, Choonjoo
*! Methodological basis: Saaty (1987); Sinuany-Stern, Mehrez, and Hadad (2000);
*!                       DEA v2.0 in Lee (forthcoming)
program define deaahp, rclass
    version 16.0
    local cmdline `"`0'"'
    local inputs
    gettoken word 0 : 0, parse("=,")
    while `"`word'"' != "=" & `"`word'"' != "" {
        if `"`word'"' == "," {
            di as error "comma encountered before '='"
            exit 198
        }
        local inputs `inputs' `word'
        gettoken word 0 : 0, parse("=,")
    }
    if `"`word'"' != "=" | `"`inputs'"' == "" {
        di as error "syntax is: deaahp inputvars = outputvars, dmu(varname)"
        exit 198
    }
    syntax varlist(min=1 numeric) [if] [in], DMU(varname) ///
        [COMParison(name) PRIORities(name) TARGET(real 1) ///
         TIETOLerance(real 1e-8) MODEL(string) METHOD(string) RTS(string) ///
         ORIentation(string) AHPMETHOD(string) GENerate(name) ///
         DEAGenerate(name) ENGINE(string)]
    local outputs `varlist'

    if missing(`target', `tietolerance') {
        di as error "target() and tietolerance() must be finite"
        exit 198
    }

    if `tietolerance' < 0 {
        di as error "tietolerance() must be nonnegative"
        exit 198
    }
    if `"`comparison'"' != "" & `"`priorities'"' != "" {
        di as error "specify only one of comparison() or priorities()"
        exit 198
    }
    if `"`method'"' == "" local method tiebreak
    local method = lower(`"`method'"')
    if !inlist(`"`method'"',"tiebreak","pairwise") {
        di as error "method() must be tiebreak or pairwise"
        exit 198
    }
    if `"`method'"' == "pairwise" & `"`comparison'`priorities'"' != "" {
        di as error "comparison() and priorities() are not allowed with method(pairwise)"
        exit 198
    }
    if `"`model'"' == "" local model te
    if lower(`"`model'"') != "te" {
        di as error "version 0.2.0 supports model(te) only"
        exit 198
    }
    if `"`rts'"' == "" local rts crs
    if !inlist(lower(`"`rts'"'),"crs","vrs") {
        di as error "rts() must be crs or vrs"
        exit 198
    }
    if `"`orientation'"' == "" local orientation input
    if !inlist(lower(`"`orientation'"'),"input","output","i","o") {
        di as error "orientation() must be input or output"
        exit 198
    }
    if inlist(lower(`"`orientation'"'),"i") local orientation input
    if inlist(lower(`"`orientation'"'),"o") local orientation output
    if `"`ahpmethod'"' == "" local ahpmethod eigen
    if !inlist(lower(`"`ahpmethod'"'),"eigen","geomean") {
        di as error "ahpmethod() must be eigen or geomean"
        exit 198
    }
    if `"`engine'"' == "" local engine simplex
    if `"`generate'"' != "" & `"`generate'"' == `"`deagenerate'"' {
        di as error "generate() and deagenerate() must name different variables"
        exit 198
    }
    if `"`generate'"' != "" confirm new variable `generate'
    if `"`deagenerate'"' != "" confirm new variable `deagenerate'
    capture which dea
    if _rc {
        di as error "deaahp requires dea version 2 on the ado-path"
        exit 601
    }

    unab inputs : `inputs'
    confirm numeric variable `inputs' `outputs'

    marksample touse
    markout `touse' `inputs' `outputs'
    quietly count if `touse' & missing(`dmu')
    if r(N)>0 {
        di as error "dmu() must be nonmissing in the estimation sample"
        exit 459
    }
    tempvar dupdmu deawork
    quietly duplicates tag `dmu' if `touse', generate(`dupdmu')
    quietly count if `touse' & `dupdmu'>0
    if r(N)>0 {
        di as error "dmu() must be unique and nonmissing in the estimation sample"
        exit 459
    }

    tempname E DR HR T TP C LMAX CI CR SUMW MINW PE PX PST PW PD
    quietly dea `inputs' = `outputs' if `touse', dmu(`dmu') ///
        model(te) rts(`rts') orientation(`orientation') engine(`engine') ///
        generate(`deawork')
    matrix `E' = r(efficiency)
    local dea_engine `"`r(engine)'"'
    local N = rowsof(`E')
    if r(n_failed) > 0 {
        di as error "DEA reported failed DMU evaluations"
        exit 498
    }

    matrix `T' = J(`N',1,0)
    tempvar dmukey dupkey
    capture confirm string variable `dmu'
    if !_rc quietly gen str32 `dmukey' = strtoname(`dmu') if `touse'
    else quietly gen str32 `dmukey' = strtoname("dmu_"+string(`dmu',"%18.0g")) if `touse'
    quietly duplicates tag `dmukey' if `touse', generate(`dupkey')
    quietly count if `touse' & `dupkey'>0
    if r(N)>0 {
        di as error "dmu() identifiers are not unique after conversion to Stata matrix names"
        exit 459
    }

    local allnames
    local k 0
    quietly count
    forvalues obs=1/`r(N)' {
        if `touse'[`obs'] {
            local ++k
            quietly levelsof `dmukey' if _n==`obs', local(onekey) clean
            local allnames `allnames' `onekey'
        }
    }
    matrix rownames `E'=`allnames'

    if `"`method'"' == "pairwise" {
        if `N' < 2 {
            di as error "method(pairwise) requires at least two DMUs"
            exit 2001
        }
        if `"`rts'"'!="crs" | `"`orientation'"'!="input" {
            di as error "method(pairwise) implements the source model's rts(crs) orientation(input) specification"
            exit 198
        }
        quietly _ahpdea_load
        quietly _ahp_dea_load
        mata: ahpdea__pairwise_sums("`inputs'","`outputs'","`touse'", ///
            "`C'","`PE'","`PX'","`PST'")
        mata: st_numscalar("`MINW'",min(st_matrix("`C'")))
        if missing(`MINW') | `MINW'<=0 {
            di as error "pairwise DEA comparison construction failed"
            exit 498
        }
        matrix rownames `C'=`allnames'
        matrix colnames `C'=`allnames'
        matrix rownames `PE'=`allnames'
        matrix colnames `PE'=`allnames'
        matrix rownames `PX'=`allnames'
        matrix colnames `PX'=`allnames'
        matrix rownames `PST'=`allnames'
        matrix colnames `PST'=`allnames'
        quietly ahp `C', method(`ahpmethod')
        matrix `PW'=r(weights)'
        matrix rownames `PW'=`allnames'
        scalar `LMAX'=r(lambda_max)
        scalar `CI'=r(ci)
        scalar `CR'=r(cr)
        matrix `PD'=r(details)
        matrix `T'=J(`N',1,1)
        matrix `TP'=`PW'
        quietly _ahp_dea_load
        mata: ahpdea__hybrid_rank("`E'","`T'","`TP'",`tietolerance',"`DR'","`HR'")
        matrix rownames `T'=`allnames'
        matrix rownames `DR'=`allnames'
        matrix rownames `HR'=`allnames'

        if `"`deagenerate'"' != "" quietly gen double `deagenerate'=.
        if `"`generate'"' != "" quietly gen double `generate'=.
        local k 0
        quietly count
        forvalues obs=1/`r(N)' {
            if `touse'[`obs'] {
                local ++k
                if `"`deagenerate'"' != "" quietly replace `deagenerate'=`E'[`k',1] in `obs'
                if `"`generate'"' != "" quietly replace `generate'=`HR'[`k',1] in `obs'
            }
        }
        di as text "DEA-first AHP pairwise ranking"
        di as text "Pairwise DEA model: " as result "`rts' `orientation'"
        di as text "DMU pairs evaluated: " as result `=`N'*(`N'-1)/2'
        di as text "AHP method / CR: " as result "`ahpmethod' / " %9.6f scalar(`CR')
        di as text "Hybrid output scale: " as result "ordinal rank (not efficiency)"

        return matrix hybrid_rank=`HR'
        return matrix pair_priority=`PW'
        return matrix comparison=`C'
        return matrix pair_efficiency=`PE'
        return matrix cross_efficiency=`PX'
        return matrix pair_status=`PST'
        return matrix ahp_details=`PD'
        return matrix dea_rank=`DR'
        return matrix efficiency=`E'
        return scalar lambda_max=scalar(`LMAX')
        return scalar ci=scalar(`CI')
        return scalar cr=scalar(`CR')
        return scalar N=`N'
        return scalar N_pairs=`N'*(`N'-1)/2
        return local source_model "Sinuany-Stern, Mehrez, and Hadad (2000)"
        return local source_doi "10.1111/j.1475-3995.2000.tb00189.x"
        return local method_definition "Sinuany-Stern two-DMU self-plus-cross DEA scores form a reciprocal AHP matrix"
        return local ahpmethod "`ahpmethod'"
        return local engine "`dea_engine'"
        return local orientation "`orientation'"
        return local rts "`rts'"
        return local model "te"
        return local method "pairwise"
        return local hybrid_scale "ordinal"
        return local outputs "`outputs'"
        return local inputs "`inputs'"
        return local dmu "`dmu'"
        return local cmdline `"deaahp `cmdline'"'
        return local cmd "deaahp"
        exit
    }

    local tiednames
    local k 0
    local ntied 0
    quietly count
    forvalues obs=1/`r(N)' {
        if `touse'[`obs'] {
            local ++k
            if abs(`E'[`k',1]-`target') <= `tietolerance' {
                matrix `T'[`k',1] = 1
                local ++ntied
                quietly levelsof `dmukey' if _n==`obs', local(onekey) clean
                local tiednames `tiednames' `onekey'
            }
        }
    }

    local tie_resolved 0
    local tie_source none
    matrix `TP' = J(max(1,`ntied'),1,1)
    if `ntied' >= 2 {
        if `"`comparison'`priorities'"' == "" {
            di as error "`ntied' tied DMUs require comparison() or priorities()"
            di as error "expected names:`tiednames'"
            exit 198
        }
        if `"`comparison'"' != "" {
            local rn : rownames `comparison'
            local cn : colnames `comparison'
            if `"`rn'"' != `"`tiednames'"' | `"`cn'"' != `"`tiednames'"' {
                di as error "comparison() row and column names must match the tie set"
                di as error "expected:`tiednames'"
                exit 503
            }
            quietly ahp `comparison', method(`ahpmethod')
            matrix `TP' = r(weights)
            if rowsof(`TP')==1 & colsof(`TP')==`ntied' matrix `TP'=`TP''
            scalar `LMAX' = r(lambda_max)
            scalar `CI' = r(ci)
            scalar `CR' = r(cr)
            matrix `C' = `comparison'
            local tie_source comparison
        }
        else {
            matrix `TP' = `priorities'
            if rowsof(`TP')==1 & colsof(`TP')==`ntied' matrix `TP'=`TP''
            if rowsof(`TP')!=`ntied' | colsof(`TP')!=1 {
                di as error "priorities() must contain one value for each tied DMU"
                exit 503
            }
            local pn : rownames `TP'
            if `"`pn'"' != `"`tiednames'"' {
                di as error "priorities() names must match the tie set"
                di as error "expected:`tiednames'"
                exit 503
            }
            mata: st_numscalar("`SUMW'", sum(st_matrix("`TP'")))
            mata: st_numscalar("`MINW'", min(st_matrix("`TP'")))
            if missing(`SUMW') | missing(`MINW') | `MINW'<=0 | `SUMW'<=0 {
                di as error "priorities() values must be positive and finite"
                exit 459
            }
            mata: st_matrix("`TP'",st_matrix("`TP'"):/sum(st_matrix("`TP'")))
            local tie_source priorities
        }
        local tie_resolved 1
    }

    quietly _ahp_dea_load
    mata: ahpdea__hybrid_rank("`E'","`T'","`TP'",`tietolerance',"`DR'","`HR'")
    matrix rownames `T'=`allnames'
    matrix rownames `DR'=`allnames'
    matrix rownames `HR'=`allnames'
    if `"`deagenerate'"' != "" {
        quietly gen double `deagenerate' = .
    }
    if `"`generate'"' != "" {
        quietly gen double `generate' = .
    }
    local k 0
    quietly count
    forvalues obs=1/`r(N)' {
        if `touse'[`obs'] {
            local ++k
            if `"`deagenerate'"' != "" quietly replace `deagenerate'=`E'[`k',1] in `obs'
            if `"`generate'"' != "" quietly replace `generate'=`HR'[`k',1] in `obs'
        }
    }

    di as text "DEA-first AHP tie discrimination"
    di as text "DEA model: " as result "`rts' `orientation'"
    di as text "Target / tolerance: " as result %9.6g `target' " / " %9.2g `tietolerance'
    di as text "DMUs in selected tie: " as result `ntied'
    if `tie_resolved' di as text "Tie resolved using: " as result "`tie_source'"
    else di as text "No AHP second stage was required"
    di as text "Hybrid output scale: " as result "ordinal rank (not efficiency)"

    return matrix hybrid_rank = `HR'
    return matrix tie_priority = `TP'
    return matrix tie_members = `T'
    return matrix dea_rank = `DR'
    return matrix efficiency = `E'
    if `tie_resolved' & `"`comparison'"' != "" return matrix comparison = `C'
    if `tie_resolved' & `"`comparison'"' != "" {
        return scalar lambda_max = scalar(`LMAX')
        return scalar ci = scalar(`CI')
        return scalar cr = scalar(`CR')
    }
    return scalar N = `N'
    return scalar N_tied = `ntied'
    return scalar target = `target'
    return scalar tietolerance = `tietolerance'
    return scalar tie_resolved = `tie_resolved'
    return local tie_names `"`tiednames'"'
    return local tie_source "`tie_source'"
    return local ahpmethod "`ahpmethod'"
    return local engine "`dea_engine'"
    return local orientation "`orientation'"
    return local rts "`rts'"
    return local model "te"
    return local method "tiebreak"
    return local hybrid_scale "ordinal"
    return local method_definition "DEA numerical-equivalence class followed by supplied AHP priorities"
    return local application_precedent "Wang, Nguyen, and Wang (2023)"
    return local distinct_pairwise_model "Sinuany-Stern, Mehrez, and Hadad (2000)"
    return local outputs "`outputs'"
    return local inputs "`inputs'"
    return local dmu "`dmu'"
    return local cmdline `"deaahp `cmdline'"'
    return local cmd "deaahp"
end
