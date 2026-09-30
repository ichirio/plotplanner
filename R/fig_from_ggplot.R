# ============================================================================
#  POC: a figure design back from ggplot2 code or a ggplot object
# ----------------------------------------------------------------------------
#  The other direction of tfl_fig_design_code().  Everything becomes the
#  GENERIC pieces -- a `call` layer per layer, a `plot.add` call per
#  figure-wide setting -- because they say exactly what was written: nothing
#  has to be recognised to be kept.  What cannot be said as a piece is not
#  dropped: it is kept as code where it can be (`data_code`, `!r`) and listed
#  in the "not_converted" attribute where it cannot.
#
#  Two sources:
#   * code: parsed, never run.  `+` chains from ggplot() (or another base
#     call, e.g. ggsurvfit()) are split into their terms; `p <- p + ...`
#     continues a plot; patchwork operators between plots become `compose`.
#   * a ggplot object: ggplot2 >= 3.5 keeps each layer's constructor call and
#     each scale's call, which are what was written (defaults excluded); the
#     facet, coordinates, theme and labels have no call and are rebuilt from
#     their values.
#
#  POC status: not exported for use, not documented beyond this header.
# ============================================================================

# Functions that set the whole figure: they go to `plot.add`, not `layers`
.gg_plotwide <- function(fn) {
  grepl(.fig_plotwide_re, .fig_bare_fn_name(fn)) ||
    .fig_bare_fn_name(fn) %in% c("lims", "xlim", "ylim", "expand_limits")
}

.gg_complete_themes <- c("theme_grey", "theme_gray", "theme_bw",
                         "theme_linedraw", "theme_light", "theme_dark",
                         "theme_minimal", "theme_classic", "theme_void",
                         "theme_test")

# A call's function name as written: `fn` or `pkg::fn`
.gg_fn_name <- function(cl) {
  f <- cl[[1L]]
  if (is.call(f) && identical(f[[1L]], as.name("::"))) {
    return(paste0(as.character(f[[2L]]), "::", as.character(f[[3L]])))
  }
  if (is.name(f)) as.character(f) else NA_character_
}

.gg_deparse <- function(e) paste(deparse(e, width.cutoff = 500L), collapse = "\n")

# Functions whose calls stay structured ({fn, args}) inside an argument;
# anything else is kept verbatim as `!r`
.gg_nested_ok <- function(fn) {
  if (grepl("::", fn, fixed = TRUE)) return(FALSE)
  fn %in% getNamespaceExports("ggplot2") && !fn %in% c("aes", "vars")
}

# A value that is a function object (not code): a piece cannot say it
.gg_no_piece <- function(what) {
  stop(structure(class = c("gg_no_piece", "error", "condition"),
                 list(message = what, call = NULL)))
}

# One argument's value, from the language it was written in
.gg_value <- function(e, ctx) {
  if (is.null(e)) return(NULL)
  if (is.function(e)) .gg_no_piece("an argument is a function object, not code")
  if (is.environment(e) || isS4(e) || (is.list(e) && !is.call(e))) {
    .gg_no_piece("an argument is an evaluated object, not code")
  }
  if (is.atomic(e) && length(e) == 1L) return(e)
  if (is.name(e)) {
    ctx$note("a variable (`%s`) is kept as R code", as.character(e))
    return(tfl_fig_r(as.character(e)))
  }
  if (is.call(e)) {
    fn <- .gg_fn_name(e)
    args <- as.list(e)[-1L]
    literal <- function(a) is.atomic(a) && length(a) == 1L
    if (identical(fn, "c") && length(args) && all(vapply(args, literal, NA))) {
      v <- unlist(args)
      if (!is.null(names(args)) && any(nzchar(names(args)))) {
        return(stats::setNames(as.list(v), names(args)))
      }
      return(v)
    }
    if (identical(fn, "-") && length(args) == 1L && is.numeric(args[[1L]])) {
      return(-args[[1L]])
    }
    if (!is.na(fn) && .gg_nested_ok(fn)) return(.gg_call_spec(e, ctx))
    return(tfl_fig_r(.gg_deparse(e)))
  }
  tfl_fig_r(.gg_deparse(e))
}

