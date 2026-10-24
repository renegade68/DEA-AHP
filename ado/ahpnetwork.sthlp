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
{opt solver(direct|iterate)} {opt maxiter(#)} {opt tolerance(#)}]

{marker description}{...}
{title:Description}

{pstd}{cmd:ahpnetwork} implements the supermatrix stage of the analytic
network process (ANP). Each observation is a directed influence from a source
node (a supermatrix column) to a target node (a supermatrix row). The supplied
local priorities are combined with cluster weights to form a column-stochastic
weighted supermatrix. The default direct solver identifies closed communicating
classes, computes their stationary priorities, and accounts for absorption from
transient nodes. It returns the ordinary power limit or, when explicitly
requested, the Cesaro limit.{p_end}

{pstd}This command consumes already-derived local priorities. It does not
silently reinterpret a hierarchy as a network or derive every local vector
from pairwise judgments. Those vectors may be produced by {help ahp},
{help ahphierarchy}, or another documented elicitation method.{p_end}

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

{phang}{opt limit(power|cesaro)} selects the mathematical limit. {cmd:power},
the default, requires every closed communicating class to be aperiodic.
{cmd:cesaro} requests the limit of averaged powers and also permits periodic
closed classes. A closed class is a mutually reachable group with no outgoing
edges to other groups. The command never switches limit rules implicitly.{p_end}

{phang}{opt solver(direct|iterate)} selects the computation. {cmd:direct},
the default since version 0.2.0, uses nonnegative state reduction for stationary
and absorption probabilities. It does not wait for slowly changing powers to
approach their limit. {cmd:iterate} multiplies successive powers or updates
their Cesaro mean; it stops only when both the change between iterations and
the distance to the independently computed direct limit are at most
{cmd:tolerance()}. It also computes the direct reference, so it is a diagnostic
alternative rather than a cheaper solver.{p_end}

{phang}{opt maxiter(#)} limits iterations for {cmd:solver(iterate)}. The
default is {cmd:10000}; the value must be positive. It does not limit the
direct solver, which reports zero iterations.{p_end}

{phang}{opt tolerance(#)} sets the positive tolerance used for local- and
cluster-weight sum checks and weight-constancy checks. For {cmd:solver(iterate)},
it also bounds the largest elementwise change and distance to the computed
direct reference. The default is {cmd:1e-8}. It does not remove small positive
edges or determine communicating classes. Numerical checks of the direct
solution are separate floating-point consistency checks.{p_end}

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
active target clusters receive equal weights. Accepted rounding discrepancies
in column sums are normalized before limit analysis; the largest adjustment
is returned in {cmd:r(normalization_adjustment)}. The returned
{cmd:r(supermatrix)} is column stochastic to floating-point precision.{p_end}

{pstd}A periodic closed class causes an error under {cmd:limit(power)}, even
if some aggregate priorities happen to be constant across iterations. Use
{cmd:limit(cesaro)} for its averaged limit. Under {cmd:solver(iterate)}, failure
to meet both stopping checks by {cmd:maxiter()} is an error; no unconverged
result is returned.{p_end}

{marker stored_results}{...}
{title:Stored results}

{synoptset 29 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{cmd:r(supermatrix)}}column-stochastic weighted supermatrix{p_end}
{synopt:{cmd:r(limit_matrix)}}direct power/Cesaro limit, or validated iterative approximation{p_end}
{synopt:{cmd:r(priorities)}}row averages of the limit matrix, normalized to sum to one{p_end}
{synopt:{cmd:r(membership)}}numeric cluster identifier for each node{p_end}
{synopt:{cmd:r(classes)}}node rows: communicating component, closed-class ID (0 if transient), period (0 if transient){p_end}
{synopt:{cmd:r(N_nodes)}, {cmd:r(N_clusters)}}network dimensions{p_end}
{synopt:{cmd:r(N_closed)}, {cmd:r(N_transient)}}number of closed classes and transient nodes{p_end}
{synopt:{cmd:r(max_period)}}largest period among closed classes{p_end}
{synopt:{cmd:r(iterations)}}iteration count; 0 for direct solver{p_end}
{synopt:{cmd:r(convergence_error)}}last iterate change; missing for direct solver{p_end}
{synopt:{cmd:r(reference_error)}}largest elementwise distance to computed direct limit; 0 for direct solver{p_end}
{synopt:{cmd:r(stationary_residual)}}maximum of abs(W*L-L) and abs(L*W-L) for returned W and L{p_end}
{synopt:{cmd:r(projection_error)}}maximum of abs(L*L-L) for returned L{p_end}
{synopt:{cmd:r(normalization_adjustment)}}largest absolute entry adjustment in column normalization{p_end}
{synopt:{cmd:r(limit_spread)}}maximum difference between limit columns and final priorities{p_end}
{synopt:{cmd:r(nodes)}, {cmd:r(clusters)}}node and cluster identifiers{p_end}
{synopt:{cmd:r(cluster_weight_source)}}{cmd:variable} or {cmd:equal_active_clusters}{p_end}
{synopt:{cmd:r(limit)}}{cmd:power} or {cmd:cesaro}{p_end}
{synopt:{cmd:r(solver)}}{cmd:direct} or {cmd:iterate}{p_end}
{synopt:{cmd:r(initial_mixture)}}{cmd:uniform}; each initial node receives equal mass{p_end}
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

{pstd}In reducible networks, the returned priorities use a uniform initial
mixture across all nodes. Transient mass is allocated to closed classes using
absorption probabilities; the columns of {cmd:r(limit_matrix)} retain dependence
on the initial node. A unique initial-condition-independent ranking is not
promised. Communicating components and analyst-specified clusters are distinct.
{p_end}

{pstd}The direct solver uses the Grassmann-Taksar-Heyman nonnegative reduction
for each closed class and nonnegative state elimination for transient absorption.
This avoids the cancellation in subtracting a near-one self-loop from one.
These routines are independently implemented in Mata. Stationarity,
idempotence, and probability-sum checks diagnose the computed result; they are
not rigorous bounds on error relative to an exact-arithmetic limit.
Extreme numerical ranges can still fail validation. Dense matrices also limit
practical network size through memory and computation time.{p_end}

{phang}Saaty, T. L. 1996. {it:Decision Making with Dependence and Feedback:
The Analytic Network Process}. Pittsburgh, PA: RWS Publications.{p_end}

{phang}Grassmann, W. K., M. I. Taksar, and D. P. Heyman. 1985.
Regenerative analysis and steady state distributions for Markov chains.
{it:Operations Research} 33(5): 1107-1116.
{browse "https://doi.org/10.1287/opre.33.5.1107":doi:10.1287/opre.33.5.1107}.{p_end}

{title:Author}
{pstd}Choonjoo Lee, Korea National Defense University.
sarang90@korea.kr{p_end}
