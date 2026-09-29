# Tests for the DEFERRED, LAST-WINS plan spike (#474).
# This whole file belongs to R/ard-plan-spike.R and is deleted with it.

skip_if_no_cards2 <- function() testthat::skip_if_not_installed("cards")

# Flattening is RUN before the plan now, so that tfl_plan()'s roles
# name columns that exist.  This keeps the tests to one line.
nz <- function(x) {
  if (identical(tflspec:::.plan_source_kind(x), "ard"))
    suppressMessages(tfl_ard_normalize(x)) else x
}

plan_ard <- function() {
  adsl <- cards::ADSL
  adsl$SEX <- as.character(adsl$SEX)
  adsl$TRT <- as.character(adsl$ARM)
  cards::ard_stack(
    adsl, .by = TRT,
    cards::ard_continuous(
      variables = c(AGE, BMIBL),
      statistic = ~ cards::continuous_summary_fns(c("N", "mean", "sd"))),
    cards::ard_categorical(variables = SEX, statistic = ~ c("n", "p")),
    .total_n = TRUE)
}

base_plan <- function(ard = plan_ard()) {
  tfl_plan(nz(ard), cols = "TRT", rows = c(group = "variable")) |>
    tfl_plan_cells(continuous  = c("n"         = "{N:d}",
                               "Mean (SD)" = "{mean} ({sd})"),
               categorical = "{n:d} ({p:.1f%})")
}

# --------------------------------------------------------------- the rule

test_that("a later layer wins, which is the whole point", {
  skip_if_no_cards2()
  p <- base_plan() |> tfl_plan_digits(2) |> tfl_plan_digits(AGE = 0)
  cells <- tfl_apply_plan(p, "args")$spread$cells

  # set everything, then fix one variable -- a two-line edit
  expect_match(cells$AGE[["Mean (SD)"]], "{mean:.0f} ({sd:.0f})", fixed = TRUE)
  expect_match(cells$BMIBL[["Mean (SD)"]], "{mean:.2f} ({sd:.2f})",
               fixed = TRUE)
})

test_that("last wins for the same key too, not just for a narrower one", {
  skip_if_no_cards2()
  p <- base_plan() |> tfl_plan_digits(2) |> tfl_plan_digits(AGE = 0) |>
    tfl_plan_digits(AGE = 3)
  expect_match(tfl_apply_plan(p, "args")$spread$cells$AGE[["Mean (SD)"]],
               "{mean:.3f}", fixed = TRUE)
})

test_that("a later tfl_plan_cells() replaces an earlier entry for that key", {
  skip_if_no_cards2()
  p <- base_plan() |> tfl_plan_cells(continuous = c("n" = "{N:d}"))
  ent <- tfl_apply_plan(p, "args")$spread$cells$continuous
  expect_length(ent, 1L)
  expect_identical(unname(ent), "{N:d}")
})

test_that("levels and labels merge one name at a time", {
  skip_if_no_cards2()
  p <- base_plan() |>
    tfl_plan_levels(TRT = c("Placebo", "Xanomeline Low Dose",
                        "Xanomeline High Dose")) |>
    tfl_plan_levels(SEX = c("M", "F"))          # adds, does not replace
  lv <- tfl_apply_plan(p, "args")$spread$levels
  expect_setequal(names(lv), c("TRT", "SEX"))
  expect_identical(lv$SEX, c("M", "F"))
})

test_that("one key restated is replaced, not merged into", {
  skip_if_no_cards2()
  p <- base_plan() |> tfl_plan_levels(SEX = c("M", "F")) |>
    tfl_plan_levels(SEX = c("F", "M"))
  expect_identical(tfl_apply_plan(p, "args")$spread$levels$SEX, c("F", "M"))
})

test_that("a map can be handed over whole, not taken apart", {
  skip_if_no_cards2()
  lab <- c(AGE = "Age (years)", SEX = "Sex")
  p <- base_plan() |> tfl_plan_labels(lab)
  expect_identical(unlist(tfl_apply_plan(p, "args")$spread$labels), lab)
})

# ------------------------------------------------------------ the digits

test_that("a token that states its own digits keeps them", {
  skip_if_no_cards2()
  p <- tfl_plan(nz(plan_ard()), cols = "TRT", rows = c(group = "variable")) |>
    tfl_plan_cells(continuous = c("Mean (SD)" = "{mean:.4f} ({sd})")) |>
    tfl_plan_digits(1)
  ent <- tfl_apply_plan(p, "args")$spread$cells$AGE
  expect_match(ent[["Mean (SD)"]], "{mean:.4f} ({sd:.1f})", fixed = TRUE)
})

test_that("`{p:%}` with no digits declared says what to do about it", {
  skip_if_no_cards2()
  p <- tfl_plan(nz(plan_ard()), cols = "TRT", rows = c(group = "variable")) |>
    tfl_plan_cells(categorical = "{n:d} ({p:%})")
  expect_error(tfl_apply_plan(p, "args"), "asks the plan for its digits")
  expect_error(tfl_apply_plan(p, "args"), "tfl_plan_digits")
})

test_that("digits pick by specificity once last-wins has had its say", {
  skip_if_no_cards2()
  # `continuous` is a kind, `AGE` is a variable: the variable is narrower
  p <- tfl_plan(nz(plan_ard()), cols = "TRT", rows = c(group = "variable")) |>
    tfl_plan_cells(continuous  = c("Mean (SD)" = "{mean} ({sd})"),
               categorical = "{n:d} ({p:%})") |>
    tfl_plan_digits(continuous = 2) |> tfl_plan_digits(AGE = 0) |>
    tfl_plan_digits(SEX = 1)
  cells <- tfl_apply_plan(p, "args")$spread$cells
  expect_match(cells$BMIBL[["Mean (SD)"]], "{mean:.2f}", fixed = TRUE)
  expect_match(cells$AGE[["Mean (SD)"]], "{mean:.0f}", fixed = TRUE)
  expect_match(cells$SEX, "{p:.1f%}", fixed = TRUE)
})

# ----------------------------------------------------- nothing runs early

test_that("the data is held, not transformed, and nothing is run", {
  skip_if_no_cards2()
  ard <- plan_ard()
  p <- base_plan(ard) |> tfl_plan_digits(1)
  expect_identical(p$data, nz(ard))
  expect_false(is.data.frame(p$layers))
  # `args` resolves without running the conversion
  a <- tfl_apply_plan(p, "args")$spread
  expect_true(all(c("cols", "rows", "cells") %in% names(a)))
})

test_that("the plan prints its layers in the order that decides the result", {
  skip_if_no_cards2()
  out <- utils::capture.output(print(base_plan() |> tfl_plan_digits(1)))
  expect_true(any(grepl("what cols / rows / label may name", out)))
  expect_true(any(grepl("cols ", out)))
  expect_true(any(grepl("1\\. cells", out)))
  expect_true(any(grepl("2\\. digits", out)))
  expect_true(any(grepl("tfl_apply_plan", out)))
})

test_that("a plan with no layers says so rather than printing nothing", {
  skip_if_no_cards2()
  out <- utils::capture.output(print(tfl_plan(nz(plan_ard()))))
  expect_true(any(grepl("no layers", out)))
})

# ------------------------------------------- the same answer as the verbs

test_that("a plan and the immediate form agree", {
  skip_if_no_cards2()
  ard <- plan_ard()
  cells <- list(continuous  = c("n"         = "{N:d}",
                                "Mean (SD)" = "{mean:.1f} ({sd:.2f})"),
                categorical = "{n:d} ({p:.1f%})")
  direct <- suppressMessages(
    ard |> tfl_ard_normalize() |>
      tfl_ard_spread(cols = "TRT", rows = c(group = "variable"), cells = cells))
  planned <- suppressMessages(tfl_apply_plan(
    tfl_plan(nz(ard), cols = "TRT", rows = c(group = "variable")) |>
      tfl_plan_cells(continuous = cells$continuous,
                 categorical = cells$categorical)))
  expect_equal(planned, direct)
})

test_that("stage = 'long' is the frame going in", {
  skip_if_no_cards2()
  ard <- plan_ard()
  expect_equal(tfl_apply_plan(base_plan(ard), "long"), tfl_ard_normalize(ard))
})

# ----------------------------------------------------------- the seam

test_that("a plan can start from an already-normalized frame", {
  skip_if_no_cards2()
  ard <- plan_ard()
  d <- tfl_ard_normalize(ard)
  d$variable <- ifelse(d$variable == "BMIBL", "AGE", d$variable)  # a seam edit

  p <- tfl_plan(d, cols = "TRT", rows = c(group = "variable"))
  expect_identical(p$kind, "normalized")
  expect_true(any(grepl("normalized frame",
                        utils::capture.output(print(p)))))

  out <- suppressMessages(tfl_apply_plan(
    p |> tfl_plan_cells(continuous = c("n" = "{N:d}"), categorical = "{n:d}")))
  expect_true(is.data.frame(out))
})

test_that("a raw ARD is refused, with the line to write", {
  skip_if_no_cards2()
  # the roles name columns of what is handed in, so a frame that has
  # not been flattened cannot be one of them
  expect_error(tfl_plan(plan_ard()), "NORMALIZED frame")
  expect_error(tfl_plan(plan_ard()), "tfl_ard_normalize()", fixed = TRUE)
})

test_that("a role that names no column blames tfl_plan()", {
  skip_if_no_cards2()
  expect_error(tfl_plan(nz(plan_ard()), cols = "ARM"),
               "no column .ARM. in the data")
  expect_error(tfl_plan(nz(plan_ard()), cols = "TRT",
                        rows = c(g = "nope")),
               "tfl_plan(rows = )", fixed = TRUE)
})

# --------------------------------------------------------------- refusals

test_that("two unnamed values are refused", {
  skip_if_no_cards2()
  expect_error(tfl_plan_digits(tfl_plan(plan_ard()), 1, 2), "at most one unnamed")
})

test_that("the rounding family is last-wins, like every other layer", {
  skip_if_no_cards2()
  p <- base_plan() |> tfl_plan_digits(1, rounding = "sas") |> tfl_plan_digits(2, rounding = "r")
  expect_identical(tfl_apply_plan(p, "args")$spread$rounding, "r")
})

test_that("one rounding family reaches tfl_ard_spread()", {
  skip_if_no_cards2()
  p <- base_plan() |> tfl_plan_digits(1) |> tfl_plan_digits(1, rounding = "sas")
  expect_identical(tfl_apply_plan(p, "args")$spread$rounding, "sas")
})

# ------------------------------------------------- what a plan starts from

# A long summary somebody built with dplyr: keys, a statistic name and a
# value, and nothing cards ever touched.
hand_long <- function(var_col = "PARAM") {
  d <- data.frame(
    TRT       = rep(c("A", "B"), each = 6),
    PARAM     = rep(rep(c("ALT", "AST"), each = 3), 2),
    stat_name = rep(c("n", "mean", "sd"), 4),
    stat      = c(20, 31.245, 4.1, 20, 28.7, 3.92,
                  18, 33.108, 5.3, 18, 30.2, 4.44),
    stringsAsFactors = FALSE)
  names(d)[names(d) == "PARAM"] <- var_col
  d
}

test_that("the four kinds of source are told apart by their columns", {
  skip_if_no_cards2()
  kind <- tflspec:::.plan_source_kind
  expect_identical(kind(plan_ard()), "ard")
  expect_identical(kind(tfl_ard_normalize(plan_ard())), "normalized")
  expect_identical(kind(hand_long()), "long")
  expect_identical(kind(data.frame(group = "ALT", A = "31.2")), "wide")
})

test_that("a long frame nobody built with cards makes a table", {
  out <- suppressMessages(tfl_apply_plan(
    tfl_plan(nz(hand_long()), cols = "TRT", rows = c(param = "PARAM"),
                  label = c(row = "stat_name"), notes = FALSE) |>
      tfl_plan_cells(c("n" = "{n:.0f}", "Mean (SD)" = "{mean} ({sd})")) |>
      tfl_plan_digits(2)))
  expect_identical(names(out), c("param", "row", "A", "B"))
  # the plan-wide digits reached a frame with no `variable` column at all
  expect_identical(out$A[out$param == "ALT" & out$row == "Mean (SD)"],
                   "31.25 (4.10)")
})

test_that("per-variable keys work once the column is called `variable`", {
  out <- suppressMessages(tfl_apply_plan(
    tfl_plan(nz(hand_long("variable")), cols = "TRT", rows = c(param = "variable"),
                  label = c(row = "stat_name"), notes = FALSE) |>
      tfl_plan_cells(c("Mean (SD)" = "{mean} ({sd})")) |>
      tfl_plan_digits(2) |> tfl_plan_digits(AST = 3)))
  expect_identical(out$A[out$param == "ALT"], "31.25 (4.10)")
  expect_identical(out$A[out$param == "AST"], "28.700 (3.920)")
})

test_that("a digits key that reached nothing is refused, not ignored", {
  p <- tfl_plan(nz(hand_long()), cols = "TRT", rows = c(param = "PARAM"),
                label = c(row = "stat_name"), notes = FALSE) |>
    tfl_plan_cells(c("Mean (SD)" = "{mean} ({sd})")) |>
    tfl_plan_digits(2) |>
    tfl_plan_digits(AST = 3)          # AST is a PARAM value, not a variable
  expect_error(tfl_apply_plan(p, "args"), "matched nothing")
  expect_error(tfl_apply_plan(p, "args"), "AST")
})

test_that("a frame that is already the table is refused at the door", {
  # the point of deferring: this is caught at tfl_plan(), not three stages
  # later inside the resolver
  # the refusal moved to resolution: a listing's source is an ordinary frame
  # too, and only tfl_plan_listing() can say which this is
  p <- tfl_plan(data.frame(group = "ALT", A = "31.2 (4.1)"))
  expect_error(tfl_apply_plan(p), "declares nothing")
  expect_error(tfl_apply_plan(p), "tfl_plan_listing")
})

