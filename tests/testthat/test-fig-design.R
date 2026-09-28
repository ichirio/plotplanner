test_that("the schema describes every implemented type's arguments", {
  s <- tfl_fig_schema()
  cat <- tfl_fig_catalog()
  expect_setequal(unique(s$type), unique(cat$type[cat$status == "implemented"]))
  expect_true(all(s$section %in% c("data", "mapping", "style", "axes",
                                   "legend", "output")))
  expect_false(any(c("adam", "file", "plot_id") %in% s$arg))
  km <- tfl_fig_schema("km")
  expect_equal(km$default[km$arg == "param"], "OS")
  expect_match(km$choices[km$arg == "style"], "risk_table")
  expect_true(all(c("x_max", "x_by") %in% km$arg))
})

test_that("a design goes to YAML and back, and makes the script", {
  d <- tfl_fig_design("km", "risk_table",
                      list(param = "TTDE", group = "TRT01A",
                           x_max = 24, x_by = 3))
  f <- tempfile(fileext = ".yml")
  tfl_write_fig_design(d, f)
  d2 <- tfl_read_fig_design(f)
  expect_equal(unclass(d2), unclass(d))
  adam <- tfl_example_adam()
  code <- tfl_fig_design_code(d2, adam)
  expect_true(any(grepl("TTDE", code)))
  expect_true(any(grepl("fig <-", code, fixed = TRUE)))
  expect_error(tfl_fig_design("km", "nope"), "not one of")
})

test_that("a design is checked against the schema and the data", {
  adam <- tfl_example_adam()
  d <- tfl_fig_design("km", args = list(group = "NOVAR", legend = "left",
                                        x_max = "a", colour = "x"))
  p <- tfl_check_fig_design(d, adam)
  expect_true(all(c("group", "legend", "x_max", "colour") %in% p$arg))
  ok <- tfl_fig_design("km", args = list(param = unique(adam$ADTTE$PARAMCD)[1],
                                         group = "TRT01P"))
  expect_equal(nrow(tfl_check_fig_design(ok, adam)), 0L)
})

test_that("group and pop come from ADSL for the types that join it", {
  s <- tfl_fig_schema()
  expect_equal(s$of[s$type == "mean" & s$arg == "group"], "ADSL")
  expect_equal(s$of[s$type == "km" & s$arg == "group"], "data")
})
