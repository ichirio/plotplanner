# Excel plot list: one row = one figure, columns = the quick API arguments.

pp_list_cols <- c("plot_id", "type", "style", "title", "param", "group", "pop", "legend", "args")

# type -> quick function, from the catalogue
pp_quick_fun_list <- function() {
  x <- tfl_fig_catalog("implemented")
  x <- x[!duplicated(x$type), ]
  as.list(stats::setNames(x$fun, x$type))
}

#' Write an Excel plot list template
#'
#' One row per figure: `plot_id`, `type`, `style`, `title`, `param`, `group`,
#' `pop`, `legend`, `args`. Blank cells use the defaults. `args` takes any
#' further arguments in R syntax, e.g. `x_max = 24, x_by = 3` or
#' `events = c(Death = "DTHADY", Discontinued = "EOSDY")`.
#'
#' @param path Output `.xlsx` path.
#' @param adam Optional ADaM data; offers PARAMCD values, grouping variables
#'   and population flags from the data in drop-downs.
#' @param rows Optional data frame of rows to pre-fill (default: one example
#'   per type).
#' @param n_rows Rows prepared with drop-downs.
#' @return `path`, invisibly.
#' @export
tfl_fig_list_template <- function(path, adam = NULL, rows = NULL, n_rows = 300) {
  adam <- pp_prep_adam(adam)
  rows <- rows %or% data.frame(
    plot_id = c("F-14.2.1", "F-14.2.2", "F-14.2.3"),
    type = c("km", "waterfall", "swimmer"),
    style = c("risk_table", "response", "full"),
    title = NA, param = c("OS", NA, NA), group = c("TRT01P", NA, NA), pop = NA,
    legend = NA, args = c("x_max = 24, x_by = 3", NA, 'events = c(Death = "DTHADY")'),
    stringsAsFactors = FALSE
  )
  for (cc in setdiff(pp_list_cols, names(rows))) rows[[cc]] <- NA
  rows <- rows[pp_list_cols]

  wb <- openxlsx::createWorkbook()
  hdr <- openxlsx::createStyle(textDecoration = "bold", fgFill = "#DDEBF7", border = "Bottom")
  openxlsx::addWorksheet(wb, "plots")
  openxlsx::writeData(wb, "plots", rows, headerStyle = hdr)
  openxlsx::freezePane(wb, "plots", firstRow = TRUE)
  openxlsx::setColWidths(wb, "plots", seq_along(pp_list_cols), widths = c(12, 11, 13, 30, 10, 10, 8, 13, 45))

  st <- tfl_fig_types()
  openxlsx::addWorksheet(wb, "styles")
  openxlsx::writeData(wb, "styles", st, headerStyle = hdr)
  openxlsx::setColWidths(wb, "styles", 1:4, widths = c(11, 13, 9, 90))

  help <- do.call(rbind, lapply(names(pp_quick_fun_list()), function(t) {
    f <- formals(get(pp_quick_fun_list()[[t]]))
    f <- f[setdiff(names(f), c("adam", "style", "title", "file", "plot_id", "...", "param", "group", "pop", "legend"))]
    data.frame(type = t, argument = names(f),
               default = vapply(f, function(v) paste(deparse(v), collapse = ""), character(1)),
               stringsAsFactors = FALSE)
  }))
  help <- rbind(help, data.frame(type = "(all)", argument = names(pp_default_options()),
                                 default = vapply(pp_default_options(), function(v) if (v == "") "" else deparse(v), character(1)),
                                 stringsAsFactors = FALSE))
  openxlsx::addWorksheet(wb, "args")
  openxlsx::writeData(wb, "args", help, headerStyle = hdr)
  openxlsx::setColWidths(wb, "args", 1:3, widths = c(11, 18, 40))

  # drop-down lists
  openxlsx::addWorksheet(wb, "_lists", visible = FALSE)
  col <- 0L
  add_list <- function(name, values) {
    col <<- col + 1L
    values <- unique(as.character(values))
    if (!length(values)) values <- ""
    openxlsx::writeData(wb, "_lists", data.frame(x = values), startCol = col, colNames = FALSE)
    openxlsx::createNamedRegion(wb, "_lists", cols = col, rows = seq_along(values), name = name)
  }
  add_list("PP_TYPES", names(pp_quick_fun_list()))
  for (t in names(pp_quick_fun_list())) add_list(paste0("ST_", t), st$style[st$type == t])
  add_list("PP_LEGENDS", names(pp_quick_legends))
  if (!is.null(adam)) {
    params <- unique(unlist(lapply(adam, function(d) if ("PARAMCD" %in% names(d)) pp_values(d, "PARAMCD"))))
    sl <- adam[["ADSL"]] %or% adam[[1]]
    groups <- names(sl)[vapply(sl, function(v) (is.character(v) || is.factor(v)) &&
                                 length(unique(v)) %in% 2:15, logical(1))]
    pops <- grep("FL$", names(sl), value = TRUE)
    add_list("PP_PARAMS", params)
    add_list("PP_GROUPS", groups)
    add_list("PP_POPS", pops)
  }
  rr <- 2:(n_rows + 1)
  dv <- function(colname, formula) {
    openxlsx::dataValidation(wb, "plots", cols = match(colname, pp_list_cols), rows = rr,
                             type = "list", value = gsub('"', "&quot;", gsub("&", "&amp;", formula, fixed = TRUE), fixed = TRUE))
  }
  dv("type", "PP_TYPES")
  dv("style", 'INDIRECT("ST_"&$B2)')
  dv("legend", "PP_LEGENDS")
  if (!is.null(adam)) {
    dv("param", "PP_PARAMS")
    dv("group", "PP_GROUPS")
    dv("pop", "PP_POPS")
  }
  openxlsx::saveWorkbook(wb, path, overwrite = TRUE)
  invisible(path)
}

