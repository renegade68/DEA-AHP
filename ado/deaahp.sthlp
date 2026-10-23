{smcl}
{* *! help revision 24oct2026}{...}
{viewerjumpto "Syntax" "deaahp##syntax"}{...}
{viewerjumpto "Description" "deaahp##description"}{...}
{viewerjumpto "Options" "deaahp##options"}{...}
{viewerjumpto "Stored results" "deaahp##stored_results"}{...}
{viewerjumpto "Examples" "deaahp##examples"}{...}
{viewerjumpto "References" "deaahp##references"}{...}
{viewerjumpto "Authors" "deaahp##authors"}{...}
{title:Title}

{p2colset 5 17 19 2}{...}
{p2col :{cmd:deaahp} {hline 2}}DEA-first AHP tie discrimination or pairwise ranking{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}{cmd:deaahp} {it:inputvars} {cmd:=} {it:outputvars}
[{it:if}] [{it:in}], {opt dmu(varname)}
[{opt comparison(matrix)} {opt priorities(matrix)}
 {opt target(#)} {opt tietolerance(#)} {opt model(te)}
 {opt method(tiebreak|pairwise)}
 {opt rts(crs|vrs)} {opt orientation(input|output)}
 {opt ahpmethod(eigen|geomean)} {opt engine(simplex|ipm)}
 {opt generate(newvar)} {opt deagenerate(newvar)}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt dmu(varname)}}unique DMU identifier; required{p_end}
{synopt:{opt method(tiebreak|pairwise)}}integration rule; default {cmd:tiebreak}{p_end}
{synopt:{opt comparison(matrix)}}tie-set reciprocal comparison matrix{p_end}
{synopt:{opt priorities(matrix)}}tie-set priority vector{p_end}
{synopt:{opt target(#)}}efficiency level to resolve; default {cmd:1}{p_end}
{synopt:{opt tietolerance(#)}}tie tolerance; default {cmd:1e-8}{p_end}
{synopt:{opt model(te)}}tie-equivalence workflow{p_end}
{synopt:{opt rts(crs|vrs)}}returns to scale; default {cmd:crs}{p_end}
{synopt:{opt orientation(input|output)}}radial orientation; default {cmd:input}{p_end}
{synopt:{opt ahpmethod(eigen|geomean)}}AHP priority method; default {cmd:eigen}{p_end}
{synopt:{opt engine(simplex|ipm)}}first-stage DEA solver; default {cmd:simplex}{p_end}
{synopt:{opt generate(newvar)}}hybrid rank variable{p_end}
{synopt:{opt deagenerate(newvar)}}DEA efficiency variable{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}With {cmd:method(tiebreak)}, the default, {cmd:deaahp} first calls
{help dea} and preserves its efficiency ordering
outside the subsequently declared numerical equivalence class. It then identifies DMUs whose efficiency lies within
{cmd:tietolerance()} of {cmd:target()}. When at least two DMUs are selected,
the command applies AHP priorities only within that tie set. DMUs outside the
selected set retain their DEA ordering relative to the selected class.

{pstd}The result is an ordinal, lexicographic refinement. AHP priorities are
normalized within the selected set and are not DEA efficiency scores; they
must not be compared numerically with efficiencies of DMUs outside that set.
{cmd:generate()} therefore creates a rank, while {cmd:deagenerate()} retains
the separate DEA efficiency.{p_end}

{pstd}With {cmd:method(pairwise)}, the command implements the construction of
Sinuany-Stern, Mehrez, and Hadad (2000). It evaluates every unordered pair of
DMUs against a technology containing only that pair. It obtains the primary
self scores E_ii and E_jj and the corresponding benevolent cross scores E_ij
and E_ji. Their reciprocal judgment is
{it:a}_{ij}=({it:E}_{ii}+{it:E}_{ij})/({it:E}_{jj}+{it:E}_{ji}). Classical
AHP then synthesizes the full matrix into a ranking of all DMUs. The source
model is CCR/input, so {cmd:method(pairwise)} requires
{cmd:rts(crs) orientation(input)}.{p_end}

{pstd}For {cmd:method(tiebreak)}, the default target is 1, so the usual
application discriminates among frontier DMUs. Version 0.2.0 supports
{cmd:model(te)}. The command requires
{cmd:dea} version 2 on the ado-path. The public AHP-DEA installation package
does not replace {cmd:dea}; the journal replication archive includes a
separate reviewer-only copy of the required DEA files.{p_end}

{marker options}{...}
{title:Options}

{phang}{opt method(tiebreak|pairwise)} selects the integration rule.
{cmd:tiebreak} preserves the conventional DEA ordering and uses supplied AHP
information only within a selected numerical equivalence class.
{cmd:pairwise} generates the AHP matrix internally from two-DMU DEA runs.

{phang}{opt comparison(matrix)} supplies a positive reciprocal comparison
matrix over the tied DMUs. Row and column names must exactly match the
sanitized {cmd:dmu()} identifiers reported by the command.

{phang}{opt priorities(matrix)} supplies an already synthesized positive AHP
priority vector over the tied DMUs. Names must match the tie set. Specify only
one of {cmd:comparison()} and {cmd:priorities()}.
These options apply only to {cmd:method(tiebreak)}.

{phang}{opt target(#)} selects the DEA efficiency level to resolve; default 1.

{phang}{opt tietolerance(#)} defines numerical membership in the selected tie;
default 1e-8.

{phang}{opt model(te)} selects the numerical-equivalence workflow. The only
supported value is {cmd:te}, which is also the default.

{phang}{opt rts(crs|vrs)} and {opt orientation(input|output)} specify the
radial DEA model for {cmd:method(tiebreak)}. The source-defined pairwise method
requires {cmd:rts(crs) orientation(input)}.

{phang}{opt ahpmethod(eigen|geomean)} selects the AHP synthesis rule; default
{cmd:eigen}. The eigenvector method and its consistency statistics follow
Saaty. The row geometric mean is an optional computational alternative.

{phang}{opt generate(newvar)} creates the ordinal hybrid rank. It does not
create a hybrid efficiency score.

{phang}{opt deagenerate(newvar)} creates the original DEA efficiency score.

{phang}{opt engine(simplex|ipm)} selects the solver used by the first-stage
{cmd:dea} call; the default is {cmd:simplex}. The source-defined
{cmd:method(pairwise)} calculations use the simplex interface.

{pstd}Both output names are validated before estimation. Existing variables
are never overwritten, and an error cannot leave only one requested output
variable behind.

{marker stored_results}{...}
{title:Stored results}

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{cmd:r(efficiency)}}original DEA efficiencies{p_end}
{synopt:{cmd:r(dea_rank)}}DEA ranks retaining ties{p_end}
{synopt:{cmd:r(tie_members)}}indicator for selected DMUs{p_end}
{synopt:{cmd:r(tie_priority)}}AHP priorities within the tie set{p_end}
{synopt:{cmd:r(hybrid_rank)}}DEA-first ranks: within-tie or full pairwise AHP,
according to {cmd:r(method)}{p_end}
{synopt:{cmd:r(hybrid_scale)}}{cmd:ordinal}; the hybrid output is a rank, not an
efficiency score{p_end}
{synopt:{cmd:r(method)}}{cmd:tiebreak} or {cmd:pairwise}{p_end}
{synopt:{cmd:r(comparison)}}supplied tie matrix, or the DEA-generated reciprocal
matrix under {cmd:method(pairwise)}{p_end}
{synopt:{cmd:r(pair_efficiency)}}pair-specific primary self scores; element
(i,j) is DMU i's self score when paired with j{p_end}
{synopt:{cmd:r(cross_efficiency)}}benevolent cross scores used with
{cmd:r(pair_efficiency)} to construct the judgments{p_end}
{synopt:{cmd:r(pair_status)}}LP status matrix for the pairwise score problems{p_end}
{synopt:{cmd:r(pair_priority)}}AHP priority vector for all DMUs under
{cmd:method(pairwise)}{p_end}
{synopt:{cmd:r(ahp_details)}}AHP diagnostics under {cmd:method(pairwise)}{p_end}
{synopt:{cmd:r(N_pairs)}}number of evaluated pairs under {cmd:method(pairwise)}{p_end}
{synopt:{cmd:r(N)}}number of DMUs{p_end}
{synopt:{cmd:r(N_tied)}}number of selected DMUs{p_end}
{synopt:{cmd:r(target)}}selected efficiency level{p_end}
{synopt:{cmd:r(tietolerance)}}tie membership tolerance{p_end}
{synopt:{cmd:r(tie_resolved)}}1 if an AHP second stage was run{p_end}
{synopt:{cmd:r(ahpmethod)}}AHP priority method{p_end}
{synopt:{cmd:r(engine)}}first-stage DEA solver{p_end}
{synopt:{cmd:r(rts)}}returns to scale{p_end}
{synopt:{cmd:r(orientation)}}radial orientation{p_end}
{synopt:{cmd:r(model)}}{cmd:te}, the implemented tie-equivalence workflow{p_end}
{synopt:{cmd:r(method_definition)}}implemented workflow definition{p_end}
{synopt:{cmd:r(application_precedent)}}DEA-screening/AHP application precedent{p_end}
{synopt:{cmd:r(distinct_pairwise_model)}}source for the pairwise DEA-AHP family{p_end}
{synopt:{cmd:r(lambda_max)}, {cmd:r(ci)}, {cmd:r(cr)}}AHP consistency results
when {cmd:comparison()} is used{p_end}
{synoptline}

{marker examples}{...}
{title:Examples}

{pstd}The following block is self-contained:{p_end}
{pstd}Run the complete block, omitting the leading dots. It restores the data in memory.{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. input str1 dmu double x double y}{p_end}
{phang2}{cmd:. "A" 1 1}{p_end}
{phang2}{cmd:. "B" 2 2}{p_end}
{phang2}{cmd:. "C" 2 1}{p_end}
{phang2}{cmd:. end}{p_end}
{phang2}{cmd:. matrix AB = (1,3 \ 1/3,1)}{p_end}
{phang2}{cmd:. matrix rownames AB = A B}{p_end}
{phang2}{cmd:. matrix colnames AB = A B}{p_end}
{phang2}{cmd:. deaahp x = y, dmu(dmu) comparison(AB) generate(hrank)}{p_end}

{phang2}{cmd:. deaahp x = y, dmu(dmu) method(pairwise) generate(prank)}{p_end}
{phang2}{cmd:. matrix list r(comparison)}{p_end}
{phang2}{cmd:. matrix list r(pair_priority)}{p_end}
{phang2}{cmd:. restore}{p_end}

{marker references}{...}
{title:References}

{pstd}{cmd:method(pairwise)} implements the DEA/AHP ranking construction of
Sinuany-Stern, Mehrez, and Hadad (2000), DOI:
10.1111/j.1475-3995.2000.tb00189.x. The article also appears under the legacy
DOI 10.1016/S0969-6016(00)00013-7. Saaty's eigenvector synthesis and
consistency diagnostics provide the AHP building block.{p_end}

{pstd}The implemented {cmd:model(te)} is the package's numerical-equivalence
workflow; it should be cited as such. Wang, Nguyen, and Wang (2023), DOI
10.1109/TEM.2021.3110519, is an applied precedent for DEA screening followed
by expert AHP, not an identity claim. The examples above illustrate both implemented workflows; externally constructed
comparison matrices require the declared comparison() interface.{p_end}

{pstd}For the DEA implementation, cite both the original software and the
version-2 update used by this command.{p_end}

{phang}Ji, Y.-B., and C. Lee. 2010. Data envelopment analysis.
{it:Stata Journal} 10(2): 267-280.
{browse "https://doi.org/10.1177/1536867X1001000207":doi:10.1177/1536867X1001000207}{p_end}

{phang}Lee, C. Forthcoming. {it:dea: An Update and Extension to Data Envelopment Analysis}.
Accepted for publication in the
{browse "https://www.stata-journal.com/":Stata Journal}.{p_end}

{pstd}The latter article describes DEA version 2.0. The
{browse "https://github.com/renegade68/DEA-Stata":DEA-Stata repository}
maintains the software and subsequent updates.{p_end}

{marker authors}{...}
{title:Authors}

{pstd}Lee, Choonjoo{break}
Korea National Defense University{break}
sarang90@korea.kr{p_end}