# aes(...) as a named list of expressions (text); x and y may be positional
.gg_aes <- function(e) {
  if (is.null(e)) return(list())
  a <- as.list(e)[-1L]
  nm <- names(a) %||% rep("", length(a))
  pos <- which(!nzchar(nm))
  nm[pos] <- c("x", "y")[seq_along(pos)]
  stats::setNames(lapply(a, .gg_deparse), nm)
}

.gg_formals <- function(fn) {
  rf <- .fig_resolve_fn(fn)
  pkg <- rf$pkg %||% .fig_find_pkg(rf$fn)
  if (is.null(pkg) || !requireNamespace(pkg, quietly = TRUE)) return(NULL)
  f <- tryCatch(getExportedValue(pkg, rf$fn), error = function(e) NULL)
  if (is.function(f)) names(formals(f)) else NULL
}

.gg_is_aes <- function(e) is.call(e) && identical(.gg_fn_name(e), "aes")

# One call as a piece: fn (with its package when written), data, aes, pos,
# args
.gg_call_spec <- function(e, ctx, global = NULL) {
  fn <- .gg_fn_name(e)
  a <- as.list(e)[-1L]
  nm <- names(a) %||% rep("", length(a))
  spec <- list(fn = fn)
  data <- NULL; aes <- NULL
  keep <- rep(TRUE, length(a))
  for (i in seq_along(a)) {
    if (nm[i] %in% c("mapping", "") && .gg_is_aes(a[[i]]) && is.null(aes)) {
      aes <- .gg_aes(a[[i]]); keep[i] <- FALSE
    } else if (identical(nm[i], "data")) {
      if (is.function(a[[i]])) .gg_no_piece("its data is a function object, not code")
      data <- .gg_deparse(a[[i]]); keep[i] <- FALSE
    }
  }
  # the plot's own data and mapping, which the design has no place for: each
  # layer that inherits them says them itself
  if (!is.null(global)) {
    inherit <- !identical(a[["inherit.aes"]], FALSE)
    # only a function that takes data / a mapping is given the plot's
    # (annotate() takes neither)
    f <- .gg_formals(fn)
    if (is.null(data) && (is.null(f) || "data" %in% f)) data <- global$data
    if (!is.null(f) && !"mapping" %in% f) inherit <- FALSE
    if (inherit && length(global$aes)) {
      aes <- c(global$aes[setdiff(names(global$aes), names(aes))], aes)
    }
  }
  if (!is.null(data)) spec$data <- data
  if (length(aes)) spec$aes <- aes
  pos <- a[keep & !nzchar(nm)]
  if (length(pos)) spec$pos <- unname(lapply(pos, .gg_value, ctx = ctx))
  args <- a[keep & nzchar(nm)]
  if (length(args)) spec$args <- lapply(args, .gg_value, ctx = ctx)
  spec
}

# The terms of a `+` chain, left to right
.gg_terms <- function(e) {
  if (is.call(e) && identical(e[[1L]], as.name("+")) && length(e) == 3L) {
    return(c(.gg_terms(e[[2L]]), list(e[[3L]])))
  }
  list(e)
}

.gg_new_ctx <- function() {
  ctx <- new.env(parent = emptyenv())
  ctx$lost <- character()
  ctx$kept <- character()
  ctx$note <- function(...) ctx$lost <- union(ctx$lost, sprintf(...))
  ctx
}

# ---- from code -------------------------------------------------------------

# One plot being read: its global data / aes, layers and plot.add
.gg_new_plot <- function() list(global = list(), layers = list(), add = list(),
                                 base_theme = FALSE)

