# Advice on a figure design: what would usually be done, and one-step
# fixes for it.
#
# The checks (tfl_check_fig_design()) say what is wrong -- a variable not
# in the data, a layer with no data.  The advice says what is usually
# wanted and is missing or unusual: a KM figure without the number at
# risk, a legend inside the panel with many groups, more groups than the
# palette has colours, a waterfall with the patients' numbers on the x
# axis ...  Each line names the piece it is about and, where one change
# would do it, carries a fix: a small edit of the design that
# tfl_fig_apply_fix() makes -- a layer or step added, a setting changed.
# A GUI shows the advice by the preview and offers the fix as one click.
#
# Rules are functions of (design, ctx) that return zero or more lines
# (.adv()); ctx holds what the rules read from the data: the levels of the
# colour variable, the dataset's variables, the PARAMCDs.

.adv <- function(rule, level, part, message, fix = NULL) {
  structure(list(rule = rule, level = level, part = part, message = message,
                 fix = fix), class = "tfl_fig_advice_line")
}

# a fix: op = add_layer | add_step | set_plot | set_piece | remove_layer
.fix <- function(op, ...) list(op = op, ...)

.layer_kinds <- function(d) vapply(d$layers, function(l) l$layer %||% "", "")
.step_kinds <- function(d) vapply(d$data, function(s) s$step %||% "", "")
.has_layer <- function(d, k) any(.layer_kinds(d) == k)
.has_step <- function(d, k) any(.step_kinds(d) == k)
.layer_i <- function(d, k) which(.layer_kinds(d) == k)
.step_i <- function(d, k) which(.step_kinds(d) == k)

# what the rules read from the data (NULL parts when there is no data)
.fig_advice_ctx <- function(design, adam) {
  adam <- if (!is.null(adam)) pp_prep_adam(adam)
  ctx <- list(adam = adam, levels = NULL, palette_n = NA_integer_, vars = NULL)
  reads <- Filter(function(s) identical(s$step, "read"), design$data)
  if (!is.null(adam) && length(reads)) {
    ctx$vars <- names(adam[[toupper(reads[[1L]]$dataset %||% "")]])
  }
  pal <- tfl_fig_palettes()[[.pv(design$plot, "palette") %||% "treatment"]]
  ctx$palette <- pal
  ctx$palette_n <- length(pal)
  by <- design$plot$colour_by
  if (!is.null(adam) && !is.null(by)) {
    # the variable in the dataset read, else in ADSL (joined)
    ds <- if (length(reads)) adam[[toupper(reads[[1L]]$dataset %||% "")]]
    x <- if (!is.null(ds) && by %in% names(ds)) ds[[by]] else adam$ADSL[[by]]
    if (!is.null(x)) {
      ctx$levels <- if (is.factor(x)) levels(droplevels(x)) else sort(unique(as.character(x[!is.na(x)])))
    }
  }
  ctx
}

