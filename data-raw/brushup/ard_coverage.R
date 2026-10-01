# ============================================================================
#  iter00: what the ARD spec can say, and whether what it makes is right
# ----------------------------------------------------------------------------
#  Each case (tests/testthat/fixtures/ard-cases.R): one analysis row of an
#  ARD spec, and the same analysis written by hand with cards / cardx.
#  tfl_build_ard() runs the spec; the hand call runs on the same data; the
#  two ARDs are compared number by number (tests/testthat/helper-ard-exact.R,
#  also what test-ard-exact.R runs).
#
#    status  spec   : the row says it with the spec's own columns
#            args   : it needs the row's `args` (R) for what no column says
#            custom : only `custom` code says it
#    same    TRUE when every value of the hand ARD is in the spec's, equal
#
#    Rscript data-raw/brushup/ard_coverage.R      (from the package root)
# ============================================================================
suppressMessages({
  pkgload::load_all(".", quiet = TRUE)
  library(cards)
})
source("tests/testthat/helper-ard-exact.R")
cases <- source("tests/testthat/fixtures/ard-cases.R")$value
adam <- exact_data()
dir <- exact_dir(adam)
tab <- do.call(rbind, lapply(cases, function(cs) {
  r <- exact_run(cs, adam, dir)
  data.frame(id = cs$id, group = cs$group, fun = cs$fun, status = cs$status,
             same = r$same, n = r$n, note = cs$note %||% "", error = r$error,
             stringsAsFactors = FALSE)
}))
print(tab[, c("id", "status", "same", "n", "error")], right = FALSE)
saveRDS(tab, "data-raw/brushup/ard_coverage.rds")
