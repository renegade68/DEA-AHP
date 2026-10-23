{smcl}
{* *! help revision 24oct2026}{...}
{viewerjumpto "Syntax" "dahpsynth##syntax"}{...}
{viewerjumpto "Description" "dahpsynth##description"}{...}
{viewerjumpto "Options" "dahpsynth##options"}{...}
{viewerjumpto "Stored results" "dahpsynth##stored_results"}{...}
{viewerjumpto "Examples" "dahpsynth##examples"}{...}
{viewerjumpto "Remarks" "dahpsynth##remarks"}{...}
{viewerjumpto "References" "dahpsynth##references"}{...}
{viewerjumpto "Authors" "dahpsynth##authors"}{...}
{title:Title}

{p2colset 5 17 19 2}{...}
{p2col :{cmd:dahpsynth} {hline 2}}AHP synthesis when hierarchy structure varies across contexts{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}{cmd:dahpsynth} {it:P1 L1 P2 L2 ...}{cmd:,} {opt contexts(#)} [{opt contextweights(numlist)} {opt timepool(arithmetic|geometric)} {opt tolerance(#)}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt contexts(#)}}number of parent/local matrix pairs; required{p_end}
{synopt:{opt contextweights(numlist)}}positive context weights{p_end}
{synopt:{opt timepool(arithmetic|geometric)}}context pooling rule{p_end}
{synopt:{opt tolerance(#)}}local-column sum tolerance; default {cmd:1e-8}{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}Each context is supplied as a pair: a parent-priority vector P followed by a local-priority matrix L. Different contexts may contain different numbers and names of criteria. The alternatives must remain identical and in the same order so that context results have a common ratio-scale frame.

{pstd}The structural-change rule is contextwise renormalization. Criteria absent from a context receive no path in that context; criteria present in that context are represented by a positive parent-priority vector that is normalized to one. Local columns must each sum to one. No priority mass is automatically carried from a removed criterion to a new criterion.

{marker options}{...}
{title:Options}

{phang}{opt contexts(#)} specifies the number of parent/local pairs and is
required.

{phang}{opt contextweights(numlist)} supplies positive context weights; equal
weights are the default.

{phang}{opt timepool(arithmetic|geometric)} specifies context pooling.

{phang}{opt tolerance(#)} sets the local-column sum tolerance.

{marker stored_results}{...}
{title:Stored results}

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{cmd:r(weights)}}integrated priorities{p_end}
{synopt:{cmd:r(context_weights)}}context-specific priorities{p_end}
{synopt:{cmd:r(contributions#)}}path contributions for context {it:#}{p_end}
{synopt:{cmd:r(N_contexts)}}number of contexts{p_end}
{synopt:{cmd:r(timepool)}}context pooling rule{p_end}
{synopt:{cmd:r(structure_rule)}}applied context-structure rule{p_end}
{synoptline}

{marker examples}{...}
{title:Examples}

{pstd}The following uses two contexts whose criteria may differ:{p_end}
{pstd}Run the complete block, omitting the leading dots. It restores the data in memory.{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. matrix P1=(.5\.3\.2)}{p_end}
{phang2}{cmd:. matrix rownames P1=capability readiness cost}{p_end}
{phang2}{cmd:. matrix L1=(.6,.3,.2\.3,.5,.2\.1,.2,.6)}{p_end}
{phang2}{cmd:. matrix rownames L1=A B C}{p_end}
{phang2}{cmd:. matrix colnames L1=capability readiness cost}{p_end}
{phang2}{cmd:. matrix P2=(.65\.35)}{p_end}
{phang2}{cmd:. matrix rownames P2=capability resilience}{p_end}
{phang2}{cmd:. matrix L2=(.5,.2\.35,.3\.15,.5)}{p_end}
{phang2}{cmd:. matrix rownames L2=A B C}{p_end}
{phang2}{cmd:. matrix colnames L2=capability resilience}{p_end}
{phang2}{cmd:. dahpsynth P1 L1 P2 L2, contexts(2) contextweights(.4 .6)}{p_end}
{phang2}{cmd:. restore}{p_end}


{marker remarks}{...}
{title:Remarks}

{dlgtab:Limitation}

{pstd}This command supports changing criterion sets with a fixed alternative set. Changes to alternatives require an explicit cross-context identity or mapping model and are deliberately rejected in this release.{p_end}

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
