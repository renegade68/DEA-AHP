{smcl}
{* *! help revision 24oct2026}{...}
{viewerjumpto "Syntax" "ahpdeasim##syntax"}{...}
{viewerjumpto "Description" "ahpdeasim##description"}{...}
{viewerjumpto "Options" "ahpdeasim##options"}{...}
{viewerjumpto "Stored results" "ahpdeasim##stored_results"}{...}
{viewerjumpto "Examples" "ahpdeasim##examples"}{...}
{viewerjumpto "References" "ahpdeasim##references"}{...}
{viewerjumpto "Authors" "ahpdeasim##authors"}{...}
{title:Title}

{p2colset 5 17 19 2}{...}
{p2col :{cmd:ahpdeasim} {hline 2}}Monte Carlo judgment sensitivity for AHP-first DEA{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 12}{cmd:ahpdeasim} {it:inputvars} {cmd:=} {it:outputvars} {ifin},
{cmd:dmu(}{it:varname}{cmd:)}
[{cmd:inputmatrix(}{it:name}{cmd:)} {cmd:outputmatrix(}{it:name}{cmd:)}
{cmd:reps(}{it:#}{cmd:)} {cmd:sigma(}{it:#}{cmd:)} {cmd:seed(}{it:#}{cmd:)}
{cmd:band(}{it:#}{cmd:)} {cmd:lowerband(}{it:#}{cmd:)}
{cmd:upperband(}{it:#}{cmd:)}
{cmd:inputscale(}{it:name}{cmd:)} {cmd:outputscale(}{it:name}{cmd:)}
{cmd:ahpmethod(eigen|geomean)} {cmd:rts(crs|vrs)}
{cmd:orientation(input|output)}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt dmu(varname)}}unique DMU identifier; required{p_end}
{synopt:{opt inputmatrix(name)}}input comparison matrix{p_end}
{synopt:{opt outputmatrix(name)}}output comparison matrix{p_end}
{synopt:{opt reps(#)}}replications; default {cmd:200}{p_end}
{synopt:{opt sigma(#)}}log-judgment perturbation SD; default {cmd:.10}{p_end}
{synopt:{opt seed(#)}}random-number seed; default {cmd:12345}{p_end}
{synopt:{opt band(#)}}symmetric allowance; default {cmd:0}{p_end}
{synopt:{opt lowerband(#)}}lower asymmetric allowance{p_end}
{synopt:{opt upperband(#)}}upper asymmetric allowance{p_end}
{synopt:{opt inputscale(name)}}input reference scales{p_end}
{synopt:{opt outputscale(name)}}output reference scales{p_end}
{synopt:{opt ahpmethod(eigen|geomean)}}AHP priority method{p_end}
{synopt:{opt rts(crs|vrs)}}returns to scale; default {cmd:crs}{p_end}
{synopt:{opt orientation(input|output)}}radial orientation; default {cmd:input}{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}{cmd:ahpdeasim} evaluates the sensitivity of {help ahpdea}'s
{cmd:bounds(band)} model to uncertainty in classical reciprocal AHP judgments.
For each upper-triangular comparison a_ij and replication b, it draws{p_end}

{p 8 12}a_ij^(b) = a_ij exp(sigma z_ij^(b)),  z_ij^(b) standard normal,{p_end}

{pstd}sets a_ji^(b)=1/a_ij^(b), retains unit diagonals, and reruns
{cmd:ahpdea}. Thus positivity and reciprocity are preserved. The original
judgment is the median of each perturbed comparison. Draws are independent
across criterion pairs and input/output matrices.{p_end}

{pstd}This is a sensitivity model, not a sampling distribution inferred from
experts or data. Analysts should justify {cmd:sigma()} substantively and
compare several values. {cmd:sigma(0)} exactly nests the reference model.{p_end}

{marker options}{...}
{title:Options}

{phang}{cmd:dmu(varname)} specifies a unique, nonmissing DMU identifier in the
estimation sample.{p_end}
{phang}{cmd:inputmatrix()} and {cmd:outputmatrix()} provide the named
classical AHP comparison matrices. They are required on sides with multiple
variables and omitted on single-variable sides.{p_end}
{phang}{cmd:reps(#)} sets the number of replications; the default is 200 and
the minimum is 2.{p_end}
{phang}{cmd:sigma(#)} sets the nonnegative standard deviation of additive
normal noise on the log-comparison scale; the default is 0.10.{p_end}
{phang}{cmd:seed(#)} sets the nonnegative random-number seed; the default is
12345.{p_end}
{phang}{cmd:band(#)} sets a nonnegative symmetric proportional allowance
around the perturbed AHP priority ratios; the default is zero.{p_end}
{phang}{cmd:lowerband(#)} and {cmd:upperband(#)} set asymmetric allowances.
Both must be supplied, the lower allowance must be in [0,1], and neither may
be combined with a nonzero {cmd:band()}.{p_end}
{phang}{cmd:inputscale()} and {cmd:outputscale()} supply positive named
reference-scale column vectors passed unchanged to {help ahpdea}; omitted
sides use positive estimation-sample means.{p_end}
{phang}{cmd:ahpmethod(eigen|geomean)} selects the AHP priority method applied
to the reference and every perturbed comparison matrix; default
{cmd:eigen}.{p_end}
{phang}{cmd:rts(crs|vrs)} selects constant or variable returns to scale;
default {cmd:crs}.{p_end}
{phang}{cmd:orientation(input|output)} selects the radial DEA orientation;
default {cmd:input}.{p_end}

{pstd}Pair-specific and group min/max bounds are outside this first simulation
interface.{p_end}

{marker stored_results}{...}
{title:Stored results}

{pstd}{cmd:ahpdeasim} stores in {cmd:r()}:{p_end}
{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{cmd:r(summary)}}DMU rows by mean, sample SD, nearest-rank p05/p50/p95, mean rank, and top-set inclusion probability{p_end}
{synopt:{cmd:r(efficiency_draws)}}DMU-by-replication restricted-efficiency matrix{p_end}
{synopt:{cmd:r(reference_efficiency)}}unperturbed restricted efficiency{p_end}
{synopt:{cmd:r(unrestricted_efficiency)}}unrestricted DEA efficiency{p_end}
{synopt:{cmd:r(input_priority)}}unperturbed input priorities{p_end}
{synopt:{cmd:r(output_priority)}}unperturbed output priorities{p_end}
{synopt:{cmd:r(input_cr)}, {cmd:r(output_cr)}}reference AHP consistency ratios{p_end}
{synopt:{cmd:r(reps)}}number of replications{p_end}
{synopt:{cmd:r(sigma)}}log-judgment perturbation SD{p_end}
{synopt:{cmd:r(seed)}}random-number seed{p_end}
{synopt:{cmd:r(perturbation)}}{cmd:reciprocal_lognormal}{p_end}
{synopt:{cmd:r(rts)}}returns to scale{p_end}
{synopt:{cmd:r(orientation)}}radial orientation{p_end}
{synoptline}

{pstd}Ranks use descending efficiency with average ranks for numerical ties.
{cmd:pr_best} is the probability that a DMU belongs to the best-efficiency
tie set, so probabilities need not sum to one.{p_end}

{marker examples}{...}
{title:Examples}

{pstd}The following block is self-contained:{p_end}
{pstd}Run the complete block, omitting the leading dots. It restores the data in memory.{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. input str1 id double(x1 x2 y1 y2)}{p_end}
{phang2}{cmd:. "A" 1 4 5 1}{p_end}
{phang2}{cmd:. "B" 2 2 4 3}{p_end}
{phang2}{cmd:. "C" 4 1 1 5}{p_end}
{phang2}{cmd:. "D" 3 4 3 2}{p_end}
{phang2}{cmd:. end}{p_end}
{phang2}{cmd:. matrix AX=(1,2\1/2,1)}{p_end}
{phang2}{cmd:. matrix rownames AX=x1 x2}{p_end}
{phang2}{cmd:. matrix colnames AX=x1 x2}{p_end}
{phang2}{cmd:. matrix AY=(1,1/2\2,1)}{p_end}
{phang2}{cmd:. matrix rownames AY=y1 y2}{p_end}
{phang2}{cmd:. matrix colnames AY=y1 y2}{p_end}
{phang2}{cmd:. ahpdeasim x1 x2 = y1 y2, dmu(id) inputmatrix(AX) outputmatrix(AY) reps(20) sigma(.10) seed(20260803) band(.20)}{p_end}
{phang2}{cmd:. matrix list r(summary)}{p_end}
{phang2}{cmd:. restore}{p_end}



{marker references}{...}
{title:References}

{phang}Saaty, R. W. 1987. The analytic hierarchy process---what it is and how
it is used. {it:Mathematical Modelling} 9(3--5): 161--176.
{browse "https://doi.org/10.1016/0270-0255(87)90473-8":doi:10.1016/0270-0255(87)90473-8}{p_end}

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
