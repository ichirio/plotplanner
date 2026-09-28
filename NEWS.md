# tflspec 0.0.10

* **The former names are gone** (#11): `ard_normalize()`, `rtf_plan()`,
  `table_plan()`, `plan_cells()`, `rtf_report()`, `pp_km()`, `plot_code()`
  and the rest now stop with "could not find function"; call the `tfl_`
  name (the table is in 0.0.9 below).  tflspec keeps only the `tfl_`
  functions, before its API grows around two sets of names.

# tflspec 0.0.9

* **Every function now starts with `tfl_`** (#9), so tflspec's names do not
  collide with cards / cardx (`ard_*`) or rtfreporter (`rtf_*`) when they
  are attached together, and say whose function it is -- as `rtf_` does
  for rtfreporter.  The scheme is `tfl_` + area + action:
  - ARD: `tfl_ard_spec()`, `tfl_read_ard_spec()`, `tfl_ard_code()` (was
    `ard_spec_code()`), `tfl_build_ard()`, `tfl_ard_normalize()`,
    `tfl_ard_spread()`, ...
  - Tables: `tfl_table_spec()`, `tfl_read_table_spec()`, `tfl_plan()` (was
    `rtf_plan()` / `table_plan()`) and the verbs `tfl_plan_cells()`,
    `tfl_plan_digits()`, ..., `tfl_apply_plan()`, `tfl_plan_template()`.
  - Reports: `tfl_report()` (was `rtf_report()`), `tfl_read_report_spec()`,
    `tfl_report_path()`.
  - Listings: `tfl_listing_code()` (was `listing_spec_code()`),
    `tfl_read_data_code()`.
  - Figures: `tfl_fig_km()`, `tfl_fig_waterfall()`, ... (were `pp_*()`),
    `tfl_fig_spec()` / `tfl_read_fig_spec()` / `tfl_fig_code()` /
    `tfl_fig_list_code()` (were `plot_spec()`, `read_plot_spec()`,
    `plot_code()`, `plot_list_code()`), `tfl_fig_style()`,
    `tfl_check_fig()` (was `check_figure()`), `tfl_fig_types()` (was
    `pp_styles()`); figures drawn directly: `tfl_plot_sankey()`,
    `tfl_plot_sankey_batch()`, `tfl_plot_sunburst()`.
  S3 classes follow: `tfl_plan`, `tfl_table_spec`, `tfl_ard_spec`,
  `tfl_ard_cells`, `tfl_ard_overall`, `tfl_fig_spec` (was `pp_spec`),
  `tfl_code` (was `pp_code`).
* **The former names still work**: each is the same function as its new
  name (see `?tflspec-superseded` for the table).  They are superseded --
  no warning -- and will be removed before the first CRAN release.
  Generated code (`tfl_plan_template()`, figure scripts) writes the new
  names.  The five example reports' RTF are byte-identical.

# tflspec 0.0.8

* **pharmaverseadam example** (`inst/examples/pharmaverseadam/`): a plot
  list with 19 clinical figures (`plot_list.xlsx`), the data preparation
  tflspec does not do (`prepare_adam.R`) and `run_all.R` (spec -> programs ->
  figures). All 19 programs run without warnings.
* Template figure types take `where =`, an extra record condition in R code
  (e.g. only scheduled visits).
* Groups follow the paired numeric code of ADSL when there is one (`TRT01AN`
  for `TRT01A`) instead of alphabetical order.
* Generated programs cope with real data: swimmer event markers are skipped
  when no subject has an event; a forest model that does not converge is
  shown as NE; eDISH drops records without a ULN.
* `write_plot_code()` / `plot_list_code(dir =)` keep plot ids in file names
  (`F-01.R`, not `F.01.R`).
* **Catalogue of clinical figure types**: `pp_catalog()` classifies every type
  and style (subtype) by category (efficacy: time to event / tumour response /
  subgroups and rates, longitudinal, safety, PK / PD, distribution, treatment
  patterns), with planned types recorded for later. `pp_styles()` and the
  Excel plot list are derived from it.
* **Ten new figure types**, each with styles: `pp_forest()` (hr, or,
  estimates), `pp_bar()` (rate_ci, stacked, dodged), `pp_mean()` (se, sd, ci,
  se_n), `pp_individual()` (spaghetti, spider), `pp_box()` (by_visit,
  by_group, change), `pp_ae_dot()` (risk_diff, incidence), `pp_butterfly()`
  (soc, pt), `pp_edish()` (alt, alt_ast), `pp_scatter()` (shift, xy) and
  `pp_pk()` (mean, mean_log, individual). Their scripts depend only on
  dplyr / ggplot2 (+ survival, patchwork).
* Swimmer subtype: `pp_swimmer(start =, end =)` draws bars from a start day
  instead of 0.
* `pp_example_adam()` gains `ADAE`, `ADLB`, `ADPC`, tumour size over time in
  `ADTR`, and `SEX` / `AGEGR1` / `TRT01A` / start and end days in `ADSL`
  (drawn from a separate random stream: existing values are unchanged).
* **Treatment-sequence figures moved here from ydisctools**: `plot_sankey()`
  (nodes laid out from the node table, baseline-aware ribbon stacking,
  shared / adaptive scales), `plot_sankey_subgroups_batch()` and
  `plot_sunburst()`, with their tests. `plot_sankey_polygon()` (deprecated
  alias) was not carried over.
* `sankey_data()` / `sunburst_data()` build their inputs from one row per
  subject and line (e.g. lines of therapy), optionally by subgroup.
* Quick API `pp_sankey()` (styles `grey_links`, `colored_links`,
  `subgroups`) and `pp_sunburst()` (style `rings`); both are also available
  as `type` in the Excel plot list (`group` = subgroup variable of sankey).
  Unlike the other figure types, these scripts call tflspec.
* `pp_example_adam()` gains `ADLOT` (lines of therapy); existing datasets
  are unchanged.
* ggplot2 and rlang are now imported.

# tflspec 0.0.7

* **`rtf_plan()` is now `table_plan()`**, and the object it returns is of
  class `table_plan` (was `rtf_plan`), the plan paired with `table_spec`.
  The plan lives in tflspec, not rtfreporter, so it no longer carries
  rtfreporter's `rtf_` prefix.  `rtf_plan()` still works: it is the same
  function under its former name, **superseded** -- write `table_plan()` in
  new code.  `plan_template()` now writes `table_plan()` (#7).

# tflspec 0.0.6

* **Figure style standard** (`fig_style()`, `fig_style_template()`,
  `read_fig_style()`): every look-and-feel value of a figure -- font sizes,
  line widths, ticks, reference lines, the censor mark, palettes, event
  markers, the output size -- in one catalog of three sheets (`settings`,
  `colors`, `markers`).  The built-in one is taken from the KM / waterfall /
  swimmer sample programs; a company sets its own with
  `options(tflspec.fig_style = read_fig_style(path))`.  `pp_km()`,
  `pp_waterfall()` and `pp_swimmer()` take their defaults from it (so the
  generated scripts change: e.g. the KM line is 0.3, the censor mark size 3
  / stroke 0.6, the 50% line `twodash`; a swimmer event named like a marker
  of the style -- `Death`, `Discontinued` -- takes its shape and colour).
* **Figure checks** (`fig_setup_code()`, `check_figure()`): the style as
  data plus `theme_tfl()`, `scale_colour_tfl()` / `scale_fill_tfl()`,
  `tfl_marker()`, `tfl_save()` and `tfl_check()` as plain ggplot2 code, for
  figure programs written by hand or by an AI.  `tfl_check()` warns
  ("Figure check: ...") about rows ggplot2 dropped, legend colours that are
  not the standard's and a legend not in the expected order, notes data
  beyond the visible axes, and returns a fingerprint of the drawn data.
* **KM number at risk from the table's ARD**: `pp_km(ard = )` reads the
  number at risk from the KM table's `cardx::ard_survival_survfit()` ARD, so
  the figure and the table agree, and warns when it differs from the
  curve's own count.

# tflspec 0.0.5

* **`library(tflspec)` is enough**: rtfreporter moved from `Imports` to
  `Depends`, so attaching tflspec attaches rtfreporter too.  tflspec
  extends rtfreporter (a plan is one of its table sources), which is the
  case `Depends` is for.  Code written for the rtfreporter branch needs
  `library(tflspec)` and nothing else, unless it calls the moved functions
  as `rtfreporter::` (now `tflspec::`).
* R CMD check (`--as-cran`) runs on GitHub Actions: ubuntu devel / release
  / oldrel-1, macOS, Windows.

# tflspec 0.0.4

* **The ARD spec engine moved here from tflplanner**: an Excel definition of
  the study's analyses (`study`, `datasets`, `populations`, `analyses`) ->
  cards / cardx code -> the study ARD.  `ard_spec()`, `read_ard_spec()`,
  `write_ard_spec()`, `ard_spec_code()`, `build_ard()`, `ard_for()`, and the
  catalogs `ard_methods()` / `ard_statistics()`.  New: `ard_spec_template()`,
  `ard_spec_hash()` (was internal), and `ard_spec_code(part = "setup" /
  "body")` for a program layout of one's own.
* The catalogs have built-in defaults here; a company's own are passed as
  `statistics =` / `methods =` to the functions that use them (tflplanner
  passes its company standards), or set with
  `options(tflspec.ard_statistics =, tflspec.ard_methods =)`.
* **Listing code** moved from tflplanner too: `listing_spec_code()` writes a
  listing's program from its definition rows, and `read_data_code()` the
  lines that read a dataset of the data catalog.  The layout itself stays
  rtfreporter's (`listing_spec()`, `as_rtftables(listing = )`).
* Verified: tflplanner's generated ARD programs, report programs, listing
  code and ARD status for two studies are identical before and after the
  move (104 / 104).

# tflspec 0.0.3

* **plotplanner is now tflspec.** The repository and package were renamed
  when the table half joined, so one package holds the Excel specifications
  for tables, listings and figures.  Options `plotplanner.*` are now
  `tflspec.*`.
* **The ARD / plan / spec family moved here from rtfreporter**
  (ichirio/rtfreporter#474, branch `feat/474-ard-experimental` at 2d608cc):
  `ard_*()`, `rtf_plan()` and the `plan_*()` verbs, `apply_plan()`,
  `table_spec()` / `read_table_spec()` / `write_table_spec()` /
  `as_table_spec()`, and `read_report_spec()` / `rtf_report()` /
  `report_path()`, together with their tests, the example workbooks
  (`inst/extdata/ard-spec/`) and their builders (`data-raw/`).  The code is
  unchanged apart from names: generated scripts now say `tflspec::`, and the
  pipe option is `tflspec.ard_pipe`.  Rounding still follows rtfreporter's
  `round_num()` and `rtfreporter.rounding`.
* A plan is a table source for rtfreporter: tflspec registers
  `as_rtftables.rtf_plan()` on rtfreporter's `as_rtftables()` generic
  (rtfreporter >= 0.8.0.9085), so `rtf_tables(doc, plan)` works as it did on
  the branch.
* Verified against the branch: the same 735 tests pass, and the five example
  reports (DM, AE, ORR, LB, PK) give byte-identical RTF, from both the plan
  code and the Excel spec.