.gg_add_term <- function(pl, term, ctx) {
  if (!is.call(term)) {
    ctx$note("`%s` added to a plot is kept as R code", .gg_deparse(term))
    pl$layers[[length(pl$layers) + 1L]] <-
      list(layer = "layer_code", code = paste0("p <- p + ", .gg_deparse(term)))
    return(pl)
  }
  fn <- .gg_fn_name(term)
  if (identical(.fig_bare_fn_name(fn), "ggplot")) {
    a <- as.list(term)[-1L]
    nm <- names(a) %||% rep("", length(a))
    for (i in seq_along(a)) {
      if (.gg_is_aes(a[[i]])) pl$global$aes <- .gg_aes(a[[i]])
      else if (nm[i] %in% c("", "data")) pl$global$data <- .gg_deparse(a[[i]])
      else ctx$note("ggplot(%s = ) is not kept", nm[i])
    }
    return(pl)
  }
  if (is.na(fn)) {
    ctx$note("`%s` is kept as R code", .gg_deparse(term))
    pl$layers[[length(pl$layers) + 1L]] <-
      list(layer = "layer_code", code = paste0("p <- p + ", .gg_deparse(term)))
    return(pl)
  }
  if (.gg_plotwide(fn)) {
    if (.fig_bare_fn_name(fn) %in% .gg_complete_themes) pl$base_theme <- TRUE
    pl$add[[length(pl$add) + 1L]] <- .gg_call_spec(term, ctx)
  } else {
    if (!.fig_bare_fn_name(fn) %in% getNamespaceExports("ggplot2") &&
        !grepl("::", fn, fixed = TRUE)) {
      pk <- .fig_find_pkg(.fig_bare_fn_name(fn))
      if (is.null(pk)) {
        ctx$note("`%s()` is not a ggplot2 function (a wrapper of your own?): kept as a call, not checked", fn)
      }
    }
    spec <- tryCatch(.gg_call_spec(term, ctx, global = pl$global),
                     gg_no_piece = function(c) {
                       ctx$note("`%s()` is not converted: %s", fn, conditionMessage(c))
                       NULL
                     })
    if (!is.null(spec)) pl$layers[[length(pl$layers) + 1L]] <- c(list(layer = "call"), spec)
  }
  pl
}

# The root of a chain that does not start with ggplot(): a base call piece
.gg_base_term <- function(e, ctx) {
  ctx$note("the figure starts from `%s`, not ggplot(): kept as a base call",
           .gg_deparse(e))
  if (is.call(e) && identical(e[[1L]], as.name("|>"))) {
    rhs <- e[[3L]]
    spec <- .gg_call_spec(rhs, ctx)
    spec$pos <- c(list(tfl_fig_r(.gg_deparse(e[[2L]]))), spec$pos)
    return(c(list(layer = "call", base = TRUE), spec))
  }
  if (is.call(e)) return(c(list(layer = "call", base = TRUE), .gg_call_spec(e, ctx)))
  list(layer = "call", base = TRUE, fn = "identity",
       pos = list(tfl_fig_r(.gg_deparse(e))))
}

.gg_read_chain <- function(e, plots, ctx) {
  terms <- .gg_terms(e)
  root <- terms[[1L]]
  if (is.name(root) && as.character(root) %in% names(plots)) {
    pl <- plots[[as.character(root)]]
  } else if (is.call(root) && identical(.fig_bare_fn_name(.gg_fn_name(root)), "ggplot")) {
    pl <- .gg_add_term(.gg_new_plot(), root, ctx)
  } else {
    pl <- .gg_new_plot()
    pl$layers <- list(.gg_base_term(root, ctx))
  }
  for (t in terms[-1L]) pl <- .gg_add_term(pl, t, ctx)
  pl
}

# Functions that start a figure other than ggplot(): ggsurvfit's gg*()
.gg_base_fns <- function() {
  ex <- if (requireNamespace("ggsurvfit", quietly = TRUE)) getNamespaceExports("ggsurvfit") else character()
  c("ggsurvfit", "ggcuminc", grep("^gg", ex, value = TRUE))
}

