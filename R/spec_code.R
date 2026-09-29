# ============================================================================
#  A table or report definition -> the R code that makes it
# ----------------------------------------------------------------------------
#  tfl_table_plan() and tfl_report() turn a definition workbook into an
#  object.  tfl_table_code() and tfl_report_code() write the same thing as
#  a program: the tfl_plan_*() verbs (tables) and the rtfreporter calls
#  (reports) the workbook stands for.
#
#  Both halves come from ONE list of steps, so the object and the program
#  cannot disagree: a step is a call -- a function and its arguments, as
#  values -- which .spec_eval() runs and .spec_code() writes out.
#  .plan_spec_steps() says which verbs a table definition is;
#  .report_spec_steps() which rtfreporter calls a report definition is.
# ============================================================================

# a call to write or to run: `fun` and its arguments (values, or calls /
# symbols of their own)
.spec_call <- function(fun, ...) {
  a <- list(...)
  a <- a[!vapply(a, is.null, logical(1L))]
  structure(list(fun = fun, args = a), class = "tfl_spec_call")
}

# a name in the program (`doc`, `plan`): its value comes from `env` when run
.spec_sym <- function(name) structure(list(name = name), class = "tfl_spec_sym")

.spec_eval <- function(x, env) {
  if (inherits(x, "tfl_spec_sym")) return(get(x$name, envir = env))
  if (inherits(x, "tfl_spec_call")) {
    f <- get(x$fun, envir = asNamespace("tflspec"), mode = "function")
    return(do.call(f, lapply(x$args, .spec_eval, env = env)))
  }
  if (is.list(x) && !is.object(x)) {
    return(lapply(x, .spec_eval, env = env))
  }
  x
}

# an argument name as it can be written: bare, or quoted
.spec_name <- function(n) {
  if (!nzchar(n)) return("")
  if (identical(make.names(n), n)) n else encodeString(n, quote = "\"")
}

# ---- writing a value as R --------------------------------------------------

# One line when it fits in `width` at this `indent`; otherwise one element a
# line, indented.  Values read back as what they were (checked by the
# tests: the written program makes the same pages).
.spec_code <- function(x, indent = 0L, width = 80L) {
  one <- .spec_code_line(x)
  if (nchar(one) + indent <= width) return(one)
  parts <- .spec_parts(x)
  if (is.null(parts)) return(one)
  pad <- strrep(" ", indent + 2L)
  el <- vapply(seq_along(parts$items), function(i) {
    nm <- parts$names[i]
    v <- .spec_code(parts$items[[i]], indent + 2L, width)
    paste0(pad, if (nzchar(nm)) paste0(.spec_name(nm), " = "), v)
  }, "")
  paste0(parts$open, "(\n", paste(el, collapse = ",\n"), "\n",
         strrep(" ", indent), ")")
}

# the head and the elements of a value that can be written over lines
.spec_parts <- function(x) {
  nm <- function(v) names(v) %||% rep("", length(v))
  if (inherits(x, "tfl_spec_call")) {
    return(list(open = x$fun, items = x$args, names = nm(x$args)))
  }
  if (inherits(x, "tfl_ard_cells")) {
    v <- unclass(x)
    return(list(open = "tfl_ard_cells", items = v, names = nm(v)))
  }
  if (is.data.frame(x)) {
    v <- c(as.list(x), list(check.names = FALSE))
    return(list(open = "data.frame", items = v, names = nm(v)))
  }
  if (is.list(x) && !is.object(x)) {
    return(list(open = "list", items = x, names = nm(x)))
  }
  if (is.atomic(x) && length(x) > 1L &&
      !length(setdiff(names(attributes(x)), "names"))) {
    v <- as.list(x)
    return(list(open = "c", items = v, names = nm(x)))
  }
  NULL
}

.spec_code_line <- function(x) {
  if (inherits(x, "tfl_spec_sym")) return(x$name)
  p <- .spec_parts(x)
  if (!is.null(p) && !(is.atomic(x) && !is.list(x))) {
    el <- vapply(seq_along(p$items), function(i)
      paste0(if (nzchar(p$names[i])) paste0(.spec_name(p$names[i]), " = "),
             .spec_code_line(p$items[[i]])), "")
    return(paste0(p$open, "(", paste(el, collapse = ", "), ")"))
  }
  paste(deparse(x, width.cutoff = 500L,
                control = c("keepNA", "keepInteger", "niceNames",
                            "showAttributes")),
        collapse = " ")
}

