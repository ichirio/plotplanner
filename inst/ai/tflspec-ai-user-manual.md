# tflspec — AI user manual

**This manual documents tflspec 0.0.24.9004** (the development version,
after release 0.0.24; with rtfreporter 0.8.2).
Check it matches what you have — `packageVersion("tflspec")`. If they
differ, trust the package, not this file, and fetch the matching copy with
`tflspec_ai_manual()`.

**Source:** <https://github.com/ichirio/tflspec>

> **How to use this file.** Attach it at the start of a chat session and say:
> *"Use this manual when writing tflspec specifications and programs."* The
> assistant then has the specification formats, the functions that turn them
> into R code, and the common traps in context.
> 日本語で質問しても構いません（本文は英語ですが、回答は質問の言語で返ります）。

> **Scope: *using* tflspec** — writing specifications (Excel workbooks, YAML)
> and the report programs made from them. How a table becomes RTF pages is
> rtfreporter's; attach rtfreporter's own manual
> (`rtfreporter::rtfreporter_ai_manual()`) when the task is its code.

---

## 0. Ground rules for the assistant

1. **Only call functions listed in §13**, and rtfreporter's functions from
   rtfreporter's manual. tflspec is young and almost certainly *not* in your
   training data. If a requested feature has no function, say so plainly
   instead of inventing a name or an argument.
2. **tflspec writes specifications and code; it does not draw.** The ARD
   functions (`normalize_ard()`, `widen_ard()` ...), the plan
   (`table_plan()`, the `plan_*()` verbs, `plan_apply()`) and the RTF
   rendering are **rtfreporter's**. A program that runs a table spec starts
   with `library(rtfreporter)`.
3. **Every tflspec function is `tfl_*`** (and `tflspec_ai_manual()`).
   `table_plan()`, the `plan_*()` verbs, `plan_apply()`, `normalize_ard()`
   are **rtfreporter's**, never `tfl_`-prefixed; there are no aliases for
   former names (§12).
4. **A specification is data.** Workbooks are read with `col_types = "text"`:
   write every cell as text; `TRUE` / `FALSE`, numbers and `|`-lists are
   parsed and checked where they are written, with an error naming the
   sheet and column.
5. **Unknown columns are errors**, never ignored — a typo in a header would
   otherwise be a setting that silently never applies. The one exception is
   a `note` column, allowed on every sheet and never read.
6. **Sheets whose name starts with `_`** (`_methods`, `_statistics`,
   `_tflplanner` ...) and `about` are notes: never read as part of the
   definition.  **Each writer writes only its spec's sheets** (a table
   spec: `study`, the seven table sheets, `about`; a report spec: `study`,
   the six report sheets, `about`; an ARD spec: its four sheets); what a
   column means is a comment on its header cell (`tfl_spec_columns()`).
   Several specs may share one workbook (`tfl_write_specs()`): each reader
   takes its own sheets and passes over the others' sheets and `study`
   keys.
7. **`output_id` is the key.** A row with a blank `output_id` is the study
   default; a report's own row replaces the default row **per sheet** (and,
   on the keyed sheets, per key).
8. Indices are 1-based (ordinary R).

---

## 1. The one workflow

```text
ADaM ──(ARD spec)──> ARD ──(table spec)──> plan ──(report spec)──> RTF
          tfl_ard_code()      tfl_table_code()       tfl_report_code()
          tfl_build_ard()     tfl_table_plan()       tfl_report()
```

Each spec can be **run** (`tfl_build_ard()`, `tfl_table_plan()`,
`tfl_report()`) or **written out as a program** (`tfl_ard_code()`,
`tfl_table_code()`, `tfl_report_code()`) from the **same** list of steps, so
the object and the program cannot disagree. The written program is what a
study keeps: it needs rtfreporter (and cards), not tflspec.

Listings (`tfl_listing_spec()` → `tfl_listing_code()` / `tfl_listing()`)
and figures (figure design YAML → `tfl_fig_design_code()`) are the same idea.

---

## 2. Copy-paste starter (complete, runnable)