.fig_advice_rules <- function() list(
  # ---- KM
  km_risk = function(d, ctx) {
    if (.has_layer(d, "km_curve") && !.has_layer(d, "risk_table")) .adv(
      "km_risk", "info", "layers",
      "A KM figure usually shows the number at risk below the curves.",
      .fix("add_layer", layer = list(layer = "risk_table")))
  },
  km_censor = function(d, ctx) {
    if (.has_layer(d, "km_curve") && !.has_layer(d, "censor_mark")) .adv(
      "km_censor", "info", "layers",
      "KM curves usually mark where subjects are censored.",
      .fix("add_layer", layer = list(layer = "censor_mark"), after = "km_curve"))
  },
  km_axis = function(d, ctx) {
    if (.has_layer(d, "km_curve") && is.null(d$plot$x_max)) .adv(
      "km_axis", "info", "plot",
      "Set X max and X step, so the breaks (and the number at risk's columns) fall on round times.")
  },
  km_unit = function(d, ctx) {
    sf <- Filter(function(s) identical(s$step, "survfit"), d$stats)
    if (length(sf) && !.has_step(d, "time_unit")) .adv(
      "km_unit", "info", "data",
      "The time is in days; a KM axis is usually in months (or weeks).",
      .fix("add_step", step = list(step = "time_unit", variable = sf[[1L]]$time %||% "AVAL",
                                   unit = "months")))
  },
  # ---- groups, colours, legend
  palette_short = function(d, ctx) {
    n <- length(ctx$levels)
    if (n && is.null(names(ctx$palette)) && n > ctx$palette_n) .adv(
      "palette_short", "warning", "plot",
      sprintf("%d groups, but the palette has %d colours: some groups get none.", n, ctx$palette_n))
  },
  palette_names = function(d, ctx) {
    n <- length(ctx$levels)
    if (n && !is.null(names(ctx$palette))) {
      miss <- setdiff(ctx$levels, names(ctx$palette))
      if (length(miss)) .adv(
        "palette_names", "warning", "plot",
        sprintf("The palette has no colour for %s (drawn grey).", paste(miss, collapse = ", ")))
    }
  },
  legend_inside = function(d, ctx) {
    n <- length(ctx$levels)
    if (n > 4L && grepl("^inside", .pv(d$plot, "legend") %||% "")) .adv(
      "legend_inside", "info", "plot",
      sprintf("%d groups: a legend inside the panel may cover the data; below is usual.", n),
      .fix("set_plot", legend = "bottom"))
  },
  legend_none = function(d, ctx) {
    n <- length(ctx$levels)
    if (n > 1L && identical(.pv(d$plot, "legend"), "none")) .adv(
      "legend_none", "warning", "plot",
      sprintf("%d groups are coloured, but there is no legend.", n),
      .fix("set_plot", legend = "bottom"))
  },
  no_colour = function(d, ctx) {
    maps <- unlist(lapply(d$layers, function(l) c(l$colour, l$fill)))
    if (is.null(d$plot$colour_by) && length(maps)) .adv(
      "no_colour", "warning", "plot",
      sprintf("Layers colour by %s, but the figure's 'Colours by' is empty: the palette is not applied.",
              paste(unique(maps), collapse = ", ")),
      .fix("set_plot", colour_by = unique(maps)[1L]))
  },
  # ---- mean over time
  mean_n = function(d, ctx) {
    sm <- Filter(function(s) identical(s$step, "summary"), d$stats)
    if (length(sm) && .has_layer(d, "errorbar") && !.has_layer(d, "n_table")) {
      by <- .split_vals(sm[[1L]]$by)
      eb <- d$layers[[.layer_i(d, "errorbar")[1L]]]
      .adv("mean_n", "info", "layers",
           "A mean-over-time figure usually shows the n of each group at each visit below it.",
           .fix("add_layer", layer = list(layer = "n_table", data = sm[[1L]]$name %||% "sm",
                                          x = eb$x, group = eb$colour %||% by[1L])))
    }
  },
  visit_order = function(d, ctx) {
    xs <- unique(unlist(lapply(d$layers, function(l) l$x)))
    xs <- xs[grepl("^AVISIT$|VISIT$", xs)]
    ordered <- unlist(lapply(d$data, function(s) if (identical(s$step, "levels")) s$variable))
    for (x in setdiff(xs, ordered)) {
      return(.adv("visit_order", "warning", "data",
        sprintf("%s is text: without an order its visits sort alphabetically. Order it by its number.", x),
        .fix("add_step", step = list(step = "levels", variable = x, order_by = paste0(x, "N")))))
    }
  },
  # ---- waterfall
  waterfall_ref = function(d, ctx) {
    if (.has_step(d, "rank") && .has_layer(d, "col")) {
      ys <- unlist(lapply(d$layers, function(l) if (identical(l$layer, "hline")) .split_vals(l$yintercept)))
      if (!all(c("20", "-30") %in% ys)) .adv(
        "waterfall_ref", "info", "layers",
        "A waterfall usually marks +20% (progression) and -30% (response).",
        .fix("add_layer", layer = list(layer = "hline", yintercept = "20, -30", linetype = "dashed",
                                       colour = "grey", linewidth = 0.5)))
    }
  },
  waterfall_x = function(d, ctx) {
    if (.has_step(d, "rank") && .has_layer(d, "col") && isTRUE(as.logical(.pv(d$plot, "x_text")))) .adv(
      "waterfall_x", "info", "plot",
      "The bars' numbers on the x axis say nothing; they are usually hidden.",
      .fix("set_plot", x_text = FALSE))
  },
  # ---- general
  nothing = function(d, ctx) {
    if (!length(d$layers)) .adv("nothing", "warning", "layers", "No layer: nothing is drawn.")
  },
  no_read = function(d, ctx) {
    if (!.has_step(d, "read")) .adv("no_read", "warning", "data", "No dataset is read.",
                                    .fix("add_step", step = list(step = "read", dataset = "ADSL"), first = TRUE))
  },
  pop = function(d, ctx) {
    if (.has_step(d, "read") && !.has_step(d, "flag") && !.has_step(d, "data_code")) {
      # the flag the data has: the usual ones first, else any *FL
      have <- grep("FL$", ctx$vars %||% character(), value = TRUE)
      flag <- c(intersect(c("FASFL", "SAFFL", "ITTFL", "PPROTFL"), have), have, "SAFFL")[1L]
      .adv("pop", "info", "data",
           "No analysis set: every row of the dataset is used. Keep the analysis set's flag (FASFL, SAFFL ...).",
           .fix("add_step", step = list(step = "flag", variable = flag)))
    }
  },
  size = function(d, ctx) {
    w <- as.numeric(.pv(d$plot, "width")); h <- as.numeric(.pv(d$plot, "height"))
    if (!is.na(w) && !is.na(h) && w < h) .adv(
      "size", "info", "plot", "The figure is taller than wide; a landscape page usually wants the reverse.")
  }
)