test_that("tfl_ard_spread() tolerates a frame with no variable/context", {
  # it used to fail with an internal R error rather than a message
  out <- suppressMessages(tfl_ard_spread(
    hand_long(), cols = "TRT", rows = c(param = "PARAM"),
    label = c(row = "stat_name"),
    cells = c("Mean (SD)" = "{mean:.1f} ({sd:.1f})"), notes = FALSE))
  expect_identical(out$A[out$param == "ALT"], "31.2 (4.1)")
})

test_that("a missing .label says what to do instead of naming the ARD", {
  expect_error(
    tfl_ard_spread(hand_long(), cols = "TRT", rows = c(param = "PARAM"),
               cells = "{mean:.1f}"),
    "has no `.label`")
  expect_error(
    tfl_ard_spread(hand_long(), cols = "TRT", rows = c(param = "PARAM"),
               cells = "{mean:.1f}"),
    "carries the row identity")
})
# --------------------------------------------------------- the display half

disp_plan <- function(ard = plan_ard()) {
  tfl_plan(nz(ard), cols = "TRT", rows = c(group = "variable"),
                notes = FALSE) |>
    tfl_plan_cells(continuous  = c("Mean (SD)" = "{mean:.1f} ({sd:.2f})"),
               categorical = "{n:.0f} ({p:.1f%})")
}

test_that("stage = \"pages\" reaches the same rtftable as the code does", {
  skip_if_no_cards2()
  ard <- plan_ard()
  tbl <- suppressMessages(tfl_apply_plan(disp_plan(ard)))

  ref <- as_rtftables(tbl, stub_vars = c("group", "label"),
                      group_by = "indent", split = "group_safe",
                      max_rows = 22, border = "tfl")
  new <- suppressMessages(tfl_apply_plan(
    disp_plan(ard) |>
      tfl_plan_stub(vars = c("group", "label")) |>
      tfl_plan_row_group(mode = "indent") |>
      tfl_plan_paginate_rows(split = "group_safe", max_rows = 22) |>
      tfl_plan_style(border = "tfl"),
    "pages"))
  expect_equal(new, ref)
})

test_that("tfl_plan_col_header(n = ) reads the ARD and spends it", {
  skip_if_no_cards2()
  # the point of resolving them together: the denominator in the header and
  # the percentages under it come from one reading of one ARD
  new <- suppressMessages(tfl_apply_plan(
    disp_plan() |>
      tfl_plan_stub(vars = c("group", "label")) |> tfl_plan_style(border = "tfl") |>
      tfl_plan_col_header(n = function(a) tfl_ard_pull(a, cols = "TRT", variable = "AGE"),
                      header = function(n) c("Characteristic",
                                             paste0(names(n), " N=",
                                                    as.integer(n)))),
    "pages"))
  hdr <- unlist(new[[1]]$col_header)
  expect_true(any(grepl("Placebo N=86", hdr, fixed = TRUE)))
})

test_that("a literal n is taken as it is", {
  skip_if_no_cards2()
  new <- suppressMessages(tfl_apply_plan(
    disp_plan() |>
      tfl_plan_stub(vars = c("group", "label")) |>
      tfl_plan_col_header(n = 254L,
                      header = function(n) c(paste0("All (N=", n, ")"),
                                             "A", "B", "C")),
    "pages"))
  expect_true(any(grepl("All (N=254)", unlist(new[[1]]$col_header),
                        fixed = TRUE)))
})

test_that("tfl_plan_stub() folds the row keys before as_rtftables() sees them", {
  skip_if_no_cards2()
  new <- suppressMessages(tfl_apply_plan(
    disp_plan() |>
      tfl_plan_stub(vars = c("group", "label"), into = "row_label") |>
      tfl_plan_style(border = "tfl"),
    "pages"))
  expect_true("row_label" %in% names(new[[1]]$data))
})

test_that("tfl_plan_after() runs its steps on the pages, in order", {
  skip_if_no_cards2()
  seen <- character(0)
  new <- suppressMessages(tfl_apply_plan(
    disp_plan() |>
      tfl_plan_stub(vars = c("group", "label")) |>
      tfl_plan_after(function(x) { seen <<- c(seen, "one"); x },
                 function(x) { seen <<- c(seen, "two"); x }),
    "pages"))
  expect_identical(seen, c("one", "two"))
})

test_that("tfl_plan_after() refuses anything that is not a function", {
  skip_if_no_cards2()
  expect_error(tfl_plan_after(disp_plan(), "set_decimal_split"),
               "takes functions")
  expect_error(tfl_plan_after(disp_plan(), "set_decimal_split"),
               "tfl_plan_columns(decimal = )", fixed = TRUE)
})

test_that("decimal alignment is a declaration: the same pages as an after() step", {
  skip_if_no_cards2()
  p <- base_plan()
  by_step <- as_rtftables(
    tfl_plan_after(p, function(x) set_decimal_split(x, cols = 3:5)))
  by_decl <- as_rtftables(tfl_plan_columns(p, decimal = ".values"))
  expect_identical(by_decl, by_step)
  # by name, so it follows the columns wherever they go
  by_name <- as_rtftables(tfl_plan_columns(p, decimal = c("Placebo",
    "Xanomeline High Dose", "Xanomeline Low Dose")))
  expect_identical(by_name, by_step)
})

test_that("the display verbs are last-wins too", {
  skip_if_no_cards2()
  p <- disp_plan() |>
    tfl_plan_paginate_rows(max_rows = 10) |> tfl_plan_style(border = "tfl") |>
    tfl_plan_paginate_rows(max_rows = 40)          # later wins, `border` is kept
  rtf <- tflspec:::.plan_rtf_args(p)
  expect_identical(rtf$max_rows, 40)
  expect_identical(rtf$border, "tfl")
})

test_that("how far a plan goes is read off what it declares", {
  skip_if_no_cards2()
  # nothing about the display: the answer is the table data.frame
  expect_identical(.plan_reach(disp_plan()), "table")
  expect_true(is.data.frame(suppressMessages(tfl_apply_plan(disp_plan()))))

  # anything that only makes sense once there are pages moves the answer
  for (v in list(function(p) tfl_plan_style(p, border = "tfl"),
                 function(p) tfl_plan_col_header(p, c("a", "b", "c", "d")),
                 function(p) tfl_plan_cell_style(p, bold = ~ TRUE),
                 function(p) tfl_plan_after(p, identity))) {
    expect_identical(.plan_reach(v(disp_plan())), "pages")
  }

  # calling the verb IS the declaration, even with nothing in it
  expect_identical(.plan_reach(tfl_plan_style(disp_plan())), "pages")
})

test_that("a named stage still stops where it is told, for looking inside", {
  skip_if_no_cards2()
  p <- disp_plan() |> tfl_plan_stub(vars = c("group", "label"))
  expect_true(is.data.frame(suppressMessages(tfl_apply_plan(p, "table"))))
  expect_s3_class(suppressMessages(tfl_apply_plan(p, "long")), "data.frame")
  expect_true(all(c("cols", "cells") %in% names(tfl_apply_plan(p, "args")$spread)))
  expect_type(suppressMessages(tfl_apply_plan(p)), "list")
})

test_that("the plan says which of the two it will give", {
  skip_if_no_cards2()
  expect_true(any(grepl("table data.frame",
                        utils::capture.output(print(disp_plan())),
                        fixed = TRUE)))
  expect_true(any(grepl("RTF pages",
    utils::capture.output(print(tfl_plan_style(disp_plan(), border = "tfl"))),
    fixed = TRUE)))
})

test_that("rtf_tables() takes a plan, so tfl_apply_plan() is for looking", {
  skip_if_no_cards2()
  p <- disp_plan() |>
    tfl_plan_stub(vars = c("group", "label")) |> tfl_plan_style(border = "tfl")
  doc <- rtf_document() |>
    rtf_section(page = 1, secinfo = list(
      header = rtf_header(rows = list(c(c = "T"))),
      footer = rtf_footer(rows = list(c(l = "F")))))
  direct <- suppressMessages(rtf_tables(doc, p))
  byhand <- suppressMessages(rtf_tables(doc, tfl_apply_plan(p, "pages")))
  expect_equal(direct, byhand)
})
# ------------------------------------------------- conditional cell styles

styled <- function(...) {
  suppressMessages(tfl_apply_plan(
    disp_plan() |>
      tfl_plan_stub(vars = c("group", "label"), into = "row_label",
                before = TRUE) |>
      tfl_plan_cell_style(...) |>
      tfl_plan_style(border = "tfl"),
    "pages"))
}

test_that("a bare formula styles the whole row", {
  skip_if_no_cards2()
  # `group` is folded away by stub_cols(); it is put back through the
  # rtf_stub_src map so a condition can still ask about it, the way SAS's
  # compute block sees variables the report does not print
  pg <- styled(bold = ~ !is.na(group) & group == "SEX")[[1]]
  cs <- pg$cell_styles
  on <- vapply(cs, function(z) !is.null(z) && isTRUE(z$bold[[1]]), TRUE)
  expect_true(any(on))
  expect_false(all(on))
  # every column of a styled row is styled, since the formula was bare
  expect_true(all(vapply(cs[on], function(z) all(z$bold), TRUE)))
})

test_that("a heading row has no source row, so its keys read NA", {
  skip_if_no_cards2()
  pg <- styled(bold = ~ is.na(group))[[1]]
  on <- vapply(pg$cell_styles,
               function(z) !is.null(z) && isTRUE(z$bold[[1]]), TRUE)
  expect_true(any(on))
})

test_that("a named list scopes a style to one column, by NAME", {
  skip_if_no_cards2()
  pg <- styled(align = list(Placebo = ~ "right"))[[1]]
  j <- match("Placebo", names(pg$data))
  expect_false(is.na(j))
  expect_identical(pg$cell_styles[[1]]$align[[j]], "right")
  expect_true(all(is.na(pg$cell_styles[[1]]$align[-j])))
})

test_that("NA means \"leave the column default alone\"", {
  skip_if_no_cards2()
  cs <- styled(bold = ~ NA)[[1]]$cell_styles
  expect_true(all(vapply(cs, is.null, TRUE)))
})

test_that("styles are last-wins like every other layer", {
  skip_if_no_cards2()
  pg <- suppressMessages(tfl_apply_plan(
    disp_plan() |>
      tfl_plan_stub(vars = c("group", "label"), into = "row_label",
                before = TRUE) |>
      tfl_plan_cell_style(bold = ~ TRUE) |>
      tfl_plan_cell_style(bold = ~ FALSE) |>          # a later LAYER wins
      tfl_plan_style(border = "tfl"),
    "pages"))[[1]]
  expect_true(all(vapply(pg$cell_styles,
                         function(z) !any(z$bold), TRUE)))
})

test_that("the same key twice in ONE call is a typo, not a layering", {
  skip_if_no_cards2()
  expect_error(styled(bold = ~ TRUE, bold = ~ FALSE), "twice in one call")
  expect_error(tfl_plan_digits(disp_plan(), AGE = 1, AGE = 2), "twice in one call")
})

test_that("a column that is not there is named, not ignored", {
  skip_if_no_cards2()
  expect_error(styled(bold = list(NOPE = ~ TRUE)), "no printed column")
  expect_error(styled(bold = list(NOPE = ~ TRUE)), "Available")
})

test_that("a style that is not a one-sided formula is refused", {
  skip_if_no_cards2()
  expect_error(styled(bold = "yes"), "one-sided formula")
})

test_that("a condition of the wrong length is refused", {
  skip_if_no_cards2()
  expect_error(styled(bold = ~ c(TRUE, FALSE)), "values for")
})

test_that("folding the stub inside as_rtftables() is refused with a reason", {
  skip_if_no_cards2()
  # the heading rows it adds were never seen by the conditions
  p <- disp_plan() |> tfl_plan_cell_style(bold = ~ TRUE) |>
    tfl_plan_stub(vars = c("group", "label"))        # folded inside, not before
  expect_error(tfl_apply_plan(p, "pages"), "before = TRUE")
  expect_error(tfl_apply_plan(p, "pages"), "wrong row")
})

test_that("tfl_plan_cell_style() and tfl_plan_style(cell_styles=) do not both apply", {
  skip_if_no_cards2()
  p <- disp_plan() |>
    tfl_plan_stub(vars = c("group", "label"), into = "row_label",
              before = TRUE) |>
    tfl_plan_cell_style(bold = ~ TRUE) |>
    tfl_plan_style(cell_styles = list(NULL))
  expect_error(tfl_apply_plan(p, "pages"), "use one")
})
# --------------------------------------------------------- tfl_plan_template()