```r
library(rtfreporter)
library(tflspec)

d  <- system.file("extdata", "ard-spec", package = "tflspec")
sp <- tfl_read_table_spec(c(file.path(d, "study.xlsx"),
                            file.path(d, "report.xlsx")), output_id = "DM")

# the program a study keeps: the table plan + the document
cat(tfl_table_code(sp, pipe = "|>"), sep = "\n")
cat(tfl_report_code(sp, content = "plan"), sep = "\n")

# or run it: `data` is a normalized ARD (rtfreporter::normalize_ard())
# plan <- tfl_table_plan(data, sp)
# generate_rtfreport(tfl_report(sp, plan), tfl_report_path(sp), overwrite = TRUE)
```

`tfl_table_code()` writes `plan <- table_plan(data, ...) |> plan_*(...)`;
`tfl_report_code()` writes `doc <- rtf_document(...)`,
`rtf_section(...)`, `rtf_tables(doc, plan)`.

---

## 3. Program structure

A table program written from the specs has three parts:

```r
library(rtfreporter)
# 1 DATA    make `data`: an ARD, normalized
data <- normalize_ard(ard)
# 2 TABLE   the table spec as plan verbs      (tfl_table_code())
plan <- table_plan(data, cols = "TRT01P", rows = c(group = "variable")) |>
  plan_cells(continuous = c("Mean (SD)" = "{mean} ({sd})")) |>
  plan_stub(name = "row_label", before = TRUE)
# 3 REPORT  the report spec as the document  (tfl_report_code())
doc <- rtf_document()
doc <- rtf_tables(doc, plan)
generate_rtfreport(doc, "output/DM.rtf", overwrite = TRUE)
```

The ARD comes from the ARD spec (§5): `tfl_ard_code(spec, output_id)`
writes the cards code; `tfl_build_ard()` runs it and saves one study ARD;
`tfl_ard_for(ard, output_id)` takes one output's rows.

---

## 4. Function map — what to call for what

| I want to … | Call |
|---|---|
| start an ARD spec / read / write it | `tfl_ard_spec_template()` / `tfl_read_ard_spec()` / `tfl_write_ard_spec()` |
| write the cards code of one output | `tfl_ard_code(spec, output_id)` |
| run the ARD spec, one study ARD | `tfl_build_ard(spec)`; one output's rows: `tfl_ard_for(ard, output_id)` |
| scaffold a table spec from an ARD | `tfl_table_spec_template(ard)` |
| read / write a table (+ report) spec | `tfl_read_table_spec()` / `tfl_read_report_spec()` / `tfl_write_table_spec()` / `tfl_write_report_spec()` |
| several specs in one workbook; what a column means | `tfl_write_specs(path, ard, table, report, listing)`; `tfl_spec_columns(sheet)` |
| the plan a table spec stands for | `tfl_table_plan(data, spec)` (then any rtfreporter verb: last wins) |
| the plan as code | `tfl_table_code(spec)` |
| a plan written in code, back to a workbook | `tfl_as_table_spec(plan)` |
| the document / its code / its file | `tfl_report(spec, plan)` / `tfl_report_code(spec)` / `tfl_report_path(spec)` |
| a listing's program / its pages | `tfl_listing_code(spec)` / `tfl_listing(spec, data)` |
| a figure: start / check / write the script | `tfl_fig_template()` / `tfl_check_fig_design()` / `tfl_fig_design_code()` |
| attach this manual to a chat session | `tflspec_ai_manual(file = )` |

---

## 5. ARD spec — four sheets

`tfl_ard_spec()`, `tfl_read_ard_spec()`, `tfl_write_ard_spec()`,
`tfl_ard_spec_template()`.

| Sheet | Columns | Meaning |
|---|---|---|
| `study` | `key`, `value` | `id`: the subject key (`USUBJID`); `output`: where the study ARD goes (`output/ard/ard.rds`) |
| `datasets` | `dataset`, `level`, `path`, `derive` | a name for the data, its level (`SDTM` / `ADaM`), its file relative to the study folder, new columns (`NAME = R expression`, `|` between them) |
| `populations` | `population_id`, `dataset`, `where`, `derive` | an analysis set: the subjects of `dataset` for which `where` (R) holds; `derive` adds columns (`TRTA = TRT01A`) |
| `analyses` | `output_id`, `analysis_id`, `label`, `method`, `dataset`, `population_id`, `where`, `by`, `variables`, `statistics`, `formats`, `args`, `code` | one analysis a row; both ids become ARD columns |

