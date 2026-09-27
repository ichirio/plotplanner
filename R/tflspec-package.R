#' tflspec: Excel specifications for tables, listings and figures
#'
#' Reads study specifications written in Excel and turns them into what a
#' clinical TFL report is made of: ARD-based tables (`ard_*()`, `rtf_plan()` /
#' `plan_*()`, `table_spec()` / `read_report_spec()`) and figure code
#' (`plot_spec()` / `plot_code()`).  Rendering to RTF is rtfreporter's job;
#' this package decides *what* goes on the page.
#'
#' @keywords internal
#' @import rtfreporter
"_PACKAGE"
