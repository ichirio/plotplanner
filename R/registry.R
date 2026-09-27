# Registry of plot types, layer patterns and presets.
#
# Each plot type = one base pattern + optional layer patterns. `roles` lists the
# roles of each pattern; TRUE = required. Layers marked `multi` accept several
# role rows (one marker per row).

pp_types <- function() {
  list(
    km = list(
      title = "Kaplan-Meier curve (ggsurvfit)",
      packages = c("dplyr", "ggplot2", "ggsurvfit", "patchwork"),
      roles = list(
        base = c(time = TRUE, censor = TRUE, strata = FALSE)
      ),
      layers = list(
        censor_mark = list(roles = character()),
        ci          = list(roles = character()),
        median_line = list(roles = character()),
        n_at_risk   = list(roles = character())
      ),
      time_roles = list(base = "time")
    ),
    waterfall = list(
      title = "Waterfall plot",
      packages = c("dplyr", "ggplot2", "patchwork"),
      roles = list(
        base = c(id = TRUE, value = TRUE, fill = FALSE)
      ),
      layers = list(
        ref_lines  = list(roles = character()),
        ref_labels = list(roles = character())
      ),
      time_roles = list()
    ),
    swimmer = list(
      title = "Swimmer plot",
      packages = c("dplyr", "ggplot2", "patchwork"),
      roles = list(
        base = c(id = TRUE, end = TRUE, colour = FALSE),
        assessment_marker = c(x = TRUE, fill = FALSE),
        event_marker = c(x = TRUE)
      ),
      layers = list(
        assessment_marker = list(roles = c("x", "fill")),
        event_marker      = list(roles = "x", multi = TRUE),
        ongoing_arrow     = list(roles = character()),
        visit_grid        = list(roles = character())
      ),
      time_roles = list(base = "end", assessment_marker = "x", event_marker = "x")
    )
  )
}

pp_legend_types <- c("mapped", "manual", "none")
pp_legend_positions <- c(
  "right", "bottom", "top", "left", "below",
  "inside_tr", "inside_tl", "inside_br", "inside_bl"
)
pp_themes <- c("boxed", "L_axis", "minimal", "classic")
pp_glyphs <- c("point", "line", "rect")

#' Colour palette presets
#'
#' Named palettes (e.g. `response`) are matched to data values by name;
#' unnamed palettes are assigned to values in order.
#' @return A named list of character vectors.
#' @export
pp_palettes <- function() {
  list(
    response = c(
      CR = "#008000", PR = "#0000FF", SD = "#FFA500", PD = "#800080",
      NE = "#A0A0A0", "NON-CR/NON-PD" = "#20B2AA"
    ),
    response_light = c(
      CR = "#99CC99", PR = "#9999FF", SD = "#FFCC99", PD = "#CC99FF",
      NE = "#D9D9D9", "NON-CR/NON-PD" = "#99D8D3"
    ),
    treatment = c("#0072B2", "#D55E00", "#009E73", "#CC79A7", "#E69F00", "#56B4E9"),
    okabe_ito = c(
      "#E69F00", "#56B4E9", "#009E73", "#F0E442",
      "#0072B2", "#D55E00", "#CC79A7", "#000000"
    ),
    grey = c("#000000", "#555555", "#999999", "#CCCCCC")
  )
}

# Shape names accepted in the spec, mapped to ggplot2 point shapes.
pp_shape_names <- c(
  circle = 21, square = 22, diamond = 23, triangle = 24, triangle_down = 25,
  x = 4, plus = 3, dot = 16, solid_square = 15, solid_triangle = 17,
  star = 8, open_circle = 1
)

# Default option values. `{plot_id}` / `{ds}` are substituted at generation.
pp_default_options <- function() {
  list(
    data_expr = "{ds}",
    id_var = "USUBJID",
    line_width = "0.5",
    fig_path = 'file.path("output", "{plot_id}.png")',
    base_size = "10",
    time_unit = "as_is",
    x_max = "", x_by = "", y_min = "", y_max = "", y_by = "",
    censor_shape = "x",
    arm_label = "All",
    risk_title = "Number of Patients at Risk",
    risk_height = "0.18",
    ref_lines = "20,-30",
    bar_width = "2",
    marker_size = "1.8",
    marker_palette = "response",
    visit_every = "",
    visit_label = "Month",
    bar_legend_prefix = "Best response ",
    legend_title = "",
    legend_ncol = "3",
    legend_height = "0.2",
    legend_width = "0.3",
    legend_hide = ""
  )
}

pp_time_divisor <- c(as_is = NA, days_to_weeks = 7, days_to_months = 30.4375, days_to_years = 365.25)
pp_time_axis_label <- c(
  as_is = "Time", days_to_weeks = "Time (Weeks)",
  days_to_months = "Time (Months)", days_to_years = "Time (Years)"
)