- `method`: a keyword — `continuous`, `categorical`, `dichotomous`,
  `missing`, `hierarchical`, `max`, `subjects`, `total_n`, `proportion_ci`,
  `mean_ci`, `ttest`, `wilcox`, `chisq`, `fisher`, `custom` — or any
  `pkg::function` (`cards::`, `cardx::`). `tfl_ard_methods()` lists the
  keywords, each with a `label` (the name a person reads: "Summary
  statistics", "Counts and percents", "Nested counts (e.g. SOC / PT)" …)
  and a one-line `note`; `tfl_ard_statistics()` the statistics and their
  formats.
- `by`, `variables`, `statistics`: `|` between several.
- `formats`: `mean=xx.x | p=xx.x% | AGE:sd=xx.xx` — the `xx` part says the
  decimals only.
- `custom` takes R in `code`; `args` passes arguments to the method.

---

## 6. Table spec — sheets and columns

`tfl_table_spec()`, `tfl_read_table_spec()`, `tfl_write_table_spec()`,
`tfl_table_spec_template(ard)` (scaffolds `tables` / `variables` / `cells`
from an ARD). A workbook may be split over several files; a sheet is said
once. The `study` sheet has `key` / `value` (`rounding`: `sas` / `iec` /
`r`; `output_path`; `program_dir`).

**tables** (one row a table) — the roles and the table-wide layers:

| Column | Goes to | Notes |
|---|---|---|
| `cols` | `table_plan(cols = )` | column keys, outermost first: `TR01AG1 \| SEROSTAT` |
| `rows` | `table_plan(rows = )` | `name = column`; a quoted value is a constant heading |
| `label` | `table_plan(label = )` | blank keeps `.label`; `NA` builds then drops; `NULL` leaves out |
| `stats`, `value`, `na` | `plan_cells()` | `stats = rows`: one statistic a row |
| `sep` | `plan_columns(sep = )` | what joins several column keys into a column name (default `____`) |
| `sort` | `plan_sort()` | `TRUE`, `FALSE`, or keys in order, `-` for descending |
| `sort_stat` | `plan_sort(stat = )` | the statistic totalled for a frequency order |
| `header_n` | `plan_col_header(values = list(n = ))` | `page`, `table`, or `n = page \| N = table` |

**variables**: `variable`, `label`, `order`, `levels` (`Grade 0 | Grade 1`)
→ `plan_labels()`, `plan_levels()`.

**cells**: `variable`, `context`, `row`, `when`, `template`, `digits`,
`signif` → `plan_cells()`. Rows with the same variable / context / row are
one chain tried in order; `when` is an R guard (`n == 0`). A row with **no
template** in a `stats = rows` table is one statistic's digits →
`plan_digits(.rows = c(Mean = 2, SD = "3s"))` (`"3s"` = 3 significant).

**layout** (one row a table; prefix = verb, suffix = argument):

| Columns | Verb |
|---|---|
| `pages_max_rows`, `pages_split`, `pages_min_group_rows`, `pages_cont_label` | `plan_paginate_rows()` |
| `group_mode`, `group_collapse` | `plan_row_group()` |
| `group_page`, `group_col`, `group_keep` | `plan_paginate_group(col, keep)` — one page per value |
| `blank_where`, `blank_first`, `blank_last`, `blank_counted` | `plan_blanks()` |
| `stub_vars`, `stub_name`, `stub_indent`, `stub_summary`, `stub_before` | `plan_stub()` |
| `colpages_every`, `colpages_at`, `colpages_keep`, `colpages_order` | `plan_paginate_cols()` |

**columns** (one row a printed column, by name; `.values` = every value
column): `column`, `width`, `row_title`, `decimal_split`, `hide` →
`plan_columns(widths, row_title, decimal)`, `plan_hide()`.

**style** (one row a table): `plan_style()`'s arguments — `border`,
`align_count_pct`, `font`, `font_size_half_points`, `row_height_twips`,
`row_height_exact`, `header_row_height_twips`, `blank_row_height_twips`,
`cell_padding_left_twips`, `cell_padding_right_twips`, `cell_valign`,
`table_align`, `markup`, `blank_row_normalize`, and one kind of row's rules
`border_header` … `border_last_row` written as sides (`top | bottom`) or
`none`; plus `auto_width` (→ `plan_columns()`).

**col_header** (one row a header cell): `line`, `cols` (a name, `.values`,
a position or range `3:last`, or `KEY = value`), `span` (blank: one cell;
`each`: one per column; a key: one per value), `text` (tokens `{col}`,
`{col1}`, `{n}`, `{n1}`, `{n:sum}`), `align`, `bold`, `border_top`,
`border_bottom` → `plan_col_header(header = )`.

`tfl_as_table_spec(plan)` writes a plan back as a workbook and lists what a
sheet cannot say (`attr(, "not_converted")`) — `plan_cell_style()`,
`plan_after()` steps, guarded labels stay in code.

---

## 7. Report spec — the document

`tfl_read_report_spec()` reads the table sheets **and** these; `tfl_report()`
runs them, `tfl_report_code()` writes them, `tfl_report_path()` gives the
file.

| Sheet | Columns |
|---|---|
| `report` | `type` (`table` / `listing` / `figure`), `file` (`{output_id}.rtf`), `program`, `auto_section`, `section_align`, `auto_title`, `title_align`, `table_font_size`, `title_font_size`, `footnote_font_size`, `page_header`, `page_footer` |
| `page` | `paper_size`, `orientation`, `width_in`, `height_in`, margins `margin_*_in`, `header_dist_in`, `footer_dist_in`, `font_size_half_points`, `title_format`, `footnote_format`, `title_width`, `footnote_width`, `markup` |
| `header`, `footer`, `titles`, `footnotes` | `line`, `left`, `center`, `right` — a report's line replaces the default line of the same number |

Page tokens in the running header / footer: `{PAGE}`, `{TOTAL_PAGES}`,
`{PROGRAM}`, `{DATETIME}`.

---

## 8. Listing spec

`tfl_listing_spec()`, `tfl_read_listing_spec()`, `tfl_write_listing_spec()`;
`tfl_listing_code()` writes the program, `tfl_listing()` makes the pages.

| Sheet | Columns |
|---|---|
| `listings` (one row a listing) | `output_id`, `type` (`multiline`), `dataset`, `where` (R), `sort` (`-` for descending), `max_rows` |
| `listing_cols` (one row a column) | `output_id`, `vars` (`|` stacks variables in one column), `label`, `width`, `collapse_repeats` |

Layout on the page is rtfreporter's `listing_spec()` / `as_rtftables()`.
`tfl_read_data_code(datasets, dataset)` writes the line that reads a
dataset of the data catalog (`.rds`, `.xpt`, `.sas7bdat`, `.csv`,
`.parquet`).

---

## 9. Figure design (YAML)

`tfl_fig_design()`, `tfl_read_fig_design()` / `tfl_write_fig_design()`
(one `.yml` a figure), `tfl_fig_design_code()` writes the ggplot2 script,
`tfl_check_fig_design()` / `tfl_fig_advice()` check it, `tfl_fig_template()`
starts one (`tfl_fig_templates()` lists 38, each with its `category` --
the clinical category of `tfl_fig_catalog()` -- and the `data` it reads:
`"ADTR + ADRS"` both, `"ADLB / ADVS + ADSL"` one of ADLB / ADVS and ADSL),
`tfl_fig_parts()` lists every piece and field.

```yaml
template: km_risk_table
data:                                   # ADaM -> df
- {step: read, dataset: ADTTE}
- {step: param, value: OS}
- {step: flag, variable: FASFL}
stats:                                  # computed from df
- {step: survfit, name: fit, time: AVAL, censor: CNSR, by: TRT01A}
plot: {x_label: Time (Months), colour_by: TRT01A, legend: inside}
layers:                                 # what is drawn, in order
- {layer: km_curve}
- {layer: risk_table}
```

- `data` steps: `read`, `join`, `param`, `flag`, `filter`, `derive`,
  `time_unit`, `levels`, `rank`, `data_code`.
- `layers`: catalog layers (`line`, `point`, `errorbar`, `boxplot` … see
  `tfl_fig_add_layer()`), `geom` (any geom by name), `call` (any function:
  `fn`, `package`, `data`, `aes`, `pos`, `args`), `layer_code`, `figure`.
- `plot.add`: `call`s written after the figure's settings (`theme()`,
  `scale_*()`, `facet_*()`, `labs()` …).
