# ============================================================================
#  iter00: what the table spec can say of an rtfreporter plan
# ----------------------------------------------------------------------------
#  Each case: a plan (a base plan and one more verb).  tfl_as_table_spec()
#  writes it as a table spec, lists what it could not say (not_converted)
#  and rebuilds the pages from the spec to compare them with the plan's
#  (same_pages).
#
#    Rscript data-raw/brushup/table_coverage.R      (from the package root)
# ============================================================================
suppressMessages({
  pkgload::load_all(".", quiet = TRUE)
  library(rtfreporter)
})

# the cases: tests/testthat/fixtures/table-cases.R (the round-trip test
# runs them too)
cases <- source("tests/testthat/fixtures/table-cases.R", local = TRUE)$value

run <- function(nm) {
  p <- tryCatch(eval(cases[[nm]]), error = function(e) e)
  if (inherits(p, "error")) {
    return(data.frame(case = nm, built = FALSE, same_pages = NA,
                      not_converted = "", error = conditionMessage(p)))
  }
  sp <- tryCatch(suppressMessages(tfl_as_table_spec(p, output_id = "T")),
                 error = function(e) e)
  if (inherits(sp, "error")) {
    return(data.frame(case = nm, built = TRUE, same_pages = NA,
                      not_converted = "", error = conditionMessage(sp)))
  }
  data.frame(case = nm, built = TRUE,
             same_pages = isTRUE(attr(sp, "same_pages")),
             not_converted = paste(attr(sp, "not_converted"), collapse = " / "),
             error = "")
}
tab <- do.call(rbind, lapply(names(cases), run))
print(tab, right = FALSE)
saveRDS(tab, "data-raw/brushup/table_coverage.rds")
