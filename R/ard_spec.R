# ============================================================================
#  The study's ARD from its definition (ARD spec)
# ----------------------------------------------------------------------------
#  Moved from tflplanner (R/ard_spec.R) so the definition -> code -> ARD
#  engine works without the GUI.  tflplanner keeps what belongs to a study
#  folder: editing the rows, saving the programs, running them, the status.
#
# A study's analyses are rows: which data, which population, which subset,
# grouped by what, which variables, which method and statistics.  Each row
# becomes one cards / cardx call; every result is tagged with the ids that
# trace it -- output_id, analysis_id, population_id -- and all of them are
# bound into ONE ARD for the study (output/ard/ard.rds).
#
# The workbook is turned into R code (tfl_ard_code()) and the ARD is made by
# running that code (tfl_build_ard()), so the code a programmer can read, keep
# and rerun is exactly what made the ARD.
#
#   study        key / value: id (the subject key, USUBJID), output (where
#                the ARD goes)
#   datasets     dataset, path, derive           the analysis data
#   populations  population_id, dataset, where,  analysis sets (and the
#                derive                          denominators)
#   analyses     output_id, analysis_id, method, dataset, population_id,
#                where, by, variables, statistics, formats, args, code
#
# The concepts are those of CDISC ARS (analysis set, data subset, grouping,
# method), so an tfl_ard_spec can later be written as ARS metadata.

.ard_spec_sheets <- list(
  study = c("key", "value"),
  datasets = c("dataset", "level", "path", "derive"),
  populations = c("population_id", "dataset", "where", "derive"),
  analyses = c("output_id", "analysis_id", "label", "method", "dataset",
               "population_id", "where", "by", "variables", "statistics",
               "formats", "args", "code", "purpose", "reason"))

.split_bar <- function(x) {
  if (is.null(x) || is.na(x) || !nzchar(trimws(x))) return(character())
  trimws(strsplit(x, "|", fixed = TRUE)[[1L]])
}

# The call an analysis row stands for, with `data` and `population` bound.
.analysis_body <- function(r, keys, subj, has) {
  m <- r$method
  k <- match(m, keys$method)
  fn <- if (is.na(k)) m else keys$call[k]
  kind <- if (is.na(k)) "" else keys$kind[k]
  stats <- if (!is.na(r$statistics)) r$statistics else if (!is.na(k) &&
    nzchar(keys$statistics[k])) keys$statistics[k] else NA
  if (identical(fn, "(code)")) return(r$code)
  by <- .vars(r$by)
  vars <- .vars(r$variables)
  if (identical(fn, "(subjects)")) {
    # a subject-level flag: has the subject any record of the data?
    flag <- if (length(.split_bar(r$variables))) .split_bar(r$variables)[1L] else
      make.names(r$analysis_id)
    st <- if (!has("statistic")) .stat_arg("categorical", stats)
    return(paste0(
      sprintf("population$%s <- population$%s %%in%% data$%s\n", flag, subj,
              subj),
      sprintf("cards::ard_dichotomous(population%s, variables = %s, value = list(%s = TRUE)%s%s)",
              if (!is.null(by)) paste0(", by = ", by) else "", flag, flag,
              if (!is.null(st)) paste0(", ", st) else "",
              if (!is.na(r$args)) paste0(", ", r$args) else "")))
  }
  # the keyword's own arguments, each unless the row's args gives it
  dflt <- if (!is.na(k) && nzchar(keys$defaults[k])) {
    d <- trimws(strsplit(gsub("<id>", subj, keys$defaults[k], fixed = TRUE),
                         ",")[[1L]])
    d[!vapply(sub("\\s*=.*$", "", d), has, NA)]
  }
  args <- c(
    if (!is.null(by)) paste("by =", by),
    if (!identical(fn, "cards::ard_total_n") && !is.null(vars))
      paste("variables =", vars),
    if (!has("statistic")) .stat_arg(kind, stats),
    dflt,
    if (!is.na(r$args)) r$args)
  sprintf("%s(%s)", fn, paste(c(.data_arg(fn, has), args),
                               collapse = ",\n    "))
}

