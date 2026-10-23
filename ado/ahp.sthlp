{smcl}
{* *! help revision 24oct2026}{...}
{viewerjumpto "Syntax" "ahp##syntax"}{...}
{viewerjumpto "Description" "ahp##description"}{...}
{viewerjumpto "Options" "ahp##options"}{...}
{viewerjumpto "Stored results" "ahp##stored_results"}{...}
{viewerjumpto "Examples" "ahp##examples"}{...}
{viewerjumpto "Remarks" "ahp##remarks"}{...}
{viewerjumpto "References" "ahp##references"}{...}
{viewerjumpto "Authors" "ahp##authors"}{...}
{title:Title}

{p2colset 5 17 19 2}{...}
{p2col :{cmd:ahp} {hline 2}}Analytic hierarchy process for one or more evaluators{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}{cmd:ahp} {it:matrix_list} [{cmd:,} {opt method(eigen|geomean)} {opt aggregate(aij|aip)} {opt pool(arithmetic|geometric)} {opt evaluatorweights(numlist)} {opt tolerance(#)}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt method(eigen|geomean)}}priority method; default {cmd:eigen}{p_end}
{synopt:{opt aggregate(aij|aip)}}group aggregation rule; default {cmd:aij}{p_end}
{synopt:{opt pool(arithmetic|geometric)}}AIP pooling rule; default {cmd:arithmetic}{p_end}
{synopt:{opt evaluatorweights(numlist)}}positive evaluator weights{p_end}
{synopt:{opt tolerance(#)}}reciprocity tolerance; default {cmd:1e-6}{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}{cmd:ahp} derives AHP priorities from positive reciprocal pairwise-comparison matrices. Its default path implements the classical procedure presented by Saaty (1987, 1990): the normalized principal right eigenvector, CI, CR, and the 0.10 consistency diagnostic. One matrix represents one evaluator. All matrices must have identical dimensions and meaningful row/column names.

{pstd}Judgments may use Saaty's fundamental scale 1, 3, 5, 7, 9, its intermediate values 2, 4, 6, 8, and reciprocals. Measured ratios and finer refinements are also admissible in the source framework, so the command validates positivity and reciprocity but does not force entries onto integer categories.

{pstd}{cmd:aggregate(aij)} aggregates individual judgments by the weighted geometric mean before deriving priorities. {cmd:aggregate(aip)} derives individual priorities first and pools them using {cmd:pool()}.

{marker options}{...}
{title:Options}

{phang}{opt method()} selects the principal right eigenvector method or row geometric mean/logarithmic least squares method.

{phang}{opt aggregate(aij|aip)} selects aggregation of individual judgments
or aggregation of individual priorities. The default is {cmd:aij}.

{phang}{opt pool(arithmetic|geometric)} selects the pooling rule under
{cmd:aggregate(aip)}. The default is arithmetic.

{phang}{opt evaluatorweights()} supplies positive evaluator weights; they are normalized internally. Equal weights are the default.

{phang}{opt tolerance()} sets the maximum allowed reciprocal error in A:*A'. The default is 1e-6.

{marker stored_results}{...}
{title:Stored results}

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{cmd:r(weights)}}priority vector{p_end}
{synopt:{cmd:r(details)}}evaluator and group consistency diagnostics{p_end}
{synopt:{cmd:r(group_matrix)}}AIJ group comparison matrix{p_end}
{synopt:{cmd:r(lambda_max)}}group principal eigenvalue{p_end}
{synopt:{cmd:r(ci)}}group consistency index{p_end}
{synopt:{cmd:r(cr)}}group consistency ratio{p_end}
{synopt:{cmd:r(consistent)}}indicator for {cmd:r(cr)<=.10}{p_end}
{synopt:{cmd:r(reciprocal_error)}}maximum reciprocal error{p_end}
{synopt:{cmd:r(N_evaluators)}}number of evaluators{p_end}
{synopt:{cmd:r(method)}}priority method{p_end}
{synopt:{cmd:r(aggregate)}}group aggregation rule{p_end}
{synopt:{cmd:r(pool)}}AIP pooling rule{p_end}
{synopt:{cmd:r(foundation)}}methodological foundation{p_end}
{synopt:{cmd:r(scale_convention)}}judgment-scale convention{p_end}
{synoptline}

{pstd}Group diagnostics are missing under AIP because AIP does not construct a
group judgment matrix.{p_end}

{marker examples}{...}
{title:Examples}

{pstd}Run the complete block, omitting the leading dots. It restores the data in memory.{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. matrix A = (1, 5/3, 5/2 \ 3/5, 1, 3/2 \ 2/5, 2/3, 1)}{p_end}
{phang2}{cmd:. matrix colnames A = capability readiness cost}{p_end}
{phang2}{cmd:. matrix rownames A = capability readiness cost}{p_end}
{phang2}{cmd:. ahp A, method(eigen)}{p_end}
{phang2}{cmd:. restore}{p_end}



{marker remarks}{...}
{title:Remarks}

{pstd}The command computes a single hierarchy node. Matrix-oriented workflows may combine returned priorities with {help ahpsynth}. For ordinary long-format data and automatic multi-level synthesis, see {help ahphierarchy}. This modular separation leaves rating-mode, incomplete-matrix, and uncertainty extensions explicit rather than changing the classical node calculation.{p_end}

{marker references}{...}
{title:References}

{phang}Saaty, T. L. 1980. {it:The Analytic Hierarchy Process}. New York:
McGraw-Hill.{p_end}

{phang}Saaty, R. W. 1987. The analytic hierarchy process---what it is and how
it is used. {it:Mathematical Modelling} 9(3--5): 161--176.
{browse "https://doi.org/10.1016/0270-0255(87)90473-8":doi:10.1016/0270-0255(87)90473-8}.{p_end}

{phang}Saaty, T. L. 1990. How to make a decision: The analytic hierarchy
process. {it:European Journal of Operational Research} 48(1): 9--26.
{browse "https://doi.org/10.1016/0377-2217(90)90057-I":doi:10.1016/0377-2217(90)90057-I}.{p_end}

{phang}Aczel, J., and T. L. Saaty. 1983. Procedures for synthesizing ratio
judgements. {it:Journal of Mathematical Psychology} 27(1): 93--102.
{browse "https://doi.org/10.1016/0022-2496(83)90028-7":doi:10.1016/0022-2496(83)90028-7}.{p_end}

{phang}Crawford, G., and C. Williams. 1985. A note on the analysis of
subjective judgment matrices. {it:Journal of Mathematical Psychology} 29(4):
387--405.
{browse "https://doi.org/10.1016/0022-2496(85)90002-1":doi:10.1016/0022-2496(85)90002-1}.{p_end}

{marker authors}{...}
{title:Authors}

{pstd}Lee, Choonjoo{break}
Korea National Defense University{break}
sarang90@korea.kr{p_end}
