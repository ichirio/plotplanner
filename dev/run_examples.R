# Generate code for the example spec (several legend variants), run it, save PNGs.
library(plotplanner)
for (pk in c("dplyr", "ggplot2", "ggsurvfit", "patchwork", "survival")) suppressWarnings(suppressMessages(library(pk, character.only = TRUE)))
adam <- pp_example_adam()
for (nm in names(adam)) assign(tolower(nm), adam[[nm]])
out <- "C:/Yrepo/plotplanner/dev/out"
spec <- pp_example_spec()
spec$options <- rbind(spec$options, data.frame(plot_id = NA, key = "fig_path",
  value = sprintf('file.path("%s", "{plot_id}.png")', out)))

variants <- list(
  list(suffix = "", mod = function(s) s),
  list(suffix = "_manual_inside", mod = function(s) { s$plots$legend_type <- "manual"; s$plots$legend_pos <- "inside_tr"; s }),
  list(suffix = "_mapped_bottom", mod = function(s) { s$plots$legend_type <- "mapped"; s$plots$legend_pos <- "bottom"; s }),
  list(suffix = "_noadam", mod = function(s) s, noadam = TRUE)
)
ok <- TRUE
for (v in variants) {
  s <- v$mod(spec)
  s$plots$plot_id <- paste0(s$plots$plot_id, v$suffix)
  for (tab in c("roles", "filters", "options", "levels", "legend")) {
    has <- !is.na(s[[tab]]$plot_id); s[[tab]]$plot_id[has] <- paste0(s[[tab]]$plot_id[has], v$suffix)
  }
  code <- plot_code(s, adam = if (isTRUE(v$noadam)) NULL else adam)
  for (id in names(code)) {
    writeLines(code[[id]], file.path(out, paste0(id, ".R")))
    res <- tryCatch({ eval(parse(text = code[[id]]), envir = new.env(parent = globalenv())); "OK" },
                    error = function(e) paste("ERROR:", conditionMessage(e)),
                    warning = function(w) paste("WARNING:", conditionMessage(w)))
    cat(sprintf("%-28s %s\n", id, res))
    if (res != "OK") ok <- FALSE
  }
}
cat(if (ok) "ALL OK\n" else "FAILURES\n")
