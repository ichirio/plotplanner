# Five figures written by hand with ggplot2 -- the right answers the figure
# templates' scripts are compared with (test-fig-exact.R): every layer's
# data (layer_data()), the labels and the axes' ranges and breaks.  The data
# steps are base R, written apart from the templates' dplyr; the layers say
# their settings directly, and the templates' base theme (ggplot2 4.0 takes
# a geom's default line width from it).  Each function takes the example ADaM (as
# tfl_example_adam() gives it) and returns the plots the script assigns,
# by the names it assigns them.

pal_of <- function(x) {
  lv <- if (is.factor(x)) levels(droplevels(x)) else sort(unique(as.character(x)))
  stats::setNames(c("blue", "#D55E00", "#009E73", "#CC79A7", "#E69F00",
                    "#56B4E9")[seq_along(lv)], lv)
}

list(
  # Kaplan-Meier curves with censor marks and the median line, and the
  # number at risk below
  km_risk_table = function(adam, param, group = "TRT01P") {
    d <- adam$ADTTE
    d <- d[d$PARAMCD == param & d$FASFL == "Y", ]
    d$AVAL <- d$AVAL / 30.4375
    d$grp <- d[[group]]
    fit <- ggsurvfit::survfit2(survival::Surv(AVAL, CNSR == 0) ~ grp, data = d)
    pal <- pal_of(d$grp)
    xb <- pretty(c(0, max(fit$time)))
    p <- ggsurvfit::ggsurvfit(fit, linewidth = 0.3) +
      ggsurvfit::add_censor_mark(shape = 4, size = 3, stroke = 0.6) +
      ggplot2::geom_hline(yintercept = 0.5, linetype = "twodash",
                          colour = "grey50", linewidth = 0.3) +
      ggplot2::scale_colour_manual(values = pal, breaks = names(pal)) +
      ggplot2::scale_x_continuous(breaks = xb, expand = ggplot2::expansion(mult = c(0.02, 0.02))) +
      ggplot2::scale_y_continuous(breaks = seq(0, 1, by = 0.2)) +
      ggplot2::coord_cartesian(xlim = range(xb), ylim = c(0, 1)) +
      ggplot2::labs(x = "Time (Months)", y = "Survival Probability") +
      ggplot2::theme_minimal(base_size = 10)
    s <- summary(fit, times = xb, extend = TRUE)
    risk <- data.frame(time = s$time,
                       strata = factor(sub("^[^=]*=", "", as.character(s$strata)),
                                       levels = rev(names(pal))),
                       n_risk = s$n.risk)
    p_risk <- ggplot2::ggplot(risk, ggplot2::aes(x = time, y = strata,
                                                 label = n_risk, colour = strata)) +
      ggplot2::geom_text(size = 3) +
      ggplot2::scale_colour_manual(values = pal, guide = "none") +
      ggplot2::scale_x_continuous(breaks = xb, expand = ggplot2::expansion(mult = c(0.02, 0.02))) +
      ggplot2::coord_cartesian(xlim = range(xb), clip = "off") +
      ggplot2::labs(title = "Number of Patients at Risk", x = NULL, y = NULL) +
      ggplot2::theme_void(base_size = 10)
    list(p = p, p_risk = p_risk)
  },

  # best % change of each subject, coloured by best overall response, with
  # the 0, +20% and -30% lines
  waterfall_response = function(adam) {
    tr <- adam$ADTR
    tr <- tr[tr$PARAMCD == "BPCHG" & tr$FASFL == "Y", ]
    rs <- adam$ADRS[adam$ADRS$PARAMCD == "BOR", c("USUBJID", "AVALC")]
    names(rs)[2] <- "BOR"
    d <- merge(tr, rs, by = "USUBJID", all.x = TRUE, sort = FALSE)
    d <- d[!is.na(d$AVAL), ]
    d <- d[order(-d$AVAL), ]
    d$INDEX <- seq_len(nrow(d))
    d$BOR <- factor(d$BOR, levels = c("CR", "PR", "SD", "PD", "NE"))
    pal <- c(CR = "#008000", PR = "#0000FF", SD = "#FFA500", PD = "#800080",
             NE = "#A0A0A0", `NON-CR/NON-PD` = "#20B2AA")
    p <- ggplot2::ggplot() +
      ggplot2::geom_col(data = d, ggplot2::aes(x = INDEX, y = AVAL, fill = BOR),
                        width = 0.8) +
      ggplot2::geom_hline(yintercept = 0, linetype = "solid", colour = "black",
                          linewidth = 0.5) +
      ggplot2::geom_hline(yintercept = c(20, -30), linetype = "dashed",
                          colour = "grey", linewidth = 0.5) +
      ggplot2::annotate("text", x = Inf, y = c(20, -30),
                        label = c("20%", "-30%"), hjust = -0.3, size = 3.5) +
      ggplot2::scale_fill_manual(values = pal, breaks = names(pal),
                                 na.value = "grey80") +
      ggplot2::scale_y_continuous(breaks = seq(-100, 100, by = 20)) +
      ggplot2::coord_cartesian(ylim = c(-100, 100), clip = "off") +
      ggplot2::labs(x = "Patients",
                    y = "Best % Change in Sum of Target Lesion Diameters") +
      ggplot2::theme_minimal(base_size = 10)
    list(p = p)
  },

  # Cox hazard ratio (95% CI) overall and by sex and age group, with the N
  # and estimate columns beside
  forest_hr = function(adam, param, subgroups = c("SEX", "AGEGR1")) {
    d <- adam$ADTTE[adam$ADTTE$PARAMCD == param, ]
    keep <- c("TRT01P", "FASFL", subgroups)
    d <- d[setdiff(names(d), keep)]
    d <- merge(d, adam$ADSL[c("USUBJID", keep)], by = "USUBJID", sort = FALSE)
    d <- d[d$FASFL == "Y", ]
    d$TRT01P <- factor(d$TRT01P, levels = sort(unique(d$TRT01P)))
    d <- droplevels(d)
    hr <- function(x) {
      ne <- c(est = NA, lcl = NA, ucl = NA)
      if (length(unique(x$TRT01P)) < 2 || sum(x$CNSR == 0) < 2) return(ne)
      fit <- tryCatch(survival::coxph(survival::Surv(AVAL, CNSR == 0) ~ TRT01P,
                                      data = x), warning = function(w) NULL)
      if (is.null(fit)) return(ne)
      ci <- summary(fit)$conf.int
      c(est = ci[1, 1], lcl = ci[1, 3], ucl = ci[1, 4])
    }
    row <- function(label, head, n, e) data.frame(
      label = label, head = head, n = n, est = e[["est"]], lcl = e[["lcl"]],
      ucl = e[["ucl"]])
    rows <- list(row("All subjects", FALSE, nrow(d), hr(d)))
    for (v in subgroups) {
      rows[[length(rows) + 1]] <- row(v, TRUE, NA, c(est = NA, lcl = NA, ucl = NA))
      for (lv in sort(unique(stats::na.omit(d[[v]])))) {
        s <- d[d[[v]] %in% lv, ]
        rows[[length(rows) + 1]] <- row(paste0("   ", lv), FALSE, nrow(s), hr(s))
      }
    }
    e <- do.call(rbind, rows)
    ok <- is.finite(e$est) & is.finite(e$lcl) & is.finite(e$ucl) &
      e$lcl > 0 & e$ucl < 1000
    e$txt <- ifelse(e$head, "", ifelse(ok, sprintf("%.2f (%.2f, %.2f)", e$est,
                                                   e$lcl, e$ucl), "NE"))
    e$est[!ok] <- NA
    e$lcl[!ok] <- NA
    e$ucl[!ok] <- NA
    e$y <- rev(seq_len(nrow(e)))
    p <- ggplot2::ggplot(e, ggplot2::aes(y = y)) +
      ggplot2::geom_vline(xintercept = 1, linetype = "dashed", colour = "grey50") +
      ggplot2::geom_errorbar(ggplot2::aes(xmin = lcl, xmax = ucl), width = 0.25,
                             orientation = "y", na.rm = TRUE) +
      ggplot2::geom_point(ggplot2::aes(x = est), shape = 15, size = 2.5,
                          na.rm = TRUE) +
      ggplot2::scale_x_log10() +
      ggplot2::scale_y_continuous(breaks = e$y, labels = e$label,
                                  expand = ggplot2::expansion(add = 0.6)) +
      ggplot2::labs(x = "Hazard Ratio (95% CI)", y = NULL) +
      ggplot2::theme_minimal(base_size = 10)
    p_txt <- ggplot2::ggplot(e, ggplot2::aes(y = y)) +
      ggplot2::geom_text(ggplot2::aes(x = 0, label = ifelse(is.na(n), "", n)),
                         size = 3) +
      ggplot2::geom_text(ggplot2::aes(x = 1, label = txt), size = 3) +
      ggplot2::scale_x_continuous(limits = c(-0.4, 1.6), breaks = c(0, 1),
                                  labels = c("N", "Estimate (95% CI)"),
                                  position = "top") +
      ggplot2::scale_y_continuous(expand = ggplot2::expansion(add = 0.6)) +
      ggplot2::theme_void(base_size = 10)
    list(p = p, p_txt = p_txt)
  },

  # the mean (+/- SE) of a lab parameter by visit and arm
  mean_se = function(adam, param) {
    d <- adam$ADLB[adam$ADLB$PARAMCD == param, ]
    d <- merge(d, adam$ADSL[c("USUBJID", "TRT01A", "SAFFL")], by = "USUBJID",
               sort = FALSE)
    d <- d[d$SAFFL == "Y" & !is.na(d$AVAL) & !is.na(d$AVISITN), ]
    # merge() drops a column's label, which names the legend by default
    attr(d$TRT01A, "label") <- attr(adam$ADSL$TRT01A, "label")
    d$AVISIT <- stats::reorder(factor(d$AVISIT), d$AVISITN)
    g <- unique(d[c("TRT01A", "AVISITN", "AVISIT")])
    g <- g[order(g$TRT01A, g$AVISITN, g$AVISIT), ]
    key <- paste(d$TRT01A, d$AVISITN, d$AVISIT)
    gk <- paste(g$TRT01A, g$AVISITN, g$AVISIT)
    g$n <- as.integer(tapply(d$AVAL, key, length)[gk])
    g$mean <- as.numeric(tapply(d$AVAL, key, mean)[gk])
    g$sd <- as.numeric(tapply(d$AVAL, key, stats::sd)[gk])
    g$se <- g$sd / sqrt(g$n)
    g$lo <- g$mean - g$se
    g$hi <- g$mean + g$se
    attr(g$TRT01A, "label") <- attr(d$TRT01A, "label")
    pal <- pal_of(d$TRT01A)
    pd <- ggplot2::position_dodge(width = 0.3)
    p <- ggplot2::ggplot() +
      ggplot2::geom_line(data = g, ggplot2::aes(x = AVISIT, y = mean, colour = TRT01A,
                                                group = TRT01A),
                         linewidth = 0.5, position = pd) +
      ggplot2::geom_point(data = g, ggplot2::aes(x = AVISIT, y = mean, colour = TRT01A,
                                                 group = TRT01A),
                          shape = 16, size = 2, position = pd) +
      ggplot2::geom_errorbar(data = g, ggplot2::aes(x = AVISIT, ymin = lo, ymax = hi,
                                                    colour = TRT01A),
                             width = 0.2, position = pd) +
      ggplot2::scale_colour_manual(values = pal, breaks = names(pal)) +
      ggplot2::labs(x = "Visit", y = paste("Mean (+/- SE)", param)) +
      ggplot2::theme_minimal(base_size = 10)
    list(p = p)
  },

  # box plots of a lab parameter by visit and arm, with the mean marked
  box_by_visit = function(adam, param = "ALT") {
    d <- adam$ADLB[adam$ADLB$PARAMCD == param, ]
    d <- merge(d, adam$ADSL[c("USUBJID", "TRT01A", "SAFFL")], by = "USUBJID",
               sort = FALSE)
    d <- d[d$SAFFL == "Y" & !is.na(d$AVAL), ]
    attr(d$TRT01A, "label") <- attr(adam$ADSL$TRT01A, "label")
    d$AVISIT <- stats::reorder(factor(d$AVISIT), d$AVISITN)
    g <- unique(d[c("TRT01A", "AVISITN", "AVISIT")])
    g <- g[order(g$TRT01A, g$AVISITN, g$AVISIT), ]
    key <- paste(d$TRT01A, d$AVISITN, d$AVISIT)
    g$mean <- as.numeric(tapply(d$AVAL, key, mean)[paste(g$TRT01A, g$AVISITN,
                                                         g$AVISIT)])
    pal <- pal_of(d$TRT01A)
    pd <- ggplot2::position_dodge(width = 0.8)
    p <- ggplot2::ggplot() +
      ggplot2::geom_boxplot(data = d, ggplot2::aes(x = AVISIT, y = AVAL, fill = TRT01A),
                            width = 0.7, outlier.shape = 16, position = pd) +
      ggplot2::geom_point(data = g, ggplot2::aes(x = AVISIT, y = mean, group = TRT01A),
                          shape = 3, size = 2, position = pd) +
      ggplot2::scale_fill_manual(values = pal, breaks = names(pal),
                                 na.value = "grey80") +
      ggplot2::labs(x = "Visit", y = param) +
      ggplot2::theme_minimal(base_size = 10)
    list(p = p)
  }
)