# How the analysis data goes into a method's call: `data` first, as cards
# and cardx functions take it; nothing when the function's first argument
# is given in `args` and it has no `data` argument (a fitted model:
# cardx::ard_car_anova(x = lm(..., data = data))).  A function that cannot
# be looked up (its package not installed) takes `data` first.
.data_arg <- function(fn, has) {
  f <- tryCatch(eval(str2lang(fn)), error = function(e) NULL)
  if (!is.function(f)) return("data")
  fm <- names(formals(f))
  if ("data" %in% fm || !length(fm)) return("data")
  if (fm[1L] != "..." && has(fm[1L])) return(NULL)
  "data"
}

.normalize_ard_sheet <- function(d, sheet) {
  cols <- .ard_spec_sheets[[sheet]]
  d <- as.data.frame(d, stringsAsFactors = FALSE)
  out <- lapply(cols, function(c) {
    v <- if (c %in% names(d)) as.character(d[[c]]) else
      rep(NA_character_, nrow(d))
    v <- trimws(v)
    v[!is.na(v) & !nzchar(v)] <- NA
    v
  })
  out <- as.data.frame(stats::setNames(out, cols), stringsAsFactors = FALSE)
  out <- out[rowSums(!is.na(out)) > 0, , drop = FALSE]
  rownames(out) <- NULL
  out
}

#' Write an ARD definition to a workbook
#'
#' Writes the four sheets (`study`, `datasets`, `populations`, `analyses`)
#' and no more; what each column means is a comment on its header cell
#' ([tfl_spec_columns()]).  [tfl_read_ard_spec()] takes one back.  With
#' other specs in one workbook: [tfl_write_specs()].
#'
#' @param spec An ARD definition: an [tfl_ard_spec()], or a list of the sheets.
#' @param path The workbook to write.
#' @param statistics,methods The catalogs ([tfl_ard_statistics()],
#'   [tfl_ard_methods()]) to use instead of the current ones.
#' @param catalogs `TRUE` also writes the catalogs the spec is checked
#'   against, as the sheets `_methods` and `_statistics` (for reference: the
#'   reader passes over sheets whose name starts with `_`).
#' @return `path`, invisibly.
#' @export
tfl_write_ard_spec <- function(spec, path, statistics = NULL, methods = NULL,
                               catalogs = FALSE) {
  old <- .set_catalogs(statistics, methods)
  on.exit(options(old), add = TRUE)
  a <- .ard_spec_normalized(spec)
  .write_spec_book(c(a, if (isTRUE(catalogs))
    list(`_methods` = tfl_ard_methods(),
         `_statistics` = tfl_ard_statistics())), path)
}

# the four sheets of an ARD definition, in shape
.ard_spec_normalized <- function(spec) {
  stats::setNames(lapply(names(.ard_spec_sheets), function(s)
    .normalize_ard_sheet(spec[[s]], s)), names(.ard_spec_sheets))
}

.ard_readme <- function() {
  data.frame(
    sheet = c("study", "datasets", "datasets", "populations", "populations",
              "analyses", "analyses", "analyses", "analyses", "analyses",
              "analyses", "analyses"),
    column = c("key / value", "dataset / path", "derive",
               "population_id / dataset / where", "derive",
               "output_id / analysis_id", "method",
               "dataset / population_id / where",
               "by / variables / statistics", "formats", "args / code",
               "purpose / reason"),
    description = c(
      "id: the subject key (USUBJID); output: where the study ARD goes",
      "a name for the data, and its file relative to the study folder",
      "new columns, NAME = R expression, | between them",
      "an analysis set: the subjects of `dataset` for which `where` (R) holds",
      "columns added to the population (TRTA = TRT01A ...)",
      "the report the analysis serves, and its id; both are ARD columns",
      "a keyword (tfl_ard_methods()) or any pkg::function (cards::, cardx::)",
      "the analysis data: `dataset` restricted to the population and `where`",
      "grouping and analysis variables, statistics (tfl_ard_statistics()); | between several",
      "stat_fmt formats: statistic=format, | between them (mean=xx.x | p=xx.x% | AGE:sd=xx.xx); blank = the default of the statistic",
      "more arguments as R; `code` for custom (data, population are bound)",
      "for CDISC ARS (tfl_ars()): PRIMARY / SECONDARY / EXPLORATORY OUTCOME MEASURE; SPECIFIED IN PROTOCOL / SPECIFIED IN SAP (default) / DATA DRIVEN / REQUESTED BY REGULATORY AGENCY"),
    stringsAsFactors = FALSE)
}

