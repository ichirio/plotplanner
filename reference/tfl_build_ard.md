# Make the study's ARD from its definition

Runs
[`tfl_ard_code()`](https://ichirio.github.io/tflspec/reference/tfl_ard_code.md)
from the study folder: the ARD is exactly what the code gives.

## Usage

``` r
tfl_build_ard(
  spec,
  dir = ".",
  output_id = NULL,
  save = TRUE,
  statistics = NULL,
  methods = NULL
)
```

## Arguments

- spec:

  An
  [`tfl_ard_spec()`](https://ichirio.github.io/tflspec/reference/tfl_read_ard_spec.md)
  (or the path of one).

- dir:

  The study folder (the code's working directory).

- output_id:

  Only these outputs' analyses; `NULL` for all.

- save:

  `FALSE` leaves out the final
  [`saveRDS()`](https://rdrr.io/r/base/readRDS.html).

- statistics, methods:

  The catalogs
  ([`tfl_ard_statistics()`](https://ichirio.github.io/tflspec/reference/tfl_ard_statistics.md),
  [`tfl_ard_methods()`](https://ichirio.github.io/tflspec/reference/tfl_ard_methods.md))
  to use instead of the current ones.

## Value

The ARD (with `output_id`, `analysis_id`, `population_id`), invisibly;
with `save`, also written where the study key `output` says.
