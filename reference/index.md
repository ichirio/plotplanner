# Package index

## Manual

- [`tflspec_ai_manual()`](https://ichirio.github.io/tflspec/reference/tflspec_ai_manual.md)
  : The AI assistant manual that ships with this package

## ARD spec

The analyses of a study as a workbook: its data, its analysis sets and
one cards / cardx call per row; the R code it stands for and the one
study ARD it makes.

- [`tfl_read_ard_spec()`](https://ichirio.github.io/tflspec/reference/tfl_read_ard_spec.md)
  [`tfl_ard_spec()`](https://ichirio.github.io/tflspec/reference/tfl_read_ard_spec.md)
  : Read and check an ARD definition workbook
- [`tfl_write_ard_spec()`](https://ichirio.github.io/tflspec/reference/tfl_write_ard_spec.md)
  : Write an ARD definition to a workbook
- [`tfl_ard_spec_template()`](https://ichirio.github.io/tflspec/reference/tfl_ard_spec_template.md)
  : An empty ARD spec
- [`tfl_ard_code()`](https://ichirio.github.io/tflspec/reference/tfl_ard_code.md)
  : The R code that makes the study's ARD
- [`tfl_build_ard()`](https://ichirio.github.io/tflspec/reference/tfl_build_ard.md)
  : Make the study's ARD from its definition
- [`tfl_ard_for()`](https://ichirio.github.io/tflspec/reference/tfl_ard_for.md)
  : One output's part of the study ARD
- [`tfl_ard_spec_hash()`](https://ichirio.github.io/tflspec/reference/tfl_ard_spec_hash.md)
  : A fingerprint of one output's ARD definition
- [`tfl_ard_methods()`](https://ichirio.github.io/tflspec/reference/tfl_ard_methods.md)
  : The methods an analysis row may name
- [`tfl_ard_statistics()`](https://ichirio.github.io/tflspec/reference/tfl_ard_statistics.md)
  : The statistics an ARD analysis may ask for

## CDISC ARS

The analyses as CDISC’s Analysis Results Standard, and back.

- [`tfl_ars()`](https://ichirio.github.io/tflspec/reference/tfl_ars.md)
  : The specs as a CDISC ARS reporting event
- [`tfl_write_ars_json()`](https://ichirio.github.io/tflspec/reference/tfl_write_ars_json.md)
  : Write a CDISC ARS reporting event as JSON
- [`tfl_check_ars()`](https://ichirio.github.io/tflspec/reference/tfl_check_ars.md)
  : Check a CDISC ARS reporting event
- [`tfl_ars_unmapped()`](https://ichirio.github.io/tflspec/reference/tfl_ars_unmapped.md)
  : What the ARS does not say
- [`tfl_ars_ard()`](https://ichirio.github.io/tflspec/reference/tfl_ars_ard.md)
  : Make the ARD of a CDISC ARS reporting event with siera
- [`tfl_read_ars_json()`](https://ichirio.github.io/tflspec/reference/tfl_read_ars_json.md)
  : Read a CDISC ARS reporting event from JSON
- [`tfl_ars_to_specs()`](https://ichirio.github.io/tflspec/reference/tfl_ars_to_specs.md)
  : A CDISC ARS reporting event as tflspec specs
- [`tfl_write_ars_xlsx()`](https://ichirio.github.io/tflspec/reference/tfl_write_ars_xlsx.md)
  : Write a CDISC ARS reporting event as CDISC's Excel template

## Table spec

A table as a workbook: its roles and the rtfreporter plan verbs it
stands for; a plan written in code back to a workbook.

- [`tfl_table_spec()`](https://ichirio.github.io/tflspec/reference/tfl_table_spec.md)
  : A workbook-shaped definition of how an ARD becomes a table
- [`tfl_read_table_spec()`](https://ichirio.github.io/tflspec/reference/tfl_read_table_spec.md)
  : Read an ARD table definition from a workbook
- [`tfl_write_report_spec()`](https://ichirio.github.io/tflspec/reference/tfl_write_table_spec.md)
  [`tfl_write_table_spec()`](https://ichirio.github.io/tflspec/reference/tfl_write_table_spec.md)
  : Write a table or report definition to a workbook
- [`tfl_write_specs()`](https://ichirio.github.io/tflspec/reference/tfl_write_specs.md)
  : Write several specs to one workbook
- [`tfl_spec_columns()`](https://ichirio.github.io/tflspec/reference/tfl_spec_columns.md)
  : What each column of a spec workbook means
- [`tfl_table_spec_template()`](https://ichirio.github.io/tflspec/reference/tfl_table_spec_template.md)
  : Scaffold a definition workbook from an ARD
- [`tfl_table_plan()`](https://ichirio.github.io/tflspec/reference/tfl_table_plan.md)
  : A table's plan from its definition
- [`tfl_table_code()`](https://ichirio.github.io/tflspec/reference/tfl_table_code.md)
  : The code of a table's plan, from its definition
- [`tfl_as_table_spec()`](https://ichirio.github.io/tflspec/reference/tfl_as_table_spec.md)
  : Write a plan as a table definition workbook

## Report spec

The page, the running header and footer, the titles and footnotes.

- [`tfl_read_report_spec()`](https://ichirio.github.io/tflspec/reference/tfl_read_report_spec.md)
  : Read a report definition: the table and everything around it
- [`tfl_read_toc()`](https://ichirio.github.io/tflspec/reference/tfl_read_toc.md)
  : Read a table of contents (TOC) as report specs
- [`tfl_report()`](https://ichirio.github.io/tflspec/reference/tfl_report.md)
  : Build a report's RTF document from its definition
- [`tfl_report_code()`](https://ichirio.github.io/tflspec/reference/tfl_report_code.md)
  : The code of a report's document, from its definition
- [`tfl_report_path()`](https://ichirio.github.io/tflspec/reference/tfl_report_path.md)
  : Where a report's RTF file goes

## Listing spec

- [`tfl_listing_spec()`](https://ichirio.github.io/tflspec/reference/tfl_listing_spec.md)
  [`tfl_read_listing_spec()`](https://ichirio.github.io/tflspec/reference/tfl_listing_spec.md)
  [`tfl_write_listing_spec()`](https://ichirio.github.io/tflspec/reference/tfl_listing_spec.md)
  : A listing definition: read, write and check it
- [`tfl_listing()`](https://ichirio.github.io/tflspec/reference/tfl_listing.md)
  : A listing's pages from its definition
- [`tfl_listing_code()`](https://ichirio.github.io/tflspec/reference/tfl_listing_code.md)
  : The code that makes a listing from its definition
- [`tfl_as_listing_spec()`](https://ichirio.github.io/tflspec/reference/tfl_as_listing_spec.md)
  : A listing written in code, as a listing spec
- [`tfl_read_data_code()`](https://ichirio.github.io/tflspec/reference/tfl_read_data_code.md)
  : The code that reads one dataset of a data catalog

## Figure design

A figure as a YAML design, and the ggplot2 script it stands for.

- [`tfl_fig_design()`](https://ichirio.github.io/tflspec/reference/tfl_fig_design.md)
  [`tfl_write_fig_design()`](https://ichirio.github.io/tflspec/reference/tfl_fig_design.md)
  [`tfl_read_fig_design()`](https://ichirio.github.io/tflspec/reference/tfl_fig_design.md)
  [`tfl_fig_design_code()`](https://ichirio.github.io/tflspec/reference/tfl_fig_design.md)
  [`tfl_check_fig_design()`](https://ichirio.github.io/tflspec/reference/tfl_fig_design.md)
  : A figure design
- [`tfl_fig_advice()`](https://ichirio.github.io/tflspec/reference/tfl_fig_advice.md)
  [`tfl_fig_apply_fix()`](https://ichirio.github.io/tflspec/reference/tfl_fig_advice.md)
  : Advice on a figure design
- [`tfl_fig_templates()`](https://ichirio.github.io/tflspec/reference/tfl_fig_templates.md)
  [`tfl_fig_template()`](https://ichirio.github.io/tflspec/reference/tfl_fig_templates.md)
  : Figure templates
- [`tfl_fig_parts()`](https://ichirio.github.io/tflspec/reference/tfl_fig_parts.md)
  : The pieces of a figure design
- [`tfl_fig_add_layer()`](https://ichirio.github.io/tflspec/reference/tfl_fig_add_layer.md)
  : Add a layer to the figure designs' catalog
- [`tfl_fig_calls()`](https://ichirio.github.io/tflspec/reference/tfl_fig_calls.md)
  : Extension functions a figure design knows
- [`tfl_fig_compat()`](https://ichirio.github.io/tflspec/reference/tfl_fig_compat.md)
  : ggplot2 3.5 / 4.0 differences for figure designs
- [`tfl_fig_r()`](https://ichirio.github.io/tflspec/reference/tfl_fig_r.md)
  : Raw R code in a figure design

## Figure style

- [`tfl_fig_style()`](https://ichirio.github.io/tflspec/reference/tfl_fig_style.md)
  [`tfl_fig_style_template()`](https://ichirio.github.io/tflspec/reference/tfl_fig_style.md)
  [`tfl_read_fig_style()`](https://ichirio.github.io/tflspec/reference/tfl_fig_style.md)
  : The figure style standard
- [`tfl_fig_setup_code()`](https://ichirio.github.io/tflspec/reference/tfl_fig_setup_code.md)
  [`tfl_check_fig()`](https://ichirio.github.io/tflspec/reference/tfl_fig_setup_code.md)
  : The helper script of a study's figure programs
- [`tfl_fig_palettes()`](https://ichirio.github.io/tflspec/reference/tfl_fig_palettes.md)
  : Colour palette presets

## Figure spec (sheets) and quick figures

- [`tfl_fig_spec()`](https://ichirio.github.io/tflspec/reference/tfl_fig_spec.md)
  : Build a spec from data frames

- [`tfl_fig_spec_template()`](https://ichirio.github.io/tflspec/reference/tfl_fig_spec_template.md)
  : Write an Excel spec template with drop-down lists built from ADaM
  data

- [`tfl_read_fig_spec()`](https://ichirio.github.io/tflspec/reference/tfl_read_fig_spec.md)
  : Read an Excel plot spec

- [`tfl_check_fig_spec()`](https://ichirio.github.io/tflspec/reference/tfl_check_fig_spec.md)
  : Check a plot spec against ADaM data

- [`tfl_example_fig_spec()`](https://ichirio.github.io/tflspec/reference/tfl_example_fig_spec.md)
  : Example plot spec

- [`tfl_fig_code()`](https://ichirio.github.io/tflspec/reference/tfl_fig_code.md)
  : Generate ggplot2 code from a plot spec

- [`tfl_write_fig_code()`](https://ichirio.github.io/tflspec/reference/tfl_write_fig_code.md)
  :

  Write generated code to `.R` files

- [`tfl_fig_schema()`](https://ichirio.github.io/tflspec/reference/tfl_fig_schema.md)
  : The arguments of every figure type, described

- [`tfl_fig_types()`](https://ichirio.github.io/tflspec/reference/tfl_fig_types.md)
  : Styles of the quick API

- [`tfl_fig_catalog()`](https://ichirio.github.io/tflspec/reference/tfl_fig_catalog.md)
  : Catalogue of clinical figure types

- [`tfl_fig_list_template()`](https://ichirio.github.io/tflspec/reference/tfl_fig_list_template.md)
  : Write an Excel plot list template

- [`tfl_fig_list_code()`](https://ichirio.github.io/tflspec/reference/tfl_fig_list_code.md)
  : Generate code for every row of a plot list

- [`tfl_fig_km()`](https://ichirio.github.io/tflspec/reference/tfl_fig_km.md)
  : Kaplan-Meier plot code (ggsurvfit)

- [`tfl_fig_waterfall()`](https://ichirio.github.io/tflspec/reference/tfl_fig_waterfall.md)
  : Waterfall plot code

- [`tfl_fig_swimmer()`](https://ichirio.github.io/tflspec/reference/tfl_fig_swimmer.md)
  : Swimmer plot code

- [`tfl_fig_forest()`](https://ichirio.github.io/tflspec/reference/tfl_fig_forest.md)
  : Forest plot code

- [`tfl_fig_mean()`](https://ichirio.github.io/tflspec/reference/tfl_fig_mean.md)
  : Mean over time code

- [`tfl_fig_box()`](https://ichirio.github.io/tflspec/reference/tfl_fig_box.md)
  : Box plot code

- [`tfl_fig_bar()`](https://ichirio.github.io/tflspec/reference/tfl_fig_bar.md)
  : Bar chart code for rates and category percentages

- [`tfl_fig_scatter()`](https://ichirio.github.io/tflspec/reference/tfl_fig_scatter.md)
  : Scatter plot code

- [`tfl_fig_individual()`](https://ichirio.github.io/tflspec/reference/tfl_fig_individual.md)
  : Individual profile code (spaghetti / spider)

- [`tfl_fig_pk()`](https://ichirio.github.io/tflspec/reference/tfl_fig_pk.md)
  : PK concentration-time plot code

- [`tfl_fig_ae_dot()`](https://ichirio.github.io/tflspec/reference/tfl_fig_ae_dot.md)
  : AE dot plot code

- [`tfl_fig_butterfly()`](https://ichirio.github.io/tflspec/reference/tfl_fig_butterfly.md)
  : AE butterfly plot code

- [`tfl_fig_edish()`](https://ichirio.github.io/tflspec/reference/tfl_fig_edish.md)
  : eDISH plot code

- [`tfl_fig_sankey()`](https://ichirio.github.io/tflspec/reference/tfl_fig_sankey.md)
  : Sankey diagram code for treatment sequences

- [`tfl_fig_sunburst()`](https://ichirio.github.io/tflspec/reference/tfl_fig_sunburst.md)
  : Sunburst code for treatment sequences

- [`print(`*`<tfl_code>`*`)`](https://ichirio.github.io/tflspec/reference/print.tfl_code.md)
  : Code object returned by the quick API

## Sankey and sunburst

- [`tfl_plot_sankey()`](https://ichirio.github.io/tflspec/reference/tfl_plot_sankey.md)
  : Plot Sankey Diagram with Rectangular Nodes and Bezier Polygon Links
- [`tfl_plot_sankey_batch()`](https://ichirio.github.io/tflspec/reference/tfl_plot_sankey_batch.md)
  : Batch Create Sankey Plots for Subgroup Analysis
- [`tfl_sankey_data()`](https://ichirio.github.io/tflspec/reference/tfl_sankey_data.md)
  [`tfl_sunburst_data()`](https://ichirio.github.io/tflspec/reference/tfl_sankey_data.md)
  : Sankey / sunburst input from treatment-line data
- [`tfl_plot_sunburst()`](https://ichirio.github.io/tflspec/reference/tfl_plot_sunburst.md)
  : Plot a Static Sunburst of Treatment Sequences

## Data

- [`tfl_read_adam()`](https://ichirio.github.io/tflspec/reference/tfl_read_adam.md)
  : Read ADaM datasets
- [`tfl_example_adam()`](https://ichirio.github.io/tflspec/reference/tfl_example_adam.md)
  : Example ADaM-like data for trying tflspec
