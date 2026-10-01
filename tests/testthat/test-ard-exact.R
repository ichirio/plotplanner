# What an ARD spec row makes is what the same analysis written by hand
# with cards / cardx makes: every number, under the same groups, variable,
# level and statistic.  The cases (fixtures/ard-cases.R) cover the method
# keywords and cards / cardx functions written as pkg::function --
# hierarchies, survival, models, confidence intervals, tests, strata,
# denominators, subsets.

test_that("each ARD spec row makes what the hand-written call makes", {
  skip_on_cran()
  skip_if_not_installed("cards")
  skip_if_not_installed("cardx")
  skip_if_not_installed("dplyr")
  cases <- source(test_path("fixtures", "ard-cases.R"), local = TRUE)$value
  adam <- exact_data()
  dir <- exact_dir(adam)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  for (cs in cases) {
    needs <- exact_needs(cs)
    if (!all(vapply(needs, requireNamespace, NA, quietly = TRUE))) next
    res <- exact_run(cs, adam, dir)
    expect_true(isTRUE(res$same), label = paste(cs$id, res$error))
  }
})

test_that("a method that gives several ARDs keeps which is which", {
  skip_if_not_installed("cards")
  skip_if_not_installed("cardx")
  skip_if_not_installed("dplyr")
  sp <- exact_spec(list(method = "cards::ard_pairwise", population_id = "SAF",
                        args = paste("variable = TRT01A, .f = function(df)",
                                     "cardx::ard_stats_t_test(df, by = TRT01A, variables = AGE)")))
  code <- paste(tfl_ard_code(sp, save = FALSE), collapse = "\n")
  expect_match(code, "bind_rows(ard, .id = \"pairwise\")", fixed = TRUE)
  adam <- exact_data()
  dir <- exact_dir(adam)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  ard <- suppressMessages(suppressWarnings(tfl_build_ard(sp, dir = dir,
                                                         save = FALSE)))
  expect_length(unique(ard$pairwise), 3L)
})

test_that("a fitted model given as the first argument takes no data", {
  skip_if_not_installed("cardx")
  skip_if_not_installed("car")
  sp <- exact_spec(list(method = "cardx::ard_car_anova", population_id = "SAF",
                        args = "x = lm(AGE ~ TRT01A, data = data)"))
  code <- paste(tfl_ard_code(sp, save = FALSE), collapse = "\n")
  expect_match(code, "cardx::ard_car_anova(x = lm(AGE ~ TRT01A, data = data))",
               fixed = TRUE)
  # a function with a `data` argument still takes the data first
  sp <- exact_spec(list(method = "cardx::ard_stats_aov", population_id = "SAF",
                        args = "formula = AGE ~ TRT01A"))
  code <- paste(tfl_ard_code(sp, save = FALSE), collapse = "\n")
  expect_match(code, "cardx::ard_stats_aov(data,", fixed = TRUE)
})