#' Read and check an ARD definition workbook
#'
#' @param path An `ard_spec.xlsx`.
#' @param check `FALSE` reads a definition still being written without
#'   refusing it.
#' @inheritParams tfl_write_ard_spec
#' @return An `tfl_ard_spec`: a list of the four sheets.
#' @export
tfl_read_ard_spec <- function(path, check = TRUE, statistics = NULL,
                          methods = NULL) {
  sheets <- readxl::excel_sheets(path)
  out <- lapply(names(.ard_spec_sheets), function(s) {
    cols <- .ard_spec_sheets[[s]]
    d <- if (s %in% sheets) .xlsx_text(path, s) else
      data.frame(matrix(character(), 0, length(cols),
                        dimnames = list(NULL, cols)))
    bad <- setdiff(names(d), c(cols, "note"))
    if (length(bad)) {
      stop("Sheet `", s, "` has columns it does not read: ",
           paste(bad, collapse = ", "), call. = FALSE)
    }
    for (c in cols) if (!c %in% names(d)) d[[c]] <- NA_character_
    d <- d[cols]
    d[] <- lapply(d, function(v) {
      v <- trimws(as.character(v))
      v[!is.na(v) & !nzchar(v)] <- NA
      v
    })
    d[rowSums(!is.na(d)) > 0, , drop = FALSE]
  })
  names(out) <- names(.ard_spec_sheets)
  if (check) tfl_ard_spec(out, statistics = statistics, methods = methods) else
    structure(out, class = "tfl_ard_spec")
}

# a sheet as text, as it reads in Excel
.xlsx_text <- function(path, sheet) {
  d <- readxl::read_excel(path, sheet, col_types = "text",
                          .name_repair = "minimal")
  .xlsx_lf(as.data.frame(d, stringsAsFactors = FALSE, check.names = FALSE))
}

# A line break in a cell as "\n".  openxlsx on Windows writes "\n" as
# "\r\n" (its XML goes out in text mode), so each write would add a "\r".
.xlsx_lf <- function(d) {
  for (j in seq_along(d)) {
    if (is.character(d[[j]])) d[[j]] <- gsub("\r\n", "\n", d[[j]],
                                             fixed = TRUE)
  }
  d
}

