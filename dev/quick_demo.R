library(plotplanner)
for (pk in c("dplyr", "ggplot2", "ggsurvfit", "patchwork", "survival")) suppressWarnings(suppressMessages(library(pk, character.only = TRUE)))
adam <- pp_example_adam()
for (nm in names(adam)) assign(tolower(nm), adam[[nm]])
out <- "C:/Yrepo/plotplanner/dev/out/quick"
options(plotplanner.fig_path = sprintf('file.path("%s", "{plot_id}.png")', out))
calls <- list(
  km_risk      = quote(pp_km(adam, param = "OS", x_max = 24, x_by = 3, plot_id = "km_risk")),
  km_simple    = quote(pp_km(adam, param = "PFS", style = "simple", legend = "bottom", plot_id = "km_simple")),
  km_ci        = quote(pp_km(adam, style = "ci", legend = "panel_inside", plot_id = "km_ci")),
  km_single    = quote(pp_km(adam, param = "DOR", style = "single_arm", x_max = 12, x_by = 1, plot_id = "km_single")),
  wf_resp      = quote(pp_waterfall(adam, plot_id = "wf_resp")),
  wf_plain     = quote(pp_waterfall(adam, style = "plain", plot_id = "wf_plain")),
  sw_full      = quote(pp_swimmer(adam, events = c(Death = "DTHADY", "Subsequent therapy" = "NACTDY", Discontinued = "EOSDY"), x_max = 24, x_by = 3, visit_every = 3, plot_id = "sw_full")),
  sw_assess    = quote(pp_swimmer(adam, style = "assessment", legend = "bottom", plot_id = "sw_assess")),
  sw_resp      = quote(pp_swimmer(adam, style = "response", legend = "inside_bl", plot_id = "sw_resp")),
  sw_bar       = quote(pp_swimmer(adam, style = "bar", plot_id = "sw_bar")),
  km_noadam    = quote(pp_km(plot_id = "km_noadam")),
  sw_noadam    = quote(pp_swimmer(plot_id = "sw_noadam"))
)
ok <- TRUE
for (nm in names(calls)) {
  res <- tryCatch({
    code <- eval(calls[[nm]])
    writeLines(code, file.path(out, paste0(nm, ".R")))
    eval(parse(text = code), envir = new.env(parent = globalenv())); "OK"
  }, error = function(e) paste("ERROR:", conditionMessage(e)), warning = function(w) paste("WARNING:", conditionMessage(w)))
  cat(sprintf("%-11s %-6s  %s\n", nm, res, deparse1(calls[[nm]])))
  if (res != "OK") ok <- FALSE
}
# Excel plot list
tpl <- file.path(out, "plot_list.xlsx")
write_plot_list_template(tpl, adam)
code <- plot_list_code(tpl, adam)
for (id in names(code)) { eval(parse(text = code[[id]]), envir = new.env(parent = globalenv())); cat("list:", id, "OK\n") }
cat(if (ok) "ALL OK\n" else "FAILURES\n")