.gg_is_base_call <- function(e) {
  if (is.call(e) && identical(e[[1L]], as.name("|>"))) e <- e[[3L]]
  is.call(e) && !is.na(.gg_fn_name(e)) &&
    .fig_bare_fn_name(.gg_fn_name(e)) %in% .gg_base_fns()
}

.gg_is_plot_expr <- function(e, plots) {
  root <- .gg_terms(e)[[1L]]
  (is.name(root) && as.character(root) %in% names(plots)) ||
    (is.call(root) && identical(.fig_bare_fn_name(.gg_fn_name(root)), "ggplot")) ||
    .gg_is_base_call(root)
}

# patchwork: `a | b`, `(a | b) / c` ... over plot names
.gg_compose_names <- function(e) {
  if (is.name(e)) return(as.character(e))
  if (is.call(e) && as.character(e[[1L]]) %in% c("|", "/", "+", "-", "(")) {
    return(unlist(lapply(as.list(e)[-1L], .gg_compose_names)))
  }
  NA_character_
}

# Names every design script assigns itself (the palette, the dodge): a
# figure's own variables of those names would be overwritten, so code that
# uses them is renamed
.gg_reserved <- c("pal", "pd", "pal_lv")

.gg_rename <- function(x, ren) {
  for (o in names(ren)) x <- gsub(paste0("\\b", o, "\\b"), ren[[o]], x, perl = TRUE)
  x
}

.gg_rename_design <- function(x, ren) {
  if (!length(ren)) return(x)
  if (.is_fig_r(x)) return(tfl_fig_r(.gg_rename(as.character(x), ren)))
  if (is.list(x)) {
    for (i in seq_along(x)) {
      nm <- names(x)[i] %||% ""
      if (nm %in% c("data", "code") && is.character(x[[i]])) x[[i]] <- .gg_rename(x[[i]], ren)
      else if (!is.null(x[[i]])) x[[i]] <- .gg_rename_design(x[[i]], ren)
    }
  }
  x
}

.gg_design_of <- function(pl, data_code = NULL) {
  add <- pl$add
  # The design's finishing block writes the company theme; a complete theme
  # first in plot.add replaces it, which is what ggplot() alone would have
  # (theme_grey()) unless the code chose one
  if (!isTRUE(pl$base_theme)) add <- c(list(list(fn = "theme_grey")), add)
  texts <- c(data_code, unlist(lapply(c(pl$layers, add), function(z)
    rapply(z, function(v) as.character(v), how = "unlist"))))
  used <- .gg_reserved[vapply(.gg_reserved, function(n)
    any(grepl(paste0("\\b", n, "\\b"), texts, perl = TRUE)), NA)]
  ren <- if (length(used)) stats::setNames(paste0(used, "_"), used) else character()
  data_code <- .gg_rename(data_code, ren)
  pl$layers <- .gg_rename_design(pl$layers, ren)
  add <- .gg_rename_design(add, ren)
  tfl_fig_design(
    data = if (length(data_code)) list(list(step = "data_code",
                                            code = paste(data_code, collapse = "\n"))),
    plot = list(add = add),
    layers = pl$layers)
}