#' @rdname tfl_read_ard_spec
#' @param x A list of the sheets (data frames).
#' @export
tfl_ard_spec <- function(x, statistics = NULL, methods = NULL) {
  old <- .set_catalogs(statistics, methods)
  on.exit(options(old), add = TRUE)
  x <- structure(x, class = "tfl_ard_spec")
  a <- x$analyses
  err <- character()
  need <- c("output_id", "analysis_id", "method")
  for (k in need) {
    if (any(is.na(a[[k]]))) err <- c(err, sprintf("`analyses$%s` is blank in row(s) %s", k,
                                                   paste(which(is.na(a[[k]])), collapse = ", ")))
  }
  dup <- duplicated(paste(a$output_id, a$analysis_id))
  if (any(dup)) err <- c(err, sprintf("output_id / analysis_id repeated: %s",
                                      paste(unique(paste(a$output_id, a$analysis_id)[dup]),
                                            collapse = ", ")))
  m <- stats::na.omit(a$method)
  bad <- m[!m %in% tfl_ard_methods()$method & !grepl("^[A-Za-z.][A-Za-z0-9.]*::[A-Za-z._][A-Za-z0-9._]*$", m)]
  if (length(bad)) err <- c(err, sprintf(
    "unknown method(s): %s (a keyword of tfl_ard_methods(), or pkg::function)",
    paste(unique(bad), collapse = ", ")))
  miss <- setdiff(stats::na.omit(c(a$dataset, x$populations$dataset)),
                  x$datasets$dataset)
  if (length(miss)) err <- c(err, sprintf("dataset(s) not in `datasets`: %s",
                                          paste(miss, collapse = ", ")))
  miss <- setdiff(stats::na.omit(a$population_id),
                  x$populations$population_id)
  if (length(miss)) err <- c(err, sprintf("population(s) not in `populations`: %s",
                                          paste(miss, collapse = ", ")))
  keys <- tfl_ard_methods()
  st <- tfl_ard_statistics()
  for (i in seq_len(nrow(a))) {
    k <- match(a$method[i], keys$method)
    s <- .split_bar(a$statistics[i])
    if (!is.na(k) && keys$kind[k] == "continuous") {
      bad <- setdiff(s, st$statistic[st$kind == "continuous"])
      if (length(bad)) err <- c(err, sprintf(
        "%s / %s: no continuous statistic %s (see tfl_ard_statistics())",
        a$output_id[i], a$analysis_id[i], paste(bad, collapse = ", ")))
    }
    f <- .parse_formats(a$formats[i])
    bad <- names(f)[is.na(f) | !.fmt_ok(f)]
    if (length(bad)) err <- c(err, sprintf(
      "%s / %s: formats are statistic=format, the format xx.x, xx.x%%, a number of decimals or pvalue (%s)",
      a$output_id[i], a$analysis_id[i], paste(bad, collapse = ", ")))
  }
  cust <- a$method %in% "custom" & is.na(a$code)
  if (any(cust)) err <- c(err, "a `custom` analysis needs its `code`")
  if (length(err)) stop(paste(c("The ARD definition is not valid:", err),
                              collapse = "\n  "), call. = FALSE)
  x
}

.study_value <- function(x, key, default) {
  v <- x$study$value[match(key, x$study$key)]
  if (length(v) && !is.na(v)) v else default
}

.r_name <- function(x) make.names(tolower(x))

# `NAME = expr | NAME = expr` as a transform() call on `obj`
.derive_code <- function(obj, derive) {
  d <- .split_bar(derive)
  if (!length(d)) return(NULL)
  sprintf("%s <- transform(%s, %s)", obj, obj, paste(d, collapse = ", "))
}

.reader <- function(path) {
  ext <- tolower(tools::file_ext(path))
  f <- switch(ext, rds = "readRDS", xpt = "haven::read_xpt",
              sas7bdat = "haven::read_sas", csv = "utils::read.csv",
              parquet = "arrow::read_parquet",
              stop("No reader for .", ext, call. = FALSE))
  sprintf("%s(%s)", f, encodeString(path, quote = "\""))
}

.vars <- function(x) {
  v <- .split_bar(x)
  if (!length(v)) return(NULL)
  if (length(v) == 1L) v else sprintf("c(%s)", paste(v, collapse = ", "))
}

.stat_arg <- function(method, stats) {
  s <- .split_bar(stats)
  if (!length(s)) return(NULL)
  q <- function(v) paste(encodeString(v, quote = "\""), collapse = ", ")
  switch(method,
    continuous = {
      # cards' own statistics and those computed by .tfl_stats, in the
      # order asked
      own <- !s %in% .computed_stats()
      run <- cumsum(c(TRUE, own[-1L] != own[-length(own)]))
      parts <- vapply(split(seq_along(s), run), function(i) {
        if (own[i[1L]]) sprintf("cards::continuous_summary_fns(c(%s))", q(s[i]))
        else sprintf(".tfl_stats[c(%s)]", q(s[i]))
      }, "")
      sprintf("statistic = ~ %s", if (length(parts) == 1L) parts else
        sprintf("c(%s)", paste(parts, collapse = ", ")))
    },
    categorical = ,
    missing = sprintf("statistic = ~ c(%s)", q(s)),
    NULL)
}

