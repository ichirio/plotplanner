library(tflspec)
for (pk in c("dplyr", "ggplot2", "patchwork")) suppressWarnings(suppressMessages(library(pk, character.only = TRUE)))
adam <- pp_example_adam()
adlot <- adam$ADLOT
out <- normalizePath("dev/out/seq", "/")
options(tflspec.fig_path = sprintf('file.path("%s", "{plot_id}.png")', out))
calls <- list(
  sk_grey    = quote(pp_sankey(adam, plot_id = "sk_grey")),
  sk_color   = quote(pp_sankey(adam, style = "colored_links", title = "Treatment sequences", plot_id = "sk_color")),
  sk_sub     = quote(pp_sankey(adam, style = "subgroups", by = "AGEGR1", plot_id = "sk_sub")),
  sb_rings   = quote(pp_sunburst(adam, plot_id = "sb_rings")),
  sk_noadam  = quote(pp_sankey(plot_id = "sk_noadam")),
  sb_noadam  = quote(pp_sunburst(legend = "bottom", plot_id = "sb_noadam"))
)
ok <- TRUE
for (nm in names(calls)) {
  res <- tryCatch({
    code <- eval(calls[[nm]]); writeLines(code, file.path(out, paste0(nm, ".R")))
    eval(parse(text = code), envir = new.env(parent = globalenv())); "OK"
  }, error = function(e) paste("ERROR:", conditionMessage(e)), warning = function(w) paste("WARNING:", conditionMessage(w)))
  cat(sprintf("%-10s %s\n", nm, res)); if (res != "OK") ok <- FALSE
}
cat(if (ok) "ALL OK\n" else "FAILURES\n")
