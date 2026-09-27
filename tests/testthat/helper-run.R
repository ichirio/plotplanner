run_code <- function(code) {
  for (pk in c("dplyr", "ggplot2", "ggsurvfit", "patchwork", "survival")) {
    suppressWarnings(suppressMessages(library(pk, character.only = TRUE)))
  }
  env <- new.env(parent = globalenv())
  adam <- pp_example_adam()
  for (nm in names(adam)) assign(tolower(nm), adam[[nm]], envir = env)
  code <- sub('fig_path   <- [^\n]*', sprintf('fig_path   <- "%s"', normalizePath(tempfile(fileext = ".png"), "/", mustWork = FALSE)), code)
  eval(parse(text = code), envir = env)
  env
}

