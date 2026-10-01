# What a function that takes a spec does with something else: it says what
# it wants and what it got.  And a file that is not there is said one way.

test_that("a function given something other than a spec says so", {
  df <- data.frame(a = 1:2)
  expect_error(tfl_ard_code(df),
               "tfl_ard_code(): `spec` must be an ARD spec", fixed = TRUE)
  expect_error(tfl_ard_code(df), "got a data.frame (2 x 1)", fixed = TRUE)
  expect_error(tfl_ard_code(list(a = 1)),
               "tfl_ard_code(): `spec` must be an ARD spec", fixed = TRUE)
  expect_error(tfl_build_ard(df), "`spec` must be an ARD spec", fixed = TRUE)
  expect_error(tfl_table_code(df),
               "tfl_table_code(): `spec` must be a table / report spec",
               fixed = TRUE)
  expect_error(tfl_report_path(42), "got a numeric", fixed = TRUE)
})

test_that("a file that is not there is said one way", {
  expect_error(tfl_read_ard_spec("nope.xlsx"),
               "tfl_read_ard_spec(): no file 'nope.xlsx'", fixed = TRUE)
  expect_error(tfl_read_table_spec("nope.xlsx"),
               "tfl_read_table_spec(): no file 'nope.xlsx'", fixed = TRUE)
  expect_error(tfl_read_listing_spec("nope.xlsx"),
               "tfl_read_listing_spec(): no file 'nope.xlsx'", fixed = TRUE)
})

test_that("tfl_ard_for() refuses an output the ARD has not, naming those it has", {
  ard <- data.frame(output_id = c("A", "A", "B"), analysis_id = "x",
                    population_id = NA, stat = 1:3)
  expect_identical(nrow(tfl_ard_for(ard, "B")), 1L)
  expect_error(tfl_ard_for(ard, "C"), "no output 'C'")
  expect_error(tfl_ard_for(ard, "C"), "It has: A, B")
  expect_error(tfl_ard_for(list(), "A"), "must be a study ARD")
})