.fig_from_code <- function(exprs) {
  ctx <- .gg_new_ctx()
  plots <- list()
  data_code <- character()
  last <- NULL
  compose <- NULL
  for (e in as.list(exprs)) {
    is_assign <- is.call(e) && as.character(e[[1L]]) %in% c("<-", "=")
    target <- if (is_assign) as.character(e[[2L]]) else NULL
    rhs <- if (is_assign) e[[3L]] else e
    nms <- .gg_compose_names(rhs)
    if (length(plots) && length(nms) > 1L && all(nms %in% names(plots))) {
      compose <- list(layout = .gg_deparse(rhs), names = unique(nms))
      next
    }
    terms <- .gg_terms(rhs)
    is_plot_name <- vapply(terms, function(t) is.name(t) && as.character(t) %in% names(plots), NA)
    if (length(terms) > 1L && sum(is_plot_name) > 1L) {
      pn <- vapply(terms[is_plot_name], as.character, "")
      extra <- terms[!is_plot_name]
      compose <- list(layout = paste(pn, collapse = " + "), names = unique(pn),
                      add = lapply(extra, function(t) {
                        if (is.call(t)) .gg_call_spec(t, ctx)
                        else list(fn = "identity", pos = list(tfl_fig_r(.gg_deparse(t))))
                      }))
      next
    }
    if (.gg_is_plot_expr(rhs, plots)) {
      pl <- .gg_read_chain(rhs, plots, ctx)
      key <- target %||% ".last"
      plots[[key]] <- pl
      last <- key
      next
    }
    # printing, saving: not part of the design
    if (is.name(rhs) && as.character(rhs) %in% names(plots)) { last <- as.character(rhs); next }
    if (is.call(rhs) && .fig_bare_fn_name(.gg_fn_name(rhs)) %in% c("ggsave", "print")) {
      ctx$note("`%s` is not part of a design (the script saves the figure itself)",
               .fig_bare_fn_name(.gg_fn_name(rhs)))
      next
    }
    txt <- attr(e, "gg_text") %||% .gg_deparse(e)
    data_code <- c(data_code, txt)
    ctx$kept <- c(ctx$kept, txt)
  }
  if (!is.null(compose)) {
    ctx$note("a patchwork layout: each plot is its own design under `plots`")
    parts <- lapply(compose$names, function(n) unclass(.gg_design_of(plots[[n]])))
    names(parts) <- compose$names
    d <- tfl_fig_design(
      data = if (length(data_code)) list(list(step = "data_code",
                                              code = paste(data_code, collapse = "\n"))),
      plots = parts, compose = c(list(layout = compose$layout),
                                 if (length(compose$add)) list(add = compose$add)))
  } else if (is.null(last)) {
    stop("tfl_as_fig_design(): no ggplot() chain found in the code.", call. = FALSE)
  } else {
    d <- .gg_design_of(plots[[last]], data_code)
  }
  if (length(ctx$kept)) {
    ctx$note("%d line(s) before the plot are kept as a data_code step", length(ctx$kept))
  }
  attr(d, "not_converted") <- ctx$lost
  attr(d, "source") <- "code"
  d
}

# ---- from a ggplot object --------------------------------------------------

.gg_quo_text <- function(q) {
  if (inherits(q, "quosure")) return(rlang::quo_text(q))
  .gg_deparse(q)
}

# A grid unit (or a ggplot2 margin) as the call that makes it
.gg_unit_code <- function(u) {
  v <- as.numeric(u)
  ty <- unique(grid::unitType(u))
  num <- paste(vapply(v, .fig_num_code, ""), collapse = ", ")
  if (inherits(u, "margin") || inherits(u, "ggplot2::margin")) {
    return(sprintf('margin(%s, unit = "%s")', num, ty[1L]))
  }
  if (length(ty) != 1L) return(NULL)
  if (length(v) == 1L) sprintf('unit(%s, "%s")', num, ty) else sprintf('unit(c(%s), "%s")', num, ty)
}

