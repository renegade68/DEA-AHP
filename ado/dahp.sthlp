{smcl}
{* *! help revision 24oct2026}{...}
{viewerjumpto "Syntax" "dahp##syntax"}{...}
{viewerjumpto "Description" "dahp##description"}{...}
{viewerjumpto "Options" "dahp##options"}{...}
{viewerjumpto "Stored results" "dahp##stored_results"}{...}
{viewerjumpto "Examples" "dahp##examples"}{...}
{viewerjumpto "Remarks" "dahp##remarks"}{...}
{viewerjumpto "References" "dahp##references"}{...}
{viewerjumpto "Authors" "dahp##authors"}{...}
{title:Title}

{p2colset 5 17 19 2}{...}
{p2col :{cmd:dahp} {hline 2}}Context- or time-dependent analytic hierarchy process{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}{cmd:dahp} {it:matrix_list}{cmd:,} {opt contexts(#)} [{opt evaluators(#)} {opt contextweights(numlist)} {opt evaluatorweights(numlist)} {opt method(eigen|geomean)} {opt aggregate(aij|aip)} {opt pool(arithmetic|geometric)} {opt timepool(arithmetic|geometric)} {opt tolerance(#)}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt contexts(#)}}number of contexts; required{p_end}
{synopt:{opt evaluators(#)}}evaluators per context; default {cmd:1}{p_end}
{synopt:{opt contextweights(numlist)}}positive context weights{p_end}
{synopt:{opt evaluatorweights(numlist)}}positive evaluator weights{p_end}
{synopt:{opt method(eigen|geomean)}}within-context priority method{p_end}
{synopt:{opt aggregate(aij|aip)}}within-context group aggregation{p_end}
{synopt:{opt pool(arithmetic|geometric)}}AIP pooling rule{p_end}
{synopt:{opt timepool(arithmetic|geometric)}}context pooling rule{p_end}
{synopt:{opt tolerance(#)}}reciprocity tolerance; default {cmd:1e-6}{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}{cmd:dahp} computes AHP priorities for multiple time periods or states and pools the context-specific priorities. Matrices are supplied in context-major order: all evaluator matrices for context 1, followed by all evaluator matrices for context 2, and so on.

{pstd}{cmd:contexts()} times {cmd:evaluators()} must equal the number of matrices. Context weights can represent durations, discount weights, or scenario probabilities; interpretation remains the analyst's responsibility.

{marker options}{...}
{title:Options}

{phang}{opt contexts(#)} specifies the number of contexts and is required.

{phang}{opt evaluators(#)} specifies evaluators per context; default 1.

{phang}{opt contextweights(numlist)} supplies positive context weights. Equal
weights are the default.

{phang}{opt evaluatorweights(numlist)} supplies positive evaluator weights,
which are normalized internally.

{phang}{opt method(eigen|geomean)}, {opt aggregate(aij|aip)}, and
{opt pool(arithmetic|geometric)} have the meanings documented in {help ahp}.

{phang}{opt timepool(arithmetic|geometric)} pools context priorities; the
default is arithmetic.

{phang}{opt tolerance(#)} sets the reciprocal-matrix tolerance.

{marker stored_results}{...}
{title:Stored results}

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{cmd:r(weights)}}integrated priorities{p_end}
{synopt:{cmd:r(context_weights)}}context-specific priorities{p_end}
{synopt:{cmd:r(details)}}AIJ consistency diagnostics{p_end}
{synopt:{cmd:r(N_contexts)}}number of contexts{p_end}
{synopt:{cmd:r(N_evaluators)}}evaluators per context{p_end}
{synopt:{cmd:r(method)}}priority method{p_end}
{synopt:{cmd:r(aggregate)}}group aggregation rule{p_end}
{synopt:{cmd:r(pool)}}AIP pooling rule{p_end}
{synopt:{cmd:r(timepool)}}context pooling rule{p_end}
{synoptline}

{pstd}Under AIP, context diagnostic rows are missing because pooled priorities do not imply a unique group pairwise-comparison matrix.{p_end}

{marker examples}{...}
{title:Examples}

{pstd}The following block is self-contained:{p_end}
{pstd}Run the complete block, omitting the leading dots. It restores the data in memory.{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. matrix A1=(1,3,5\1/3,1,2\1/5,1/2,1)}{p_end}
{phang2}{cmd:. matrix A2=(1,1/2,2\2,1,4\1/2,1/4,1)}{p_end}
{phang2}{cmd:. matrix rownames A1=capability readiness cost}{p_end}
{phang2}{cmd:. matrix colnames A1=capability readiness cost}{p_end}
{phang2}{cmd:. matrix rownames A2=capability readiness cost}{p_end}
{phang2}{cmd:. matrix colnames A2=capability readiness cost}{p_end}
{phang2}{cmd:. dahp A1 A2, contexts(2) contextweights(.4 .6)}{p_end}
{phang2}{cmd:. matrix list r(context_weights)}{p_end}
{phang2}{cmd:. restore}{p_end}



{marker remarks}{...}
{title:Remarks}

{pstd}The first release treats time and state as generic weighted contexts. Transition matrices, path dependence, absolute rating mode, and temporal responsiveness diagnostics are planned extensions built on the same Mata core.{p_end}

{dlgtab:Extension interface}

{pstd}To add an endogenous transition or path-dependent model, compute or
estimate the context weights outside {cmd:dahp}, pass the resulting positive
weights through {cmd:contextweights()}, and retain the context-specific
matrix returned in {cmd:r(context_weights)}. If criteria change, supply each
context's named parent/local pair to {help dahpsynth}. This preserves the
classical AHP calculation inside each context and makes the added dynamic law
an auditable external module rather than a silent change to AHP.{p_end}

{marker references}{...}
{title:References}

{phang}Saaty, T. L. 1980. {it:The Analytic Hierarchy Process}. New York:
McGraw-Hill.{p_end}

{phang}Saaty, R. W. 1987. The analytic hierarchy process---what it is and how
it is used. {it:Mathematical Modelling} 9(3--5): 161--176.
{browse "https://doi.org/10.1016/0270-0255(87)90473-8":doi:10.1016/0270-0255(87)90473-8}{p_end}

{marker authors}{...}
{title:Authors}

{pstd}Lee, Choonjoo{break}
Korea National Defense University{break}
sarang90@korea.kr{p_end}