# the continuous statistics the ARD program computes (not cards)
.computed_stats <- function() {
  d <- tfl_ard_statistics("continuous")
  d$statistic[!is.na(d$fun)]
}

# the kinds of statistic a method's analysis may ask for
.stat_kinds <- function(kind) {
  switch(kind %||% "",
         continuous = "continuous", categorical = "categorical",
         missing = "missing", "result")
}

.fmt_ok <- function(f) grepl("^(x+(\\.x+)?%?|[0-9]+|pvalue)$", f)

# `mean=xx.x | AGE:sd=xx.xx` as a named vector
.parse_formats <- function(x) {
  p <- .split_bar(x)
  if (!length(p)) return(character())
  k <- trimws(sub("=.*$", "", p))
  v <- trimws(sub("^[^=]*=", "", p))
  v[!grepl("=", p, fixed = TRUE)] <- NA
  stats::setNames(v, k)
}

.fmt_vector <- function(f) {
  if (!length(f)) return("character()")
  sprintf("c(%s)", paste(sprintf("%s = %s", encodeString(names(f), quote = "`"),
                                 encodeString(f, quote = "\"")),
                         collapse = ", "))
}

# the helpers every ARD program starts with: the computed statistics it
# uses, and stat_fmt
.ard_helpers <- function(used) {
  st <- tfl_ard_statistics()
  cst <- st[st$kind == "continuous" & !is.na(st$fun) & st$statistic %in% used, ]
  dflt <- st[!duplicated(st$statistic) & !is.na(st$fmt), ]
  dflt <- stats::setNames(dflt$fmt, dflt$statistic)
  fl <- sprintf("%s = %s", encodeString(names(dflt), quote = "`"),
                encodeString(dflt, quote = "\""))
  fl <- vapply(split(fl, ceiling(seq_along(fl) / 5)), paste, "",
               collapse = ", ")
  c(if (nrow(cst)) c(
      "# statistics cards does not compute itself (company standards)",
      ".tfl_stats <- list(",
      paste0("  ", encodeString(cst$statistic, quote = "`"), " = ", cst$fun,
             c(rep(",", nrow(cst) - 1L), "")),
      ")", ""),
    "# stat_fmt: each statistic formatted -- xx.x = 1 decimal, xx.x% = a",
    "# proportion as a percent, pvalue = <0.001 or 3 decimals",
    ".fmt_default <- c(",
    paste0("  ", fl, c(rep(",", length(fl) - 1L), "")),
    ")",
    ".fmt <- function(ard, fmt = character()) {",
    "  # a method that gives several ARDs (cards::ard_pairwise(): one per",
    "  # pair of groups): one, each row keeping its ARD's name as `pairwise`",
    "  if (is.list(ard) && !is.data.frame(ard)) {",
    "    ard <- dplyr::bind_rows(ard, .id = \"pairwise\")",
    "  }",
    "  if (!inherits(ard, \"card\")) return(ard)",
    "  f <- .fmt_default",
    "  f[names(fmt)] <- fmt",
    "  f <- f[order(grepl(\":\", names(f), fixed = TRUE))]",
    "  for (k in names(f)) {",
    "    s <- sub(\"^.*:\", \"\", k)",
    "    v <- if (grepl(\":\", k, fixed = TRUE)) sub(\":.*$\", \"\", k)",
    "    rows <- ard$stat_name == s & (is.null(v) | ard$variable %in% v)",
    "    if (!any(rows)) next",
    "    fun <- if (f[[k]] == \"pvalue\") {",
    "      function(x) ifelse(x < 0.001, \"<0.001\", sprintf(\"%.3f\", x))",
    "    } else {",
    "      # the decimals (the x after the point, or the number); % scales by 100",
    "      d <- if (grepl(\"^[0-9]+$\", f[[k]])) as.integer(f[[k]]) else",
    "        nchar(sub(\"^[^.]*[.]?\", \"\", sub(\"%$\", \"\", f[[k]])))",
    "      sc <- if (endsWith(f[[k]], \"%\")) 100 else 1",
    "      local({ d <- d; sc <- sc; cards::label_round(d, scale = sc) })",
    "    }",
    "    ard <- cards::update_ard_fmt_fun(",
    "      ard, variables = dplyr::all_of(unique(ard$variable[rows])),",
    "      stat_names = s, fmt_fun = fun)",
    "  }",
    "  cards::apply_fmt_fun(ard)",
    "}",
    "# only the statistics asked for, of a method that gives more",
    ".keep <- function(ard, keep) ard[ard$stat_name %in% keep, , drop = FALSE]",
    "")
}

