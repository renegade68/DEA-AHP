{smcl}
{* *! help revision 24oct2026}{...}
{viewerjumpto "Syntax" "ahpnetwork##syntax"}{...}
{viewerjumpto "Description" "ahpnetwork##description"}{...}
{viewerjumpto "Options" "ahpnetwork##options"}{...}
{viewerjumpto "Data contract" "ahpnetwork##data"}{...}
{viewerjumpto "Stored results" "ahpnetwork##stored_results"}{...}
{viewerjumpto "Example" "ahpnetwork##example"}{...}
{title:Title}

{p2colset 5 22 24 2}{...}
{p2col :{cmd:ahpnetwork} {hline 2}}ANP weighted and limit supermatrices from long-format network priorities{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}{cmd:ahpnetwork} {it:local_weight_var} {ifin}{cmd:,}
{opt source(string_varname)} {opt target(string_varname)}
[{opt sourcecluster(string_varname)} {opt targetcluster(string_varname)}
{opt clusterweight(varname)} {opt limit(power|cesaro)}
{opt maxiter(#)} {opt tolerance(#)}]

{marker description}{...}
{title:Description}

{pstd}{cmd:ahpnetwork} implements the supermatrix stage of the analytic
network process (ANP). Each observation is a directed influence from a source
node (a supermatrix column) to a target node (a supermatrix row). The supplied
local priorities are combined with cluster weights to form a column-stochastic
weighted supermatrix. Repeated multiplication, or an explicitly requested
Cesaro mean, produces a limit matrix and node priorities.

{pstd}This command consumes already-derived local priorities. It does not
silently reinterpret a hierarchy as a network or derive every local vector
from pairwise judgments. Those vectors may be produced by {help ahp},
{help ahphierarchy}, or another documented elicitation method.

{marker options}{...}
{title:Options}

{phang}{opt source(string_varname)} identifies the source node, represented
by a column of the supermatrix. {opt target(string_varname)} identifies the
target node influenced by that source, represented by a row.

{phang}{opt sourcecluster(string_varname)} and
{opt targetcluster(string_varname)} identify the clusters containing the
source and target nodes. They must be specified together. If omitted, all
nodes belong to one cluster named {cmd:network}.

{phang}{opt clusterweight(varname)} supplies the target-cluster weight for
each source. It requires {opt sourcecluster()} and {opt targetcluster()}.
Without this option, the active target clusters for each source receive equal
weight.

{phang}{opt limit(power|cesaro)} selects the limiting rule. {cmd:power}, the
default, iterates ordinary supermatrix powers. {cmd:cesaro} iterates their
running average and is useful for periodic networks. The command never
switches rules implicitly.

{phang}{opt maxiter(#)} sets the maximum number of limit iterations. The
default is {cmd:10000}; the value must be positive.

{phang}{opt tolerance(#)} sets the positive tolerance used for local- and
cluster-weight sum checks, weight-constancy checks, column stochasticity, and
limit convergence. The default is {cmd:1e-8}.

{marker data}{...}
{title:Data contract}

{pstd}{opt source()} identifies the influencing source represented by a
supermatrix column; {opt target()} identifies the influenced row node. For
each source and active target cluster, local weights must be positive,
nonduplicated, and sum to one. Every node must have an outgoing source column.
Node and cluster identifiers must be nonempty valid Stata names. Zero-weight
edges are omitted from the long data rather than recorded with weight zero.

{pstd}{opt sourcecluster()} and {opt targetcluster()} must be supplied
together. A node must belong to exactly one cluster. If {opt clusterweight()}
is supplied, it must be positive, constant within each source-target-cluster
block, and sum to one across a source's active target clusters. If omitted,
active target clusters receive equal weights. The returned
{cmd:r(supermatrix)} is always column stochastic.

{pstd}{opt limit(power)} is the default and requires ordinary matrix powers
to converge. {opt limit(cesaro)} averages successive powers and is intended
for periodic networks. Nonconvergence by {opt maxiter()} is an error rather
than an implicit change of limit rule.

{marker stored_results}{...}
{title:Stored results}

{synoptset 29 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{cmd:r(supermatrix)}}column-stochastic weighted supermatrix{p_end}
{synopt:{cmd:r(limit_matrix)}}converged power or Cesaro limit matrix{p_end}
{synopt:{cmd:r(priorities)}}row averages of the limit matrix, normalized to sum to one{p_end}
{synopt:{cmd:r(membership)}}numeric cluster identifier for each node{p_end}
{synopt:{cmd:r(N_nodes)}, {cmd:r(N_clusters)}}network dimensions{p_end}
{synopt:{cmd:r(iterations)}}limit iterations{p_end}
{synopt:{cmd:r(convergence_error)}}change between the last two powers or averages{p_end}
{synopt:{cmd:r(limit_spread)}}maximum difference between limit columns and final priorities{p_end}
{synopt:{cmd:r(nodes)}, {cmd:r(clusters)}}node and cluster identifiers{p_end}
{synopt:{cmd:r(cluster_weight_source)}}{cmd:variable} or {cmd:equal_active_clusters}{p_end}
{synopt:{cmd:r(limit)}}{cmd:power} or {cmd:cesaro}{p_end}
{synopt:{cmd:r(model)}}implemented ANP supermatrix model{p_end}
{synopt:{cmd:r(cmd)}}{cmd:ahpnetwork}{p_end}
{synopt:{cmd:r(cmdline)}}command as typed{p_end}
{synoptline}

{marker example}{...}
{title:Example}

{pstd}Run the complete block, omitting the leading dots. It restores the data in memory.{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. input str8 source str8 target double local}{p_end}
{phang2}{cmd:. A A .5}{p_end}
{phang2}{cmd:. A B .5}{p_end}
{phang2}{cmd:. B A .25}{p_end}
{phang2}{cmd:. B B .75}{p_end}
{phang2}{cmd:. end}{p_end}
{phang2}{cmd:. ahpnetwork local, source(source) target(target)}{p_end}
{phang2}{cmd:. restore}{p_end}

{title:Interpretation and references}

{pstd}The stopping rule compares consecutive powers or consecutive Cesaro
averages. tolerance() is not a guaranteed bound on distance to the exact
limit. For slowly converging networks, inspect sensitivity to tolerance()
and maxiter(). In reducible networks the returned priorities use a uniform
initial mixture across columns; a unique initial-condition-independent
ranking is not promised.{p_end}

{phang}Saaty, T. L. 1996. {it:Decision Making with Dependence and Feedback:
The Analytic Network Process}. Pittsburgh, PA: RWS Publications.{p_end}

{title:Author}
{pstd}Choonjoo Lee, Korea National Defense University.
sarang90@korea.kr{p_end}