#' Advice on a figure design
#'
#' What is usually wanted and is missing or unusual in a design -- a KM
#' figure without the number at risk, a legend inside the panel with many
#' groups, more groups than the palette has colours, text visits with no
#' order ...  Not errors (those are [tfl_check_fig_design()]): the figure
#' draws either way.  Where one change would do it, the line carries a
#' fix that `tfl_fig_apply_fix()` makes: a layer or a step added, a
#' setting changed.
#'
#' @param design A `tfl_fig_design`.
#' @param adam The data ([tfl_read_adam()]); with it the groups' levels
#'   are counted against the palette and the legend.
#' @param fix One row's `fix` (a list: `op` and its fields).
#' @return `tfl_fig_advice()`: a data frame with `rule`, `level` (`info`,
#'   `warning`), `part` (`data`, `stats`, `plot`, `layers`), `message` and
#'   `fix` (a list column; `NULL` where there is no one-step fix).
#'   `tfl_fig_apply_fix()`: the design, changed.
#' @export
tfl_fig_advice <- function(design, adam = NULL) {
  ctx <- .fig_advice_ctx(design, adam)
  lines <- list()
  for (r in .fig_advice_rules()) {
    out <- tryCatch(r(design, ctx), error = function(e) NULL)
    if (inherits(out, "tfl_fig_advice_line")) lines <- c(lines, list(out))
  }
  data.frame(
    rule = vapply(lines, `[[`, "", "rule"),
    level = vapply(lines, `[[`, "", "level"),
    part = vapply(lines, `[[`, "", "part"),
    message = vapply(lines, `[[`, "", "message"),
    fix = I(lapply(lines, `[[`, "fix")),
    stringsAsFactors = FALSE)
}

#' @rdname tfl_fig_advice
#' @export
tfl_fig_apply_fix <- function(design, fix) {
  if (is.null(fix)) return(design)
  switch(fix$op,
    add_layer = {
      k <- .layer_kinds(design)
      at <- if (!is.null(fix$after) && any(k == fix$after)) max(which(k == fix$after)) else length(k)
      design$layers <- append(design$layers, list(fix$layer), after = at)
    },
    add_step = {
      if (isTRUE(fix$first)) {
        design$data <- c(list(fix$step), design$data)
      } else if (!is.null(fix$before) && fix$before %in% .step_kinds(design)) {
        design$data <- append(design$data, list(fix$step),
                              after = min(which(.step_kinds(design) == fix$before)) - 1L)
      } else {
        # after the last keep-rows step, before any derive of the same variable
        design$data <- c(design$data, list(fix$step))
      }
    },
    set_plot = {
      for (f in setdiff(names(fix), "op")) design$plot[[f]] <- fix[[f]]
    },
    set_piece = {
      x <- design[[fix$sec]][[fix$i]]
      for (f in setdiff(names(fix), c("op", "sec", "i"))) x[[f]] <- fix[[f]]
      design[[fix$sec]][[fix$i]] <- x
    },
    remove_layer = design$layers <- design$layers[-fix$i],
    stop("Unknown fix: ", fix$op, call. = FALSE))
  design
}
