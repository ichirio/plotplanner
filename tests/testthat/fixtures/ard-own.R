# A study's own analysis function, as an ARD spec loads it with the study
# key `source`: an analysis cards / cardx has no function for.  The
# difference of two proportions with Newcombe's hybrid score interval
# (Newcombe 1998, method 10), as a cards ARD.
#
# The contract of an own function: it takes the analysis data first, then
# `by` and `variables` as bare column names (as cards does), and gives a
# cards ARD (class `card`).

ard_riskdiff_newcombe <- function(data, by, variables, value = "Y",
                                  conf.level = 0.95) {
  by <- deparse(substitute(by))
  var <- deparse(substitute(variables))
  g <- factor(data[[by]])
  g <- droplevels(g)
  if (nlevels(g) != 2L) stop("`by` needs two groups", call. = FALSE)
  x <- as.vector(tapply(data[[var]] %in% value, g, sum))
  n <- as.vector(table(g))
  p <- x / n
  z <- stats::qnorm(1 - (1 - conf.level) / 2)
  wilson <- function(x, n) {
    (2 * x + z^2 + c(-1, 1) * z * sqrt(z^2 + 4 * x * (n - x) / n)) /
      (2 * (n + z^2))
  }
  w1 <- wilson(x[1L], n[1L])
  w2 <- wilson(x[2L], n[2L])
  d <- p[1L] - p[2L]
  lo <- d - sqrt((p[1L] - w1[1L])^2 + (w2[2L] - p[2L])^2)
  hi <- d + sqrt((w1[2L] - p[1L])^2 + (p[2L] - w2[1L])^2)
  stat <- c(estimate = d, conf.low = lo, conf.high = hi)
  cards::as_card(dplyr::tibble(
    group1 = by,
    group1_level = list(levels(g)[1L]),
    variable = var,
    variable_level = list(paste(value, collapse = ",")),
    context = "riskdiff_newcombe",
    stat_name = names(stat),
    stat_label = c("Risk difference", "CI lower bound", "CI upper bound"),
    stat = as.list(unname(stat)),
    fmt_fun = list(1L),
    warning = list(NULL),
    error = list(NULL)))
}
