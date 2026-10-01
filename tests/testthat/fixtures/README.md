`ars-csd-demographics.json`: CDISC's ARS v1.0 example "Common Safety
Displays" (https://github.com/cdisc-org/analysis-results-standard,
`workfiles/examples/ARS v1/Common Safety Displays.json`, MIT licence), cut
down to the demographics output (Out14-1-1) and what it refers to, its
results removed.  The tests check that tfl_check_ars() finds no problem in it.
