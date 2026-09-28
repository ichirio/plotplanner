test_that("every former name is the same function as its tfl_ name", {
  ns <- asNamespace("tflspec")
  ex <- getNamespaceExports(ns)
  old <- setdiff(ex, grep("^tfl_", ex, value = TRUE))
  expect_gt(length(old), 80)
  for (o in old) {
    f <- get(o, envir = ns)
    new <- ex[startsWith(ex, "tfl_") &
                vapply(ex, function(n) identical(get(n, envir = ns), f), NA)]
    expect_length(new, 1L)
  }
  expect_identical(rtf_plan, tfl_plan)
  expect_identical(table_plan, tfl_plan)
  expect_identical(pp_km, tfl_fig_km)
})
