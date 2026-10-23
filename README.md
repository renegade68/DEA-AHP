# DEA-AHP

Stata software accompanying the manuscript:

> Lee, M., and C. Lee. 2026. *Integrating analytic hierarchy process and data
> envelopment analysis in Stata*. Manuscript under review at the
> [Stata Journal](https://www.stata-journal.com/).

The commands support analytic hierarchy process (AHP), hierarchy and network
synthesis, and two explicitly ordered integrations with data envelopment
analysis (DEA). `ahpdea` uses AHP priorities to restrict DEA multipliers;
`deaahp` uses DEA results before applying AHP.

Requires Stata 16 or newer. This author-maintained software extends the August
2026 submission with recursive hierarchy synthesis (`ahphierarchy`) and ANP
supermatrix analysis (`ahpnetwork`). Submission of the manuscript does not
imply journal approval of later software changes. The code and help files
define the implemented models and their limitations.

## Start using the commands

Download or clone this repository. Keep **all files in `ado/` together**,
including the six `.mata` implementation files and the helper `.ado` files.
Add that folder to Stata's search path:

```stata
adopath ++ "/your/path/DEA-AHP/ado"
which ahp
help ahp
```

The six standalone commands `ahp`, `ahphierarchy`, `ahpnetwork`, `ahpsynth`,
`dahp`, and `dahpsynth` do not require DEA. For example:

```stata
matrix A = (1, 5/3, 5/2 \ 3/5, 1, 3/2 \ 2/5, 2/3, 1)
matrix rownames A = capability readiness cost
matrix colnames A = capability readiness cost
ahp A
matrix list r(weights)
```

The resulting priority weights are 0.5, 0.3, and 0.2.

For `ahpdea`, `deaahp`, or `ahpdeasim`, also download
[DEA-Stata](https://github.com/renegade68/DEA-Stata) and keep its entire `ado/`
folder together, including its implementation `.do` files. Add both folders:

```stata
adopath ++ "/your/path/DEA-Stata/ado"
adopath ++ "/your/path/DEA-AHP/ado"
which dea
which _dea_simplex
which ahpdea
help ahpdea
```

Use `which` to identify the active copy if another DEA or AHP installation is
already present. The hybrid commands require the DEA version-2 LP interface;
the original 2010 DEA package alone is insufficient. DEA is a separate
dependency and is not bundled or replaced by this repository. The reviewed
combination uses [DEA-Stata commit 41ea1dc](https://github.com/renegade68/DEA-Stata/tree/41ea1dccda72b4a49c0964e358a0f76196709994),
whose main command is `dea` 2.0.28.

This repository uses a local-folder installation. It does not provide an
`ssc install` or `net install` package. Help examples generate their own
teaching data or matrices. Copy the complete block, omitting the leading dots;
the `preserve` and `restore` lines protect data already in memory. No separate
dataset or example do-file is required.

## Choose a command

| Family | Command | Purpose | Files |
| --- | --- | --- | --- |
| AHP | `ahp` | Reciprocal judgments, eigenvector/geometric-mean priorities, AIJ/AIP group aggregation and consistency diagnostics | [code](ado/ahp.ado) · [help](ado/ahp.sthlp) |
| Hierarchies | `ahphierarchy` | Recursive long-format hierarchy synthesis; explicit structures; crisp, interval and triangular-fuzzy judgments | [code](ado/ahphierarchy.ado) · [help](ado/ahphierarchy.sthlp) |
| Networks | `ahpnetwork` | ANP weighted supermatrices and power/Cesaro summaries from supplied local priorities | [code](ado/ahpnetwork.ado) · [help](ado/ahpnetwork.sthlp) |
| Synthesis | `ahpsynth` | Combine parent and local priorities with path contributions | [code](ado/ahpsynth.ado) · [help](ado/ahpsynth.sthlp) |
| Contexts | `dahp` | AHP within declared time/state contexts and explicit context pooling | [code](ado/dahp.ado) · [help](ado/dahp.sthlp) |
| Contexts | `dahpsynth` | Context-dependent criteria with a fixed alternative set | [code](ado/dahpsynth.ado) · [help](ado/dahpsynth.sthlp) |
| AHP before DEA | `ahpdea` | Scaled virtual-share assurance-region DEA under CRS/VRS and input/output orientation | [code](ado/ahpdea.ado) · [help](ado/ahpdea.sthlp) |
| DEA before AHP | `deaahp` | AHP within a declared DEA tie, or pairwise DEA/AHP ranking | [code](ado/deaahp.ado) · [help](ado/deaahp.sthlp) |
| Sensitivity | `ahpdeasim` | Reciprocal judgment perturbations and efficiency/rank sensitivity | [code](ado/ahpdeasim.ado) · [help](ado/ahpdeasim.sthlp) |

## Interpretation

`dahp` treats time and state as analyst-defined weighted contexts; it does not
estimate transition probabilities or an endogenous dynamic process.
`ahpnetwork` consumes supplied local priorities. Its iterative stopping
tolerance is not a guaranteed bound on distance to an exact limit; inspect
sensitivity to iteration settings for slowly converging networks.

Interval/fuzzy priority envelopes and Monte Carlo judgment-perturbation ranges
are not automatically statistical confidence intervals. Numerical verification
does not validate an application's expert judgments, production variables,
or causal interpretation. Each help file states its model and data contract.

## Versions and feedback

Individual computational versions are recorded in the `.ado` headers; help
revisions are dated separately. The October 2026 maintenance changes reject
missing numerical options, protect the caller's scalar during the DEA API
check, and make the help examples directly executable. The full Stata test
suite, additional input-validation checks, and the nine actual help examples
were run locally with Stata/MP 16.1 and the DEA dependency identified above.
Other Stata binaries and operating systems have not been tested here.

For a problem report, include the command, Git commit, `which` output, Stata
version, a small reproducible example, and expected versus actual results.
Use [GitHub Issues](https://github.com/renegade68/DEA-AHP/issues), with synthetic
data in place of confidential research data.

## Attribution and licensing

Cite the manuscript above for this software and the command-specific
references in the help files for the methods. Include the software commit
used. Complete journal details and a DOI will be added when available.
The manuscript authors are Miyoung Lee and Choonjoo Lee; the code author
identified in the source is Choonjoo Lee.

The DEA dependency has its own attribution and license, including Ji and Lee
(2010), *Data envelopment analysis*, and Lee's forthcoming DEA update. See
[DEA-Stata](https://github.com/renegade68/DEA-Stata) for those details.
Manuscripts, publisher PDFs, private data, and development outputs are not
included in this software repository.

The software and accompanying help files are licensed under the
[Academic Free License 3.0](LICENSE). See the [software notice](LICENSE_CODE.txt)
for scope and attribution. Manuscripts and publisher versions are outside this
software license.