#' Generate code for every row of a plot list
#'
#' @param x Path to a plot list `.xlsx` ([tfl_fig_list_template()]) or a
#'   data frame with the same columns.
#' @param adam Optional ADaM data.
#' @param dir If given, write `<plot_id>.R` files here.
#' @return A named character vector of scripts (invisibly when `dir` is given).
#' @export
tfl_fig_list_code <- function(x, adam = NULL, dir = NULL) {
  if (is.character(x)) x <- openxlsx::read.xlsx(x, sheet = "plots", na.strings = c("", "NA"))
  x <- as.data.frame(x, stringsAsFactors = FALSE)
  for (cc in setdiff(pp_list_cols, names(x))) x[[cc]] <- NA
  x <- x[!is.na(x$type), , drop = FALSE]
  adam <- pp_prep_adam(adam)
  code <- vapply(seq_len(nrow(x)), function(i) {
    r <- lapply(x[i, ], function(v) if (is.na(v) || trimws(v) == "") NULL else trimws(as.character(v)))
    fun <- pp_quick_fun_list()[[r$type]]
    if (is.null(fun)) stop("Row ", i, ": unknown type '", r$type, "'.", call. = FALSE)
    args <- list(adam = adam, plot_id = r$plot_id %or% paste0("plot", i))
    for (a in c("style", "title", "param", "group", "legend")) {
      if (!is.null(r[[a]]) && a %in% names(formals(get(fun)))) args[[a]] <- r[[a]]
    }
    if (!is.null(r$group) && "by" %in% names(formals(get(fun)))) args$by <- r$group
    if (!is.null(r$pop)) args$pop <- if (toupper(r$pop) == "NONE") NULL else r$pop
    if (!is.null(r$args)) {
      extra <- tryCatch(eval(parse(text = paste0("list(", r$args, ")")), envir = baseenv()),
                        error = function(e) stop("Row ", i, " (", args$plot_id, "): cannot read args: ",
                                                 conditionMessage(e), call. = FALSE))
      args[names(extra)] <- extra
    }
    paste(do.call(fun, args), collapse = "\n")
  }, character(1))
  names(code) <- x$plot_id %or% paste0("plot", seq_len(nrow(x)))
  if (!is.null(dir)) {
    dir.create(dir, showWarnings = FALSE, recursive = TRUE)
    for (i in seq_along(code)) writeLines(code[[i]], file.path(dir, paste0(pp_file_name(names(code)[i]), ".R")), useBytes = TRUE)
    return(invisible(code))
  }
  code
}