# Theme values as a design writes them: elements as nested calls holding
# only what differs from the base theme's element
.gg_theme_value <- function(v, base, ctx, name) {
  if (inherits(v, "element_blank") || inherits(v, "ggplot2::element_blank")) {
    return(list(fn = "element_blank"))
  }
  cls <- intersect(sub("^ggplot2::", "", class(v)),
                   c("element_text", "element_line", "element_rect", "element_point",
                     "element_polygon", "element_geom"))
  if (length(cls)) {
    fields <- if (isS4(v) || inherits(v, "S7_object")) S7::props(v) else unclass(v)
    bf <- if (!is.null(base) && !inherits(base, "element_blank") &&
              !inherits(base, "ggplot2::element_blank")) {
      if (isS4(base) || inherits(base, "S7_object")) S7::props(base) else unclass(base)
    } else list()
    fn_args <- names(formals(getExportedValue("ggplot2", cls[1L])))
    args <- list()
    for (f in intersect(names(fields), fn_args)) {
      if (!identical(fields[[f]], bf[[f]]) && !is.null(fields[[f]])) {
        val <- fields[[f]]
        if (inherits(val, "unit")) {
          code <- .gg_unit_code(val)
          if (is.null(code)) { ctx$note("theme(%s = ): `%s` is not converted", name, f); next }
          val <- tfl_fig_r(code)
        } else if (is.list(val) || is.function(val)) {
          ctx$note("theme(%s = ): `%s` is not converted", name, f)
          next
        }
        args[[f]] <- val
      }
    }
    if (!length(args)) return(NULL)
    return(list(fn = cls[1L], args = args))
  }
  if (inherits(v, "unit")) {
    code <- .gg_unit_code(v)
    if (is.null(code)) { ctx$note("theme(%s = ): a unit is not converted", name); return(NULL) }
    return(tfl_fig_r(code))
  }
  if (is.atomic(v)) return(v)
  ctx$note("theme(%s = ) could not be read back", name)
  NULL
}

# Which complete theme, at what size, the figure's theme starts from
.gg_base_theme <- function(th) {
  size <- tryCatch(th$text$size, error = function(e) NULL) %||% 11
  best <- NULL; best_n <- Inf
  for (fn in setdiff(.gg_complete_themes, "theme_gray")) {
    b <- tryCatch(getExportedValue("ggplot2", fn)(base_size = size), error = function(e) NULL)
    if (is.null(b)) next
    n <- sum(!vapply(names(th), function(k) identical(th[[k]], b[[k]]), NA))
    if (n < best_n) { best <- list(fn = fn, size = size, theme = b); best_n <- n }
  }
  best
}

# A scale's call with each argument written as a variable replaced by the
# value the object holds for it
.gg_resolve_scale <- function(sc) {
  cl <- sc$call
  a <- as.list(cl)[-1L]
  for (nm in names(a)) {
    if (!nzchar(nm) || !(is.name(a[[nm]]) || is.call(a[[nm]]))) next
    if (is.call(a[[nm]]) && !is.na(.gg_fn_name(a[[nm]])) &&
        .gg_nested_ok(.gg_fn_name(a[[nm]]))) next
    # a manual scale's palette returns its values whatever n it is asked for
    v <- if (nm == "values") tryCatch(sc$palette(1L), error = function(e) NULL)
         else tryCatch(sc[[nm]], error = function(e) NULL)
    if (!is.null(v) && is.atomic(v) && !is.function(v)) cl[[nm]] <- v
  }
  cl
}

# A layer's `position = <variable>` written as the position it holds
.gg_resolve_position <- function(cl, l) {
  pv <- cl[["position"]]
  if (is.null(pv) || !is.name(pv)) return(cl)
  cls <- sub("^Position", "", sub("^ggplot2::", "", class(l$position)[1L]))
  fn <- paste0("position_", tolower(gsub("([a-z])([A-Z])", "\\1_\\2", cls)))
  if (!fn %in% getNamespaceExports("ggplot2")) return(cl)
  f <- formals(getExportedValue("ggplot2", fn))
  args <- list()
  for (k in names(f)) {
    v <- tryCatch(l$position[[k]], error = function(e) NULL)
    dflt <- tryCatch(eval(f[[k]]), error = function(e) NULL)
    if (!is.null(v) && is.atomic(v) && !identical(v, dflt)) args[[k]] <- v
  }
  cl[["position"]] <- as.call(c(as.name(fn), args))
  cl
}

