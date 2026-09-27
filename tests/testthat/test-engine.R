with_variant <- function(spec, type, pos) {
  spec$plots$legend_type <- type
  spec$plots$legend_pos <- pos
  spec
}

test_that("example spec generates runnable code for every legend variant", {
  skip_if_not_installed("ggsurvfit")
  skip_if_not_installed("patchwork")
  adam <- pp_example_adam()
  variants <- list(c("mapped", "right"), c("mapped", "inside_tr"), c("mapped", "bottom"),
                   c("manual", "below"), c("manual", "inside_br"), c("manual", "right"),
                   c("none", "right"))
  for (v in variants) {
    spec <- with_variant(pp_example_spec(), v[1], v[2])
    for (use_adam in list(adam, NULL)) {
      code <- plot_code(spec, adam = use_adam)
      for (id in names(code)) {
        expect_no_error(run_code(code[[id]]), message = paste(id, v, collapse = " "))
      }
    }
  }
})

test_that("generated code does not depend on tflspec", {
  code <- plot_code(pp_example_spec(), adam = pp_example_adam())
  expect_false(any(grepl("tflspec::", code)))
  expect_true(all(grepl("ggsave(", code, fixed = TRUE)))
})

test_that("codelist values from ADaM become literal palettes", {
  code <- plot_code(pp_example_spec(), "F-KM-1", adam = pp_example_adam())
  expect_match(code, 'pal_strata <- c("Drug A" = "blue", "Drug B" = "#D55E00")', fixed = TRUE)
  expect_match(code, 'PARAMCD == "OS"', fixed = TRUE)
  # without data, an unnamed palette is resolved at run time
  code2 <- plot_code(pp_example_spec(), "F-KM-1")
  expect_match(code2, "unique(na.omit(as.character(km_df$TRT01P)))", fixed = TRUE)
})

test_that("levels sheet sets order, labels and colours", {
  spec <- pp_example_spec()
  spec$levels <- data.frame(plot_id = "F-WF-1", variable = "BOR", value = c("PD", "PR"),
                            label = c("Progressive", NA), order = c(1, 2), colour = c("red", NA))
  spec <- plot_spec(spec$plots, spec$roles, spec$filters, spec$levels, spec$legend, spec$options)
  code <- plot_code(spec, "F-WF-1")
  expect_match(code, 'pal_fill <- c("PD" = "red", "PR" = "#0000FF")', fixed = TRUE)
  expect_match(code, 'pal_fill_lab <- c("PD" = "Progressive", "PR" = "PR")', fixed = TRUE)
})

test_that("legend sheet gives a data-independent legend", {
  spec <- pp_example_spec()
  lg <- data.frame(plot_id = "F-SW-1", order = 1:3,
                   label = c("Complete response", "Ongoing", "Death"),
                   glyph = c("rect", "line", "point"),
                   shape = c(NA, NA, "triangle_down"),
                   colour = c(NA, "black", "black"), fill = c("#99CC99", NA, NA), linetype = NA)
  spec <- plot_spec(spec$plots, spec$roles, spec$filters, spec$levels, lg, spec$options)
  code <- plot_code(spec, "F-SW-1")
  expect_match(code, "manual (legend sheet)", fixed = TRUE)
  expect_match(code, '"Complete response", "rect", NA, NA, "#99CC99", NA', fixed = TRUE)
  expect_match(code, '"Death", "point", 25, "black", "black", NA', fixed = TRUE)
  skip_if_not_installed("patchwork")
  expect_no_error(run_code(code))
})

test_that("check_plot_spec reports problems", {
  adam <- pp_example_adam()
  bad <- pp_example_spec()
  bad$filters$value[1] <- "OSX"
  bad$roles <- bad$roles[!(bad$roles$plot_id == "F-WF-1" & bad$roles$role == "value"), ]
  bad$plots$legend_pos[1] <- "somewhere"
  out <- suppressMessages(check_plot_spec(bad, adam))
  expect_true(any(grepl("OSX", out$message)))
  expect_true(any(grepl("required role 'value'", out$message)))
  expect_true(any(grepl("legend_pos", out$message)))
  expect_equal(nrow(suppressMessages(check_plot_spec(pp_example_spec(), adam))), 0)
})

test_that("spec template round-trips", {
  adam <- pp_example_adam()
  path <- tempfile(fileext = ".xlsx")
  write_plot_spec_template(adam, path, spec = pp_example_spec())
  expect_true(all(c("plots", "roles", "filters", "levels", "legend", "options",
                    "adam_vars", "adam_values") %in% openxlsx::getSheetNames(path)))
  spec2 <- read_plot_spec(path)
  expect_identical(plot_code(spec2, adam = adam), plot_code(pp_example_spec(), adam = adam))
})

test_that("unknown layer is an error", {
  spec <- pp_example_spec()
  spec$plots$layers[1] <- "censor_mark, sparkles"
  expect_error(plot_code(spec, "F-KM-1"), "unknown layer")
})
