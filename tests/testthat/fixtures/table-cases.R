# The table cases: an rtfreporter plan each, a base plan and one more verb,
# for the round trip plan -> table spec -> workbook -> plan / code -> RTF
# (test-table-roundtrip.R) and the coverage table
# (data-raw/brushup/table_coverage.R).  Sourced into an environment where
# rtfreporter is attached; its value is the cases, each an unevaluated
# call, evaluated in that environment.

adsl <- cards::ADSL
adsl$SEX <- as.character(adsl$SEX)
adsl$TRT <- as.character(adsl$ARM)
ard <- cards::ard_stack(
  adsl, .by = TRT,
  cards::ard_continuous(
    variables = c(AGE, BMIBL),
    statistic = ~ cards::continuous_summary_fns(c("N", "mean", "sd", "median", "min", "max"))),
  cards::ard_categorical(variables = c(SEX, AGEGR1), statistic = ~ c("n", "p")),
  .total_n = TRUE)
d <- suppressMessages(normalize_ard(ard))

adae <- cards::ADAE
adae$TRT <- as.character(adae$TRTA)
adsl$TRTA <- adsl$TRT
hard <- cards::ard_stack_hierarchical(
  adae, by = TRT, variables = c(AESOC, AEDECOD), denominator = adsl,
  id = USUBJID, over_variables = TRUE)
hd <- suppressMessages(normalize_ard(hard, hierarchy = c("AESOC", "AEDECOD"),
                                     overall = "Any TEAE"))

base <- function() {
  table_plan(d, cols = "TRT", rows = c(group = "variable")) |>
    plan_cells(notes = FALSE) |>
    plan_cells(continuous = c("n" = "{N:d}", "Mean (SD)" = "{mean} ({sd})"),
               categorical = "{n:d} ({p:.1f%})")
}

list(
  base = quote(base()),
  labels = quote(base() |> plan_labels(AGE = "Age (years)", SEX = "Sex")),
  levels = quote(base() |> plan_levels(SEX = c("M", "F"))),
  digits = quote(base() |> plan_digits(2, rounding = "sas")),
  digits_var = quote(base() |> plan_digits(AGE = 2)),
  cells_by_var = quote(base() |> plan_cells(AGE = c("Median" = "{median}", "Min, Max" = "{min}, {max}"))),
  cells_na = quote(base() |> plan_cells(na = "-")),
  stub = quote(base() |> plan_stub(name = "row_label", before = TRUE)),
  stub_indent = quote(base() |> plan_stub(name = "row_label", indent = 4)),
  blanks = quote(base() |> plan_blanks(where = "between_groups", first = TRUE, last = TRUE)),
  paginate_rows = quote(base() |> plan_paginate_rows(max_rows = 6, split = "group_safe", cont_label = "(cont.)")),
  paginate_cols = quote(base() |> plan_paginate_cols(every = 2)),
  paginate_group = quote(base() |> plan_paginate_group(col = "group")),
  row_group = quote(base() |> plan_row_group(mode = "indent")),
  columns_widths = quote(base() |> plan_columns(widths = c(4, 2))),
  columns_decimal = quote(base() |> plan_columns(decimal = TRUE)),
  columns_title = quote(base() |> plan_columns(row_title = "label")),
  style = quote(base() |> plan_style(align_count_pct = TRUE, font = "Arial")),
  style_border = quote(base() |> plan_style(border = "tfl")),
  cell_style = quote(base() |> plan_cell_style(bold = ~ TRUE)),
  cell_style_cols = quote(base() |> plan_cell_style(cols = "label", bold = TRUE)),
  cell_style_where = quote(base() |> plan_stub(name = "row_label", before = TRUE) |>
    plan_cell_style(where = ~ row_label == "Sex", bold = TRUE, background = "#EEEEEE")),
  break_before = quote(base() |> plan_paginate_rows(split = "rows", break_before = 4L)),
  colpages_fit = quote(base() |> plan_paginate_cols(every = 2, fit = FALSE, allow_span_break = FALSE)),
  style_border_obj = quote(base() |> plan_style(border = rtf_border(top = TRUE))),
  col_header = quote(base() |> plan_col_header(values = list(n = TRUE),
    rtf_col_header(c("", "{col}"), c("Characteristic", "(N={n})")))),
  titles = quote(base() |> plan_titles("Table 14.1.1", "Demographics")),
  footnotes = quote(base() |> plan_footnotes("N: subjects in the population.")),
  titles_pages = quote(base() |> plan_titles(pages = list(c("Table 1", "Part A")))),
  sort = quote(base() |> plan_sort("-group")),
  hide = quote(base() |> plan_hide("Placebo")),
  after_decimal = quote(base() |> plan_after(function(x) set_decimal_split(x, cols = 3:5))),
  after_fun = quote(base() |> plan_after(function(x) x)),
  hier = quote(table_plan(hd, cols = "TRT", rows = c(group = "AESOC", "AEDECOD")) |>
                 plan_cells(notes = FALSE) |> plan_cells("{n:d} ({p:.1f%})")),
  hier_sort = quote(table_plan(hd, cols = "TRT", rows = c(group = "AESOC", "AEDECOD")) |>
                      plan_cells(notes = FALSE) |> plan_cells("{n:d} ({p:.1f%})") |>
                      plan_sort(".overall", "group", "-n"))
)