# a call, on one line when it fits after `indent` characters
.spec_call_code <- function(cl, indent = 2L) {
  one <- .spec_code_line(cl)
  if (nchar(one) + indent <= 80L) return(one)
  .spec_code(cl, indent)
}

# ---- tables ----------------------------------------------------------------

# The roles a table definition gives tfl_plan() (its `tables` sheet).
.plan_spec_roles <- function(sp) {
  sa <- .ard_spec_table_args(sp)
  sa[intersect(c("cols", "rows", "label", "stats", "sep", "value", "na",
                 "sort_stat"), names(sa))]
}

# The label column's name the roles give, as the plan will call it: one
# column is itself, several coalesce into `label` (or the name given).
.spec_label_name <- function(roles) {
  lb <- roles[["label"]]
  if (is.null(lb)) return("label")
  if (length(lb) == 1L && !is.list(lb) && is.na(lb)) return(character(0))
  nm <- names(lb)
  if (is.list(lb)) {
    if (length(lb) == 1L && is.character(lb[[1L]]) && length(lb[[1L]]) >= 2L) {
      return(if (is.null(nm) || !nzchar(nm[1L])) "label" else nm[1L])
    }
  } else if (is.character(lb) && length(lb) >= 2L) {
    return(if (is.null(nm) || !any(nzchar(nm))) "label" else nm[nzchar(nm)][1L])
  }
  if (!is.null(nm) && nzchar(nm[1L])) nm[1L] else "label"
}

