lot <- data.frame(
  USUBJID = c("1", "1", "2", "3", "3", "3", "4"),
  LINE    = c(1, 2, 1, 1, 2, 3, 1),
  TRT     = c("Chemo", "IO", "Chemo", "IO", "Chemo", "Targeted", "IO"),
  AGE     = c("young", "young", "old", "old", "old", "old", "young")
)

test_that("sankey_data counts subjects per node and transitions per link", {
  sk <- sankey_data(lot)
  expect_equal(sk$nodes$label, c("L1: Chemo", "L1: IO", "L2: Chemo", "L2: IO", "L3: Targeted"))
  expect_equal(sk$nodes$n, c(2, 2, 1, 1, 1))  # L2: Chemo (subject 3), IO (subject 1)
  expect_equal(sk$links$source, c("S1_Chemo", "S1_IO", "S2_Chemo"))
  expect_equal(sk$links$target, c("S2_IO", "S2_Chemo", "S3_Targeted"))
  expect_equal(sk$links$value, c(1, 1, 1))
  expect_s3_class(plot_sankey(sk$nodes, sk$links, node_label = "label", node_value = "n",
                              node_treatment = "category"), "ggplot")
})

test_that("sankey_data builds subgroups and respects category levels", {
  sk <- sankey_data(lot, by = "AGE", levels = c("IO", "Chemo", "Targeted"))
  expect_setequal(unique(sk$nodes$grp), c("ALL", "young", "old"))
  expect_equal(sk$nodes$label[sk$nodes$grp == "ALL"][1:2], c("L1: IO", "L1: Chemo"))
  expect_equal(sum(sk$nodes$n[sk$nodes$grp == "young" & sk$nodes$stage == "L1"]), 2)
})

test_that("sunburst_data gives one row per sequence", {
  p <- sunburst_data(lot)
  expect_equal(names(p), c("L1", "L2", "L3", "n"))
  expect_equal(nrow(p), 4)
  expect_equal(p$n[is.na(p$L2) & p$L1 == "IO"], 1)
  expect_equal(sum(p$n), 4)
  expect_s3_class(plot_sunburst(p), "ggplot")
})

test_that("more than one row per subject and line is an error", {
  expect_error(sankey_data(rbind(lot, lot[1, ])), "More than one row")
})

test_that("pp_sankey / pp_sunburst generate runnable code for every style", {
  skip_if_not_installed("patchwork")
  adam <- pp_example_adam()
  for (use_adam in list(adam, NULL)) {
    for (st in c("grey_links", "colored_links", "subgroups")) {
      code <- pp_sankey(use_adam, style = st, by = if (st == "subgroups") "AGEGR1")
      expect_match(code, "library(tflspec)", fixed = TRUE)
      expect_no_error(run_code(code))
    }
    expect_no_error(run_code(pp_sunburst(use_adam)))
  }
  expect_error(pp_sankey(style = "subgroups"), "needs `by`")
  expect_error(pp_sankey(adam, category = "NOPE"), "no column")
})
