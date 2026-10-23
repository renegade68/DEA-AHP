{smcl}
{* *! help revision 24oct2026}{...}
{viewerjumpto "Syntax" "ahpdea##syntax"}{...}
{viewerjumpto "Description" "ahpdea##description"}{...}
{viewerjumpto "Options" "ahpdea##options"}{...}
{viewerjumpto "Stored results" "ahpdea##stored_results"}{...}
{viewerjumpto "Examples" "ahpdea##examples"}{...}
{viewerjumpto "References" "ahpdea##references"}{...}
{viewerjumpto "Authors" "ahpdea##authors"}{...}
{title:Title}

{p2colset 5 17 19 2}{...}
{p2col :{cmd:ahpdea} {hline 2}}AHP-derived assurance-region DEA{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 12}{cmd:ahpdea} {it:inputvars} {cmd:=} {it:outputvars} {ifin},
{cmd:dmu(}{it:varname}{cmd:)}
[{cmd:inputmatrix(}{it:name}{cmd:)} {cmd:outputmatrix(}{it:name}{cmd:)}
{cmd:inputweights(}{it:name}{cmd:)} {cmd:outputweights(}{it:name}{cmd:)}
{cmd:inputscale(}{it:name}{cmd:)} {cmd:outputscale(}{it:name}{cmd:)}
{cmd:inputlower(}{it:name}{cmd:)} {cmd:inputupper(}{it:name}{cmd:)}
{cmd:outputlower(}{it:name}{cmd:)} {cmd:outputupper(}{it:name}{cmd:)}
{cmd:inputgroup(}{it:namelist}{cmd:)} {cmd:outputgroup(}{it:namelist}{cmd:)}
{cmd:model(ar)} {cmd:bounds(band|groupminmax|pairwise)} {cmd:band(}{it:#}{cmd:)}
{cmd:lowerband(}{it:#}{cmd:)} {cmd:upperband(}{it:#}{cmd:)} {cmd:ahpmethod(eigen|geomean)}
{cmd:rts(crs|vrs)} {cmd:orientation(input|output)}
{cmd:generate(}{it:newvar}{cmd:)} {cmd:baseline(}{it:newvar}{cmd:)}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt dmu(varname)}}unique DMU identifier; required{p_end}
{synopt:{opt inputmatrix(name)}}input AHP comparison matrix{p_end}
{synopt:{opt outputmatrix(name)}}output AHP comparison matrix{p_end}
{synopt:{opt inputweights(name)}}input priority vector{p_end}
{synopt:{opt outputweights(name)}}output priority vector{p_end}
{synopt:{opt inputscale(name)}}input reference scales{p_end}
{synopt:{opt outputscale(name)}}output reference scales{p_end}
{synopt:{opt inputgroup(namelist)}}input evaluator matrices{p_end}
{synopt:{opt outputgroup(namelist)}}output evaluator matrices{p_end}
{synopt:{opt bounds(band|groupminmax|pairwise)}}restriction rule; default {cmd:band}{p_end}
{synopt:{opt band(#)}}symmetric proportional allowance; default {cmd:0}{p_end}
{synopt:{opt lowerband(#)}}lower asymmetric allowance{p_end}
{synopt:{opt upperband(#)}}upper asymmetric allowance{p_end}
{synopt:{opt inputlower(name)} / {opt inputupper(name)}}input pair bounds{p_end}
{synopt:{opt outputlower(name)} / {opt outputupper(name)}}output pair bounds{p_end}
{synopt:{opt model(ar)}}assurance-region model{p_end}
{synopt:{opt ahpmethod(eigen|geomean)}}AHP priority method{p_end}
{synopt:{opt rts(crs|vrs)}}returns to scale; default {cmd:crs}{p_end}
{synopt:{opt orientation(input|output)}}radial orientation; default {cmd:input}{p_end}
{synopt:{opt generate(newvar)}}restricted efficiency variable{p_end}
{synopt:{opt baseline(newvar)}}unrestricted efficiency variable{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}{cmd:ahpdea} first derives priorities from AHP comparison matrices (or
accepts named priority vectors), then constrains the input and output
multipliers of a CRS or VRS, input- or output-oriented DEA model. The command implements the
assurance-region method specified by this package; it does not alter the
original {cmd:dea} files.{p_end}

{pstd}The command requires {cmd:dea} version 2 and its simplex module on the
ado-path. The public AHP-DEA installation package treats {cmd:dea} as a
separate dependency; the journal replication archive includes a reviewer-only
copy of the required DEA files.{p_end}

{pstd}{cmd:model(ar)} explicitly selects the implemented scaled
assurance-region formulation. The method is grounded in the DEA
weight-restriction literature of Thompson et al. (1986) and Allen et al.
(1997), with Takamura and Tone (2003) as an AHP-to-DEA application precedent.
It is not the parametric distance model of Pakkar (2015).{p_end}

{pstd}For input priorities p and positive reference scales s, the restrictions are{p_end}

{p 8 12}(1-band)(p_i/p_h) <= (v_i s_i)/(v_h s_h)
<= (1+band)(p_i/p_h).{p_end}

{pstd}The analogous restrictions apply to output multipliers.  The lower bound is
truncated at zero. By default, s is the vector of positive estimation-sample
means. {cmd:inputscale()} and {cmd:outputscale()} instead accept user-declared
reference scales. If a variable's measurement unit changes, its supplied
reference scale must change by the same factor to preserve unit invariance.
{cmd:band(0)} imposes exact scaled virtual-share ratios.{p_end}

{pstd}{cmd:lowerband()} and {cmd:upperband()} replace the symmetric band by
separate downward and upward proportional allowances. Both must be specified;
using the same value for both reproduces {cmd:band()} exactly.{p_end}

{pstd}{cmd:bounds(groupminmax)} implements Takamura and Tone's (2003) group
rule. For evaluator k with priority vector p_k, each criterion pair receives
L_ih=min_k(p_ki/p_kh) and U_ih=max_k(p_ki/p_kh). These bounds constrain the
corresponding scaled DEA multiplier ratio. A side without a group continues
to use exact {cmd:band(0)} bounds.{p_end}

{pstd}{cmd:bounds(pairwise)} accepts criterion-pair-specific final lower and
upper bounds on the same scaled multiplier ratios. A specified side requires
both matrices; an omitted side uses exact {cmd:band(0)} AHP ratios. The
matrices are bounds themselves, not proportional deviations from priorities.
They must be finite, named square matrices with unit diagonals, nonnegative
lower entries, positive upper entries, and a nonempty reciprocal-feasible
interval for every unordered pair.{p_end}

{pstd}Under VRS, the supporting hyperplane includes a free intercept. For
input orientation the command normalizes the weighted inputs and maximizes
weighted outputs plus the intercept. For output orientation it normalizes the
weighted outputs, minimizes weighted inputs plus the intercept, and returns
the reciprocal expansion factor so efficiencies retain the usual (0,1]
interpretation.{p_end}

{marker options}{...}
{title:Options}

{phang}{cmd:dmu(varname)} specifies a unique, nonmissing DMU identifier.{p_end}
{phang}{cmd:inputmatrix()} and {cmd:outputmatrix()} specify positive reciprocal
AHP matrices. Their row and column names must match the corresponding DEA
variable names and their CI and CR are returned.{p_end}
{phang}{cmd:inputweights()} and {cmd:outputweights()} accept positive named
column vectors instead. Exactly one matrix or vector is required for each side
having more than one variable. A single variable receives priority one.{p_end}
{phang}{cmd:inputscale()} and {cmd:outputscale()} specify positive named column
vectors of reference scales. Their row names and order must match the
corresponding DEA variables. The default on an omitted side is its vector of
positive estimation-sample means. These scales standardize DEA multipliers;
they are not AHP priorities.{p_end}
{phang}{cmd:inputgroup()} and {cmd:outputgroup()} accept space-separated AHP
comparison matrices, one per evaluator. Each matrix must use the associated
DEA variable names in the same order. The AIJ aggregate priority is returned
for description, while the individual priorities determine the bounds.{p_end}
{phang}{cmd:bounds(band|groupminmax|pairwise)} selects proportional bounds
around one priority vector, group min/max bounds, or directly supplied
criterion-pair bounds. The default is {cmd:band}.
{cmd:band()} may not be combined with {cmd:bounds(groupminmax)}.{p_end}
{phang}{cmd:band(#)} sets the nonnegative proportional band; the default is
zero.{p_end}
{phang}{cmd:lowerband(#)} and {cmd:upperband(#)} set asymmetric proportional
allowances. {cmd:lowerband()} must be in [0,1], {cmd:upperband()} must be
nonnegative, and both must be specified together. They may not be combined
with a nonzero {cmd:band()} or {cmd:bounds(groupminmax)}.{p_end}
{phang}{cmd:inputlower()}, {cmd:inputupper()}, {cmd:outputlower()}, and
{cmd:outputupper()} supply pair-specific ratio-bound matrices under
{cmd:bounds(pairwise)}. Lower and upper matrices must be specified together
for each declared side. Band options and evaluator groups may not be combined
with this rule.{p_end}
{phang}{cmd:model(ar)} selects the scaled virtual-share assurance-region
formulation implemented by this command. The only supported value is
{cmd:ar}, which is also the default.{p_end}
{phang}{cmd:ahpmethod(eigen|geomean)} selects the priority calculation used
when comparison matrices or evaluator groups are supplied; the default is
{cmd:eigen}. It has no effect on ready priorities supplied through
{cmd:inputweights()} or {cmd:outputweights()}.{p_end}
{phang}{cmd:rts(crs|vrs)} selects constant or variable returns to scale; the
default is {cmd:crs}.{p_end}
{phang}{cmd:orientation(input|output)} selects the radial orientation; the
default is {cmd:input}.{p_end}
{phang}{cmd:generate(newvar)} stores restricted efficiencies and
{cmd:baseline(newvar)} stores otherwise identical unrestricted DEA scores.{p_end}

{pstd}Both output names are validated before estimation. Existing variables
are never overwritten, and an error cannot leave only one requested output
variable behind.{p_end}

{marker stored_results}{...}
{title:Stored results}

{pstd}{cmd:ahpdea} stores in {cmd:r()}:{p_end}
{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{cmd:r(efficiency)}}restricted efficiency vector{p_end}
{synopt:{cmd:r(baseline_efficiency)}}unrestricted DEA efficiency vector{p_end}
{synopt:{cmd:r(input_priority)}}normalized input priorities{p_end}
{synopt:{cmd:r(output_priority)}}normalized output priorities{p_end}
{synopt:{cmd:r(input_evaluator_priority)}}individual input priorities under {cmd:inputgroup()}{p_end}
{synopt:{cmd:r(output_evaluator_priority)}}individual output priorities under {cmd:outputgroup()}{p_end}
{synopt:{cmd:r(input_scale)}}effective input reference scales{p_end}
{synopt:{cmd:r(output_scale)}}effective output reference scales{p_end}
{synopt:{cmd:r(input_lower)}, {cmd:r(input_upper)}}input ratio-bound matrices{p_end}
{synopt:{cmd:r(output_lower)}, {cmd:r(output_upper)}}output ratio-bound matrices{p_end}
{synopt:{cmd:r(input_multiplier)}}restricted optimal input multipliers{p_end}
{synopt:{cmd:r(output_multiplier)}}restricted optimal output multipliers{p_end}
{synopt:{cmd:r(intercept)}}free VRS intercept by DMU; zero under CRS{p_end}
{synopt:{cmd:r(status)}}LP status by DMU (zero means optimal){p_end}
{synopt:{cmd:r(N)}}number of DMUs{p_end}
{synopt:{cmd:r(model)}}{cmd:ar}{p_end}
{synopt:{cmd:r(method_definition)}}implemented assurance-region formulation{p_end}
{synopt:{cmd:r(bounds)}}{cmd:band}, {cmd:groupminmax}, or {cmd:pairwise}{p_end}
{synopt:{cmd:r(band)}}declared symmetric allowance{p_end}
{synopt:{cmd:r(band_type)}}{cmd:symmetric}, {cmd:asymmetric}, or {cmd:pairwise}{p_end}
{synopt:{cmd:r(input_scale_source)}}{cmd:sample_mean} or {cmd:user}{p_end}
{synopt:{cmd:r(output_scale_source)}}{cmd:sample_mean} or {cmd:user}{p_end}
{synopt:{cmd:r(lowerband)}, {cmd:r(upperband)}}effective downward and upward allowances{p_end}
{synopt:{cmd:r(methodological_foundation)}}foundational weight-restriction sources{p_end}
{synopt:{cmd:r(application_precedent)}}AHP-to-DEA application precedent{p_end}
{synopt:{cmd:r(input_cr)}, {cmd:r(output_cr)}}AHP consistency ratios when matrices are supplied{p_end}
{synopt:{cmd:r(rts)}}returns to scale{p_end}
{synopt:{cmd:r(orientation)}}radial orientation{p_end}
{synoptline}

{marker examples}{...}
{title:Examples}

{pstd}The following block is self-contained:{p_end}
{pstd}Run the complete block, omitting the leading dots. It restores the data in memory.{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. input str1 id double(x1 x2 y)}{p_end}
{phang2}{cmd:. "A" 1 4 5}{p_end}
{phang2}{cmd:. "B" 2 2 4}{p_end}
{phang2}{cmd:. "C" 4 1 5}{p_end}
{phang2}{cmd:. "D" 3 4 3}{p_end}
{phang2}{cmd:. end}{p_end}
{phang2}{cmd:. matrix AX=(1,2\1/2,1)}{p_end}
{phang2}{cmd:. matrix rownames AX=x1 x2}{p_end}
{phang2}{cmd:. matrix colnames AX=x1 x2}{p_end}
{phang2}{cmd:. ahpdea x1 x2 = y, dmu(id) model(ar) inputmatrix(AX) band(.20) generate(ar_eff) baseline(dea_eff)}{p_end}
{phang2}{cmd:. list id ar_eff dea_eff, noobs}{p_end}
{phang2}{cmd:. restore}{p_end}



{marker references}{...}
{title:References}

{pstd}The default AHP priority calculation follows Saaty's reciprocal-matrix
principal-eigenvector framework as operationally stated in Saaty (1987, 1990).
The DEA component is the CCR or BCC multiplier model with
assurance-region-style bounds imposed on scaled virtual shares. See the
package manuscript for the precise model declaration and the distinction from
fixed-weight and DEA-derived-AHP models.{p_end}

{pstd}Saaty, T. L. 1977. A scaling method for priorities in hierarchical
structures. {it:Journal of Mathematical Psychology} 15: 234-281.
doi:10.1016/0022-2496(77)90033-5.{p_end}

{pstd}Saaty, R. W. 1987. The analytic hierarchy process---what it is and how
it is used. {it:Mathematical Modelling} 9(3--5): 161--176.
doi:10.1016/0270-0255(87)90473-8. Saaty, T. L. 1990. How to make a decision:
The analytic hierarchy process. {it:European Journal of Operational Research}
48(1): 9--26. doi:10.1016/0377-2217(90)90057-I.{p_end}

{pstd}Charnes, A., W. W. Cooper, and E. Rhodes. 1978. Measuring the efficiency
of decision making units. {it:European Journal of Operational Research}
2: 429-444.{p_end}

{pstd}Thompson, R. G., et al. 1986. {it:Interfaces} 16(6): 35-49.
doi:10.1287/inte.16.6.35. Allen, R., et al. 1997. {it:Annals of Operations
Research} 73: 13-34. doi:10.1023/A:1018968909638. Takamura, Y., and K. Tone.
2003. {it:Socio-Economic Planning Sciences} 37(2): 85-102.
doi:10.1016/S0038-0121(02)00049-6.{p_end}

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
