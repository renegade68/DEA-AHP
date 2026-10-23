{smcl}
{* *! help revision 24oct2026}{...}
{viewerjumpto "Syntax" "ahpsynth##syntax"}{...}
{viewerjumpto "Description" "ahpsynth##description"}{...}
{viewerjumpto "Options" "ahpsynth##options"}{...}
{viewerjumpto "Stored results" "ahpsynth##stored_results"}{...}
{viewerjumpto "Examples" "ahpsynth##examples"}{...}
{viewerjumpto "References" "ahpsynth##references"}{...}
{viewerjumpto "Authors" "ahpsynth##authors"}{...}
{title:Title}

{p2colset 5 17 19 2}{...}
{p2col :{cmd:ahpsynth} {hline 2}}Synthesize local AHP priorities through one hierarchy level{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}{cmd:ahpsynth} {it:parent_priority_matrix local_priority_matrix} [{cmd:,} {opt tolerance(#)}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt tolerance(#)}}local-column sum tolerance; default {cmd:1e-8}{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}The parent-priority matrix is a row or column vector with p elements. The local-priority matrix has alternatives or child nodes in rows and p parent criteria in columns. Parent node names must match local-matrix column names in the same order. Each local column must be nonnegative and sum to one. The command computes global priorities as local priorities times parent priorities, following classical AHP hierarchical synthesis.

{marker options}{...}
{title:Options}

{phang}{opt tolerance(#)} sets the allowed deviation of each local column sum
from one; default 1e-8.

{marker stored_results}{...}
{title:Stored results}

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{cmd:r(weights)}}synthesized global priorities{p_end}
{synopt:{cmd:r(contributions)}}local priorities multiplied by parent priorities{p_end}
{synoptline}

{marker examples}{...}
{title:Examples}

{pstd}Run the complete block, omitting the leading dots. It restores the data in memory.{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. matrix P=(.6,.4)}{p_end}
{phang2}{cmd:. matrix colnames P=benefit cost}{p_end}
{phang2}{cmd:. matrix L=(.7,.2\.3,.8)}{p_end}
{phang2}{cmd:. matrix rownames L=A B}{p_end}
{phang2}{cmd:. matrix colnames L=benefit cost}{p_end}
{phang2}{cmd:. ahpsynth P L}{p_end}
{phang2}{cmd:. restore}{p_end}

{marker references}{...}
{title:References}

{phang}Saaty, R. W. 1987. The analytic hierarchy process---what it is and how
it is used. {it:Mathematical Modelling} 9(3--5): 161--176.
{browse "https://doi.org/10.1016/0270-0255(87)90473-8":doi:10.1016/0270-0255(87)90473-8}.{p_end}

{phang}Saaty, T. L. 1990. How to make a decision: The analytic hierarchy
process. {it:European Journal of Operational Research} 48(1): 9--26.
{browse "https://doi.org/10.1016/0377-2217(90)90057-I":doi:10.1016/0377-2217(90)90057-I}.{p_end}

{marker authors}{...}
{title:Authors}

{pstd}Lee, Choonjoo{break}
Korea National Defense University{break}
sarang90@korea.kr{p_end}