#' The R code that makes the study's ARD
#'
#' One cards / cardx call per analysis row, each result tagged with its
#' `output_id`, `analysis_id` and `population_id`, bound into one ARD and
#' saved to the study key `output` (default `output/ard/ard.rds`).  The code
#' runs from the study folder.
#'
#' `part` gives a piece of it instead, for a program layout of one's own
#' (tflplanner writes one program per output that sources a shared setup):
#' `"setup"` is what every piece starts with -- `library(cards)`, the
#' tagging helper, every computed statistic of the catalog and the
#' `stat_fmt` helpers; `"body"` is the analyses of `output_id`, ending in
#' `ard` -- without a header or `saveRDS()`.
#'
#' @param spec An [tfl_ard_spec()] (or the path of one).
#' @param output_id Only these outputs' analyses; `NULL` for all.
#' @param save `FALSE` leaves out the final `saveRDS()`.
#' @param part `"all"` (the whole program), `"setup"` or `"body"`.
#' @inheritParams tfl_write_ard_spec
#' @return The code, one element per line.
#' @export
tfl_ard_code <- function(spec, output_id = NULL, save = TRUE,
                          part = c("all", "setup", "body"),
                          statistics = NULL, methods = NULL) {
  part <- match.arg(part)
  old <- .set_catalogs(statistics, methods)
  on.exit(options(old), add = TRUE)
  x <- if (is.character(spec)) tfl_read_ard_spec(spec) else spec
  a <- x$analyses
  if (!is.null(output_id)) a <- a[a$output_id %in% output_id, , drop = FALSE]
  if (part == "setup") {
    st <- tfl_ard_statistics("continuous")
    return(.ard_common_lines(st$statistic[!is.na(st$fun)]))
  }
  if (part == "body") return(.ard_body_lines(x, a))
  out <- .study_value(x, "output", "output/ard/ard.rds")
  code <- c(
    "# The study's ARD, made from its ARD definition.  Run from the study folder.",
    paste0("# Generated by tflspec ", utils::packageVersion("tflspec"),
           ", ", format(Sys.Date())),
    "",
    .ard_common_lines(unlist(lapply(a$statistics, .split_bar))),
    .ard_body_lines(x, a))
  if (save) {
    ids <- unique(a$output_id)
    hashes <- vapply(ids, function(id) .ard_output_hash(x, id), "")
    q <- function(v) paste(encodeString(v, quote = "\""), collapse = ", ")
    code <- c(code,
              sprintf("dir.create(dirname(%s), recursive = TRUE, showWarnings = FALSE)",
                      encodeString(out, quote = "\"")),
              sprintf("saveRDS(ard, %s)", encodeString(out, quote = "\"")),
              "# what was built, and from which definition (tfl_ard_spec_hash())",
              "status <- data.frame(",
              sprintf("  output_id = c(%s),", q(ids)),
              sprintf("  definition = c(%s),", q(hashes)),
              "  built = format(Sys.time(), \"%Y-%m-%d %H:%M:%S\"),",
              "  stringsAsFactors = FALSE)",
              "status$rows <- as.integer(table(factor(ard$output_id, levels = status$output_id)))",
              sprintf("utils::write.csv(status, file.path(dirname(%s), \"ard_status.csv\"), row.names = FALSE)",
                      encodeString(out, quote = "\"")))
  }
  c(code, "")
}


