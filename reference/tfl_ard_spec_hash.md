# A fingerprint of one output's ARD definition

The md5 of what makes an output's ARD: its analysis rows and the data,
populations and study keys they use, and the content of the study's own
function files (the study key `source`; a file not there counts as
`"missing"`). An ARD built from a definition whose fingerprint differs
from the one now is outdated. A column blank in every analysis row of
the output does not count, so a column added to the definition later
leaves the fingerprints as they were.

## Usage

``` r
tfl_ard_spec_hash(spec, output_id, dir = ".")
```

## Arguments

- spec:

  An
  [`tfl_ard_spec()`](https://ichirio.github.io/tflspec/reference/tfl_read_ard_spec.md).

- output_id:

  The output.

- dir:

  The study folder, which `source` files are relative to.

## Value

A single string.
