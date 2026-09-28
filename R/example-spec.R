#' Example plot spec
#'
#' Spec for the three sample figures (KM, waterfall, swimmer) on
#' [tfl_example_adam()] data.
#' @return A `tfl_fig_spec` object.
#' @export
tfl_example_fig_spec <- function() {
  tfl_fig_spec(
    plots = data.frame(
      plot_id     = c("F-KM-1", "F-WF-1", "F-SW-1"),
      plot_type   = c("km", "waterfall", "swimmer"),
      dataset     = c("ADTTE", "ADTR", "ADSL"),
      layers      = c("censor_mark, median_line, n_at_risk", "ref_lines, ref_labels",
                      "assessment_marker, event_marker, ongoing_arrow, visit_grid"),
      title       = NA,
      x_label     = NA,
      y_label     = c("Overall Survival Probability", NA, NA),
      theme       = c("boxed", "boxed", "L_axis"),
      palette     = c("treatment", "response", "response_light"),
      legend_type = c("mapped", "mapped", "manual"),
      legend_pos  = c("inside_tr", "inside_tr", "below"),
      width = c(7.5, 7.3, 7.7), height = c(4.5, 4.2, 5), units = "in", dpi = 300
    ),
    roles = data.frame(
      plot_id  = c("F-KM-1", "F-KM-1", "F-KM-1", "F-WF-1", "F-WF-1", "F-WF-1",
                   "F-SW-1", "F-SW-1", "F-SW-1", "F-SW-1", "F-SW-1", "F-SW-1", "F-SW-1", "F-SW-1"),
      layer    = c(NA, NA, NA, NA, NA, NA, NA, NA, NA,
                   "assessment_marker", "assessment_marker", "event_marker", "event_marker", "event_marker"),
      role     = c("time", "censor", "strata", "id", "value", "fill", "id", "end", "colour",
                   "x", "fill", "x", "x", "x"),
      dataset  = c(NA, NA, NA, NA, NA, "ADRS", NA, NA, "ADRS", "ADRS", "ADRS", NA, NA, NA),
      variable = c("AVAL", "CNSR", "TRT01P", "USUBJID", "AVAL", "AVALC", "SUBJID", "TRTDURD", "AVALC",
                   "ADY", "AVALC", "DTHADY", "NACTDY", "EOSDY"),
      label    = c(rep(NA, 11), "Death", "Starting Subsequent Anti-Cancer Therapy", "Discontinued"),
      shape    = c(rep(NA, 11), "triangle_down", "circle", "triangle"),
      colour   = c(rep(NA, 11), "black", "#FF00FF", "black")
    ),
    filters = data.frame(
      plot_id  = c("F-KM-1", "F-KM-1", "F-WF-1", "F-WF-1", "F-WF-1", "F-SW-1", "F-SW-1", "F-SW-1", "F-SW-1"),
      layer    = c(NA, NA, NA, NA, NA, NA, NA, "assessment_marker", "ongoing_arrow"),
      dataset  = c(NA, NA, NA, NA, "ADRS", NA, "ADRS", "ADRS", NA),
      variable = c("PARAMCD", "FASFL", "PARAMCD", "FASFL", "PARAMCD", "FASFL", "PARAMCD", "PARAMCD", "EOSSTT"),
      value    = c("OS", "Y", "BPCHG", "Y", "BOR", "Y", "BOR", "OVR", "ONGOING")
    ),
    options = data.frame(
      plot_id = c(NA, "F-KM-1", "F-KM-1", "F-SW-1", "F-SW-1", "F-SW-1"),
      key     = c("time_unit", "x_by", "x_max", "visit_every", "x_by", "x_max"),
      value   = c("days_to_months", "3", "24", "3", "3", "24")
    )
  )
}
