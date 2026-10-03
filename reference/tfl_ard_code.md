# The R code that makes the study's ARD

One cards / cardx call per analysis row, each result tagged with its
`output_id`, `analysis_id` and `population_id`, bound into one ARD and
saved to the study key `output` (default `output/ard/ard.rds`). The code
runs from the study folder.

## Usage

``` r
tfl_ard_code(
  spec,
  output_id = NULL,
  save = TRUE,
  part = c("all", "setup", "body"),
  statistics = NULL,
  methods = NULL,
  dir = "."
)
```

## Arguments

- spec:

  An
  [`tfl_ard_spec()`](https://ichirio.github.io/tflspec/reference/tfl_read_ard_spec.md)
  (or the path of one).

- output_id:

  Only these outputs' analyses; `NULL` for all.

- save:

  `FALSE` leaves out the final
  [`saveRDS()`](https://rdrr.io/r/base/readRDS.html).

- part:

  `"all"` (the whole program), `"setup"` or `"body"`.

- statistics, methods:

  The catalogs
  ([`tfl_ard_statistics()`](https://ichirio.github.io/tflspec/reference/tfl_ard_statistics.md),
  [`tfl_ard_methods()`](https://ichirio.github.io/tflspec/reference/tfl_ard_methods.md))
  to use instead of the current ones.

- dir:

  The study folder: the fingerprints saved with the ARD
  ([`tfl_ard_spec_hash()`](https://ichirio.github.io/tflspec/reference/tfl_ard_spec_hash.md))
  read the study's own function files from it.

## Value

The code, one element per line.

## Details

`part` gives a piece of it instead, for a program layout of one's own
(tflplanner writes one program per output that sources a shared setup):
`"setup"` is what every piece starts with –
[`library(cards)`](https://github.com/pharmaverse/cards), the tagging
helper, every computed statistic of the catalog and the `stat_fmt`
helpers; `"body"` is the analyses of `output_id`, ending in `ard` –
without a header or [`saveRDS()`](https://rdrr.io/r/base/readRDS.html).