- Raw R inside a value is the `!r` tag: `labels: !r scales::label_number()`
  (`tfl_fig_r()` in R).
- Composed figures: `plots:` (name → a whole design) and `compose:`
  (`layout: km | box`, `add:` patchwork calls).
- `ggplot2_version: "3.5"` or `"4.0"` writes the script for that version
  (`tfl_fig_compat()` lists the differences); `tfl_fig_calls()` lists
  extension functions offered by name.

The older sheet-based figure spec (`tfl_fig_spec()`, `tfl_fig_code()`,
`tfl_fig_km()`, `tfl_fig_waterfall()` …) and the quick figure functions
remain; new work should use the design.

---

## 10. What the written code looks like — the plan

The plan is rtfreporter's (its manual §17). In its words: `table_plan()`
declares the **roles** once; each `plan_*()` **verb** adds a layer; a later
layer **wins** (last wins), which is why a verb piped after
`tfl_table_plan(data, spec)` changes one report without touching the
workbook; nothing runs until `plan_apply()` (or `rtf_tables(doc, plan)`),
and `plan_apply(plan, stage = "args")` shows the calls it amounts to.

- Tables: `table_plan()` takes **only the roles** — `cols`, `rows`,
  `label`, `stat`. Everything else is a verb: `plan_cells(stats =, value =,
  na =, notes =)`, `plan_sort(stat =)`, `plan_columns(widths =, sep =,
  row_title =, decimal =, auto_width =)`, `plan_col_header(header =,
  values =)`, `plan_digits(.rows =)`, `plan_stub(name =)`,
  `plan_paginate_group(col =, keep =)`, `plan_paginate_cols(keep =)`,
  `plan_cell_style(cols =, header =, where =, bold = …)`.
