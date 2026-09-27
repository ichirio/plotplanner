# Catalogue of clinical figure types: category, type, style (subtype),
# status, engine, default input and description. The implemented rows drive
# pp_styles(), the Excel plot list and the README; the planned rows record
# the classification for later types.

pp_catalog_rows <- function() {
  r <- function(category, type, style, default, engine, data, description,
                status = "implemented", fun = paste0("pp_", type), subtypes = "") {
    data.frame(category = category, type = type, style = style, default = default,
               status = status, fun = if (status == "implemented") fun else NA_character_,
               engine = engine, data = data, subtypes = subtypes, description = description,
               stringsAsFactors = FALSE)
  }
  rbind(
    # ---- efficacy: time to event ----
    r("Efficacy: time to event", "km", "risk_table", TRUE, "ggsurvfit", "ADTTE",
      "KM curves by group + censor marks + median line + number at risk panel",
      subtypes = "time_unit: days / weeks / months / years"),
    r("Efficacy: time to event", "km", "simple", FALSE, "ggsurvfit", "ADTTE", "KM curves by group + censor marks"),
    r("Efficacy: time to event", "km", "ci", FALSE, "ggsurvfit", "ADTTE",
      "KM curves by group + confidence bands + censor marks + number at risk panel"),
    r("Efficacy: time to event", "km", "single_arm", FALSE, "ggsurvfit", "ADTTE",
      "One KM curve (no group) + censor marks + median line + number at risk panel"),
    r("Efficacy: time to event", "cuminc", "competing_risks", TRUE, "ggsurvfit + tidycmprsk", "ADTTE",
      "Cumulative incidence with competing risks by group", status = "planned"),
    # ---- efficacy: tumour response ----
    r("Efficacy: tumour response", "waterfall", "response", TRUE, "ggplot2", "ADTR + ADRS",
      "Best % change bars coloured by best overall response + +20% / -30% lines with labels"),
    r("Efficacy: tumour response", "waterfall", "plain", FALSE, "ggplot2", "ADTR",
      "Best % change bars in one colour + +20% / -30% lines with labels"),
    r("Efficacy: tumour response", "swimmer", "full", TRUE, "ggplot2", "ADSL + ADRS",
      "Bars coloured by BOR + response at each assessment + event markers + ongoing arrows",
      subtypes = "origin: bars from 0 (duration, default) / from start to end (start, end)"),
    r("Efficacy: tumour response", "swimmer", "assessment", FALSE, "ggplot2", "ADSL + ADRS",
      "Bars coloured by BOR + response at each assessment + ongoing arrows",
      subtypes = "origin: from 0 / from start"),
    r("Efficacy: tumour response", "swimmer", "response", FALSE, "ggplot2", "ADSL + ADRS",
      "Bars coloured by BOR + ongoing arrows", subtypes = "origin: from 0 / from start"),
    r("Efficacy: tumour response", "swimmer", "bar", FALSE, "ggplot2", "ADSL",
      "Bars in one colour + ongoing arrows", subtypes = "origin: from 0 / from start"),
    r("Efficacy: tumour response", "individual", "spider", FALSE, "ggplot2", "ADTR + ADRS",
      "% change in tumour size over time per subject, coloured by BOR, +20% / -30% lines",
      fun = "pp_individual", subtypes = "time_unit: days / weeks / months"),
    # ---- efficacy: subgroups and rates ----
    r("Efficacy: subgroups and rates", "forest", "hr", TRUE, "ggplot2 + survival", "ADTTE + ADSL",
      "Cox hazard ratio (95% CI) overall and by subgroup + N / estimate text columns"),
    r("Efficacy: subgroups and rates", "forest", "or", FALSE, "ggplot2", "ADRS + ADSL",
      "Odds ratio of response (95% CI) overall and by subgroup + text columns"),
    r("Efficacy: subgroups and rates", "forest", "estimates", FALSE, "ggplot2", "(your estimates)",
      "Forest plot of pre-computed estimates (label, est, lcl, ucl)"),
    r("Efficacy: subgroups and rates", "bar", "rate_ci", TRUE, "ggplot2", "ADRS + ADSL",
      "Response rate by group with exact 95% CI and n/N labels"),
    r("Efficacy: subgroups and rates", "bar", "stacked", FALSE, "ggplot2", "ADRS + ADSL",
      "100% stacked bars of a category (e.g. BOR) by group"),
    r("Efficacy: subgroups and rates", "bar", "dodged", FALSE, "ggplot2", "ADRS + ADSL",
      "Percent of subjects per category, groups side by side"),
    # ---- longitudinal ----
    r("Longitudinal", "mean", "se", TRUE, "ggplot2", "ADLB / ADVS + ADSL",
      "Mean +/- SE by visit and group (dodged)", subtypes = "value: AVAL / CHG / PCHG"),
    r("Longitudinal", "mean", "sd", FALSE, "ggplot2", "ADLB / ADVS + ADSL", "Mean +/- SD by visit and group"),
    r("Longitudinal", "mean", "ci", FALSE, "ggplot2", "ADLB / ADVS + ADSL", "Mean with 95% CI by visit and group"),
    r("Longitudinal", "mean", "se_n", FALSE, "ggplot2 + patchwork", "ADLB / ADVS + ADSL",
      "Mean +/- SE by visit and group + table of n below"),
    r("Longitudinal", "individual", "spaghetti", TRUE, "ggplot2", "ADLB / ADVS + ADSL",
      "One line per subject by visit, coloured by group, with group means", fun = "pp_individual"),
    r("Longitudinal", "box", "by_visit", TRUE, "ggplot2", "ADLB / ADVS + ADSL",
      "Box plots by visit and group + mean marker"),
    r("Longitudinal", "box", "by_group", FALSE, "ggplot2", "ADLB / ADVS + ADSL",
      "Box plot per group at one visit + data points + mean marker"),
    r("Longitudinal", "box", "change", FALSE, "ggplot2", "ADLB / ADVS + ADSL",
      "Box plots of change from baseline by visit and group + zero line"),
    r("Longitudinal", "lsmeans", "mmrm", TRUE, "ggplot2 + mmrm / emmeans", "ADLB / ADVS / ADQS",
      "Model-based LS means (95% CI) over time by group", status = "planned"),
    # ---- safety ----
    r("Safety", "ae_dot", "risk_diff", TRUE, "ggplot2 + patchwork", "ADAE + ADSL",
      "Incidence by preferred term (two arms) + risk difference with 95% CI"),
    r("Safety", "ae_dot", "incidence", FALSE, "ggplot2", "ADAE + ADSL", "Incidence by preferred term by arm"),
    r("Safety", "butterfly", "soc", TRUE, "ggplot2", "ADAE + ADSL",
      "Incidence by system organ class, two arms mirrored"),
    r("Safety", "butterfly", "pt", FALSE, "ggplot2", "ADAE + ADSL",
      "Incidence by preferred term (top N), two arms mirrored"),
    r("Safety", "edish", "alt", TRUE, "ggplot2", "ADLB + ADSL",
      "Max ALT vs max total bilirubin (x ULN, log axes) + Hy's law lines and quadrants"),
    r("Safety", "edish", "alt_ast", FALSE, "ggplot2", "ADLB + ADSL",
      "Max of ALT / AST vs max total bilirubin (x ULN) + Hy's law lines"),
    r("Safety", "shift_heatmap", "worst_grade", TRUE, "ggplot2", "ADLB + ADSL",
      "Baseline vs worst post-baseline grade counts as a heatmap", status = "planned"),
    r("Safety", "patient_profile", "timeline", TRUE, "ggplot2 + patchwork", "ADSL + ADEX + ADAE + ADLB",
      "One subject: dosing, AEs and labs on a shared time axis", status = "planned"),
    # ---- PK / PD ----
    r("PK / PD", "pk", "mean", TRUE, "ggplot2", "ADPC + ADSL", "Mean +/- SD concentration by nominal time and group"),
    r("PK / PD", "pk", "mean_log", FALSE, "ggplot2", "ADPC + ADSL", "Mean +/- SD concentration, log axis"),
    r("PK / PD", "pk", "individual", FALSE, "ggplot2", "ADPC + ADSL",
      "Individual concentration-time profiles, log axis, one panel per group"),
    r("PK / PD", "qtc_conc", "scatter_fit", TRUE, "ggplot2", "ADEG + ADPC",
      "Change in QTc vs concentration with a linear fit", status = "planned"),
    r("PK / PD", "dose_response", "emax", TRUE, "ggplot2", "ADPP / ADEFF",
      "Response by dose with a fitted Emax curve", status = "planned"),
    # ---- distribution / association ----
    r("Distribution / association", "scatter", "shift", TRUE, "ggplot2", "ADLB / ADVS + ADSL",
      "Baseline vs post-baseline value at one visit + identity line"),
    r("Distribution / association", "scatter", "xy", FALSE, "ggplot2", "ADLB / ADVS + ADSL",
      "Two variables with a linear fit per group"),
    r("Distribution / association", "histogram", "by_group", TRUE, "ggplot2", "any",
      "Histogram / density of a variable by group", status = "planned"),
    r("Distribution / association", "roc", "biomarker", TRUE, "ggplot2", "ADBM",
      "ROC curve of a biomarker with AUC", status = "planned"),
    # ---- treatment patterns ----
    r("Treatment patterns", "sankey", "grey_links", TRUE, "tflspec (ggplot2)", "ADLOT",
      "Treatment-line nodes (subjects per line x category) + links in light grey"),
    r("Treatment patterns", "sankey", "colored_links", FALSE, "tflspec (ggplot2)", "ADLOT",
      "Treatment-line nodes + links in the colour of their source node"),
    r("Treatment patterns", "sankey", "subgroups", FALSE, "tflspec (ggplot2) + patchwork", "ADLOT",
      "One sankey per subgroup (`by`) on a shared scale, side by side"),
    r("Treatment patterns", "sunburst", "rings", TRUE, "tflspec (ggplot2)", "ADLOT",
      "One ring per line (inner = first line); arcs = subjects, gaps = no further line")
  )
}

#' Catalogue of clinical figure types
#'
#' Every figure type and style (subtype) tflspec knows, grouped by clinical
#' category. `status = "planned"` rows are classified but not generated yet.
#'
#' @param status `"implemented"`, `"planned"` or `NULL` for all.
#' @return A data frame: `category`, `type`, `style`, `default`, `status`,
#'   `fun` (quick function), `engine`, `data` (default input), `subtypes`
#'   (argument-level variants) and `description`.
#' @examples
#' cat <- pp_catalog()
#' table(cat$category, cat$status)
#' @export
pp_catalog <- function(status = NULL) {
  x <- pp_catalog_rows()
  if (!is.null(status)) x <- x[x$status %in% status, , drop = FALSE]
  rownames(x) <- NULL
  x
}

#' Styles of the quick API
#'
#' The implemented rows of [pp_catalog()].
#'
#' @return A data frame: `type`, `style`, `default`, `description`.
#' @export
pp_styles <- function() {
  x <- pp_catalog("implemented")
  x[c("type", "style", "default", "description")]
}