# library(cards), .tag() and the helpers (the computed statistics `used`,
# stat_fmt)
.ard_common_lines <- function(used) {
  c("library(cards)",
    "",
    ".tag <- function(ard, output_id, analysis_id, population_id) {",
    "  ard <- as.data.frame(ard)",
    "  cbind(output_id = output_id, analysis_id = analysis_id,",
    "        population_id = population_id, ard, stringsAsFactors = FALSE)",
    "}",
    "",
    .ard_helpers(used))
}

# the analyses `a`: their data, their analysis sets, one call each, bound
# into `ard`
.ard_body_lines <- function(x, a) {
  subj <- .study_value(x, "id", "USUBJID")
  code <- "# ---- data"
  used_ds <- unique(stats::na.omit(c(a$dataset, x$populations$dataset[
    x$populations$population_id %in% a$population_id])))
  for (ds in used_ds) {
    r <- x$datasets[x$datasets$dataset == ds, ]
    obj <- .r_name(ds)
    code <- c(code, sprintf("%s <- %s", obj, .reader(r$path[1L])),
              .derive_code(obj, r$derive[1L]))
  }
  code <- c(code, "", "# ---- populations")
  for (pid in unique(stats::na.omit(a$population_id))) {
    r <- x$populations[x$populations$population_id == pid, ]
    obj <- paste0("pop_", .r_name(pid))
    src <- .r_name(r$dataset[1L])
    code <- c(code, if (is.na(r$where[1L])) sprintf("%s <- %s", obj, src) else
      sprintf("%s <- subset(%s, %s)", obj, src, r$where[1L]),
      .derive_code(obj, r$derive[1L]))
  }
  code <- c(code, "", "# ---- analyses", "ards <- list()")
  keys <- tfl_ard_methods()
  for (i in seq_len(nrow(a))) {
    r <- a[i, ]
    pid <- r$population_id
    pop <- if (!is.na(pid)) paste0("pop_", .r_name(pid))
    ds <- if (!is.na(r$dataset)) .r_name(r$dataset) else pop
    pop_ds <- if (!is.na(pid)) x$populations$dataset[
      x$populations$population_id == pid][1L]
    # the analysis data: the dataset, restricted to the population's
    # subjects (or the population itself when it is that dataset), and
    # to the analysis's own subset
    data <- if (is.null(pop)) ds else if (identical(r$dataset, pop_ds) ||
                                          is.na(r$dataset)) pop else
      sprintf("subset(%s, %s %%in%% %s$%s)", ds, subj, pop, subj)
    if (!is.na(r$where)) data <- sprintf("subset(%s, %s)", data, r$where)
    given <- if (is.na(r$args)) "" else r$args
    has <- function(arg) grepl(paste0("(^|[,(\\s])", arg, "\\s*="), given)
    body <- .analysis_body(r, keys, subj, has)
    k <- match(r$method, keys$method)
    kind <- if (is.na(k)) "" else keys$kind[k]
    keep <- if (!kind %in% c("continuous", "categorical", "missing") &&
                !identical(keys$call[k], "(subjects)"))
      .split_bar(r$statistics)
    fmt <- c(if (!is.na(k)) .parse_formats(keys$formats[k]),
             .parse_formats(r$formats))
    fmt <- fmt[!duplicated(names(fmt), fromLast = TRUE)]
    code <- c(code,
              sprintf("# %s / %s%s", r$output_id, r$analysis_id,
                      if (!is.na(r$label)) paste(":", r$label) else ""),
              sprintf("ards[[%d]] <- .tag(local({", i),
              paste0("  data <- ", data),
              paste0("  population <- ", if (is.null(pop)) "NULL" else pop),
              "  ard <- local({",
              paste0("    ", strsplit(body, "\n", fixed = TRUE)[[1L]]),
              "  })",
              if (length(keep)) sprintf("  ard <- .keep(ard, c(%s))",
                                        paste(encodeString(keep, quote = "\""),
                                              collapse = ", ")),
              sprintf("  .fmt(ard%s)", if (length(fmt))
                paste0(", ", .fmt_vector(fmt)) else ""),
              sprintf("}), %s, %s, %s)",
                      encodeString(r$output_id, quote = "\""),
                      encodeString(r$analysis_id, quote = "\""),
                      if (is.na(pid)) "NA_character_" else
                        encodeString(pid, quote = "\"")))
  }
  c(code, "", "ard <- do.call(dplyr::bind_rows, ards)")
}