- `rtf_tables(doc, plan)` takes a plan directly; `plan_apply(plan, "args")`
  shows the calls it amounts to.
- Programs are written unqualified (`table_plan()`, not
  `rtfreporter::table_plan()`), so they need `library(rtfreporter)`.

---

## 11. Composing with tflplanner

tflplanner is the GUI over these specs (one study folder: `spec/`,
`programs/`, `output/`). What it saves is these workbooks and YAML files;
anything written here can be opened there.

---

## 12. Names that do NOT exist

| Wrong | Right |
|---|---|
| `tfl_table_plan_*()`, `tfl_plan_digits()` … | rtfreporter's `plan_*()` verbs, piped after `tfl_table_plan()` |
| `tflspec::table_plan()`, `tflspec::plan_apply()` | `rtfreporter::table_plan()`, `rtfreporter::plan_apply()` (or bare, after `library(rtfreporter)`) |
| `tfl_read_spec()`, `tfl_spec()` | `tfl_read_table_spec()` / `tfl_read_report_spec()` / `tfl_read_ard_spec()` / `tfl_read_listing_spec()`, by kind |
| `tfl_fig_design_write()`, `tfl_write_fig_yaml()` | `tfl_write_fig_design()` |
| `tfl_ard_normalize()`, `tfl_plan()`, `tfl_plan_*()`, `tfl_apply_plan()` | rtfreporter's `normalize_ard()`, `table_plan()`, `plan_*()`, `plan_apply()` |
| `spread_ard()`, `plan_fmt()`, `plan_header_style()` / `plan_col_style()` / `plan_zone_style()` | `widen_ard()`, `plan_digits(.rows = )`, `plan_cell_style()` |
| `table_plan(stats =, value =, na =, notes =, sort_stat =, sep =)` | `plan_cells()`, `plan_sort(stat =)`, `plan_columns(sep =)` |
| `plan_stub(into =)`, `show = FALSE`, `plan_col_header(n =)`, `plan_paginate_cols(carry =)` | `name =`, `keep = FALSE`, `values = list(n = )`, `keep =` |
| layout `stub_into`, `group_show`, `colpages_carry`, `pages_by` | `stub_name`, `group_keep`, `colpages_keep`, `group_page = TRUE` + `group_col` |

