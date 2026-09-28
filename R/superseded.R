# ============================================================================
#  Former names (superseded)
# ----------------------------------------------------------------------------
#  Every export took the package prefix tfl_ in 0.0.9 (#9), so tflspec's
#  names do not collide with cards / cardx (ard_*) or rtfreporter (rtf_*)
#  on library().  The old names below are the same functions, kept so
#  existing programs run unchanged; no warning.  To be removed before CRAN.
# ============================================================================

#' Former names of tflspec functions
#'
#' Every tflspec function now starts with `tfl_`.  The old names still work:
#' each is the same function as its new name.  They are **superseded** --
#' write the new names in new code -- and will be removed before the first
#' CRAN release.
#'
#' | Former name | New name |
#' |---|---|
#' | `apply_plan()` | [tfl_apply_plan()] |
#' | `ard_cells()` | [tfl_ard_cells()] |
#' | `ard_for()` | [tfl_ard_for()] |
#' | `ard_keys()` | [tfl_ard_keys()] |
#' | `ard_methods()` | [tfl_ard_methods()] |
#' | `ard_normalize()` | [tfl_ard_normalize()] |
#' | `ard_overall()` | [tfl_ard_overall()] |
#' | `ard_pull()` | [tfl_ard_pull()] |
#' | `ard_spec()` | [tfl_ard_spec()] |
#' | `ard_spec_code()` | [tfl_ard_code()] |
#' | `ard_spec_hash()` | [tfl_ard_spec_hash()] |
#' | `ard_spec_template()` | [tfl_ard_spec_template()] |
#' | `ard_spread()` | [tfl_ard_spread()] |
#' | `ard_statistics()` | [tfl_ard_statistics()] |
#' | `ard_template()` | [tfl_ard_template()] |
#' | `as_table_spec()` | [tfl_as_table_spec()] |
#' | `build_ard()` | [tfl_build_ard()] |
#' | `check_figure()` | [tfl_check_fig()] |
#' | `check_plot_spec()` | [tfl_check_fig_spec()] |
#' | `fig_setup_code()` | [tfl_fig_setup_code()] |
#' | `fig_style()` | [tfl_fig_style()] |
#' | `fig_style_template()` | [tfl_fig_style_template()] |
#' | `listing_spec_code()` | [tfl_listing_code()] |
#' | `plan_after()` | [tfl_plan_after()] |
#' | `plan_blanks()` | [tfl_plan_blanks()] |
#' | `plan_cell_style()` | [tfl_plan_cell_style()] |
#' | `plan_cells()` | [tfl_plan_cells()] |
#' | `plan_col_header()` | [tfl_plan_col_header()] |
#' | `plan_digits()` | [tfl_plan_digits()] |
#' | `plan_fmt()` | [tfl_plan_fmt()] |
#' | `plan_footnotes()` | [tfl_plan_footnotes()] |
#' | `plan_hide()` | [tfl_plan_hide()] |
#' | `plan_labels()` | [tfl_plan_labels()] |
#' | `plan_levels()` | [tfl_plan_levels()] |
#' | `plan_listing()` | [tfl_plan_listing()] |
#' | `plan_paginate_cols()` | [tfl_plan_paginate_cols()] |
#' | `plan_paginate_group()` | [tfl_plan_paginate_group()] |
#' | `plan_paginate_rows()` | [tfl_plan_paginate_rows()] |
#' | `plan_row_group()` | [tfl_plan_row_group()] |
#' | `plan_sort()` | [tfl_plan_sort()] |
#' | `plan_stub()` | [tfl_plan_stub()] |
#' | `plan_style()` | [tfl_plan_style()] |
#' | `plan_template()` | [tfl_plan_template()] |
#' | `plan_titles()` | [tfl_plan_titles()] |
#' | `plot_code()` | [tfl_fig_code()] |
#' | `plot_list_code()` | [tfl_fig_list_code()] |
#' | `plot_sankey()` | [tfl_plot_sankey()] |
#' | `plot_sankey_subgroups_batch()` | [tfl_plot_sankey_batch()] |
#' | `plot_spec()` | [tfl_fig_spec()] |
#' | `plot_sunburst()` | [tfl_plot_sunburst()] |
#' | `pp_ae_dot()` | [tfl_fig_ae_dot()] |
#' | `pp_bar()` | [tfl_fig_bar()] |
#' | `pp_box()` | [tfl_fig_box()] |
#' | `pp_butterfly()` | [tfl_fig_butterfly()] |
#' | `pp_catalog()` | [tfl_fig_catalog()] |
#' | `pp_edish()` | [tfl_fig_edish()] |
#' | `pp_example_adam()` | [tfl_example_adam()] |
#' | `pp_example_spec()` | [tfl_example_fig_spec()] |
#' | `pp_forest()` | [tfl_fig_forest()] |
#' | `pp_individual()` | [tfl_fig_individual()] |
#' | `pp_km()` | [tfl_fig_km()] |
#' | `pp_mean()` | [tfl_fig_mean()] |
#' | `pp_palettes()` | [tfl_fig_palettes()] |
#' | `pp_pk()` | [tfl_fig_pk()] |
#' | `pp_sankey()` | [tfl_fig_sankey()] |
#' | `pp_scatter()` | [tfl_fig_scatter()] |
#' | `pp_styles()` | [tfl_fig_types()] |
#' | `pp_sunburst()` | [tfl_fig_sunburst()] |
#' | `pp_swimmer()` | [tfl_fig_swimmer()] |
#' | `pp_waterfall()` | [tfl_fig_waterfall()] |
#' | `read_adam()` | [tfl_read_adam()] |
#' | `read_ard_spec()` | [tfl_read_ard_spec()] |
#' | `read_data_code()` | [tfl_read_data_code()] |
#' | `read_fig_style()` | [tfl_read_fig_style()] |
#' | `read_plot_spec()` | [tfl_read_fig_spec()] |
#' | `read_report_spec()` | [tfl_read_report_spec()] |
#' | `read_table_spec()` | [tfl_read_table_spec()] |
#' | `report_path()` | [tfl_report_path()] |
#' | `rtf_plan()` | [tfl_plan()] |
#' | `rtf_report()` | [tfl_report()] |
#' | `sankey_data()` | [tfl_sankey_data()] |
#' | `sunburst_data()` | [tfl_sunburst_data()] |
#' | `table_plan()` | [tfl_plan()] |
#' | `table_spec()` | [tfl_table_spec()] |
#' | `table_spec_template()` | [tfl_table_spec_template()] |
#' | `write_ard_spec()` | [tfl_write_ard_spec()] |
#' | `write_plot_code()` | [tfl_write_fig_code()] |
#' | `write_plot_list_template()` | [tfl_fig_list_template()] |
#' | `write_plot_spec_template()` | [tfl_fig_spec_template()] |
#' | `write_table_spec()` | [tfl_write_table_spec()] |
#'
#' @name tflspec-superseded
#' @keywords internal
NULL

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
apply_plan <- tfl_apply_plan

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
ard_cells <- tfl_ard_cells

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
ard_for <- tfl_ard_for

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
ard_keys <- tfl_ard_keys

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
ard_methods <- tfl_ard_methods

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
ard_normalize <- tfl_ard_normalize

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
ard_overall <- tfl_ard_overall

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
ard_pull <- tfl_ard_pull

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
ard_spec <- tfl_ard_spec

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
ard_spec_code <- tfl_ard_code

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
ard_spec_hash <- tfl_ard_spec_hash

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
ard_spec_template <- tfl_ard_spec_template

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
ard_spread <- tfl_ard_spread

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
ard_statistics <- tfl_ard_statistics

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
ard_template <- tfl_ard_template

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
as_table_spec <- tfl_as_table_spec

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
build_ard <- tfl_build_ard

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
check_figure <- tfl_check_fig

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
check_plot_spec <- tfl_check_fig_spec

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
fig_setup_code <- tfl_fig_setup_code

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
fig_style <- tfl_fig_style

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
fig_style_template <- tfl_fig_style_template

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
listing_spec_code <- tfl_listing_code

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
plan_after <- tfl_plan_after

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
plan_blanks <- tfl_plan_blanks

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
plan_cell_style <- tfl_plan_cell_style

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
plan_cells <- tfl_plan_cells

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
plan_col_header <- tfl_plan_col_header

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
plan_digits <- tfl_plan_digits

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
plan_fmt <- tfl_plan_fmt

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
plan_footnotes <- tfl_plan_footnotes

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
plan_hide <- tfl_plan_hide

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
plan_labels <- tfl_plan_labels

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
plan_levels <- tfl_plan_levels

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
plan_listing <- tfl_plan_listing

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
plan_paginate_cols <- tfl_plan_paginate_cols

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
plan_paginate_group <- tfl_plan_paginate_group

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
plan_paginate_rows <- tfl_plan_paginate_rows

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
plan_row_group <- tfl_plan_row_group

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
plan_sort <- tfl_plan_sort

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
plan_stub <- tfl_plan_stub

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
plan_style <- tfl_plan_style

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
plan_template <- tfl_plan_template

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
plan_titles <- tfl_plan_titles

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
plot_code <- tfl_fig_code

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
plot_list_code <- tfl_fig_list_code

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
plot_sankey <- tfl_plot_sankey

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
plot_sankey_subgroups_batch <- tfl_plot_sankey_batch

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
plot_spec <- tfl_fig_spec

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
plot_sunburst <- tfl_plot_sunburst

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
pp_ae_dot <- tfl_fig_ae_dot

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
pp_bar <- tfl_fig_bar

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
pp_box <- tfl_fig_box

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
pp_butterfly <- tfl_fig_butterfly

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
pp_catalog <- tfl_fig_catalog

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
pp_edish <- tfl_fig_edish

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
pp_example_adam <- tfl_example_adam

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
pp_example_spec <- tfl_example_fig_spec

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
pp_forest <- tfl_fig_forest

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
pp_individual <- tfl_fig_individual

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
pp_km <- tfl_fig_km

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
pp_mean <- tfl_fig_mean

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
pp_palettes <- tfl_fig_palettes

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
pp_pk <- tfl_fig_pk

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
pp_sankey <- tfl_fig_sankey

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
pp_scatter <- tfl_fig_scatter

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
pp_styles <- tfl_fig_types

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
pp_sunburst <- tfl_fig_sunburst

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
pp_swimmer <- tfl_fig_swimmer

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
pp_waterfall <- tfl_fig_waterfall

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
read_adam <- tfl_read_adam

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
read_ard_spec <- tfl_read_ard_spec

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
read_data_code <- tfl_read_data_code

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
read_fig_style <- tfl_read_fig_style

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
read_plot_spec <- tfl_read_fig_spec

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
read_report_spec <- tfl_read_report_spec

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
read_table_spec <- tfl_read_table_spec

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
report_path <- tfl_report_path

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
rtf_plan <- tfl_plan

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
rtf_report <- tfl_report

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
sankey_data <- tfl_sankey_data

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
sunburst_data <- tfl_sunburst_data

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
table_plan <- tfl_plan

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
table_spec <- tfl_table_spec

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
table_spec_template <- tfl_table_spec_template

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
write_ard_spec <- tfl_write_ard_spec

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
write_plot_code <- tfl_write_fig_code

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
write_plot_list_template <- tfl_fig_list_template

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
write_plot_spec_template <- tfl_fig_spec_template

#' @rdname tflspec-superseded
#' @usage NULL
#' @export
write_table_spec <- tfl_write_table_spec
