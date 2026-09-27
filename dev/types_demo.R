library(tflspec)
for (pk in c("dplyr", "ggplot2", "patchwork", "survival", "ggsurvfit")) suppressWarnings(suppressMessages(library(pk, character.only = TRUE)))
adam <- pp_example_adam()
out <- normalizePath("dev/out/types", "/")
options(tflspec.fig_path = sprintf('file.path("%s", "{plot_id}.png")', out))
env0 <- new.env()
for (nm in names(adam)) assign(tolower(nm), adam[[nm]], envir = env0)
est_df <- data.frame(label = c("Overall", "Male", "Female"), est = c(0.8, 0.7, 0.9), lcl = c(0.6, 0.5, 0.6), ucl = c(1.1, 1.0, 1.3), n = c(38, 20, 18))
assign("est_df", est_df, envir = env0)
cat_ <- pp_catalog("implemented")
cat_ <- cat_[!cat_$type %in% c("km", "waterfall", "sankey", "sunburst") | FALSE, ]
ok <- TRUE
for (i in seq_len(nrow(cat_))) for (with in c(TRUE, FALSE)) {
  f <- get(cat_$fun[i]); st <- cat_$style[i]
  id <- paste0(cat_$type[i], "_", st, if (!with) "_noadam")
  args <- list(adam = if (with) adam, style = st, plot_id = id)
  if (cat_$type[i] == "sankey" && st == "subgroups") args$by <- "AGEGR1"
  if (cat_$type[i] == "swimmer") args <- c(args, list(x_max = 24, x_by = 3))
  res <- tryCatch({
    code <- do.call(f, args); writeLines(code, file.path(out, paste0(id, ".R")))
    eval(parse(text = code), envir = new.env(parent = env0)); "OK"
  }, error = function(e) paste("ERROR:", conditionMessage(e)), warning = function(w) paste("WARNING:", conditionMessage(w)))
  if (res != "OK" || with) cat(sprintf("%-28s %s\n", id, res))
  if (res != "OK") ok <- FALSE
}
# swimmer subtype: from start
code <- pp_swimmer(adam, start = "TRTSDY", end = "TRTEDY", x_max = 24, x_by = 3, plot_id = "swimmer_from_start")
res <- tryCatch({eval(parse(text = code), envir = new.env(parent = env0)); "OK"}, error = function(e) conditionMessage(e), warning = function(w) paste("WARNING:", conditionMessage(w)))
cat("swimmer_from_start", res, "\n")
cat(if (ok) "ALL OK\n" else "FAILURES\n")
