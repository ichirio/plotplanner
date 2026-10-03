# A figure design

A figure as four parts (see
[`tfl_fig_parts()`](https://ichirio.github.io/tflspec/reference/tfl_fig_parts.md)
for every piece):

## Usage

``` r
tfl_fig_design(
  data = list(),
  stats = list(),
  plot = list(),
  layers = list(),
  template = NULL,
  ggplot2_version = NULL,
  plots = NULL,
  compose = NULL
)

tfl_write_fig_design(design, path)

tfl_read_fig_design(path)

tfl_fig_design_code(design, plot_id = "fig", ggplot2_version = NULL)

tfl_check_fig_design(design, adam = NULL, ggplot2_version = NULL)
```

## Arguments

- data, stats, layers:

  Lists of pieces (each a named list).

- plot:

  A named list of the figure-wide settings.

- template:

  The template it was made from (a note).

- ggplot2_version:

  The ggplot2 the script is written for, `"3.5"` or `"4.0"` (see
  [`tfl_fig_compat()`](https://ichirio.github.io/tflspec/reference/tfl_fig_compat.md));
  `NULL`: the design's `ggplot2_version`, else the option
  `tflspec.ggplot2_version`, else the installed ggplot2's. Set (anywhere
  but the installed version), the script's header says
  `# Written for ggplot2 X`.

- plots:

  A composed figure: a named list of figure designs (each with its own
  `data`, `stats`, `plot`, `layers`), put together by patchwork as
  `compose` says. The design's own `plot` then holds only the saved size
  (`width`, `height`, `dpi`, `units`), and it has no `data`, `stats` or
  `layers` of its own.

- compose:

  With `plots`: `layout`, an expression of the plots' names with `|`
  (side by side), `/` (stacked), `+`, `-` and brackets (default: all
  side by side); `add`, a list of calls written after it, each with `op`
  `"+"` (the default) or `"&"` (every figure) – `plot_layout`,
  `plot_annotation`, `theme` ... A figure with panels below it (the
  number at risk, n) or with ggsurvfit's `add_risktable` is kept as one
  figure (`wrap_elements()`).

- design:

  A `tfl_fig_design`.

- path:

  A `.yml` file.

- plot_id:

  The figure's ID: the PNG's name.

- adam:

  The data
  ([`tfl_read_adam()`](https://ichirio.github.io/tflspec/reference/tfl_read_adam.md)):
  the variables and PARAMCDs the design names are looked for in it.

## Value

`tfl_fig_design()` and `tfl_read_fig_design()`: a `tfl_fig_design`;
`tfl_write_fig_design()`: `path`, invisibly; `tfl_fig_design_code()`:
the script (a `tfl_code`).

`tfl_check_fig_design()`: a data frame of the problems (`part`, `field`,
`problem`; `part` is e.g. `data[2] join`); no rows when there are none.
With the target ggplot2 (`ggplot2_version`), a function or argument of a
`call` the target does not have, or drops, is one; what it only
deprecates is advice
([`tfl_fig_advice()`](https://ichirio.github.io/tflspec/reference/tfl_fig_advice.md)).

## Details

- `data`: the steps from ADaM to the plot's data `df` – each a list with
  `step` (`read`, `join`, `param`, `flag`, `filter`, `derive`,
  `time_unit`, `levels`, `rank`, `data_code`) and its fields;

- `stats`: what is computed from `df` (`survfit`, `summary`,
  `stats_code`), each with its `name`;

- `plot`: the figure-wide settings (title, axes, colours, theme, legend,
  size), plus `add`: a list of `call`s (below) written after the
  figure's settings and before any panels – for `theme()`, `scale_*`,
  `coord_*`, `facet_*`, `labs`, `guides` and the like;

- `layers`: what is drawn, in order – each a list with `layer`
  (`km_curve`, `km_ci`, `censor_mark`, `risk_table`, `n_table`,
  `ref_label`; any layer of the geom catalog – `line`, `point`,
  `errorbar`, `col`, `text`, `hline`, `ribbon`, `boxplot` ... see
  [`tfl_fig_add_layer()`](https://ichirio.github.io/tflspec/reference/tfl_fig_add_layer.md);
  `geom` (any function by name), `call` (any function, by `fn`,
  `package`, `data`, `aes`, `pos`, `args` – checked against its own
  arguments; see
  [`tfl_fig_r()`](https://ichirio.github.io/tflspec/reference/tfl_fig_r.md)
  for raw R in `aes`/`args`), `layer_code`, or `figure`: a figure type's
  whole script) and its fields.

[`tfl_fig_template()`](https://ichirio.github.io/tflspec/reference/tfl_fig_templates.md)
makes one for a kind of figure; it is kept as one YAML file per figure
(`tfl_write_fig_design()` / `tfl_read_fig_design()`) and
`tfl_fig_design_code()` writes its script.

    template: km_risk_table
    data:
    - {step: read, dataset: ADTTE}
    - {step: param, value: OS}
    - {step: flag, variable: FASFL}
    - {step: time_unit, variable: AVAL, unit: months}
    stats:
    - {step: survfit, name: fit, time: AVAL, censor: CNSR, by: TRT01A}
    plot: {x_label: Time (Months), y_label: Survival Probability, colour_by: TRT01A,
      legend: inside, x_min: 0, y_min: 0, y_max: 1, y_by: 0.2}
    layers:
    - {layer: km_curve}
    - {layer: censor_mark, shape: x}
    - {layer: hline, yintercept: 0.5, linetype: twodash}
    - {layer: risk_table}

A composed figure (two figures, each with its own data):

    plot: {width: 10, height: 4.5}
    plots:
      km:   {data: [...], stats: [...], plot: {...}, layers: [...]}
      box:  {data: [...], plot: {...}, layers: [...]}
    compose:
      layout: km | box
      add:
      - {fn: plot_layout, args: {widths: [3, 2]}}
      - {fn: plot_annotation, args: {tag_levels: A}}
      - {op: "&", fn: theme, args: {legend.position: bottom}}