test_that("tfl_plan_template() writes a plan that runs to the pages", {
  skip_if_no_cards2()
  ard <- plan_ard()
  gen <- utils::capture.output(code <- tfl_plan_template(ard, cols = "TRT",
                                                     pipe = "|>"))
  expect_true(any(grepl("tfl_ard_normalize()", code, fixed = TRUE)))
  expect_true(any(grepl("tfl_plan(", code, fixed = TRUE)))
  expect_true(any(grepl("tfl_plan_cells(", code, fixed = TRUE)))
  # both halves, because a plan that stops at the table is half a plan
  expect_true(any(grepl("tfl_plan_style(", code, fixed = TRUE)))
  expect_true(any(grepl("tfl_plan_stub(", code, fixed = TRUE)))
  expect_true(any(grepl("tfl_apply_plan(p)", code, fixed = TRUE)))

  e <- new.env(); assign("ard", ard, e)
  suppressMessages(eval(parse(text = paste(code, collapse = "
")), e))
  # the template stops at the plan: rtf_tables() takes it from there
  p <- get("p", e)
  expect_s3_class(p, "tfl_plan")
  pg <- suppressMessages(tfl_apply_plan(p, "pages"))
  expect_s3_class(pg[[1]], "rtftable")
})

test_that("tfl_plan_template() derives the stub and leaves the rest to be edited", {
  skip_if_no_cards2()
  code <- utils::capture.output(
    invisible(tfl_plan_template(plan_ard(), cols = "TRT", pipe = "|>")))
  # the stub is not written at all: tfl_plan_stub() works it out from what
  # tfl_plan(rows = ) and tfl_plan_row_group() already declared
  expect_false(any(grepl("vars", code, fixed = TRUE)))
  expect_true(any(grepl("tfl_plan_stub(", code, fixed = TRUE)))
  expect_true(any(grepl("edit this", code, fixed = TRUE)))
})

test_that("tfl_plan_template() takes the pipe like tfl_ard_template() does", {
  skip_if_no_cards2()
  base <- utils::capture.output(
    invisible(tfl_plan_template(plan_ard(), cols = "TRT", pipe = "|>")))
  mag <- utils::capture.output(
    invisible(tfl_plan_template(plan_ard(), cols = "TRT", pipe = "%>%")))
  expect_false(any(grepl("%>%", base, fixed = TRUE)))
  expect_true(any(grepl("library(magrittr)", mag, fixed = TRUE)))
})

test_that("tfl_plan_template(spec = ) reads the definition file instead", {
  skip_if_no_cards2()
  code <- utils::capture.output(
    invisible(tfl_plan_template(plan_ard(), cols = "TRT", spec = TRUE,
                            pipe = "|>")))
  expect_true(any(grepl("tfl_read_table_spec", code, fixed = TRUE)))
  expect_false(any(grepl("tfl_plan_cells(", code, fixed = TRUE)))
})

test_that("the generated header writes a real newline escape", {
  skip_if_no_cards2()
  # one unambiguous denominator, so a header block is written at all
  ard <- cards::ard_stack(
    cards::ADSL, .by = ARM,
    cards::ard_continuous(variables = AGE,
                          statistic = ~ list(N = function(x) length(x))))
  code <- utils::capture.output(
    invisible(tfl_plan_template(ard, cols = "ARM", pipe = "|>")))
  expect_true(any(grepl("tfl_plan_col_header", code, fixed = TRUE)))
  # ONE backslash, not two: the generated file is R source
  one <- paste0('"', '\\', 'nN = "')
  two <- paste0('"', '\\\\', 'nN = "')
  expect_true(any(grepl(one, code, fixed = TRUE)))
  expect_false(any(grepl(two, code, fixed = TRUE)))
})

test_that("tfl_plan_template() invents no header when the N is ambiguous", {
  skip_if_no_cards2()
  # two continuous variables disagree about N, so nothing is guessed
  code <- utils::capture.output(
    invisible(tfl_plan_template(plan_ard(), cols = "TRT", pipe = "|>")))
  expect_false(any(grepl("tflspec::tfl_plan_col_header(", code, fixed = TRUE)))
  # and the pipeline still parses: the trailing pipe must have been removed
  expect_silent(parse(text = paste(code, collapse = "\n")))
})

# ------------------------------------------------- the seams, as expressions

test_that("print() names the columns of every stage it has", {
  skip_if_no_cards2()
  p <- disp_plan() |>
    tfl_plan_stub(vars = c("group", "label"), into = "row_label") |>
    tfl_plan_style(border = "tfl")

  out <- utils::capture.output(print(p))
  # the frame going in is to hand, so it is always answered
  expect_true(any(grepl("cols / rows / label may name", out,
                        fixed = TRUE)))
  expect_true(any(grepl("stat_name", out, fixed = TRUE)))
  # spreading is not, so it says so rather than costing a run
  expect_true(any(grepl("not computed yet", out, fixed = TRUE)))

  invisible(suppressMessages(tfl_apply_plan(p)))
  out2 <- utils::capture.output(print(p))
  expect_true(any(grepl("after spread", out2, fixed = TRUE)))
  expect_true(any(grepl("as printed", out2, fixed = TRUE)))
  expect_true(any(grepl("row_label", out2, fixed = TRUE)))
})

test_that("a derived plan does not inherit its parent's column cache", {
  skip_if_no_cards2()
  p <- disp_plan()
  invisible(suppressMessages(tfl_apply_plan(p)))
  expect_false(is.null(p$cache$table))
  p2 <- p |> tfl_plan_digits(3)
  expect_null(p2$cache$table)
})

# ------------------------------------------------ titles, footnotes, listings

# a listing splits on max_rows alone, which keeps these tests about the
# blocks rather than about pagination strategies
.pages_src <- function(n = 12L) {
  data.frame(USUBJID = sprintf("S-%03d", seq_len(n)),
             ARM = rep(c("A", "B"), length.out = n),
             stringsAsFactors = FALSE)
}
.pages_plan <- function(max_rows = 4L) {
  tfl_plan(.pages_src()) |>
    tfl_plan_listing(listing_col("USUBJID", width = 12)) |>
    tfl_plan_paginate_rows(max_rows = max_rows)
}

test_that("tfl_plan_titles() / tfl_plan_footnotes() ride on every page", {
  pg <- suppressMessages(tfl_apply_plan(
    .pages_plan() |>
      tfl_plan_titles("Table 14.1.1", "Demographics") |>
      tfl_plan_footnotes("Source: ADSL")))
  expect_gt(length(pg), 1L)
  for (i in seq_along(pg)) {
    expect_identical(attr(pg[[i]], "rtf_titles"),
                     c("Table 14.1.1", "Demographics"))
    expect_identical(attr(pg[[i]], "rtf_footnotes"), "Source: ADSL")
  }
})

test_that("tfl_plan_titles(pages = ) gives each page its own block", {
  base <- .pages_plan()
  n <- length(suppressMessages(tfl_apply_plan(base)))
  expect_gt(n, 1L)
  pg <- suppressMessages(tfl_apply_plan(
    base |> tfl_plan_titles(pages = as.list(paste("Part", seq_len(n))))))
  expect_identical(attr(pg[[1]], "rtf_titles"), "Part 1")
  expect_identical(attr(pg[[n]], "rtf_titles"), paste("Part", n))
})

test_that("a page count that does not match is refused, and named", {
  p <- .pages_plan() |> tfl_plan_titles(pages = list("only one"))
  expect_error(tfl_apply_plan(p), "block for")
  expect_error(tfl_apply_plan(p), "tfl_plan_titles")
})

test_that("rows and per-page blocks are not both accepted", {
  skip_if_no_cards2()
  expect_error(tfl_plan_titles(disp_plan(), "a", pages = list("b")),
               "Not both")
})

test_that("a listing goes nowhere near an ARD", {
  skip_if_no_cards2()
  d <- data.frame(USUBJID = sprintf("S-%03d", 1:12),
                  ARM = rep(c("A", "B"), 6), AGE = 40:51,
                  stringsAsFactors = FALSE)
  pg <- suppressMessages(tfl_apply_plan(
    tfl_plan(d[d$AGE >= 45, , drop = FALSE]) |>
      tfl_plan_listing(listing_col("USUBJID", width = 12),
                   listing_col("ARM", width = 10)) |>
      tfl_plan_paginate_rows(max_rows = 20) |>
      tfl_plan_style(border = "tfl") |>
      tfl_plan_titles("Listing 16.2.1")))
  expect_s3_class(pg[[1]], "rtftable")
  expect_identical(attr(pg[[1]], "rtf_titles"), "Listing 16.2.1")
  # the records went straight through: nothing normalised or spread
  tb <- suppressMessages(tfl_apply_plan(
    tfl_plan(d[d$AGE >= 45, , drop = FALSE]) |>
      tfl_plan_listing(listing_col("USUBJID")), "table"))
  expect_identical(nrow(tb), 7L)
})

test_that("a listing matches the same call written by hand", {
  skip_if_no_cards2()
  d <- data.frame(USUBJID = sprintf("S-%03d", 1:12),
                  ARM = rep(c("A", "B"), 6), stringsAsFactors = FALSE)
  spec <- listing_spec(list(listing_col("USUBJID", width = 12),
                            listing_col("ARM", width = 10)))
  ref <- as_rtftables(d, listing = spec, max_rows = 20, border = "tfl")
  new <- suppressMessages(tfl_apply_plan(
    tfl_plan(d) |>
      tfl_plan_listing(listing_col("USUBJID", width = 12),
                   listing_col("ARM", width = 10)) |>
      tfl_plan_paginate_rows(max_rows = 20) |>
      tfl_plan_style(border = "tfl")))
  expect_equal(new, ref)
})

test_that("a frame that is neither an ARD nor a listing says which to add", {
  expect_error(tfl_apply_plan(tfl_plan(data.frame(a = "x", b = "y"))),
               "tfl_plan_listing")
  expect_error(tfl_apply_plan(tfl_plan(data.frame(a = "x", b = "y"))),
               "display verbs")
})

# ------------------------------------------- the three ways in, one system

test_that("a finished table is a source for the display half alone", {
  skip_if_no_cards2()
  # pattern 2: ard_*() built the table, the plan does the rest
  ard <- plan_ard()
  tbl <- suppressMessages(
    ard |> tfl_ard_normalize() |>
      tfl_ard_spread(cols = "TRT", rows = c(group = "variable"),
                 cells = "{n:.0f}", notes = FALSE))
  ref <- as_rtftables(tbl, read_meta = FALSE,
                      stub_vars = c("group", "label"), border = "tfl")
  new <- suppressMessages(tfl_apply_plan(
    tfl_plan(tbl) |>
      tfl_plan_stub(vars = c("group", "label")) |>
      tfl_plan_style(border = "tfl")))
  expect_equal(new, ref)
})

test_that("asking for the ARD half of a finished table says what to drop", {
  skip_if_no_cards2()
  p <- tfl_plan(nz(data.frame(group = "A", x = "1")), cols = "x") |>
    tfl_plan_cells("{n}")
  expect_error(tfl_apply_plan(p), "tfl_plan_cells() need them", fixed = TRUE)
  expect_error(tfl_apply_plan(p), "keep the display")
})

test_that("tfl_plan_paginate_group(show = FALSE) hides the carrier it groups by", {
  skip_if_no_cards2()
  p <- disp_plan() |> tfl_plan_paginate_group(col = "group", show = FALSE)
  expect_identical(tflspec:::.plan_rtf_args(p)$group_col, "group")
  expect_identical(tflspec:::.plan_rtf_args(p)$drop_cols, "group")
})

test_that("hiding ADDS rather than replaces", {
  skip_if_no_cards2()
  # last-wins here would silently un-hide the first column named
  p <- disp_plan() |> tfl_plan_hide("a") |> tfl_plan_hide("b") |>
    tfl_plan_paginate_group(col = "c", show = FALSE)
  expect_setequal(tflspec:::.plan_rtf_args(p)$drop_cols, c("a", "b", "c"))
})

test_that("the verbs refuse anything that is not a plan", {
  expect_error(tfl_plan_cells(data.frame(a = 1), "x"), "Expected a tfl_plan")
  expect_error(tfl_apply_plan(data.frame(a = 1)), "Expected a tfl_plan")
  expect_error(tfl_plan(), "required")
})

# ------------------------------- a frame that never went near cards

# Columns named the way a study names them: no `variable`, no
# `stat_name`, no `stat`, and the row label in two different places
# depending on what kind of row it is.
own_frame <- function() {
  data.frame(
    TRT   = rep(c("A", "B"), each = 5L),
    PARAM = rep(c("AGE", "AGE", "AGE", "SEX", "SEX"), 2L),
    CAT   = c(NA, NA, NA, "F", "M", NA, NA, NA, "F", "M"),
    STAT  = c("N", "mean", "sd", "n", "n", "N", "mean", "sd", "n", "n"),
    VALUE = c(10, 55.5, 4.25, 6, 4, 12, 57.25, 3.5, 7, 5),
    stringsAsFactors = FALSE)
}

test_that("a frame keeps its own names, and says which plays what", {
  p <- tfl_plan(own_frame(), cols = "TRT", rows = c(group = "PARAM"),
                label = c(label = "CAT"),
                variable = "PARAM", stat_name = "STAT", stat = "VALUE",
                notes = FALSE) |>
    tfl_plan_cells(AGE = c("Mean (SD)" = "{mean} ({sd})"),
               SEX = "{n}") |>
    tfl_plan_digits(1)
  out <- suppressMessages(tfl_apply_plan(p))
  expect_true(all(c("group", "label", "A", "B") %in% names(out)))
  expect_true(any(grepl("55.5 (4.2)", out$A, fixed = TRUE)))
})

test_that("a column that is not there blames the role that named it", {
  expect_error(
    tfl_plan(own_frame(), cols = "TRT", stat_name = "PARAMCD"),
    "no column .PARAMCD. in the data")
})

test_that("`label` naming two columns coalesces them", {
  # tfrmt has the same problem: a continuous row is labelled by its
  # statistic and a categorical one by its level, and they are not the
  # same column.  First non-missing wins.
  p <- tfl_plan(own_frame(), cols = "TRT", rows = c(group = "PARAM"),
                label = list(row = c("CAT", "STAT")),
                variable = "PARAM", stat_name = "STAT", stat = "VALUE",
                notes = FALSE) |>
    tfl_plan_cells("{n}", AGE = "{mean}") |>
    tfl_plan_digits(1)
  out <- suppressMessages(tfl_apply_plan(p, "table"))
  expect_true("row" %in% names(out))
  # the categorical rows took CAT, the continuous ones fell back to STAT
  expect_true(all(c("F", "M") %in% out$row))
  expect_true(any(c("N", "mean", "sd") %in% out$row))
})

# -------------------------------------------------------- the row order

test_that("tfl_plan_sort() goes to the ARD half, where the statistics are", {
  skip_if_no_cards2()
  p <- base_plan() |> tfl_plan_sort(".overall", "group", "-n")
  a <- tfl_apply_plan(p, "args")$spread
  expect_identical(a$sort, c(".overall", "group", "-n"))
  # and nothing reaches as_rtftables(), which could not sort on `-n`:
  # by then the statistic is a formatted cell, not a number
  r <- tflspec:::.plan_rtf_args(p)
  expect_null(r$sort_by)
})

test_that("tfl_plan_sort() over a finished table sorts the table", {
  d <- data.frame(group = c("B", "A"), x = c("1", "2"),
                  stringsAsFactors = FALSE)
  p <- tfl_plan(d) |> tfl_plan_sort("group") |> tfl_plan_paginate_rows(max_rows = 10)
  r <- tflspec:::.plan_rtf_args(p)
  expect_identical(r$sort_by, "group")
  out <- suppressMessages(tfl_apply_plan(p))
  first <- if (inherits(out, "rtftable")) out else out[[1L]]
  expect_identical(first$data$group[1L], "A")
})

test_that("sorting alone does not turn a table into RTF pages", {
  skip_if_no_cards2()
  p <- base_plan() |> tfl_plan_sort("group")
  expect_true(is.data.frame(suppressMessages(tfl_apply_plan(p))))
})


# ------------------------------------ needed and not wanted, said once

test_that("the spread builds only what the roles named", {
  skip_if_no_cards2()
  # there is nothing to drop, because nothing unasked-for is built: a
  # column is a row key, the label, or a spread column
  out <- suppressMessages(tfl_apply_plan(base_plan(), "table"))
  keys <- c("group", "label")
  arms <- setdiff(names(out), keys)
  expect_setequal(intersect(names(out), keys), keys)
  expect_true(all(grepl("Placebo|Xanomeline", arms)))
})

test_that("tfl_plan_paginate_rows(show = FALSE) hides the key the break reads", {
  skip_if_no_cards2()
  d <- nz(plan_ard())
  d$pg <- ifelse(d$variable == "SEX", "1", "2")
  p <- tfl_plan(d, cols = "TRT",
                rows = c(group = "variable",
                         pg = "pg")) |>
    tfl_plan_cells(continuous = c(n = "{N:d}"),
               categorical = "{n:d}") |>
    tfl_plan_paginate_rows(split = "by_value", by = "pg", show = FALSE)
  out <- suppressMessages(tfl_apply_plan(p))
  first <- if (inherits(out, "rtftable")) out else out[[1L]]
  expect_false("pg" %in% names(first$data))
  expect_gt(length(out), 1L)          # it really did break on it
})

test_that("tfl_plan_sort(show = FALSE) hides a sort carrier, and only it", {
  d <- data.frame(ord = c("2", "1"), label = c("B", "A"),
                  x = c("9", "8"), stringsAsFactors = FALSE)
  p <- tfl_plan(d) |> tfl_plan_sort("ord", show = FALSE) |>
    tfl_plan_paginate_rows(max_rows = 10)
  out <- suppressMessages(tfl_apply_plan(p))
  first <- if (inherits(out, "rtftable")) out else out[[1L]]
  expect_false("ord" %in% names(first$data))
  expect_identical(first$data$label[1L], "A")
})

test_that("a sort key that is not a column is not mistaken for one", {
  skip_if_no_cards2()
  # ".overall" and "-n" are instructions, not columns: hiding must not
  # try to drop them
  p <- base_plan() |> tfl_plan_sort(".overall", "group", "-n", show = FALSE) |>
    tfl_plan_paginate_rows(max_rows = 40)
  out <- suppressMessages(tfl_apply_plan(p))
  first <- if (inherits(out, "rtftable")) out else out[[1L]]
  expect_false("group" %in% names(first$data))
  expect_true("label" %in% names(first$data))
})

test_that("tfl_plan_paginate_cols() is the column axis, without a lambda", {
  skip_if_no_cards2()
  p <- disp_plan() |> tfl_plan_paginate_rows(max_rows = 40) |>
    tfl_plan_paginate_cols(at = 4L, carry = 1:2, width = "keep")
  out <- suppressMessages(tfl_apply_plan(p))
  expect_gt(length(out), 1L)
  # every block repeats the carried column
  expect_true(all(vapply(out, function(z) names(z$data)[1L], "") ==
                  names(out[[1L]]$data)[1L]))
})

test_that("a house style is an ordinary function, not a plan without data", {
  skip_if_no_cards2()
  house <- function(d) {
    tfl_plan(d, cols = "TRT", rows = c(group = "variable"),
             notes = FALSE) |>
      tfl_plan_cells(continuous = c(n = "{N:d}"), categorical = "{n:d}") |>
      tfl_plan_digits(1)
  }
  a <- suppressMessages(tfl_apply_plan(house(nz(plan_ard()))))
  b <- suppressMessages(tfl_apply_plan(house(nz(plan_ard())) |>
                                     tfl_plan_digits(3)))
  expect_identical(names(a), names(b))
  expect_true(is.data.frame(a))
  # and a plan cannot be built without the data the roles name
  expect_error(tfl_plan(cols = "TRT"), "`data` is required")
  expect_error(tfl_plan(cols = "TRT"), "ordinary function")
})


test_that("tfl_plan_paginate_group() is the group axis", {
  skip_if_no_cards2()
  p <- disp_plan() |> tfl_plan_paginate_group(col = "group")
  r <- tflspec:::.plan_rtf_args(p)
  expect_identical(r$split, "by_value")
  expect_identical(r$group_col, "group")
  out <- suppressMessages(tfl_apply_plan(p))
  expect_gt(length(out), 1L)          # one page per group value
})

test_that("two verbs asking for different splits is a mistake", {
  skip_if_no_cards2()
  p <- disp_plan() |> tfl_plan_paginate_group(col = "group") |>
    tfl_plan_paginate_rows(split = "group_safe", max_rows = 5)
  expect_error(suppressMessages(tfl_apply_plan(p)), "Use one", fixed = TRUE)
})


test_that("tfl_plan_paginate_group() is what auto_section cuts on", {
  skip_if_no_cards2()
  # a value split NAMES each page by its group value, and
  # rtf_tables(auto_section = TRUE) opens a section where the name changes
  p <- disp_plan() |>
    tfl_plan_paginate_group(col = "group", show = FALSE)
  pg <- suppressMessages(tfl_apply_plan(p))
  expect_setequal(names(pg), c("AGE", "BMIBL", "SEX"))

  doc <- rtf_document() |>
    rtf_section(page = 1, secinfo = list(header = NULL, footer = NULL)) |>
    rtf_tables(p, auto_section = TRUE)
  items <- Filter(function(x) inherits(x, "rtf_auto_section_item"),
                  doc$contents)
  expect_length(items, 3L)
  expect_setequal(vapply(items, function(x) x$label, ""),
                  c("AGE", "BMIBL", "SEX"))
})


# ------------------------------------ the header without a function

test_that("a header cell may carry {col} and {n}", {
  skip_if_no_cards2()
  p <- disp_plan() |>
    tfl_plan_col_header(n = c(Placebo = 86, "Xanomeline High Dose" = 84,
                          "Xanomeline Low Dose" = 84), rtf_col_header(
      c("",               "{col}"),
      c("Characteristic", "(N={n})")))
  out <- suppressMessages(tfl_apply_plan(p))
  first <- if (inherits(out, "rtftable")) out else out[[1L]]
  rows <- first$col_header$rows %||% first$col_header
  txt <- unlist(lapply(rows, function(r)
    vapply(r, function(z) if (is.list(z)) z$text %||% "" else
      as.character(z), "")))
  expect_true(any(grepl("Characteristic", txt, fixed = TRUE)))
  expect_true(any(grepl("(N=", txt, fixed = TRUE)))
  # the arm name came from the table, not from the author
  expect_true(any(grepl("Placebo", txt, fixed = TRUE)))
})

test_that("an rtf_col_header() goes through untouched, positionally", {
  skip_if_no_cards2()
  h <- rtf_col_header(c("Group", "Characteristic", "A", "B", "C"))
  a <- suppressMessages(tfl_apply_plan(disp_plan() |> tfl_plan_col_header(h)))
  b <- suppressMessages(tfl_apply_plan(disp_plan() |>
                                     tfl_plan_col_header(header = h)))
  expect_equal(a, b)
})

test_that("a row already the right length is left alone", {
  skip_if_no_cards2()
  # five columns, five cells: nothing to repeat and no token to fill
  h <- rtf_col_header(c("Group", "Characteristic", "A", "B", "C"))
  out <- suppressMessages(tfl_apply_plan(disp_plan() |>
                                       tfl_plan_col_header(h)))
  first <- if (inherits(out, "rtftable")) out else out[[1L]]
  expect_true(any(grepl("Characteristic", unlist(first$col_header),
                        fixed = TRUE)))
})

test_that("{n} in a spanner takes the one value there is", {
  skip_if_no_cards2()
  h <- rtf_col_header(
    list(col_cell(1L, "Group"), col_cell(2L, "Characteristic"),
         col_cell(c(3L, 5L), "All arms (N={n})")),
    c("", "", "{col}"))
  out <- suppressMessages(tfl_apply_plan(
    disp_plan() |> tfl_plan_col_header(n = 254, h)))
  first <- if (inherits(out, "rtftable")) out else out[[1L]]
  txt <- unlist(lapply(first$col_header, function(r)
    vapply(r, function(z) if (is.list(z)) as.character(z$label) else
      as.character(z), "")))
  expect_true(any(grepl("All arms (N=254)", txt, fixed = TRUE)))
  expect_true(any(grepl("Placebo", txt, fixed = TRUE)))
})


test_that("{col} is the LEAF, and {col1}/{col2} are the levels", {
  skip_if_no_cards2()
  # two `cols` keys make a name like "Placebo____F", which nobody wants
  # printed; the hierarchy itself is built by as_rtftables(header_sep = )
  d <- nz(plan_ard())
  p <- tfl_plan(d, cols = c("TRT", "variable"),
                rows = c(group = "variable"), notes = FALSE) |>
    tfl_plan_cells(continuous = c(n = "{N:d}"), categorical = "{n:d}") |>
    tfl_plan_paginate_rows(max_rows = 40) |>
    tfl_plan_col_header(n = 42, rtf_col_header(
      c("", "{col1}"),
      c("Characteristic", "{col2} (N={n})")))
  out <- suppressMessages(tfl_apply_plan(p))
  first <- if (inherits(out, "rtftable")) out else out[[1L]]
  txt <- unlist(first$col_header)
  expect_false(any(grepl("____", txt, fixed = TRUE)))
  expect_true(any(grepl("Placebo", txt, fixed = TRUE)))
  expect_true(any(grepl("(N=42)", txt, fixed = TRUE)))
})

test_that("with one key the leaf is the whole name", {
  skip_if_no_cards2()
  out <- suppressMessages(tfl_apply_plan(
    disp_plan() |> tfl_plan_col_header(rtf_col_header(c("Term", "{col}")))))
  first <- if (inherits(out, "rtftable")) out else out[[1L]]
  expect_true(any(grepl("Placebo", unlist(first$col_header),
                        fixed = TRUE)))
})


# ------------------------------------------ digits, per statistic

open_plan <- function() {
  tfl_plan(nz(plan_ard()), cols = "TRT", rows = c(group = "variable"),
           notes = FALSE) |>
    tfl_plan_cells(continuous  = c("n"         = "{N:.0f}",
                               "Mean (SD)" = "{mean} ({sd})"),
               categorical = "{n:.0f} ({p:%})")
}

test_that("digits can be stated per statistic, not just per variable", {
  skip_if_no_cards2()
  p <- open_plan() |>
    tfl_plan_digits(c(mean = 2, sd = 3, p = 1)) |>
    tfl_plan_digits(AGE = c(mean = 1, sd = 2))
  cells <- tfl_apply_plan(p, "args")$spread$cells
  expect_match(cells$AGE[["Mean (SD)"]], "{mean:.1f} ({sd:.2f})",
               fixed = TRUE)
  expect_match(cells$BMIBL[["Mean (SD)"]], "{mean:.2f} ({sd:.3f})",
               fixed = TRUE)
})

test_that("a statistic the narrower rule skips falls through", {
  skip_if_no_cards2()
  # AGE says nothing about `sd`, so the house rule answers for it
  p <- open_plan() |>
    tfl_plan_digits(c(mean = 2, sd = 3, p = 1)) |>
    tfl_plan_digits(AGE = c(mean = 0))
  expect_match(tfl_apply_plan(p, "args")$spread$cells$AGE[["Mean (SD)"]],
               "{mean:.0f} ({sd:.3f})", fixed = TRUE)
})

test_that("one number still means every token", {
  skip_if_no_cards2()
  p <- open_plan() |> tfl_plan_digits(c(mean = 2, sd = 3, p = 1)) |>
    tfl_plan_digits(AGE = 1)
  expect_match(tfl_apply_plan(p, "args")$spread$cells$AGE[["Mean (SD)"]],
               "{mean:.1f} ({sd:.1f})", fixed = TRUE)
})


test_that("kind x statistic and variable x statistic combine", {
  skip_if_no_cards2()
  p <- open_plan() |>
    tfl_plan_digits(continuous = c(mean = 2, sd = 3),
                categorical = c(p = 1)) |>
    tfl_plan_digits(AGE = c(mean = 1, sd = 2))
  cells <- tfl_apply_plan(p, "args")$spread$cells
  expect_match(cells$AGE[["Mean (SD)"]], "{mean:.1f} ({sd:.2f})",
               fixed = TRUE)
  expect_match(cells$BMIBL[["Mean (SD)"]], "{mean:.2f} ({sd:.3f})",
               fixed = TRUE)
  expect_match(cells$SEX, "{p:.1f%}", fixed = TRUE)
})


test_that("a digits value may ask for significant digits", {
  skip_if_no_cards2()
  p <- open_plan() |>
    tfl_plan_digits(continuous = c(mean = "4s", sd = "5s"),
                categorical = c(p = 1)) |>
    tfl_plan_digits(AGE = c(mean = 1))
  cells <- tfl_apply_plan(p, "args")$spread$cells
  # decimals and significant digits mix, per statistic
  expect_match(cells$AGE[["Mean (SD)"]], "{mean:.1f} ({sd:.5s})",
               fixed = TRUE)
  expect_match(cells$BMIBL[["Mean (SD)"]], "{mean:.4s} ({sd:.5s})",
               fixed = TRUE)
  out <- suppressMessages(tfl_apply_plan(p, "table"))
  expect_true(any(grepl("8.5902", out[[3L]], fixed = TRUE)))
})


# --------------------------------- the denominator the ARD states

# the header numbers n = TRUE reads, without the bookkeeping attributes
nv <- function(p) {
  v <- tflspec:::.plan_n_values(p, TRUE)
  if (!length(v)) return(numeric(0))
  stats::setNames(as.numeric(v), names(v))
}

test_that("n = TRUE reads a cards sentinel keyed by the cols", {
  skip_if_no_cards2()
  # a sentinel row is a number the ARD states outright, so reading it is
  # not a guess -- and it is taken only when its keys ARE the `cols`.
  # A sentinel's number is its `N`, as cards writes it (#480)
  d <- data.frame(
    TRT = rep(c("A", "B"), each = 2L),
    variable = c("..ard_total_n..", "X", "..ard_total_n..", "X"),
    stat_name = c("N", "n", "N", "n"),
    stat = c(40, 7, 50, 9),
    .label = c("all", "x", "all", "x"),
    stringsAsFactors = FALSE)
  p <- tfl_plan(d, cols = "TRT", notes = FALSE)
  expect_identical(nv(p), c(A = 40, B = 50))
})

test_that("two sentinels are a choice, so neither is made", {
  skip_if_no_cards2()
  d <- data.frame(
    TRT = c("A", "A"),
    variable = c("..ard_total_n..", "..ard_hierarchical_overall.."),
    stat_name = c("N", "N"), stat = c(40, 12),
    .label = c("all", "any"), stringsAsFactors = FALSE)
  p <- tfl_plan(d, cols = "TRT", notes = FALSE)
  expect_length(nv(p), 0L)
})

test_that("a short widths vector repeats its last value", {
  skip_if_no_cards2()
  a <- suppressMessages(tfl_apply_plan(disp_plan() |>
    tfl_plan_paginate_rows(max_rows = 40) |> tfl_plan_style(widths = c(5, 2))))
  b <- suppressMessages(tfl_apply_plan(disp_plan() |>
    tfl_plan_paginate_rows(max_rows = 40) |>
    tfl_plan_style(widths = c(5, 2, 2, 2, 2))))
  expect_equal(a, b)
})


test_that("a row budget that the split ignores is refused, not dropped", {
  skip_if_no_cards2()
  # raising max_rows and watching nothing change is how an afternoon goes
  p <- disp_plan() |> tfl_plan_paginate_group() |>
    tfl_plan_paginate_rows(max_rows = 28)
  expect_error(suppressMessages(tfl_apply_plan(p)), "has no effect with split")
  expect_error(suppressMessages(tfl_apply_plan(p)), "group_safe", fixed = TRUE)
})


test_that("a row budget that the split ignores is refused, not dropped", {
  skip_if_no_cards2()
  # raising max_rows and watching nothing change is how an afternoon goes
  p <- disp_plan() |> tfl_plan_paginate_group() |>
    tfl_plan_paginate_rows(max_rows = 28)
  expect_error(suppressMessages(tfl_apply_plan(p)), "has no effect with split")
  expect_error(suppressMessages(tfl_apply_plan(p)), "group_safe", fixed = TRUE)
})

test_that("tfl_apply_plan(args) shows the display half, so last-wins is "
          |> paste0("visible"), {
  skip_if_no_cards2()
  p <- disp_plan() |>
    tfl_plan_paginate_rows(max_rows = 25, split = "group_force") |>
    tfl_plan_paginate_rows(max_rows = 15)
  a <- tfl_apply_plan(p, "args")
  expect_setequal(names(a), c("spread", "rtf"))
  # the call you edit last is the one that decides, and you can see it
  expect_identical(a$rtf$max_rows, 15)
  expect_identical(a$rtf$split, "group_force")
})


test_that("a named list of n makes each name a token", {
  skip_if_no_cards2()
  # both numbers in one header, no function: the study total in a spanner
  # and each column's own underneath it
  p <- disp_plan() |> tfl_plan_paginate_rows(max_rows = 40) |>
    tfl_plan_col_header(
      n = list(n = c("Placebo" = 86, "Xanomeline High Dose" = 84,
                     "Xanomeline Low Dose" = 84),
               total = 254),
      rtf_col_header(
        list(col_cell(1, ""), col_cell(2, ""),
             col_cell(c(3, 5), "All (N={total})")),
        c("", "", "{col}"),
        c("Group", "Characteristic", "(N={n})")))
  out <- suppressMessages(tfl_apply_plan(p))
  first <- if (inherits(out, "rtftable")) out else out[[1L]]
  r1 <- vapply(first$col_header[[1L]], function(z) as.character(z$label), "")
  expect_true(any(grepl("All (N=254)", r1, fixed = TRUE)))
  expect_true(any(grepl("(N=86)", first$col_header[[3L]], fixed = TRUE)))
  expect_true(any(grepl("(N=84)", first$col_header[[3L]], fixed = TRUE)))
})


test_that("{n:sum} totals over the columns the cell covers", {
  skip_if_no_cards2()
  f <- tflspec:::.plan_header_fill
  nv <- c("A____x" = 10, "A____y" = 20, "B____x" = 30, "B____y" = 40)
  cols <- names(nv)
  h <- rtf_col_header(
    list(col_cell(1, "all {n:sum}"),
         col_cell(c(2, 3), "{col1} {n:sum}"),
         col_cell(c(4, 5), "{col1} {n:sum}")),
    c("Term", "{col2} {n}"))
  out <- f(h, nv, cols, 1L, "____")
  r1 <- vapply(out[[1L]], function(z) as.character(z$label), "")
  # a cell outside the data totals every column; a spanner totals its own
  expect_identical(r1, c("all 100", "A 30", "B 70"))
  # and a spanner takes the level its columns agree on
  expect_identical(out[[2L]], c("Term", "x 10", "y 20", "x 30", "y 40"))
})

test_that("{n:sum} needs no n_subjs: the ARD and the cell say it all", {
  skip_if_no_cards2()
  # one column per arm, a spanner over all of them
  p <- disp_plan() |> tfl_plan_paginate_rows(max_rows = 40) |>
    tfl_plan_col_header(
      n = c("Placebo" = 86, "Xanomeline High Dose" = 84,
            "Xanomeline Low Dose" = 84),
      rtf_col_header(
        list(col_cell(1, ""), col_cell(2, ""),
             col_cell(c(3, 5), "All (N={n:sum})")),
        c("Group", "Characteristic", "{col} (N={n})")))
  out <- suppressMessages(tfl_apply_plan(p))
  first <- if (inherits(out, "rtftable")) out else out[[1L]]
  r1 <- vapply(first$col_header[[1L]], function(z) as.character(z$label), "")
  expect_true(any(grepl("All (N=254)", r1, fixed = TRUE)))
})


test_that("{n:<column>} names one of the values", {
  f <- tflspec:::.plan_header_fill
  nv <- c("A" = 10, "B" = 20, "C" = 30)
  h <- rtf_col_header(
    list(col_cell(1, "A={n:A} B={n:B} C={n:C} all={n:sum}"),
         col_cell(c(2, 4), "{n:sum}")),
    c("Term", "{col} ({n})"))
  out <- f(h, nv, c("A", "B", "C"), 1L, "____")
  r1 <- vapply(out[[1L]], function(z) as.character(z$label), "")
  expect_identical(r1[[1L]], "A=10 B=20 C=30 all=60")
  expect_identical(r1[[2L]], "60")
  expect_identical(out[[2L]], c("Term", "A (10)", "B (20)", "C (30)"))
})

test_that("print() lists the header tokens and what they resolve to", {
  skip_if_no_cards2()
  p <- disp_plan() |> tfl_plan_paginate_rows(max_rows = 40) |>
    tfl_plan_col_header(n = c("Placebo" = 86, "Xanomeline High Dose" = 84,
                          "Xanomeline Low Dose" = 84),
                    rtf_col_header(c("Group", "Characteristic", "{col}")))
  invisible(suppressMessages(tfl_apply_plan(p)))
  out <- utils::capture.output(print(p))
  expect_true(any(grepl("header tokens", out, fixed = TRUE)))
  expect_true(any(grepl("{n:sum}", out, fixed = TRUE)))
  expect_true(any(grepl("{n:Placebo}", out, fixed = TRUE)))
  expect_true(any(grepl("= 86", out, fixed = TRUE)))
  expect_true(any(grepl("{col}", out, fixed = TRUE)))
  # a level shows the text it prints as, not a description of itself
  expect_true(any(grepl("= c(AGE, BMIBL, SEX)", out, fixed = TRUE)) ||
              any(grepl("= c(Placebo", out, fixed = TRUE)))
  # the numbers themselves, not a description of them
  expect_true(any(grepl("= c(Placebo = 86", out, fixed = TRUE)))
  expect_true(any(grepl("= 254 over every column", out, fixed = TRUE)))
})


test_that("..ard_total_n.. is read as the total, never each column's", {
  skip_if_no_cards2()
  # the total carries `N`, not `n`, and has no value for the `cols` keys:
  # it is one number for the whole table -- a spanner over all of it --
  # and putting it in every arm's header was #482
  d <- data.frame(
    TRT = c(NA, "A", "B"),
    variable = c("..ard_total_n..", "X", "X"),
    stat_name = c("N", "n", "n"),
    stat = c(254, 7, 9),
    .label = c("all", "x", "x"),
    stringsAsFactors = FALSE)
  p <- tfl_plan(d, cols = "TRT", notes = FALSE)
  v <- tflspec:::.plan_n_values(p, TRUE)
  expect_identical(attr(v, "total"), 254)
  expect_false(any(c("A", "B") %in% names(v)))
})

test_that("a sentinel carrying both n and N gives the denominator N", {
  skip_if_no_cards2()
  # ..ard_hierarchical_overall.. carries n (had an event) and N (the
  # denominator); a header's number is the denominator (#480) -- the
  # event count is the "Any" row's, a subset of it
  d <- data.frame(
    TRT = c("A", "A", "B", "B"),
    variable = "..ard_hierarchical_overall..",
    stat_name = c("n", "N", "n", "N"),
    stat = c(42, 86, 27, 84),
    .label = "any", stringsAsFactors = FALSE)
  p <- tfl_plan(d, cols = "TRT", notes = FALSE)
  expect_identical(nv(p), c(A = 86, B = 84))
})

test_that("a sentinel with only n gives no header number", {
  skip_if_no_cards2()
  d <- data.frame(
    TRT = c("A", "B"),
    variable = "..ard_hierarchical_overall..",
    stat_name = "n", stat = c(42, 27), .label = "any",
    stringsAsFactors = FALSE)
  p <- tfl_plan(d, cols = "TRT", notes = FALSE)
  expect_length(nv(p), 0L)
})

test_that("an AE table's header N is the analysis set, not the Any row", {
  skip_if_no_cards2()
  adsl <- cards::ADSL
  adae <- cards::ADAE[cards::ADAE$TRTEMFL == "Y", ]
  adsl$TRTA <- adsl$TRT01A
  ard <- cards::ard_stack_hierarchical(
    adae, variables = c(AEBODSYS, AEDECOD), by = TRTA,
    denominator = adsl, id = USUBJID, over_variables = TRUE)
  d <- tfl_ard_normalize(ard, hierarchy = c("AEBODSYS", "AEDECOD"),
                     overall = "Any TEAE")
  p <- tfl_plan(d, cols = "TRTA", rows = c(group1 = "AEBODSYS"),
                label = c(label = "AEDECOD"), notes = FALSE)
  n <- tflspec:::.plan_n_values(p, TRUE)
  expect_equal(unname(n[c("Placebo", "Xanomeline Low Dose",
                          "Xanomeline High Dose")]), c(86, 84, 84))
})


test_that("tfl_ard_normalize() keeps the total it drops, as a number", {
  skip_if_no_cards2()
  # the row is not a table statistic and goes; the NUMBER is a
  # denominator and stays, because a header still asks for it
  d <- data.frame(
    TRT = c(NA, "A", "B"),
    variable = c("..ard_total_n..", "X", "X"),
    variable_level = NA_character_,
    context = c("total_n", "categorical", "categorical"),
    stat_name = c("N", "n", "n"),
    stat_label = c("N", "n", "n"),
    stat = c(254, 7, 9),
    stringsAsFactors = FALSE)
  nz <- tfl_ard_normalize(d, keys = "TRT")
  expect_false(any(nz$variable == "..ard_total_n.."))
  expect_identical(attr(nz, "ard_total_n", exact = TRUE), 254)
})

test_that("a total that is not one number is not remembered", {
  skip_if_no_cards2()
  # two totals is a question, and answering it would be a guess
  d <- data.frame(
    variable = c("..ard_total_n..", "..ard_total_n..", "X"),
    variable_level = NA_character_,
    context = c("total_n", "total_n", "categorical"),
    stat_name = c("N", "N", "n"),
    stat_label = c("N", "N", "n"),
    stat = c(254, 86, 7),
    stringsAsFactors = FALSE)
  expect_null(attr(tfl_ard_normalize(d), "ard_total_n", exact = TRUE))
})

test_that("one variable's N is not a column's population (#482)", {
  skip_if_no_cards2()
  base <- data.frame(
    group1 = c(NA, rep("TRT", 4L)),
    group1_level = c(NA, "A", "A", "B", "B"),
    variable = c("..ard_total_n..", rep("X", 4L)),
    variable_level = "x",
    context = c("total_n", rep("categorical", 4L)),
    stat_name = c("N", "N", "n", "N", "n"),
    stat_label = c("N", "N", "n", "N", "n"),
    stat = c(254, 86, 7, 84, 9),
    stringsAsFactors = FALSE)
  # X's N is the count of its non-missing values: the arm size only if
  # nothing is missing, which the ARD cannot show -- so it is not read
  p <- tfl_plan(tfl_ard_normalize(base, keys = "TRT"), cols = "TRT",
                notes = FALSE)
  v <- tflspec:::.plan_n_values(p, TRUE)
  expect_length(nv(p), 0L)
  expect_match(attr(v, "why")[["A"]], "only X states an N")
  # the study total is remembered as the TOTAL, never each column's
  expect_identical(attr(v, "total"), 254)
  fill <- function() tflspec:::.plan_header_fill(
    rtf_col_header(c("", "(N={n})")), v, c("A", "B"), 1L)
  expect_warning(fill(), "printed as NA")
  expect_warning(fill(), "only X states an N")
  h <- suppressWarnings(fill())
  expect_identical(h[[1L]], c("", "(N=NA)", "(N=NA)"))
})

test_that("print() says why {n} could not be resolved", {
  skip_if_no_cards2()
  # saying nothing is what sent the reader here
  d <- data.frame(TRT = c("A", "B"), variable = "X",
                  stat_name = "mean", stat = c(1, 2),
                  .label = "x", stringsAsFactors = FALSE)
  p <- tfl_plan(d, cols = "TRT", notes = FALSE)
  p <- tfl_plan_col_header(p, n = TRUE,
                       rtf_col_header(c("", "(N={n})")))
  out <- paste(capture.output(print(p)), collapse = "|")
  expect_match(out, "NOT resolved", fixed = TRUE)
})


test_that("tfl_plan_fmt() without `cols` formats the value cells", {
  skip_if_no_cards2()
  # `cols = 3:31` is a count of the columns one study happened to have;
  # the plan knows which columns hold values
  d <- data.frame(
    group1 = "PARAM", group1_level = "Drug X",
    group2 = "TP", group2_level = c("t1", "t1", "t2", "t2"),
    variable = "AVAL", variable_level = NA_character_,
    context = "continuous",
    stat_name = c("N", "mean", "N", "mean"),
    stat_label = c("N", "Mean", "N", "Mean"),
    stat = c(12, 1.23456, 12, 2.34567),
    .kind = "continuous", stringsAsFactors = FALSE)
  p <- tfl_plan(tfl_ard_normalize(d, keys = c("PARAM", "TP")), cols = "TP",
                rows = c(Analyte = "PARAM"),
                label = c(Statistics = "stat_label"), stats = "rows",
                notes = FALSE) |>
    tfl_plan_fmt(by = "Statistics",
             formats = list(N = list(digits = 0),
                            Mean = list(signif = 3)))
  tbl <- tfl_apply_plan(p, "pages")[[1L]]$data
  expect_identical(tbl$t1, c("12", "1.23"))
  expect_identical(tbl$t2, c("12", "2.35"))
  # the label column is untouched -- it was never a value cell
  expect_identical(as.character(tbl$Statistics), c("N", "Mean"))
})

test_that("tfl_plan_paginate_cols(every = ) counts the columns for you", {
  skip_if_no_cards2()
  d <- data.frame(
    group1 = "PARAM", group1_level = "Drug X",
    group2 = "TP", group2_level = rep(paste0("t", 1:5), each = 2L),
    variable = "AVAL", variable_level = NA_character_,
    context = "continuous",
    stat_name = rep(c("N", "mean"), 5L),
    stat_label = rep(c("N", "Mean"), 5L),
    stat = seq_len(10L),
    .kind = "continuous", stringsAsFactors = FALSE)
  p <- tfl_plan(tfl_ard_normalize(d, keys = c("PARAM", "TP")), cols = "TP",
                rows = c(Analyte = "PARAM"),
                label = c(Statistics = "stat_label"), stats = "rows",
                notes = FALSE)
  # 5 value columns, 2 carried: blocks of 2, 2, 1
  pg <- tfl_apply_plan(tfl_plan_paginate_cols(p, every = 2L, carry = 1:2))
  expect_identical(vapply(pg, function(z) ncol(z$data), 0L),
                   c(4L, 4L, 3L))
  # a block wide enough for everything cuts nothing
  one <- tfl_apply_plan(tfl_plan_paginate_cols(p, every = 99L, carry = 1:2))
  expect_length(one, 1L)
})


# ------------------------------------------ the header n, key rows, .kind --

test_that("tfl_plan_col_header(n = TRUE) reads the key's own tabulation", {
  skip_if_not_installed("cards")
  adsl <- cards::ADSL
  adsl$TRT <- factor(as.character(adsl$ARM),
                     c("Xanomeline Low Dose", "Placebo",
                       "Xanomeline High Dose"))
  adsl$AGE[1:5] <- NA          # so the summary's N is NOT the arm size
  ard <- cards::ard_stack(adsl, .by = TRT,
                          cards::ard_continuous(variables = AGE))
  p <- tfl_plan(tfl_ard_normalize(ard), cols = "TRT")
  arm <- table(adsl$TRT)
  expect_equal(nv(p), stats::setNames(as.numeric(arm), names(arm)))
})

test_that("a key tabulation that is not the population split is not taken", {
  skip_if_not_installed("cards")
  adsl <- cards::ADSL
  adsl$TRT <- as.character(adsl$ARM)
  adae <- merge(cards::ADAE[, c("USUBJID", "AESOC")],
                adsl[, c("USUBJID", "TRT")], by = "USUBJID")
  # the treatment counted as an EVENT: n per arm does not add up to one N
  ard <- cards::bind_ard(
    cards::ard_categorical(adae[!duplicated(adae$USUBJID), ],
                           variables = TRT, denominator = adsl),
    cards::ard_hierarchical(adae[!duplicated(adae[c("USUBJID", "AESOC")]), ],
                            variables = AESOC, by = TRT,
                            id = USUBJID, denominator = adsl))
  p <- tfl_plan(tfl_ard_normalize(ard, hierarchy = "AESOC"), cols = "TRT")
  # not the event counts: the hierarchical summary's denominator
  arm <- table(adsl$TRT)
  expect_equal(nv(p), stats::setNames(as.numeric(arm), names(arm))[names(nv(p))])
  expect_setequal(names(nv(p)), names(arm))
})

test_that("a Total column the key cannot speak for gets no number", {
  skip_if_not_installed("cards")
  adsl <- cards::ADSL
  adsl$TRT <- as.character(adsl$ARM)
  d <- tfl_ard_normalize(cards::ard_stack(
    adsl, .by = TRT, cards::ard_categorical(variables = SEX),
    .overall = TRUE))
  d$TRT[is.na(d$TRT) & !d$.key_own] <- "Total"
  p <- tfl_plan(d, cols = "TRT")
  # the arms are the key's own partition; "Total" is nobody's
  arm <- table(adsl$TRT)
  expect_equal(nv(p)[names(arm)],
               stats::setNames(as.numeric(arm), names(arm)))
  expect_false("Total" %in% names(nv(p)))
})

test_that("a variable summarised and tabulated gets both recipes in a plan", {
  skip_if_not_installed("cards")
  adsl <- cards::ADSL
  adsl$TRT <- as.character(adsl$ARM)
  adsl$DEC <- round(adsl$AGE / 10)
  d <- tfl_ard_normalize(cards::ard_stack(
    adsl, .by = TRT,
    cards::ard_continuous(variables = DEC),
    cards::ard_categorical(variables = DEC)))
  direct <- tfl_ard_spread(d, cols = "TRT", notes = FALSE,
                       cells = list(continuous  = "{mean:.1f}",
                                    categorical = "{n}"))
  planned <- suppressMessages(tfl_plan(d, cols = "TRT") |>
    tfl_plan_cells(continuous = "{mean:.1f}", categorical = "{n}") |>
    tfl_apply_plan("table"))
  expect_equal(as.data.frame(planned), as.data.frame(direct))
  expect_false(anyNA(direct[!is.na(direct$label), -(1:2)]))
})

# ------------------------------------------------ roles from a definition file

test_that("tfl_plan(spec = ) takes the roles from the spec's tables sheet", {
  skip_if_no_cards2()
  sp <- tfl_table_spec(
    tables = data.frame(cols = "TRT", rows = "group = variable"),
    cells  = data.frame(variable = c("continuous", "categorical"),
                        row      = c("Mean (SD)", NA),
                        template = c("{mean} ({sd})", "{n} ({p})"),
                        digits   = c("1,2", "0")))
  d <- nz(plan_ard())
  p <- tfl_plan(d, spec = sp, notes = FALSE)
  expect_identical(p$roles$cols, "TRT")
  expect_identical(p$roles$rows, c(group = "variable"))
  expect_equal(as.data.frame(tfl_apply_plan(p, "table")),
               as.data.frame(tfl_ard_spread(d, cols = "TRT",
                 rows = c(group = "variable"),
                 cells = list(continuous  = c("Mean (SD)" = "{mean:.1f} ({sd:.2f})"),
                              categorical = "{n:.0f} ({p:.0f})"),
                 notes = FALSE)))
  # a role in the call still wins, and is checked against the data
  p2 <- tfl_plan(d, spec = sp, rows = c(block = "variable"), notes = FALSE)
  expect_identical(p2$roles$rows, c(block = "variable"))
  bad <- tfl_table_spec(tables = data.frame(cols = "NOPE"))
  expect_error(tfl_plan(d, spec = bad), "no column 'NOPE'|NOPE")
})

# ------------------------------------------- the table half of a workbook

spec_pages_ard <- function() nz(plan_ard())

test_that("layout / columns / style give the pages the verbs give", {
  skip_if_no_cards2()
  d <- spec_pages_ard()
  sp <- tfl_table_spec(
    tables  = data.frame(cols = "TRT", rows = "group = variable"),
    cells   = data.frame(variable = c("continuous", "continuous", "categorical"),
                         row = c("n", "Mean (SD)", NA),
                         template = c("{N:d}", "{mean} ({sd})", "{n:d} ({p:.1f%})"),
                         digits = c(NA, "1,2", NA)),
    layout  = data.frame(stub_into = "row_label", stub_before = "TRUE",
                         blank_where = "between_groups", blank_first = "TRUE",
                         pages_max_rows = "6", pages_split = "group_safe"),
    columns = data.frame(column = c("row_label", ".values"),
                         width = c("4", "2")),
    style   = data.frame(align_count_pct = "TRUE", row_height_twips = "220"))
  by_spec <- tfl_apply_plan(tfl_plan(d, spec = sp, notes = FALSE), "pages")
  by_code <- tfl_plan(d, cols = "TRT", rows = c(group = "variable"),
                      notes = FALSE) |>
    tfl_plan_cells(continuous  = c("n" = "{N:d}",
                               "Mean (SD)" = "{mean:.1f} ({sd:.2f})"),
               categorical = "{n:d} ({p:.1f%})") |>
    tfl_plan_stub(into = "row_label", before = TRUE) |>
    tfl_plan_blanks(where = "between_groups", first = TRUE) |>
    tfl_plan_paginate_rows(max_rows = 6, split = "group_safe") |>
    tfl_plan_style(widths = c(4, 2), align_count_pct = TRUE,
               row_height_twips = 220L) |>
    tfl_apply_plan("pages")
  expect_true(length(by_spec) > 1L)
  expect_equal(by_spec, by_code)
  # and the comparison is not vacuous: one changed setting shows
  sp2 <- sp
  sp2$style$row_height_twips <- "240"
  expect_false(isTRUE(all.equal(
    tfl_apply_plan(tfl_plan(d, spec = sp2, notes = FALSE), "pages"), by_code)))
})

test_that("a verb written after tfl_plan(spec = ) still wins", {
  skip_if_no_cards2()
  d <- spec_pages_ard()
  sp <- tfl_table_spec(tables = data.frame(cols = "TRT", rows = "group = variable"),
                 layout = data.frame(pages_max_rows = "6",
                                     pages_split = "group_safe"))
  p <- tfl_plan(d, spec = sp, notes = FALSE) |> tfl_plan_paginate_rows(max_rows = 40)
  expect_s3_class(tfl_apply_plan(p, "pages")[[1L]], "rtftable")
  expect_length(tfl_apply_plan(p, "pages"), 1L)
})

test_that("`.values` widths follow the data; a column left out is named", {
  skip_if_no_cards2()
  d <- spec_pages_ard()
  base <- function(columns) tfl_table_spec(
    tables = data.frame(cols = "TRT", rows = "group = variable"),
    layout = data.frame(stub_into = "row_label", stub_before = "TRUE"),
    columns = columns)
  pg <- tfl_apply_plan(tfl_plan(d, spec = base(data.frame(
    column = c("row_label", ".values"), width = c("5", "2"))), notes = FALSE),
    "pages")
  first <- if (inherits(pg, "rtftable")) pg else pg[[1L]]
  expect_identical(first$col_rel_width,
                   c(5, rep(2, ncol(first$data) - 1L)))
  expect_error(tfl_apply_plan(tfl_plan(d, spec = base(data.frame(
    column = "row_label", width = "5")), notes = FALSE), "pages"),
    "not for")
})

test_that("group_collapse alone does not become the grouping column", {
  # `lay$group_col` would partially match `group_collapse`
  skip_if_no_cards2()
  sp <- tfl_table_spec(tables = data.frame(cols = "TRT", rows = "group = variable"),
                 layout = data.frame(group_collapse = "1"))
  p <- tfl_plan(spec_pages_ard(), spec = sp, notes = FALSE)
  g <- tflspec:::.plan_merge(tflspec:::.plan_of(p, "group"))
  expect_null(g$group_col)
  expect_identical(g$collapse_repeats, 1L)
})

test_that("stats = rows formats come from `cells` rows with no template", {
  skip_if_no_cards2()
  d <- spec_pages_ard()
  d <- d[d$variable == "AGE", , drop = FALSE]
  sp <- tfl_table_spec(
    tables = data.frame(cols = "TRT", rows = "Analyte = variable",
                        label = "Statistics = stat_label", stats = "rows"),
    cells = data.frame(row = c("N", "Mean", "SD"), digits = c("0", NA, NA),
                       signif = c(NA, "4", "5")))
  by_spec <- tfl_apply_plan(tfl_plan(d, spec = sp, notes = FALSE), "pages")
  by_code <- tfl_plan(d, cols = "TRT", rows = c(Analyte = "variable"),
                      label = c(Statistics = "stat_label"), stats = "rows",
                      notes = FALSE) |>
    tfl_plan_fmt(by = "Statistics",
             formats = list(N = list(digits = 0), Mean = list(signif = 4),
                            SD = list(signif = 5))) |>
    tfl_apply_plan("pages")
  expect_equal(by_spec, by_code)
  # the same rows on a stats = cells table are a mistake, and said to be
  bad <- sp
  bad$tables$stats <- NA
  expect_error(tfl_plan(nz(plan_ard()), spec = bad, notes = FALSE),
               "not `stats = rows`")
})

test_that("display values are checked where they are written", {
  expect_error(tfl_table_spec(layout = data.frame(pages_max_rows = "twenty")),
               "`layout\\$pages_max_rows` must be a whole number")
  expect_error(tfl_table_spec(style = data.frame(align_count_pct = "maybe")),
               "TRUE or FALSE")
  expect_error(tfl_table_spec(columns = data.frame(width = "2")),
               "needs a `column`")
  expect_error(tfl_table_spec(columns = data.frame(column = c("a", "a"))),
               "two rows")
  expect_error(tfl_table_spec(layout = data.frame(output_id = c("T1", "T1"),
                                            pages_max_rows = "5")),
               "two rows")
  lay <- tflspec:::.ard_spec_typed(
    tfl_table_spec(layout = data.frame(pages_cont_label = '" (Cont.)"',
                                 colpages_carry = "1 | 2",
                                 stub_vars = "a | b"))$layout, "layout")
  expect_identical(lay$pages_cont_label, " (Cont.)")   # quotes keep spaces
  expect_identical(lay$colpages_carry, 1:2)
  expect_identical(lay$stub_vars, c("a", "b"))
})

# ------------------------------------------------ the col_header sheet

hdr_spec <- function(col_header, ...) tfl_table_spec(
  tables = data.frame(cols = "TRT", rows = "group = variable"),
  layout = data.frame(stub_into = "row_label", stub_before = "TRUE"),
  col_header = col_header, ...)
first_page <- function(pg) if (inherits(pg, "rtftable")) pg else pg[[1L]]

test_that("a col_header sheet gives the header rtf_col_header() gives", {
  skip_if_no_cards2()
  d <- spec_pages_ard()
  sp <- hdr_spec(data.frame(
    line = c(1, 1, 2, 2),
    cols = c("row_label", ".values", "row_label", ".values"),
    span = c(NA, "each", NA, "each"),
    text = c(NA, "{col}", "Characteristic", "(N={n})")))
  by_spec <- tfl_apply_plan(tfl_plan(d, spec = sp, notes = FALSE), "pages")
  by_code <- tfl_plan(d, cols = "TRT", rows = c(group = "variable"),
                      notes = FALSE) |>
    tfl_plan_stub(into = "row_label", before = TRUE) |>
    tfl_plan_col_header(n = TRUE, rtf_col_header(
      c("", "{col}"), c("Characteristic", "(N={n})"))) |>
    tfl_apply_plan("pages")
  expect_equal(by_spec, by_code)
  # {n} was read from the ARD without being asked for
  expect_match(first_page(by_spec)$col_header[[2L]][2L], "^\\(N=[0-9]+\\)$")
})

test_that("span = a key makes one spanner per value; KEY = value selects", {
  skip_if_no_cards2()
  adsl <- cards::ADSL
  adsl$TRT <- as.character(adsl$ARM)
  adsl$GRP <- ifelse(adsl$AGE < 70, "Young", "Old")
  d <- tfl_ard_normalize(cards::ard_stack(
    adsl, .by = c(TRT, GRP),
    cards::ard_categorical(variables = SEX, statistic = ~ c("n", "p"))))
  sp <- tfl_table_spec(
    tables = data.frame(cols = "TRT | GRP", rows = "group = variable"),
    layout = data.frame(stub_into = "row_label", stub_before = "TRUE"),
    col_header = data.frame(
      line = c(1, 1, 2, 2, 2),
      cols = c("row_label", ".values", "row_label", "GRP = Young", "GRP = Old"),
      span = c(NA, "TRT", NA, "each", "each"),
      text = c(NA, "{col1}", "Sex", "<70", ">=70"),
      border_bottom = c(NA, "single", NA, NA, NA)))
  h <- first_page(tfl_apply_plan(tfl_plan(d, spec = sp, notes = FALSE),
                             "pages"))$col_header
  top <- h[[1L]]
  spanners <- Filter(function(cc) cc$to > cc$from, top)
  expect_length(spanners, 3L)                          # one per arm
  expect_setequal(vapply(spanners, `[[`, "", "label"),
                  unique(adsl$TRT))
  expect_true(all(vapply(spanners, function(cc) !is.null(cc$border), NA)))
  lab <- h[[2L]]
  if (!is.character(lab)) lab <- vapply(lab, `[[`, "", "label")
  expect_identical(lab[1L], "Sex")
  expect_setequal(unique(lab[-1L]), c("<70", ">=70"))
})

test_that("a report's own header replaces the default header whole", {
  sp <- tfl_table_spec(col_header = data.frame(
    output_id = c(NA, NA, "T1"), line = c(1, 2, 1),
    cols = ".values", text = c("a", "b", "mine")))
  t1 <- tflspec:::.ard_spec_scope(sp, "T1")
  expect_identical(t1$col_header$text, "mine")
  t2 <- suppressMessages(tflspec:::.ard_spec_scope(sp, "T2"))
  expect_identical(t2$col_header$text, c("a", "b"))
})

test_that("col_header refuses what it cannot place", {
  skip_if_no_cards2()
  d <- spec_pages_ard()
  expect_error(tfl_table_spec(col_header = data.frame(line = 1, text = "x")),
               "needs a `line` and `cols`")
  bad <- function(...) tfl_apply_plan(tfl_plan(d, spec = hdr_spec(
    data.frame(line = 1, ...)), notes = FALSE), "pages")
  expect_error(bad(cols = "NOPE", text = "x"), "no column 'NOPE'")
  expect_error(bad(cols = ".values", span = "ARMX", text = "x"),
               "not a column key")
  expect_error(bad(cols = "1:99", text = "x"), "outside")
  # a typed \n is a line break; quotes keep leading spaces
  v <- tflspec:::.ard_spec_typed(tfl_table_spec(col_header = data.frame(
    line = 1, cols = "a", text = '"  a\\nb"'))$col_header, "col_header")
  expect_identical(v$text, "  a\nb")
})

# ------------------------------------------------ plan -> workbook

code_plan <- function(d = spec_pages_ard()) {
  tfl_plan(d, cols = "TRT", rows = c(group = "variable"), notes = FALSE) |>
    tfl_plan_labels(AGE = "Age (years)", SEX = "Sex") |>
    tfl_plan_cells(continuous  = c("n" = "{N:d}", "Mean (SD)" = "{mean} ({sd})"),
               categorical = "{n:d} ({p:.1f%})") |>
    tfl_plan_digits(1, rounding = "sas") |>
    tfl_plan_stub(into = "row_label", before = TRUE) |>
    tfl_plan_blanks(where = "between_groups", first = TRUE) |>
    tfl_plan_paginate_rows(max_rows = 6, split = "group_safe") |>
    tfl_plan_style(widths = c(4, 2), align_count_pct = TRUE) |>
    tfl_plan_col_header(n = TRUE, rtf_col_header(c("", "{col}"),
                                             c("Characteristic", "(N={n})")))
}

test_that("tfl_as_table_spec() writes a plan as a workbook that gives its pages", {
  skip_if_no_cards2()
  p <- code_plan()
  sp <- tfl_as_table_spec(p, output_id = "T1")
  expect_s3_class(sp, "tfl_table_spec")
  expect_true(attr(sp, "same_pages"))
  expect_length(attr(sp, "not_converted"), 0L)
  expect_identical(sp$tables$cols, "TRT")
  expect_identical(tflspec:::.ard_spec_study_value(sp, "rounding"), "sas")
  expect_identical(sp$layout$pages_max_rows, "6")
  # widths by name, the value columns as one `.values`
  expect_identical(sp$columns$column, c("row_label", ".values"))
  # the header came back as tokens and spans, not as this study's numbers
  expect_true(any(sp$col_header$text %in% "(N={n})"))
  expect_true(all(sp$col_header$span[sp$col_header$cols == ".values"] == "each"))

  skip_if_not_installed("writexl"); skip_if_not_installed("readxl")
  f <- tempfile(fileext = ".xlsx"); on.exit(unlink(f), add = TRUE)
  tfl_write_table_spec(sp, f)
  back <- tfl_apply_plan(tfl_plan(p$data, spec = tfl_read_table_spec(f, output_id = "T1"),
                              notes = FALSE), "pages")
  expect_equal(back, tfl_apply_plan(p, "pages"))
})

test_that("what a workbook cannot say is listed, and the check says so", {
  skip_if_no_cards2()
  p <- code_plan() |> tfl_plan_after(function(x) x)
  expect_message(sp <- tfl_as_table_spec(p), "tfl_plan_after\\(\\) step stays in code")
  expect_true(any(grepl("tfl_plan_after", attr(sp, "not_converted"))))
  expect_true(attr(sp, "same_pages"))      # an identity step changed nothing
  p2 <- code_plan() |> tfl_plan_after(function(x) { x[[1L]]$data[1, 1] <- "X"; x })
  sp2 <- suppressMessages(tfl_as_table_spec(p2))
  expect_false(attr(sp2, "same_pages"))
})

test_that("a named list of plans is one study workbook", {
  skip_if_no_cards2()
  sp <- tfl_as_table_spec(list(DM = code_plan(), DM2 = code_plan()))
  expect_setequal(unique(sp$tables$output_id), c("DM", "DM2"))
  expect_identical(unname(attr(sp, "same_pages")), c(TRUE, TRUE))
  expect_error(tfl_as_table_spec(list(code_plan(), code_plan())), "unique names")
})

test_that("a one-arm spanner comes back as one spanner per arm", {
  skip_if_no_cards2()
  adsl <- cards::ADSL
  adsl$TRT <- "ONLY"
  adsl$GRP <- ifelse(adsl$AGE < 70, "Young", "Old")
  d <- tfl_ard_normalize(cards::ard_stack(
    adsl, .by = c(TRT, GRP),
    cards::ard_categorical(variables = SEX, statistic = ~ c("n", "p"))))
  p <- tfl_plan(d, cols = c("TRT", "GRP"), rows = c(group = "variable"),
                notes = FALSE) |>
    tfl_plan_stub(into = "row_label", before = TRUE) |>
    tfl_plan_col_header(rtf_col_header(
      list(col_cell(1, ""), col_cell(c(2, 3), "ONLY")),
      c("Sex", "{col2}")))
  sp <- tfl_as_table_spec(p)
  expect_true(attr(sp, "same_pages"))
  top <- sp$col_header[sp$col_header$line == "1" & sp$col_header$cols == ".values", ]
  expect_identical(top$text, "{col1}")
  expect_identical(top$span, "TRT")
})


# ------------------------------- the header N, level by level (#482) --

hdr_rows <- function(out) {
  first <- if (inherits(out, "rtftable")) out else out[[1L]]
  lapply(first$col_header, function(r) if (is.character(r)) r else
    vapply(r, function(z) as.character(z$label), ""))
}

adsl_trt <- function() {
  adsl <- cards::ADSL
  adsl$TRT <- as.character(adsl$ARM)
  adsl$SEX <- as.character(adsl$SEX)
  adsl$AGEGRP <- ifelse(adsl$AGE < 70, "<70", ">=70")
  adsl
}

test_that("variables that disagree anywhere give no number anywhere", {
  skip_if_not_installed("cards")
  adsl <- adsl_trt()
  adsl$AGE[adsl$TRT == "Placebo"][1:3] <- NA   # Placebo: AGE 83, SEX 86
  ard <- cards::bind_ard(
    cards::ard_continuous(adsl, by = TRT, variables = AGE),
    cards::ard_categorical(adsl, by = TRT, variables = SEX))
  p <- tfl_plan(tfl_ard_normalize(ard), cols = "TRT", notes = FALSE)
  # the other arms agree (84 = 84) only because nothing is missing there
  expect_length(nv(p), 0L)
  expect_match(attr(tflspec:::.plan_n_values(p, TRUE), "why")[[1L]],
               "different N")
})

test_that("two variables that agree everywhere are read", {
  skip_if_not_installed("cards")
  adsl <- adsl_trt()
  ard <- cards::bind_ard(
    cards::ard_continuous(adsl, by = TRT, variables = AGE),
    cards::ard_categorical(adsl, by = TRT, variables = SEX))
  p <- tfl_plan(tfl_ard_normalize(ard), cols = "TRT", notes = FALSE)
  arm <- table(adsl$TRT)
  expect_equal(nv(p), stats::setNames(as.numeric(arm), names(arm)))
})

test_that("an N per visit is not a column's number", {
  skip_if_not_installed("cards")
  adlb <- cards::ADLB[cards::ADLB$PARAMCD == "ALT", ]
  adlb$TRT <- as.character(adlb$TRTA)
  ard <- cards::ard_continuous(adlb, by = c(TRT, AVISIT), variables = AVAL)
  p <- tfl_plan(tfl_ard_normalize(ard), cols = "TRT", notes = FALSE)
  expect_length(nv(p), 0L)
  expect_match(attr(tflspec:::.plan_n_values(p, TRUE), "why")[[1L]],
               "per row")
})

test_that("two column keys: the arm and the arm x sex cell are both read", {
  skip_if_not_installed("cards")
  adsl <- adsl_trt()
  d <- tfl_ard_normalize(cards::ard_stack(
    adsl, .by = c(TRT, SEX), cards::ard_continuous(variables = AGE),
    cards::ard_categorical(variables = AGEGRP)))
  p <- tfl_plan(d, cols = c("TRT", "SEX"), rows = c(group = "variable"),
                notes = FALSE) |>
    tfl_plan_cells(continuous = "{mean:.1f}", categorical = "{n}")
  v <- nv(p)
  expect_identical(v[["Placebo"]], 86)
  expect_identical(v[["Placebo____F"]], 53)
  expect_identical(v[["Xanomeline High Dose____M"]], 44)
  # a spanner's {n} is its level's; a leaf's is its cell's
  out <- suppressMessages(tfl_apply_plan(tfl_plan_col_header(p, n = TRUE,
    rtf_col_header(
      list(col_cell(1, ""), col_cell(2, ""),
           col_cell(c(3, 4), "{col1} (N={n})"),
           col_cell(c(5, 6), "{col1} (N={n})"),
           col_cell(c(7, 8), "{col1} (N={n})")),
      c("", "", "{col2} (N={n})"))), "pages"))
  h <- hdr_rows(out)
  expect_identical(h[[1L]][3:5], c("Placebo (N=86)",
                                   "Xanomeline High Dose (N=84)",
                                   "Xanomeline Low Dose (N=84)"))
  expect_identical(h[[2L]][3:4], c("F (N=53)", "M (N=33)"))
  # {n1} / {n2} name a depth from any cell
  out <- suppressMessages(tfl_apply_plan(tfl_plan_col_header(p, n = TRUE,
    rtf_col_header(c("", "", "{col1} {n1}"), c("", "", "{col2} {n2}"))),
    "pages"))
  h <- hdr_rows(out)
  expect_identical(h[[1L]][3:4], c("Placebo 86", "Placebo 86"))
  expect_identical(h[[2L]][3:4], c("F 53", "M 33"))
})

test_that("three keys: a depth the ARD does not state is NA, with a warning", {
  skip_if_not_installed("cards")
  adsl <- adsl_trt()
  mk <- function(extra = NULL) {
    a <- cards::ard_stack(adsl, .by = c(TRT, SEX, AGEGRP),
                          cards::ard_continuous(variables = AGE),
                          cards::ard_categorical(variables = RACE))
    if (!is.null(extra)) a <- cards::bind_ard(a, extra)
    tfl_plan(tfl_ard_normalize(a), cols = c("TRT", "SEX", "AGEGRP"),
             rows = c(group = "variable"), notes = FALSE) |>
      tfl_plan_cells(continuous = "{mean:.1f}", categorical = "{n}") |>
      tfl_plan_col_header(n = TRUE, rtf_col_header(
        c("", "", "{col1} N={n1}"), c("", "", "{col2} N={n2}"),
        c("", "", "{col3} N={n3}")))
  }
  # cards tabulates the by variables one at a time: TRT x SEX is nowhere
  expect_warning(out <- suppressMessages(tfl_apply_plan(mk(), "pages")),
                 "printed as NA")
  h <- hdr_rows(out)
  expect_identical(h[[1L]][3L], "Placebo N=86")
  expect_identical(h[[2L]][3L], "F N=NA")
  expect_identical(h[[3L]][3:4], c("<70 N=13", ">=70 N=40"))
  # tabulating SEX within TRT states it
  out <- suppressMessages(tfl_apply_plan(mk(
    cards::ard_categorical(adsl, by = TRT, variables = SEX)), "pages"))
  expect_identical(hdr_rows(out)[[2L]][3L], "F N=53")
})

test_that("a hierarchical ARD by two keys states both levels", {
  skip_if_not_installed("cards")
  adsl <- adsl_trt()
  adae <- cards::ADAE[cards::ADAE$TRTEMFL == "Y", ]
  adae$TRT <- as.character(adae$TRTA)
  adae$SEX <- as.character(adae$SEX)
  d <- tfl_ard_normalize(cards::ard_stack_hierarchical(
    adae, variables = c(AEBODSYS, AEDECOD), by = c(TRT, SEX),
    denominator = adsl, id = USUBJID, over_variables = TRUE),
    hierarchy = c("AEBODSYS", "AEDECOD"), overall = "Any TEAE")
  p <- tfl_plan(d, cols = c("TRT", "SEX"), rows = c(group1 = "AEBODSYS"),
                label = c(label = "AEDECOD"), notes = FALSE)
  v <- nv(p)
  expect_identical(v[["Placebo"]], 86)
  expect_identical(v[["Placebo____F"]], 53)
})

test_that("numbers given by the caller may be keyed at any depth", {
  skip_if_not_installed("cards")
  adsl <- adsl_trt()
  adsl$AGE[1:20] <- NA
  d <- tfl_ard_normalize(cards::ard_continuous(adsl, by = c(TRT, SEX),
                                           variables = AGE))
  p <- tfl_plan(d, cols = c("TRT", "SEX"), rows = c(group = "variable"),
                notes = FALSE) |>
    tfl_plan_cells(continuous = "{mean:.1f}")
  arm <- c(table(adsl$TRT))
  cell <- table(adsl$TRT, adsl$SEX)
  cell <- stats::setNames(as.vector(cell), paste(
    rep(rownames(cell), 2L), rep(colnames(cell), each = 3L), sep = "____"))
  hdr <- rtf_col_header(c("", "", "{col1} N={n1}"),
                        c("", "", "{col2} N={n}"))
  # from the ARD: NA and a warning, not AGE's non-missing count
  expect_warning(out <- suppressMessages(tfl_apply_plan(
    tfl_plan_col_header(p, n = TRUE, hdr), "pages")), "only AGE")
  expect_identical(hdr_rows(out)[[2L]][3L], "F N=NA")
  for (n in list(c(arm, cell), function(data) c(arm, cell))) {
    out <- suppressMessages(tfl_apply_plan(tfl_plan_col_header(p, n = n, hdr),
                                       "pages"))
    expect_identical(hdr_rows(out)[[1L]][3L], "Placebo N=86")
    expect_identical(hdr_rows(out)[[2L]][3:4], c("F N=53", "M N=33"))
  }
  # a workbook's header, its numbers from code
  sp <- tfl_table_spec(
    tables = data.frame(cols = "TRT | SEX", rows = "group = variable"),
    cells = data.frame(variable = "AGE", template = "{mean:.1f}"),
    col_header = data.frame(line = c(1, 2), cols = ".values",
                            span = c("TRT", "each"),
                            text = c("{col1} (N={n})", "{col2} (N={n})")))
  expect_warning(suppressMessages(tfl_apply_plan(
    tfl_plan(d, spec = sp, notes = FALSE), "pages")), "printed as NA")
  out <- suppressMessages(tfl_apply_plan(
    tfl_plan(d, spec = sp, notes = FALSE) |>
      tfl_plan_col_header(n = c(arm, cell)), "pages"))
  h <- hdr_rows(out)
  expect_true("Placebo (N=86)" %in% h[[1L]])
  expect_identical(h[[2L]][3:4], c("F (N=53)", "M (N=33)"))
})

test_that("{n:sum} with a column missing is NA, not a smaller total", {
  f <- tflspec:::.plan_header_fill
  h <- rtf_col_header(list(col_cell(1, ""), col_cell(c(2, 3), "{n:sum}")))
  expect_warning(out <- f(h, c(A = 10), c("A", "B"), 1L), "printed as NA")
  expect_identical(out[[1L]][[2L]]$label, "NA")
  # a spanner over some columns that share no level is not the total
  v <- structure(c(A = 10, B = 20, C = 30), total = 60)
  h <- rtf_col_header(list(col_cell(1, ""), col_cell(c(2, 3), "{n}"),
                           col_cell(c(2, 4), "{n}")))
  out <- suppressWarnings(f(h, v, c("A", "B", "C"), 1L))
  expect_identical(vapply(out[[1L]], `[[`, "", "label"), c("", "NA", "60"))
})

test_that("the key tabulated on its own states the table's total", {
  skip_if_not_installed("cards")
  adsl <- adsl_trt()
  d <- tfl_ard_normalize(cards::ard_stack(
    adsl, .by = TRT, cards::ard_categorical(variables = SEX)))
  p <- tfl_plan(d, cols = "TRT", notes = FALSE)
  expect_identical(attr(tflspec:::.plan_n_values(p, TRUE), "total"),
                   nrow(adsl) + 0)
})

test_that("pages split by a group value each read their own N from the ARD", {
  skip_if_not_installed("cards")
  set.seed(1)
  lb <- expand.grid(USUBJID = cards::ADSL$USUBJID,
                    PARAM = c("ALT", "HGB"), stringsAsFactors = FALSE)
  lb$BASEGR <- sample(c("G0", "G1"), nrow(lb), TRUE)
  lb$WORSTGR <- sample(c("G0", "G1", "G2"), nrow(lb), TRUE)
  lb <- lb[!(lb$PARAM == "HGB" & seq_len(nrow(lb)) %% 10 == 0), ]
  ard <- cards::bind_ard(
    cards::ard_categorical(lb, by = c(PARAM, BASEGR), variables = WORSTGR),
    # the population of each parameter, split by the column variable:
    # the ARD states every column's N and each page's total
    cards::ard_categorical(lb, by = PARAM, variables = BASEGR))
  p <- tfl_plan(tfl_ard_normalize(ard), cols = "BASEGR",
                rows = c(PARAM = "PARAM"), label = c(label = ".label"),
                notes = FALSE) |>
    tfl_plan_cells("{n}") |>
    tfl_plan_paginate_group(show = FALSE) |>
    tfl_plan_col_header(n = TRUE, rtf_col_header(
      list(col_cell(1, ""), col_cell(c(2, 3), "All (N={n})")),
      c("", "{col} (N={n})")))
  pg <- expect_silent(suppressMessages(tfl_apply_plan(p, "pages")))
  n <- table(lb$PARAM)
  cell <- table(lb$PARAM, lb$BASEGR)
  for (i in seq_along(pg)) {
    prm <- names(pg)[i]
    h <- hdr_rows(pg[i])
    expect_identical(h[[1L]][2L], sprintf("All (N=%d)", n[[prm]]))
    expect_identical(h[[2L]][2:3], sprintf("%s (N=%d)", c("G0", "G1"),
                                           cell[prm, c("G0", "G1")]))
  }
  expect_false(identical(hdr_rows(pg[1])[[1L]], hdr_rows(pg[2])[[1L]]))
})

# the analysis set and the subjects with the test: both in the ARD
two_pop <- function() {
  set.seed(1)
  lb <- expand.grid(USUBJID = cards::ADSL$USUBJID,
                    PARAM = c("ALT", "HGB"), stringsAsFactors = FALSE)
  lb$BASEGR <- sample(c("G0", "G1"), nrow(lb), TRUE)
  lb$WORSTGR <- sample(c("G0", "G1", "G2"), nrow(lb), TRUE)
  lb <- lb[!(lb$PARAM == "HGB" & seq_len(nrow(lb)) %% 10 == 0), ]
  d <- tfl_ard_normalize(cards::bind_ard(
    cards::ard_categorical(lb, by = c(PARAM, BASEGR), variables = WORSTGR),
    cards::ard_categorical(lb, by = PARAM, variables = BASEGR),
    cards::ard_total_n(cards::ADSL)), drop_contexts = "attributes")
  list(d = d, tested = table(lb$PARAM), set = nrow(cards::ADSL))
}
two_pop_plan <- function(d, n, text = "T (N={n})") {
  tfl_plan(d, cols = "BASEGR", rows = c(PARAM = "PARAM"),
           label = c(label = ".label"), notes = FALSE) |>
    tfl_plan_cells("{n}") |>
    tfl_plan_paginate_group(show = FALSE) |>
    tfl_plan_col_header(n = n, rtf_col_header(
      list(col_cell(1, ""), col_cell(c(2, 3), text)),
      c("", "{col} (n={n})")))
}
spanner <- function(pg) vapply(pg, function(p)
  p$col_header[[1L]][[2L]]$label, "")

test_that("n = \"page\" / \"table\" choose the population", {
  skip_if_not_installed("cards")
  x <- two_pop()
  pg <- suppressMessages(tfl_apply_plan(two_pop_plan(x$d, "page"), "pages"))
  expect_identical(unname(spanner(pg)),
                   sprintf("T (N=%d)", as.integer(x$tested[names(pg)])))
  expect_warning(pg <- suppressMessages(tfl_apply_plan(
    two_pop_plan(x$d, "table"), "pages")), "printed as NA")
  expect_identical(unname(spanner(pg)), rep(sprintf("T (N=%d)", x$set), 2L))
  # the analysis set by baseline grade is not in this ARD: NA, not a guess
  expect_identical(pg[[1L]]$col_header[[2L]][2L], "G0 (n=NA)")
})

test_that("two populations and no choice: the page's, with a warning", {
  skip_if_not_installed("cards")
  x <- two_pop()
  expect_warning(pg <- suppressMessages(tfl_apply_plan(
    two_pop_plan(x$d, TRUE), "pages")), "two populations")
  expect_identical(spanner(pg)[["HGB"]],
                   sprintf("T (N=%d)", as.integer(x$tested[["HGB"]])))
})

test_that("both populations in one header, from code and from a workbook", {
  skip_if_not_installed("cards")
  x <- two_pop()
  want <- sprintf("T (N=%d), tested n=%d", x$set,
                  as.integer(x$tested[c("ALT", "HGB")]))
  pg <- expect_silent(suppressMessages(tfl_apply_plan(two_pop_plan(
    x$d, list(n = "page", N = "table"), "T (N={N}), tested n={n}"),
    "pages")))
  expect_identical(unname(spanner(pg)), want)
  sp <- tfl_table_spec(
    tables = data.frame(cols = "BASEGR", rows = "PARAM = PARAM",
                        label = "label = .label",
                        header_n = "n = page | N = table"),
    cells = data.frame(template = "{n}"),
    layout = data.frame(group_page = "TRUE", group_show = "FALSE"),
    col_header = data.frame(
      line = c(1, 2, 2), cols = c(".values", "1", ".values"),
      span = c(NA, NA, "each"),
      text = c("T (N={N}), tested n={n}", NA, "{col} (n={n})")))
  pg <- expect_silent(suppressMessages(tfl_apply_plan(
    tfl_plan(x$d, spec = sp, notes = FALSE), "pages")))
  lab <- vapply(pg, function(p) {
    l <- vapply(p$col_header[[1L]], `[[`, "", "label")
    l[nzchar(l)][1L]
  }, "")
  expect_identical(unname(lab), want)
  expect_error(tfl_table_spec(tables = data.frame(
    cols = "BASEGR", header_n = "tested")) |>
      tflspec:::.ard_spec_table_args(), "not a population")
  expect_error(tflspec:::.plan_n_values(two_pop_plan(x$d, "x"), "x"),
               "a population is")
})

test_that("tfl_as_table_spec() writes the population to tables$header_n", {
  expect_identical(tflspec:::.plan_scope_text("table"), "table")
  expect_identical(tflspec:::.plan_scope_text(
    list(n = "page", N = "table")), "n = page | N = table")
  expect_null(tflspec:::.plan_scope_text(TRUE))
  expect_null(tflspec:::.plan_scope_text(c(A = 86)))
  expect_identical(tflspec:::.ard_spec_header_n("n = page | N = table"),
                   list(n = "page", N = "table"))
})