.fig_from_object <- function(p, data_name) {
  ctx <- .gg_new_ctx()
  if (inherits(p, "ggsurvfit")) {
    ctx$note("a ggsurvfit() figure: its layers are ggsurvfit's own, built from the fit")
  }
  global <- list(aes = lapply(p$mapping, .gg_quo_text))
  if (is.data.frame(p$data)) global$data <- data_name
  layers <- list()
  for (l in p$layers) {
    cl <- l$constructor
    if (is.null(cl) || !is.call(cl)) {
      ctx$note("a layer (%s) has no constructor call: not converted", class(l$geom)[1L])
      next
    }
    if ("..." %in% all.names(cl)) {
      ctx$note("a layer (%s) was made inside a function: its call has `...` and is not converted",
               .gg_fn_name(cl))
      next
    }
    cl <- .gg_resolve_position(cl, l)
    spec <- tryCatch(.gg_call_spec(cl, ctx, global = global),
                     gg_no_piece = function(c) {
                       ctx$note("`%s()` is not converted: %s", .gg_fn_name(cl), conditionMessage(c))
                       NULL
                     })
    if (is.null(spec)) next
    # a layer's own data frame was written as an expression the object no
    # longer knows the value of
    if (is.data.frame(l$data) && !is.null(spec$data) && !identical(spec$data, data_name)) {
      ctx$note("layer %s: its data `%s` must exist when the script runs", spec$fn, spec$data)
    }
    layers[[length(layers) + 1L]] <- c(list(layer = "call"), spec)
  }
  add <- list()
  bt <- .gg_base_theme(p$theme)
  add[[1L]] <- list(fn = bt$fn, args = list(base_size = bt$size))
  for (sc in p$scales$scales) {
    if (!is.call(sc$call)) {
      ctx$note("a scale (%s) has no call: not converted", paste(sc$aesthetics, collapse = "/"))
      next
    }
    add[[length(add) + 1L]] <- .gg_call_spec(.gg_resolve_scale(sc), ctx)
  }
  fc <- p$facet
  fcls <- class(fc)[1L]
  if (fcls %in% c("FacetWrap", "ggplot2::FacetWrap")) {
    pr <- fc$params
    args <- list()
    if (!is.null(pr$ncol)) args$ncol <- pr$ncol
    if (!is.null(pr$nrow)) args$nrow <- pr$nrow
    fr <- pr$free
    if (isTRUE(fr$x) || isTRUE(fr$y)) {
      args$scales <- if (isTRUE(fr$x) && isTRUE(fr$y)) "free" else if (isTRUE(fr$x)) "free_x" else "free_y"
    }
    add[[length(add) + 1L]] <- list(
      fn = "facet_wrap",
      pos = list(tfl_fig_r(paste0("vars(", paste(vapply(pr$facets, .gg_quo_text, ""), collapse = ", "), ")"))),
      args = if (length(args)) args)
  } else if (fcls %in% c("FacetGrid", "ggplot2::FacetGrid")) {
    pr <- fc$params
    vv <- function(q) if (length(q)) tfl_fig_r(paste0("vars(", paste(vapply(q, .gg_quo_text, ""), collapse = ", "), ")"))
    args <- list(rows = vv(pr$rows), cols = vv(pr$cols))
    args <- args[!vapply(args, is.null, NA)]
    add[[length(add) + 1L]] <- list(fn = "facet_grid", args = args)
  } else if (!fcls %in% c("FacetNull", "ggplot2::FacetNull")) {
    ctx$note("the facet (%s) is not converted", fcls)
  }
  co <- p$coordinates
  ccls <- sub("^ggplot2::", "", class(co)[1L])
  if (ccls == "CoordCartesian") {
    args <- list(xlim = co$limits$x, ylim = co$limits$y)
    args <- args[!vapply(args, is.null, NA)]
    if (length(args)) add[[length(add) + 1L]] <- list(fn = "coord_cartesian", args = args)
  } else if (ccls == "CoordFlip") {
    add[[length(add) + 1L]] <- list(fn = "coord_flip")
  } else {
    ctx$note("the coordinates (%s) are not converted", ccls)
  }
  labs <- unclass(p$labels)
  labs <- labs[!vapply(labs, is.null, NA)]
  if (length(labs)) {
    bad <- !vapply(labs, function(v) is.character(v) && length(v) == 1L, NA)
    if (any(bad)) ctx$note("labels %s are not text: not converted", paste(names(labs)[bad], collapse = ", "))
    labs <- labs[!bad]
    if (length(labs)) add[[length(add) + 1L]] <- list(fn = "labs", args = labs)
  }
  # what the theme changes on top of its complete theme
  targs <- list()
  for (k in names(p$theme)) {
    if (identical(p$theme[[k]], bt$theme[[k]])) next
    v <- .gg_theme_value(p$theme[[k]], bt$theme[[k]], ctx, k)
    if (!is.null(v)) targs[[k]] <- v
  }
  if (length(targs)) add[[length(add) + 1L]] <- list(fn = "theme", args = targs)
  if (length(p$guides$guides %||% list())) ctx$note("guides() are not converted")
  d <- tfl_fig_design(plot = list(add = add), layers = layers)
  attr(d, "not_converted") <- ctx$lost
  attr(d, "source") <- "object"
  d
}

