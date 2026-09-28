# ============================================================================
#  A listing from its definition rows -> the R code that makes it
# ----------------------------------------------------------------------------
#  Moved from tflplanner (R/lf.R).  A listing is defined like a table, in
#  rows: which data (a dataset of the study's data catalog and a condition),
#  in which order, over how many rows a page, and its columns (rtfreporter's
#  listing_col(): the variables stacked in a column, the header, the width,
#  whether a repeated value is printed once).  The code reads the data,
#  reworks it when there is rework code, and lays it out with
#  rtfreporter's listing_spec() / as_rtftables().  How a listing is laid
#  out on the page stays rtfreporter's; this only writes the calls.
# ============================================================================

#' The code that reads one dataset of a data catalog
#'
#' Writes `adsl <- haven::read_xpt("data/adam/adsl.xpt")` (the reader follows
#' the file's extension: `.rds`, `.xpt`, `.sas7bdat`, `.csv`, `.parquet`)
#' into an object named after the dataset, and its derived columns.
#'
#' @param datasets The data catalog: a data frame with `dataset`, `path`
#'   and `derive` (`NAME = R expression`, `|` between them), as the
#'   `datasets` sheet of an [tfl_ard_spec()].
#' @param dataset The dataset to read.
#' @return The code, one element per line.  A dataset the catalog does not
#'   have gives a `stop()` line, so the program says so when it runs.
#' @export
tfl_read_data_code <- function(datasets, dataset) {
  r <- datasets[!is.na(datasets$dataset) & datasets$dataset == dataset, ,
                drop = FALSE]
  if (!nrow(r) || is.na(r$path[1L])) {
    return(sprintf("stop(\"tflplanner: dataset %s is not in the data catalog.\")",
                   dataset))
  }
  obj <- .r_name(dataset)
  c(sprintf("%s <- %s", obj, .reader(r$path[1L])),
    .derive_code(obj, r$derive[1L]))
}

.r_sort <- function(obj, sort) {
  s <- .split_bar(sort)
  if (!length(s)) return(NULL)
  keys <- vapply(s, function(k) {
    if (startsWith(k, "-")) sprintf("-xtfrm(%s$%s)", obj, substring(k, 2L))
    else sprintf("%s$%s", obj, k)
  }, "")
  sprintf("%s <- %s[order(%s), , drop = FALSE]", obj, obj,
          paste(keys, collapse = ", "))
}

.r_label <- function(x) {
  encodeString(gsub("\\n", "\n", x, fixed = TRUE), quote = "\"")
}

#' The code that makes a listing from its definition
#'
#' From one row of a `listings` sheet and its rows of `listing_cols`, writes
#' the part of a listing program that reads the data, subsets, reworks and
#' sorts it, and lays it out: `content <- as_rtftables(data, listing = lst)`.
#' The program's setup (`library(rtfreporter)`) and its report are the
#' caller's.
#'
#' @param listing One row: `dataset`, `where` (R), `sort` (variables, `|`
#'   between them, `-` for descending), `max_rows`, `type` (blank: `type`
#'   below).
#' @param cols Its columns, one row each: `vars` (`|` between variables
#'   stacked in one column), `label` (`\n` for a line break), `width`,
#'   `collapse_repeats` (`TRUE` prints a repeated value once).
#' @param datasets The data catalog (see [tfl_read_data_code()]).
#' @param rework Code run on `data` before it is sorted, or `NULL`.
#' @param type The listing type when `listing$type` is blank (one of
#'   rtfreporter's `listing_spec()` types).
#' @return The code, one element per line; `NULL` when the listing names no
#'   dataset.
#' @export
tfl_listing_code <- function(listing, cols, datasets, rework = NULL,
                              type = "multiline") {
  l <- as.data.frame(listing, stringsAsFactors = FALSE)
  if (!nrow(l) || is.na(l$dataset[1L])) return(NULL)
  l <- l[1L, ]
  for (k in c("where", "sort", "max_rows", "type")) {
    if (is.null(l[[k]])) l[[k]] <- NA_character_
  }
  obj <- .r_name(l$dataset)
  col_code <- vapply(seq_len(nrow(cols)), function(i) {
    c <- cols[i, ]
    v <- .split_bar(c$vars)
    vv <- if (length(v) == 1L) encodeString(v, quote = "\"") else
      sprintf("c(%s)", paste(encodeString(v, quote = "\""), collapse = ", "))
    a <- c(vv,
           if (!is.na(c$width)) paste("width =", c$width),
           if (!is.na(c$label)) paste("label =", .r_label(c$label)),
           if (identical(toupper(c$collapse_repeats), "TRUE"))
             "collapse_repeats = TRUE")
    sprintf("  listing_col(%s)", paste(a, collapse = ", "))
  }, "")
  type <- if (is.na(l$type)) type else l$type
  c(paste0("# the data: ", l$dataset, " (data catalog)"),
    tfl_read_data_code(datasets, l$dataset),
    sprintf("data <- %s", if (is.na(l$where)) obj else
      sprintf("subset(%s, %s)", obj, l$where)),
    if (!is.null(rework)) c("", "# rework", rework, ""),
    .r_sort("data", l$sort),
    "# dates as they print",
    "data[] <- lapply(data, function(v) if (inherits(v, c(\"Date\", \"POSIXt\"))) format(v) else v)",
    "",
    sprintf("lst <- listing_spec(list(\n%s),\n  type = %s)",
            paste(col_code, collapse = ",\n"),
            encodeString(type, quote = "\"")),
    sprintf("content <- as_rtftables(data, listing = lst%s)",
            if (!is.na(l$max_rows)) paste0(", max_rows = ", l$max_rows) else
              ""))
}
