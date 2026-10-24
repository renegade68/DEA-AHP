{smcl}
{* *! help revision 24oct2026}{...}
{viewerjumpto "Syntax" "ahphierarchy##syntax"}{...}
{viewerjumpto "Description" "ahphierarchy##description"}{...}
{viewerjumpto "Options" "ahphierarchy##options"}{...}
{viewerjumpto "Data contract" "ahphierarchy##data"}{...}
{viewerjumpto "Stored results" "ahphierarchy##stored_results"}{...}
{viewerjumpto "Examples" "ahphierarchy##examples"}{...}
{title:Title}

{p2colset 5 22 24 2}{...}
{p2col :{cmd:ahphierarchy} {hline 2}}Recursive AHP synthesis from long-format pairwise judgments{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}{cmd:ahphierarchy} {it:judgment_var} {ifin}{cmd:,}
{opt parent(string_varname)} {opt left(string_varname)} {opt right(string_varname)}
[{opt evaluator(string_varname)} {opt evaluatorweight(varname)}
{opt method(eigen|geomean|llsm)} {opt aggregate(aij|aip)}
{opt pool(arithmetic|geometric)} {opt judgment(crisp|interval|fuzzy)}
{opt lower(varname)} {opt upper(varname)}
{opt synthesis(distributive|ideal)} {opt structure(frame_name)} {opt tolerance(#)}]

{marker description}{...}
{title:Description}

{pstd}{cmd:ahphierarchy} infers an AHP hierarchy from long-format, upper- or
lower-triangle pairwise judgments.  A row identifies a parent comparison
group, two children, and their positive ratio.  Reciprocal entries and unit
diagonals are generated automatically.  Local priorities are estimated at
each parent and propagated recursively from the unique root to terminal
alternatives.

{pstd}There is no fixed number of hierarchy levels. Depth is inferred from
the supplied parent-child relationships. Memory, computation time, and
floating-point precision still constrain practical problem size.{p_end}

{pstd}{opt structure()} optionally supplies the hierarchy explicitly in a
Stata frame.  This mode supports unbalanced hierarchies and unary parent
nodes, which cannot be recovered from pairwise rows alone.  Omitting the
option retains automatic inference and its existing behavior.

{pstd}Internal nodes form a rooted tree.  Terminal alternatives may appear
below multiple criteria, as in a conventional AHP hierarchy.  All identifiers
must be valid Stata names.  Every evaluator must provide one complete,
nonduplicated triangle for every parent node.

{pstd}The explicit {cmd:judgment()} and {cmd:synthesis()} module selectors
reserve a stable interface for other documented extensions. This release
implements crisp, interval, or triangular-fuzzy judgments with distributive or
ideal synthesis.  Cyclic dependence and feedback belong to an ANP/network command,
not this hierarchy command.

{marker options}{...}
{title:Options}

{phang}{opt parent()}, {opt left()}, and {opt right()} identify the comparison
group and the ordered child pair.  If a row contains left=A, right=B, and
judgment=3, A is three times B under that parent.

{phang}{opt evaluator()} identifies evaluators.  Omit it for one evaluator.

{phang}{opt evaluatorweight()} supplies a positive weight that must be
constant within evaluator.  It requires {cmd:evaluator()}.

{phang}{opt method()} chooses the node estimator.  {cmd:eigen} is the default;
{cmd:geomean} and its alias {cmd:llsm} are also available.

{phang}{opt aggregate()} chooses aggregation of individual judgments (AIJ,
the default) or priorities (AIP).  {opt pool()} selects arithmetic or geometric
pooling under AIP.

{phang}{opt judgment(crisp)} selects point judgments and is the default.
{opt judgment(interval)} treats the positional judgment variable as the lower
bound and requires {opt upper(varname)}. Bounds must be positive and ordered.
Interval mode requires {cmd:method(geomean)} or {cmd:method(llsm)},
{cmd:aggregate(aij)}, and {cmd:synthesis(distributive)}. Its point result uses
geometric midpoints. AIJ combines evaluator bounds by weighted geometric means.

{phang}{opt judgment(fuzzy)} treats the positional judgment variable as the
triangular fuzzy mode and requires {opt lower(varname)} and
{opt upper(varname)}. Values must satisfy 0 < lower <= mode <= upper. It uses
Buckley fuzzy geometric means, componentwise AIJ, and centroid defuzzification.
Fuzzy mode currently requires {cmd:method(geomean)} or {cmd:method(llsm)},
{cmd:aggregate(aij)}, and {cmd:synthesis(distributive)}.

{phang}{opt synthesis(distributive)} is the default and preserves unit mass
at every parent. {opt synthesis(ideal)} divides local alternative priorities
by their maximum within each terminal parent, combines the resulting scores
with distributive criterion weights, and normalizes the final scores to sum
to one. Ideal mode rejects a parent that mixes internal and terminal children.

{phang}{opt structure(frame_name)} reads a separate frame containing string
variables {cmd:node} and {cmd:parent}.  The root has an empty parent. Optional
string {cmd:type} contains {cmd:goal}, {cmd:criterion}, or {cmd:alternative};
optional numeric {cmd:order} controls sibling order. The frame is not changed.

{marker data}{...}
{title:Data contract}

{pstd}A comparison group with n children requires n(n-1)/2 observations per
evaluator.  Supply either direction once; do not also supply its reciprocal.
The root is the only parent that never occurs as an internal child.  A node
with its own outgoing comparison group is internal; other children are
terminal alternatives.

{pstd}With {opt structure()}, each row declares one node-parent edge, except
the single root row. Internal nodes must have one parent; terminal
alternatives may occur under multiple parents. A parent with one child has
local weight 1 and must have no comparison row. A parent with n>1 children
still requires n(n-1)/2 observations per evaluator. Every compared pair must
be a declared sibling pair.

{marker stored_results}{...}
{title:Stored results}

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{cmd:r(weights)}}final alternative priorities{p_end}
{synopt:{cmd:r(scores)}}unnormalized synthesis scores; identical to {cmd:r(weights)} under distributive mode{p_end}
{synopt:{cmd:r(interval_weights)}}rows contain conservative lower and upper final priorities; interval mode only{p_end}
{synopt:{cmd:r(interval_edges)}}local and propagated lower/upper edge envelopes; interval mode only{p_end}
{synopt:{cmd:r(fuzzy_weights)}}synthesized lower, mode, and upper TFN priorities; fuzzy mode only{p_end}
{synopt:{cmd:r(fuzzy_edges)}}local and propagated TFN lower/upper edge values; modes are in {cmd:r(edges)}{p_end}
{synopt:{cmd:r(nodes)}}node level, global weight, and terminal indicator{p_end}
{synopt:{cmd:r(edges)}}parent-child local weights and path contributions{p_end}
{synopt:{cmd:r(diagnostics)}}parent-level consistency diagnostics{p_end}
{synopt:{cmd:r(structure)}}explicit structure level, type code, and order; only with {cmd:structure()}{p_end}
{synopt:{cmd:r(levels)}}inferred hierarchy depth{p_end}
{synopt:{cmd:r(root)}}inferred root identifier{p_end}
{synopt:{cmd:r(structure_source)}}{cmd:inferred} or {cmd:frame}{p_end}
{synopt:{cmd:r(interval_rule)}}{cmd:geometric_midpoint_llsm_envelope} in interval mode{p_end}
{synopt:{cmd:r(fuzzy_rule)}}{cmd:buckley_tfn_centroid} in fuzzy mode{p_end}
{synopt:{cmd:r(structure_frame)}}structure frame name, if supplied{p_end}
{synopt:{cmd:r(structure_nodes)}, {cmd:r(structure_parents)}}labels corresponding to rows of {cmd:r(structure)}; root parent is {cmd:.}{p_end}
{synopt:{cmd:r(alternatives)}}terminal alternative identifiers{p_end}
{synopt:{cmd:r(edge_parents)}, {cmd:r(edge_children)}}edge-label lists corresponding to rows of {cmd:r(edges)}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:ahphierarchy}{p_end}
{synopt:{cmd:r(cmdline)}}command as typed{p_end}
{synoptline}

{marker examples}{...}
{title:Examples}

{pstd}Run the complete block, omitting the leading dots. It restores the data in memory.{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. input str12 parent str12 left str12 right double judgment}{p_end}
{phang2}{cmd:. Goal Cost Quality 2}{p_end}
{phang2}{cmd:. Cost A B 4}{p_end}
{phang2}{cmd:. Quality A B .25}{p_end}
{phang2}{cmd:. end}{p_end}
{phang2}{cmd:. ahphierarchy judgment, parent(parent) left(left) right(right)}{p_end}
{phang2}{cmd:. restore}{p_end}

{title:References}

{phang}Saaty, R. W. 1987. The analytic hierarchy process---what it is and how
it is used. {it:Mathematical Modelling} 9: 161--176.
{browse "https://doi.org/10.1016/0270-0255(87)90473-8":doi:10.1016/0270-0255(87)90473-8}.{p_end}

{phang}Crawford, G., and C. Williams. 1985. A note on the analysis of subjective
judgment matrices. {it:Journal of Mathematical Psychology} 29: 387--405.
{browse "https://doi.org/10.1016/0022-2496(85)90002-1":doi:10.1016/0022-2496(85)90002-1}.{p_end}

{phang}Buckley, J. J. 1985. Fuzzy hierarchical analysis.
{it:Fuzzy Sets and Systems} 17: 233--247.
{browse "https://doi.org/10.1016/0165-0114(85)90090-9":doi:10.1016/0165-0114(85)90090-9}.{p_end}

{pstd}Recursive orchestration, the structure-frame contract, and the
geometric-midpoint interval envelope are the package's declared implementation
rules. Interval envelopes and judgment-perturbation ranges are not statistical
confidence intervals.{p_end}

{title:Author}
{pstd}Choonjoo Lee, Korea National Defense University.
sarang90@korea.kr{p_end}
