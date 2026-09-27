# tflspec

Excel specifications for clinical **tables, listings and figures**. tflspec
decides *what* goes on the page; [rtfreporter](https://github.com/ichirio/rtfreporter)
renders it to RTF, and [tflplanner](https://github.com/ichirio/tflplanner) is the
GUI on top.

```
tflplanner   the GUI; installing it installs the other two
    |
tflspec      for programmers: library(tflspec) also attaches rtfreporter
    |
rtfreporter  the RTF renderer; usable on its own
```

| Part | What it does | Entry points |
|---|---|---|
| Tables (ARD) | a cards/cardx ARD -> a table data.frame -> rtfreporter pages, declared once as a plan or in an Excel table spec | `ard_normalize()`, `ard_spread()`, `rtf_plan()` + `plan_*()`, `table_spec()`, `read_report_spec()`, `rtf_report()` |
| Figures | an Excel plot spec -> a ggplot2 skeleton script | `plot_spec()`, `plot_code()`, `pp_km()`, `pp_waterfall()`, `pp_swimmer()` |

A plan is a table source for rtfreporter: `rtf_tables(doc, plan)` and
`rtfreporter::as_rtftables(plan)` both accept it (tflspec registers an
`as_rtftables()` method).

Status: early development. The table half moved here from rtfreporter's
`feat/474-ard-experimental` branch (ichirio/rtfreporter#474); the figure half
was tflspec. Discussion and sample code:
[Discussions](https://github.com/ichirio/tflspec/discussions).

## Tables

```r
library(tflspec)     # attaches rtfreporter too (Depends)

tbl <- ard |>
  ard_normalize() |>
  rtf_plan(cols = "TRT01A", rows = c(group = "variable")) |>
  plan_cells(continuous = c("n" = "{N:d}", "Mean (SD)" = "{mean} ({sd})"),
             categorical = "{n} ({p:%})") |>
  plan_digits(1)

doc <- rtf_document() |> rtf_tables(tbl)
generate_rtfreport(doc, "t_dm.rtf")
```

## Figures

Generate a **ggplot2 skeleton script** for common clinical figures by choosing a
plot type and a **style** — a few arguments instead of a few hundred lines.

tflspec does not try to cover every figure. It writes the ~95% that is the
same every time (data preparation from ADaM, the plot, legend, `ggsave()`), and
you finish the rest by editing the generated script. The script depends only on
dplyr + ggplot2 (+ ggsurvfit / patchwork), not on tflspec — except the
treatment-sequence `sankey` / `sunburst`, which are drawn by tflspec's own
ggplot2 functions (`plot_sankey()`, `plot_sunburst()`).

Figure types: see the [catalogue](#catalogue-of-figure-types) below (15 implemented types in 7 clinical categories).

### Quick start

```r
library(tflspec)
adam <- read_adam("data/adam")     # optional: .xpt / .sas7bdat / .rds folder, or list(adsl = ...)

pp_km(adam, param = "OS")                                      # print the script
pp_km(adam, param = "DOR", style = "single_arm", file = "programs/f_km_dor.R")
pp_waterfall(adam)
pp_swimmer(adam, events = c(Death = "DTHADY", Discontinued = "EOSDY"), visit_every = 3)
```

Standard ADaM names are assumed (ADTTE `AVAL`/`CNSR`/`PARAMCD`, `TRT01P`,
`FASFL`, ADRS `BOR`/`OVR` in `AVALC`, ADSL `TRTDURD`, ...). Pass an argument only
when your study differs, e.g. `group = "TRT01A"`, `pop = "SAFFL"`, `data = "ADEFF"`.
With `adam`, the group / response values and their colours are written literally
into the script; without it, they are taken from the data when the script runs.

Try it on synthetic data: `adam <- pp_example_adam()`.

| `pp_km(adam, x_max = 24, x_by = 3)` | `pp_km(adam, style = "single_arm")` | `pp_km(adam, style = "ci", legend = "panel_inside")` |
|---|---|---|
| ![](man/figures/quick_km_risk.png) | ![](man/figures/quick_km_single.png) | ![](man/figures/quick_km_ci.png) |

| `pp_waterfall(adam)` | `pp_swimmer(adam, events = ..., visit_every = 3)` | `pp_swimmer(adam, style = "response", legend = "inside_bl")` |
|---|---|---|
| ![](man/figures/quick_wf_resp.png) | ![](man/figures/quick_sw_full.png) | ![](man/figures/quick_sw_resp.png) |

## Catalogue of figure types

`pp_catalog()` classifies the figure types by clinical category. Each type has
one or more **styles** (subtypes; **bold** = default), and some have argument-level
subtypes (e.g. a swimmer plot with bars from 0 or from a start day). Rows with
status `planned` are classified but not generated yet.

| category | type | style | status | function | draws |
|---|---|---|---|---|---|
| Efficacy: time to event | km | **risk_table** | implemented | `pp_km()` | KM curves by group + censor marks + median line + number at risk panel — subtypes: time_unit: days / weeks / months / years |
| Efficacy: time to event | km | simple | implemented | `pp_km()` | KM curves by group + censor marks |
| Efficacy: time to event | km | ci | implemented | `pp_km()` | KM curves by group + confidence bands + censor marks + number at risk panel |
| Efficacy: time to event | km | single_arm | implemented | `pp_km()` | One KM curve (no group) + censor marks + median line + number at risk panel |
| Efficacy: time to event | cuminc | **competing_risks** | planned |  | Cumulative incidence with competing risks by group |
| Efficacy: tumour response | waterfall | **response** | implemented | `pp_waterfall()` | Best % change bars coloured by best overall response + +20% / -30% lines with labels |
| Efficacy: tumour response | waterfall | plain | implemented | `pp_waterfall()` | Best % change bars in one colour + +20% / -30% lines with labels |
| Efficacy: tumour response | swimmer | **full** | implemented | `pp_swimmer()` | Bars coloured by BOR + response at each assessment + event markers + ongoing arrows — subtypes: origin: bars from 0 (duration, default) / from start to end (start, end) |
| Efficacy: tumour response | swimmer | assessment | implemented | `pp_swimmer()` | Bars coloured by BOR + response at each assessment + ongoing arrows — subtypes: origin: from 0 / from start |
| Efficacy: tumour response | swimmer | response | implemented | `pp_swimmer()` | Bars coloured by BOR + ongoing arrows — subtypes: origin: from 0 / from start |
| Efficacy: tumour response | swimmer | bar | implemented | `pp_swimmer()` | Bars in one colour + ongoing arrows — subtypes: origin: from 0 / from start |
| Efficacy: tumour response | individual | spider | implemented | `pp_individual()` | % change in tumour size over time per subject, coloured by BOR, +20% / -30% lines — subtypes: time_unit: days / weeks / months |
| Efficacy: subgroups and rates | forest | **hr** | implemented | `pp_forest()` | Cox hazard ratio (95% CI) overall and by subgroup + N / estimate text columns |
| Efficacy: subgroups and rates | forest | or | implemented | `pp_forest()` | Odds ratio of response (95% CI) overall and by subgroup + text columns |
| Efficacy: subgroups and rates | forest | estimates | implemented | `pp_forest()` | Forest plot of pre-computed estimates (label, est, lcl, ucl) |
| Efficacy: subgroups and rates | bar | **rate_ci** | implemented | `pp_bar()` | Response rate by group with exact 95% CI and n/N labels |
| Efficacy: subgroups and rates | bar | stacked | implemented | `pp_bar()` | 100% stacked bars of a category (e.g. BOR) by group |
| Efficacy: subgroups and rates | bar | dodged | implemented | `pp_bar()` | Percent of subjects per category, groups side by side |
| Longitudinal | mean | **se** | implemented | `pp_mean()` | Mean +/- SE by visit and group (dodged) — subtypes: value: AVAL / CHG / PCHG |
| Longitudinal | mean | sd | implemented | `pp_mean()` | Mean +/- SD by visit and group |
| Longitudinal | mean | ci | implemented | `pp_mean()` | Mean with 95% CI by visit and group |
| Longitudinal | mean | se_n | implemented | `pp_mean()` | Mean +/- SE by visit and group + table of n below |
| Longitudinal | individual | **spaghetti** | implemented | `pp_individual()` | One line per subject by visit, coloured by group, with group means |
| Longitudinal | box | **by_visit** | implemented | `pp_box()` | Box plots by visit and group + mean marker |
| Longitudinal | box | by_group | implemented | `pp_box()` | Box plot per group at one visit + data points + mean marker |
| Longitudinal | box | change | implemented | `pp_box()` | Box plots of change from baseline by visit and group + zero line |
| Longitudinal | lsmeans | **mmrm** | planned |  | Model-based LS means (95% CI) over time by group |
| Safety | ae_dot | **risk_diff** | implemented | `pp_ae_dot()` | Incidence by preferred term (two arms) + risk difference with 95% CI |
| Safety | ae_dot | incidence | implemented | `pp_ae_dot()` | Incidence by preferred term by arm |
| Safety | butterfly | **soc** | implemented | `pp_butterfly()` | Incidence by system organ class, two arms mirrored |
| Safety | butterfly | pt | implemented | `pp_butterfly()` | Incidence by preferred term (top N), two arms mirrored |
| Safety | edish | **alt** | implemented | `pp_edish()` | Max ALT vs max total bilirubin (x ULN, log axes) + Hy's law lines and quadrants |
| Safety | edish | alt_ast | implemented | `pp_edish()` | Max of ALT / AST vs max total bilirubin (x ULN) + Hy's law lines |
| Safety | shift_heatmap | **worst_grade** | planned |  | Baseline vs worst post-baseline grade counts as a heatmap |
| Safety | patient_profile | **timeline** | planned |  | One subject: dosing, AEs and labs on a shared time axis |
| PK / PD | pk | **mean** | implemented | `pp_pk()` | Mean +/- SD concentration by nominal time and group |
| PK / PD | pk | mean_log | implemented | `pp_pk()` | Mean +/- SD concentration, log axis |
| PK / PD | pk | individual | implemented | `pp_pk()` | Individual concentration-time profiles, log axis, one panel per group |
| PK / PD | qtc_conc | **scatter_fit** | planned |  | Change in QTc vs concentration with a linear fit |
| PK / PD | dose_response | **emax** | planned |  | Response by dose with a fitted Emax curve |
| Distribution / association | scatter | **shift** | implemented | `pp_scatter()` | Baseline vs post-baseline value at one visit + identity line |
| Distribution / association | scatter | xy | implemented | `pp_scatter()` | Two variables with a linear fit per group |
| Distribution / association | histogram | **by_group** | planned |  | Histogram / density of a variable by group |
| Distribution / association | roc | **biomarker** | planned |  | ROC curve of a biomarker with AUC |
| Treatment patterns | sankey | **grey_links** | implemented | `pp_sankey()` | Treatment-line nodes (subjects per line x category) + links in light grey |
| Treatment patterns | sankey | colored_links | implemented | `pp_sankey()` | Treatment-line nodes + links in the colour of their source node |
| Treatment patterns | sankey | subgroups | implemented | `pp_sankey()` | One sankey per subgroup (`by`) on a shared scale, side by side |
| Treatment patterns | sunburst | **rings** | implemented | `pp_sunburst()` | One ring per line (inner = first line); arcs = subjects, gaps = no further line |

More styles of the same type are cheap to add: tell us which ones you need in the
[Discussions](https://github.com/ichirio/tflspec/discussions).

| `pp_forest(adam)` | `pp_ae_dot(adam)` | `pp_mean(adam, style = "se_n")` |
|---|---|---|
| ![](man/figures/type_forest_hr.png) | ![](man/figures/type_ae_dot_risk_diff.png) | ![](man/figures/type_mean_se_n.png) |

| `pp_edish(adam)` | `pp_butterfly(adam)` | `pp_pk(adam, style = "mean_log")` |
|---|---|---|
| ![](man/figures/type_edish_alt.png) | ![](man/figures/type_butterfly_soc.png) | ![](man/figures/type_pk_mean_log.png) |

| `pp_individual(adam, style = "spider")` | `pp_box(adam)` | `pp_bar(adam)` |
|---|---|---|
| ![](man/figures/type_individual_spider.png) | ![](man/figures/type_box_by_visit.png) | ![](man/figures/type_bar_rate_ci.png) |

Conventions of the generated scripts: population, group and subgroup variables
are always taken from ADSL (joined by `USUBJID`), so BDS datasets need not carry
them; `param` selects `PARAMCD`; `pop` is a `== "Y"` flag (`NULL` for none).

## Treatment sequences: sankey and sunburst

Input: one row per subject and line (e.g. lines of therapy), default dataset
`ADLOT` with `USUBJID`, `LINE` and `TRT` (change with `data`, `stage`, `category`).

```r
pp_sankey(adam)                                          # grey links
pp_sankey(adam, style = "colored_links")
pp_sankey(adam, style = "subgroups", by = "AGEGR1")
pp_sunburst(adam)
```

The scripts call `sankey_data()` / `sunburst_data()` (nodes, links and paths
from the line data) and `plot_sankey()` / `plot_sankey_subgroups_batch()` /
`plot_sunburst()` (moved here from ydisctools), which can also be used directly.

| `pp_sankey(adam, style = "colored_links")` | `pp_sankey(adam, style = "subgroups", by = "AGEGR1")` | `pp_sunburst(adam)` |
|---|---|---|
| ![](man/figures/quick_sankey.png) | ![](man/figures/quick_sankey_subgroups.png) | ![](man/figures/quick_sunburst.png) |

## Legends

`legend =`

| value | legend |
|---|---|
| `none` | no legend |
| `right`, `bottom`, `inside`, `inside_bl` | ggplot2 legend of the mapped colours / fills / shapes |
| `panel`, `panel_right`, `panel_inside` | a legend **panel drawn from an item table**, independent of the data (like hand-made legends in study figures). The items are written into the script as a `tribble` — add, remove or relabel rows by hand |

## Common arguments and options

- `title`, `pop` (population flag, `NULL` = none), `time_unit` (`days` / `weeks` / `months` / `years`), `file`, `plot_id`
- `...`: `x_max`, `x_by`, `y_min`, `y_max`, `y_by`, `ref_lines` (`"20,-30"`), `palette`
  (`treatment`, `response`, `response_light`, `okabe_ito`, `grey`), `theme` (`boxed`, `L_axis`,
  `minimal`, `classic`), `width`, `height`, `units`, `dpi`, `censor_shape`, `legend_ncol`, ...
- Set once per study:

```r
options(
  tflspec.data_expr = "adam_data${ds}",                          # how the script gets ADTTE etc.
  tflspec.fig_path  = 'file.path(output_path, "{plot_id}.png")'  # where it saves
)
```

## Many figures: Excel plot list

One row per figure, columns = the arguments above.

```r
write_plot_list_template("plot_list.xlsx", adam)   # drop-downs for type, style, legend, PARAMCD, group, pop
plot_list_code("plot_list.xlsx", adam, dir = "programs/figures")
```

| plot_id | type | style | title | param | group | pop | legend | args |
|---|---|---|---|---|---|---|---|---|
| F-14.2.1 | km | risk_table | | OS | TRT01P | | | `x_max = 24, x_by = 3` |
| F-14.2.2 | waterfall | response | | | | | | |
| F-14.2.3 | swimmer | full | | | | | | `events = c(Death = "DTHADY")` |

Blank = default. `args` takes any further argument in R syntax.

## Advanced: detailed spec

The quick API is built on a detailed spec (plots / roles / filters / levels /
legend / options sheets) that can express other combinations of patterns:
`write_plot_spec_template()`, `read_plot_spec()`, `check_plot_spec()`,
`plot_code()`. See `?plot_code` and `pp_example_spec()`.

Out of scope by design: deriving analysis variables (e.g. time from dates or
AVISIT). Use variables that exist in the ADaM data and derive the rest in the script.
