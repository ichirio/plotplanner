# Read and check an ARD definition workbook

Read and check an ARD definition workbook

## Usage

``` r
tfl_read_ard_spec(path, check = TRUE, statistics = NULL, methods = NULL)

tfl_ard_spec(x, statistics = NULL, methods = NULL)
```

## Arguments

- path:

  An `ard_spec.xlsx`.

- check:

  `FALSE` reads a definition still being written without refusing it.

- statistics, methods:

  The catalogs
  ([`tfl_ard_statistics()`](https://ichirio.github.io/tflspec/reference/tfl_ard_statistics.md),
  [`tfl_ard_methods()`](https://ichirio.github.io/tflspec/reference/tfl_ard_methods.md))
  to use instead of the current ones.

- x:

  A list of the sheets (data frames).

## Value

An `tfl_ard_spec`: a list of the four sheets.