#' POC: a figure design from ggplot2 code or a ggplot object
#'
#' @param x A ggplot object; or ggplot2 code (a character vector, a file, or
#'   an expression), which is parsed, not run.
#' @param data_name For an object: the name its data has in the script.
#' @return A `tfl_fig_design` with attributes `not_converted` (what could
#'   not be said as a piece) and `source` (`"code"` or `"object"`).
#' @keywords internal
tfl_as_fig_design <- function(x, data_name = "df") {
  if (inherits(x, "ggplot") || inherits(x, "ggplot2::ggplot")) {
    return(.fig_from_object(x, data_name))
  }
  if (is.character(x)) {
    if (length(x) == 1L && file.exists(x)) x <- readLines(x, warn = FALSE)
    ex <- parse(text = x, keep.source = TRUE)
    src <- attr(ex, "srcref")
    x <- lapply(seq_along(ex), function(i) {
      e <- ex[[i]]
      if (is.call(e)) {
        attr(e, "gg_text") <- paste(as.character(src[[i]]), collapse = "\n")
      }
      e
    })
  }
  if (is.call(x)) x <- list(x)
  .fig_from_code(x)
}

#' POC: does a design draw what the original drew?
#'
#' Writes the design's script, runs it in `env` (where the data the figure
#' names must be), and compares [ggplot2::ggplot_build()]'s data layer by
#' layer, and the labels.
#' @keywords internal
tfl_fig_roundtrip <- function(original, design, env = parent.frame()) {
  code <- tfl_fig_design_code(design)
  run <- new.env(parent = env)
  dir.create(wd <- tempfile("rt"))
  owd <- setwd(wd); on.exit(setwd(owd), add = TRUE)
  suppressMessages(suppressWarnings(eval(parse(text = code), run)))
  fig <- run$fig
  b1 <- suppressMessages(suppressWarnings(ggplot2::ggplot_build(original)))
  b2 <- suppressMessages(suppressWarnings(ggplot2::ggplot_build(fig)))
  same_layers <- length(b1$data) == length(b2$data) &&
    all(vapply(seq_along(b1$data), function(i)
      isTRUE(all.equal(b1$data[[i]], b2$data[[i]], check.attributes = FALSE)), NA))
  lab <- function(b) {
    l <- tryCatch(ggplot2::get_labs(b$plot), error = function(e) b$plot$labels)
    l <- unclass(l); l[order(names(l))]
  }
  same_labels <- isTRUE(all.equal(lab(b1), lab(b2)))
  th <- function(p) { t <- ggplot2::theme_get(); p$theme }
  same_theme <- isTRUE(all.equal(b1$plot$theme, b2$plot$theme, check.attributes = FALSE))
  list(layers = same_layers, labels = same_labels, theme = same_theme,
       n_layers = c(length(b1$data), length(b2$data)), figure = fig, code = code)
}