# The verbs a table definition stands for, in the order a report is built:
# what tfl_table_plan() runs, and what tfl_table_code() writes.  `roles` are
# the plan's (the workbook's, and any given in the call), which decide the
# label column's name.
.plan_spec_steps <- function(roles, sp) {
  st <- list()
  add <- function(fun, ...) st[[length(st) + 1L]] <<- .spec_call(fun, ...)
  sa <- .ard_spec_table_args(sp)
  if (!is.null(sa[["sort"]])) add("tfl_plan_sort", sa[["sort"]])
  if (!is.null(sa[["rounding"]])) add("tfl_plan_digits", rounding = sa[["rounding"]])
  lv <- .ard_spec_levels(sp)
  if (length(lv)) do.call(add, c(list("tfl_plan_levels"), as.list(lv)))
  lb <- .ard_spec_labels(sp)
  if (length(lb)) do.call(add, c(list("tfl_plan_labels"), as.list(lb)))
  cm <- .ard_spec_cells(sp)
  if (length(cm)) do.call(add, c(list("tfl_plan_cells"), cm))

  # rows with no template: the display format of one statistic, for a
  # table that lays the statistics out as rows
  f <- sp$cells[is.na(sp$cells$template), , drop = FALSE]
  if (nrow(f)) {
    if (!identical(roles$stats, "rows")) {
      .ard_stop(paste0(
        "The `cells` sheet has rows with no `template` -- a statistic's ",
        "display format --
  but the table is not `stats = rows`.  ",
        "Give those rows a template, or set
  `tables$stats` to `rows`."))
    }
    if (any(!is.na(f$variable) | !is.na(f$context))) {
      .ard_stop(paste0(
        "A `cells` row with no template formats one statistic across the ",
        "table;
  leave its `variable` and `context` blank."))
    }
    if (any(is.na(f$row))) {
      .ard_stop(paste0("A `cells` row with no template needs `row`: the ",
                       "statistic it formats, as the label column prints it."))
    }
    fm <- lapply(seq_len(nrow(f)), function(i) {
      if (!is.na(f$signif[i])) list(signif = as.integer(f$signif[i]))
      else list(digits = as.integer(f$digits[i]))
    })
    add("tfl_plan_fmt", by = .spec_label_name(roles),
        formats = stats::setNames(fm, f$row))
  }

  lay <- if (nrow(sp$layout)) .ard_spec_typed(sp$layout[1L, ], "layout")
         else list()
  pick <- function(prefix, map) {
    out <- list()
    for (k in names(map)) {
      v <- lay[[paste0(prefix, k)]]
      if (!is.null(v)) out[[map[[k]]]] <- v
    }
    out
  }
  a <- pick("stub_", c(vars = "vars", into = "into", indent = "indent",
                       summary = "group_summary", before = "before"))
  if (length(a)) do.call(add, c(list("tfl_plan_stub"), a))
  if (isTRUE(lay[["group_page"]])) {
    add("tfl_plan_paginate_group", col = lay[["group_col"]],
        show = !identical(lay[["group_show"]], FALSE))
  }
  a <- pick("group_", c(mode = "mode", collapse = "collapse"))
  if (length(a) || (!is.null(lay[["group_col"]]) && !isTRUE(lay[["group_page"]]))) {
    a$col <- lay[["group_col"]]
    do.call(add, c(list("tfl_plan_row_group"), a))
  }
  a <- pick("blank_", c(where = "where", first = "first", last = "last",
                        counted = "counted"))
  if (length(a)) do.call(add, c(list("tfl_plan_blanks"), a))
  a <- pick("pages_", c(max_rows = "max_rows", split = "split", by = "by",
                        min_group_rows = "min_group_rows",
                        cont_label = "cont_label"))
  if (length(a)) do.call(add, c(list("tfl_plan_paginate_rows"), a))
  a <- pick("colpages_", c(every = "every", at = "at", carry = "carry",
                           order = "order"))
  if (length(a)) do.call(add, c(list("tfl_plan_paginate_cols"), a))

  sty <- if (nrow(sp$style)) .ard_spec_typed(sp$style[1L, ], "style")
         else list()
  cl <- sp$columns
  ct <- lapply(seq_len(nrow(cl)), function(i)
    .ard_spec_typed(cl[i, , drop = FALSE], "columns"))
  flag <- function(k) vapply(ct, function(r) isTRUE(r[[k]]), NA)
  if (any(flag("row_title"))) sty$row_title <- cl$column[flag("row_title")]
  if (length(sty)) do.call(add, c(list("tfl_plan_style"), sty))
  if (any(flag("hide"))) add("tfl_plan_hide", cl$column[flag("hide")])
  hd <- sp$col_header
  if (nrow(hd)) {
    cells <- hd[setdiff(names(hd), "output_id")]
    keep <- vapply(cells, function(v) any(!is.na(v)), NA)
    cells <- cells[keep]
    rownames(cells) <- NULL
    add("tfl_plan_col_header", header = cells,
        n = .ard_spec_table_args(sp)[["header_n"]])
  }
  w <- vapply(ct, function(r) r[["width"]] %||% NA_real_, NA_real_)
  if (any(!is.na(w)) || any(flag("decimal_split"))) {
    add("tfl_plan_columns",
        widths = if (any(!is.na(w)))
          stats::setNames(w[!is.na(w)], cl$column[!is.na(w)]),
        decimal = if (any(flag("decimal_split"))) cl$column[flag("decimal_split")])
  }
  st
}

#' The code of a table's plan, from its definition
#'
#' Writes the [tfl_plan()] pipeline a table definition stands for: the
#' roles of its `tables` sheet in `tfl_plan()`, and one `tfl_plan_*()` verb
#' for each thing the other sheets say -- the same verbs, with the same
#' values, that `tfl_table_plan(data, spec)` applies.  The program then no
#' longer reads the workbook, and what the workbook cannot say (a cell style,
#' a step after the pages are made) is written under it by hand.
#' [tfl_as_table_spec()] goes the other way.
#'
#' @param spec A table definition ([tfl_read_table_spec()],
#'   [tfl_table_spec()]), or the path(s) of its workbook(s).
#' @param output_id The table, when the definition has several.
#' @param data The name of the normalized ARD in the program.
#' @param plan The name the plan is assigned to.
#' @param pipe `"|>"` or `"%>%"`; `NULL` follows
#'   `getOption("tflspec.ard_pipe")` (see [tfl_plan_template()]).
#' @return The code, one element per line.
#' @seealso [tfl_report_code()] for the report around it.
#' @examples
#' spec <- tfl_read_table_spec(
#'   system.file("extdata", "ard-spec", "DM.xlsx", package = "tflspec"))
#' cat(tfl_table_code(spec), sep = "\n")
#' @export
tfl_table_code <- function(spec, output_id = NULL, data = "data",
                           plan = "plan", pipe = NULL) {
  sp <- .ard_spec_scope(if (is.character(spec))
                          tfl_read_table_spec(spec, output_id)
                        else tfl_table_spec(spec), output_id)
  roles <- .plan_spec_roles(sp)
  op <- .ard_pipe_op(pipe)
  head <- do.call(.spec_call, c(list("tfl_plan", .spec_sym(data)), roles))
  steps <- .plan_spec_steps(roles, sp)
  lines <- c(.spec_call_code(head, 0L),
             vapply(steps, function(s) paste0("  ", .spec_call_code(s)), ""))
  lines[-length(lines)] <- paste(lines[-length(lines)], op)
  lines[1L] <- paste(plan, "<-", lines[1L])
  unlist(strsplit(lines, "\n", fixed = TRUE))
}

#' A table's plan from its definition
#'
#' Builds the [tfl_plan()] a table definition stands for: the roles of its
#' `tables` sheet go into `tfl_plan()`, and the other sheets become the
#' plan's first layers through the same verbs [tfl_table_code()] writes ---
#' so a verb written afterwards still wins, which is how one report departs
#' from the study's workbook in a line of code.  Like `tfl_plan()`, the data
#' comes first, so it pipes.
#'
#' @param data The normalized ARD, as [tfl_plan()] takes it.
#' @param spec A table definition ([tfl_read_table_spec()],
#'   [tfl_table_spec()]), or the path(s) of its workbook(s).
#' @param output_id The table, when the definition has several.
#' @param ... Passed to [tfl_plan()]: a role given here (`cols`, `rows`,
#'   `label`, `stats`, `sep`, `value`, `na`, `sort_stat`) wins over the
#'   workbook's; `notes` as there.
#' @return An [tfl_plan()].
#' @seealso [tfl_table_code()], the same steps as code; [tfl_as_table_spec()],
#'   the other way round.
#' @examples
#' \dontrun{
#' spec <- tfl_read_table_spec("study.xlsx", output_id = "DM")
#' plan <- ard |> tfl_ard_normalize() |> tfl_table_plan(spec)
#' plan |> tfl_plan_paginate_rows(max_rows = 40)   # this report's own change
#' }
#' @export
tfl_table_plan <- function(data, spec, output_id = NULL, ...) {
  sp <- .ard_spec_scope(if (is.character(spec))
                          tfl_read_table_spec(spec, output_id)
                        else tfl_table_spec(spec), output_id)
  roles <- .plan_spec_roles(sp)
  dots <- list(...)
  own <- intersect(names(dots), c("cols", "rows", "label", "stats", "sep",
                                  "value", "na", "sort_stat"))
  for (r in own) if (!is.null(dots[[r]])) roles[[r]] <- dots[[r]]
  dots[own] <- NULL
  p <- do.call(tfl_plan, c(list(data), roles, dots))
  for (st in .plan_spec_steps(roles, sp)) {
    f <- get(st$fun, envir = asNamespace("tflspec"), mode = "function")
    p <- do.call(f, c(list(p), lapply(st$args, .spec_eval, env = emptyenv())))
  }
  p
}

# ---- reports ---------------------------------------------------------------

# The rtfreporter calls a report definition stands for, as `doc <- ...`
# steps: what tfl_report() runs and what tfl_report_code() writes.
# `content` is the name of the report's content in the program.
.report_spec_steps <- function(sp, content = "content") {
  r <- .ard_spec_report_row(sp)
  pg <- if (nrow(sp$page)) .ard_spec_typed(sp$page[1L, ], "page") else list()
  geo <- c("paper_size", "orientation", "width_in", "height_in",
           "margin_top_in", "margin_bottom_in", "margin_left_in",
           "margin_right_in", "header_dist_in", "footer_dist_in")
  page <- pg[intersect(geo, names(pg))]
  fmt <- pg[intersect(c("font_size_half_points", "title_format",
                        "footnote_format", "title_width", "footnote_width",
                        "markup"), names(pg))]
  for (w in intersect(c("title_width", "footnote_width"), names(fmt))) {
    v <- suppressWarnings(as.numeric(fmt[[w]]))
    if (!is.na(v)) fmt[[w]] <- v
  }
  dir <- .ard_spec_study_value(sp, "program_dir")
  prog <- r$program
  if (!is.na(dir)) {
    sep <- if (grepl("\\", dir, fixed = TRUE)) "\\" else "/"
    prog <- paste(sub("[\\\\/]+$", "", dir), prog, sep = sep)
  }
  doc <- .spec_sym("doc")
  st <- list(.spec_call("rtf_document",
                        page = if (length(page)) page,
                        default_format = if (length(fmt))
                          do.call(.spec_call, c(list("rtf_default_format"), fmt)),
                        program = prog))
  # a report may go without the study's running header or footer -- one
  # that puts its run line under the table instead, say
  hdr <- if (!identical(r$page_header, FALSE)) .ard_spec_band(sp, "header")
  ftr <- if (!identical(r$page_footer, FALSE)) .ard_spec_band(sp, "footer")
  if (length(hdr) || length(ftr)) {
    st[[length(st) + 1L]] <- .spec_call("rtf_section", doc, secinfo = list(
      header = if (length(hdr)) .spec_call("rtf_header", hdr),
      footer = if (length(ftr)) .spec_call("rtf_footer", ftr))[
        c(if (length(hdr)) "header", if (length(ftr)) "footer")])
  }
  if (identical(r$type %||% "table", "figure")) {
    st[[length(st) + 1L]] <- .spec_call("rtf_figures", doc, .spec_sym(content))
  } else {
    st[[length(st) + 1L]] <- .spec_call("rtf_tables", doc, .spec_sym(content),
      auto_section = r$auto_section,
      section_label_align = r$section_align,
      auto_title = r$auto_title,
      title_label_align = r$title_align,
      font_size_half_points = r$table_font_size)
  }
  tt <- .ard_spec_band(sp, "titles")
  if (length(tt)) {
    st[[length(st) + 1L]] <- .spec_call("rtf_titles", doc, list(tt),
      font_size_half_points = r$title_font_size)
  }
  fn <- .ard_spec_band(sp, "footnotes")
  if (length(fn)) {
    st[[length(st) + 1L]] <- .spec_call("rtf_footnotes", doc, list(fn),
      font_size_half_points = r$footnote_font_size)
  }
  st
}

#' The code of a report's document, from its definition
#'
#' Writes the rtfreporter calls a report definition stands for -- the
#' page, the running header and footer, the content, the titles and
#' footnotes -- as `doc <- rtf_document(...)` and one `doc <- rtf_*(doc, ...)`
#' a step: what [tfl_report()] does, as a program that needs only
#' rtfreporter.  Write it out with
#' `generate_rtfreport(doc, "<file>.rtf")` ([tfl_report_path()] says which).
#'
#' @inheritParams tfl_report
#' @param content The name of the report's content in the program: a plan
#'   ([tfl_table_code()]), `rtftable` pages ([tfl_listing_code()]) or the
#'   figures.
#' @param doc The name the document is assigned to.
#' @return The code, one element per line.
#' @examples
#' spec <- tfl_read_report_spec(
#'   system.file("extdata", "ard-spec", c("report.xlsx", "study.xlsx"),
#'               package = "tflspec"), output_id = "DM")
#' cat(tfl_report_code(spec, content = "plan"), sep = "\n")
#' @export
tfl_report_code <- function(spec, output_id = NULL, content = "content",
                            doc = "doc") {
  sp <- .ard_spec_scope(if (is.character(spec))
                          tfl_read_report_spec(spec, output_id)
                        else tfl_table_spec(spec), output_id)
  steps <- .report_spec_steps(sp, content)
  out <- vapply(steps, function(s) {
    if (length(s$args) && inherits(s$args[[1L]], "tfl_spec_sym") &&
        identical(s$args[[1L]]$name, "doc")) {
      s$args[[1L]] <- .spec_sym(doc)
    }
    paste(doc, "<-", .spec_call_code(s, 0L))
  }, "")
  unlist(strsplit(out, "\n", fixed = TRUE))
}