A workbook with a former column is refused with the column to write instead.
With `sep = "_"`, a key value may not contain `_` (it could not be split
back): rename the value or choose another separator.

---

## 13. Complete public API (nothing outside this list exists)

**Manual:** `tflspec_ai_manual`

**ARD spec:** `tfl_ard_spec` `tfl_read_ard_spec` `tfl_write_ard_spec`
`tfl_ard_spec_template` `tfl_ard_code` `tfl_build_ard` `tfl_ard_for`
`tfl_ard_spec_hash` `tfl_ard_methods` `tfl_ard_statistics`

**Table spec:** `tfl_table_spec` `tfl_read_table_spec` `tfl_write_table_spec`
`tfl_write_report_spec` `tfl_write_specs` `tfl_spec_columns`
`tfl_table_spec_template` `tfl_table_plan` `tfl_table_code`
`tfl_as_table_spec`

**Report spec:** `tfl_read_report_spec` `tfl_report` `tfl_report_code`
`tfl_report_path`

**Listing spec:** `tfl_listing_spec` `tfl_read_listing_spec`
`tfl_write_listing_spec` `tfl_listing` `tfl_listing_code`
`tfl_read_data_code`

**Figure design:** `tfl_fig_design` `tfl_read_fig_design`
`tfl_write_fig_design` `tfl_fig_design_code` `tfl_check_fig_design`
`tfl_fig_advice` `tfl_fig_apply_fix` `tfl_fig_template` `tfl_fig_templates`
`tfl_fig_parts` `tfl_fig_add_layer` `tfl_fig_calls` `tfl_fig_compat`
`tfl_fig_r`

**Figure style:** `tfl_fig_style` `tfl_fig_style_template`
`tfl_read_fig_style` `tfl_fig_setup_code` `tfl_fig_palettes`
`tfl_check_fig`

**Figure spec (sheets) and quick figures:** `tfl_fig_spec`
`tfl_fig_spec_template` `tfl_read_fig_spec` `tfl_check_fig_spec`
`tfl_example_fig_spec` `tfl_fig_code` `tfl_write_fig_code` `tfl_fig_schema`
`tfl_fig_types` `tfl_fig_catalog` `tfl_fig_list_template`
`tfl_fig_list_code` `tfl_fig_km` `tfl_fig_waterfall` `tfl_fig_swimmer`
`tfl_fig_forest` `tfl_fig_mean` `tfl_fig_box` `tfl_fig_bar`
`tfl_fig_scatter` `tfl_fig_individual` `tfl_fig_pk` `tfl_fig_ae_dot`
`tfl_fig_butterfly` `tfl_fig_edish` `tfl_fig_sankey` `tfl_fig_sunburst`

**Sankey / sunburst:** `tfl_plot_sankey` `tfl_plot_sankey_batch`
`tfl_sankey_data` `tfl_plot_sunburst` `tfl_sunburst_data`

**Data:** `tfl_read_adam` `tfl_example_adam`

---

## 14. Troubleshooting

| Message | Cause | Fix |
|---|---|---|
| `The \`layout\` sheet has a column it does not read: 'stub_into' (renamed \`stub_name\`)` | a workbook from before 0.0.24 | rename the column as the message says (§12) |
| `tfl_table_plan(): 'notes' is not a role` | table-wide options passed to `tfl_table_plan()` | pipe into the verb: `plan_cells(notes = FALSE)` |
| `could not find function "table_plan"` | the program did not attach rtfreporter | `library(rtfreporter)` first |
| `... has a value containing the key separator "_"` | `sep = "_"` and a key value with `_` | rename the value, or `plan_columns(sep = )` / `tables$sep` |
| `The sheet X has rows in both a.xlsx and b.xlsx` | a sheet said in two workbooks | keep its rows in one |
| a header prints `N=NA` with a warning | the ARD does not state that population | add it to the ARD (`cards::ard_total_n()` …) or give `plan_col_header(values = list(n = ...))` |