# A fingerprint of what makes an output's ARD: its analysis rows and the
# data, populations and study keys they use.  A built ARD whose fingerprint
# differs from the definition's now is outdated.
#' A fingerprint of one output's ARD definition
#'
#' The md5 of what makes an output's ARD: its analysis rows and the data,
#' populations and study keys they use.  An ARD built from a definition
#' whose fingerprint differs from the one now is outdated.
#'
#' @param spec An [tfl_ard_spec()].
#' @param output_id The output.
#' @return A single string.
#' @export
tfl_ard_spec_hash <- function(spec, output_id) .ard_output_hash(spec, output_id)

.ard_output_hash <- function(spec, output_id) {
  a <- spec$analyses[spec$analyses$output_id %in% output_id, , drop = FALSE]
  pops <- spec$populations[spec$populations$population_id %in%
                             a$population_id, , drop = FALSE]
  dss <- spec$datasets[spec$datasets$dataset %in%
                         c(a$dataset, pops$dataset), , drop = FALSE]
  txt <- paste(c(utils::capture.output(print(as.list(a[order(a$analysis_id), ]))),
                 utils::capture.output(print(as.list(pops))),
                 utils::capture.output(print(as.list(dss[setdiff(names(dss), "level")]))),
                 utils::capture.output(print(as.list(spec$study)))),
               collapse = "\n")
  f <- tempfile()
  on.exit(unlink(f))
  writeLines(enc2utf8(txt), f, useBytes = TRUE)
  unname(tools::md5sum(f))
}

#' Make the study's ARD from its definition
#'
#' Runs [tfl_ard_code()] from the study folder: the ARD is exactly what the
#' code gives.
#'
#' @inheritParams tfl_ard_code
#' @param dir The study folder (the code's working directory).
#' @return The ARD (with `output_id`, `analysis_id`, `population_id`),
#'   invisibly; with `save`, also written where the study key `output`
#'   says.
#' @export
tfl_build_ard <- function(spec, dir = ".", output_id = NULL, save = TRUE,
                      statistics = NULL, methods = NULL) {
  code <- tfl_ard_code(spec, output_id = output_id, save = save,
                        statistics = statistics, methods = methods)
  owd <- setwd(dir)
  on.exit(setwd(owd), add = TRUE)
  e <- new.env(parent = globalenv())
  eval(parse(text = code, encoding = "UTF-8"), envir = e)
  invisible(e$ard)
}

#' One output's part of the study ARD
#'
#' @param ard The study ARD ([tfl_build_ard()]).
#' @param output_id The output.
#' @return Its rows, without the id columns: what [rtfreporter::normalize_ard()]
#'   takes.
#' @export
tfl_ard_for <- function(ard, output_id) {
  d <- ard[ard$output_id == output_id, , drop = FALSE]
  d[setdiff(names(d), c("output_id", "analysis_id", "population_id"))]
}
