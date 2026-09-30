# POC: a figure design back from ggplot2 code / a ggplot object, and the round
# trip design -> tfl_fig_design_code() -> figure, compared with the original
# through ggplot_build().  Run from the package root:
#   Rscript data-raw/fig-from-ggplot-poc/poc.R

suppressPackageStartupMessages({
  pkgload::load_all(".", quiet = TRUE)
  library(ggplot2)
  library(dplyr)
})
pdf(NULL)

# ---- subjects written as code ----------------------------------------------
simple <- list(
  scatter = '
p <- ggplot(mpg, aes(displ, hwy, colour = class)) +
  geom_point(size = 2, alpha = 0.5) +
  geom_smooth(method = "lm", se = FALSE, colour = "black", formula = y ~ x) +
  scale_x_continuous(breaks = 1:7, labels = scales::label_number(accuracy = 0.1)) +
  facet_wrap(vars(drv), ncol = 2) +
  coord_cartesian(ylim = c(10, 45)) +
  labs(title = "Mileage", x = "Displacement") +
  theme_bw(base_size = 9) +
  theme(legend.position = "bottom", axis.text = element_text(size = 8))',
  bar = '
p <- ggplot(mpg, aes(class, fill = drv)) +
  geom_bar(position = position_dodge(preserve = "single")) +
  scale_fill_brewer(palette = "Set2") +
  coord_flip()',
  box_jitter = '
p <- ggplot(mpg, aes(drv, hwy)) +
  geom_boxplot(outlier.shape = NA) +
  geom_jitter(position = position_jitter(width = 0.2, height = 0, seed = 1))',
  prep_line = '
df <- mpg %>% group_by(year, class) %>% summarise(hwy = mean(hwy), .groups = "drop")
p <- ggplot(df, aes(year, hwy, colour = class, group = class)) +
  geom_line() +
  geom_point() +
  scale_colour_viridis_d() +
  theme_minimal()',
  grid_summary = '
p <- ggplot(mpg, aes(cyl, hwy)) +
  stat_summary(fun = mean, geom = "point") +
  facet_grid(rows = vars(drv), cols = vars(year))',
  wrapper = '
my_points <- function(...) geom_point(colour = "red", ...)
p <- ggplot(mpg, aes(displ, hwy)) + my_points(size = 3)',
  variable = '
bw <- 0.5
p <- ggplot(mpg, aes(hwy)) + geom_histogram(binwidth = bw)',
  patchwork = '
a <- ggplot(mpg, aes(displ, hwy)) + geom_point()
b <- ggplot(mpg, aes(class)) + geom_bar()
p <- a | b'
)

run_code <- function(code, env) {
  e <- new.env(parent = env)
  dir.create(wd <- tempfile("orig"))
  owd <- setwd(wd); on.exit(setwd(owd), add = TRUE)
  suppressMessages(suppressWarnings(eval(parse(text = code), e)))
  e
}

check <- function(label, original, env, code = NULL, data_name = "mpg") {
  out <- list()
  for (route in c("code", "object")) {
    if (route == "code" && is.null(code)) next
    d <- tryCatch(
      if (route == "code") tfl_as_fig_design(code)
      else tfl_as_fig_design(original, data_name = data_name),
      error = function(e) e)
    if (inherits(d, "error")) {
      out[[route]] <- data.frame(subject = label, route = route, layers = NA,
                                 labels = NA, theme = NA, pieces = NA,
                                 not_converted = paste("ERROR:", conditionMessage(d)))
      next
    }
    rt <- tryCatch(tfl_fig_roundtrip(original, d, env = env), error = function(e) e)
    nc <- attr(d, "not_converted")
    pieces <- paste0(length(d$layers), " layers, ", length(d$plot$add), " plot.add",
                     if (length(d$plots)) paste0(", ", length(d$plots), " plots") else "")
    out[[route]] <- data.frame(
      subject = label, route = route,
      layers = if (inherits(rt, "error")) NA else rt$layers,
      labels = if (inherits(rt, "error")) NA else rt$labels,
      theme  = if (inherits(rt, "error")) NA else rt$theme,
      pieces = pieces,
      not_converted = paste(c(if (inherits(rt, "error")) paste("RUN ERROR:", conditionMessage(rt)), nc),
                            collapse = " / "))
    if (identical(label, "scatter") && route == "code") {
      cat("\n---- scatter, from code: the design ----\n")
      tfl_write_fig_design(d, f <- tempfile(fileext = ".yml"))
      cat(readLines(f), sep = "\n")
    }
  }
  do.call(rbind, out)
}

res <- list()
base_env <- new.env()
base_env$mpg <- ggplot2::mpg
for (nm in names(simple)) {
  e <- run_code(simple[[nm]], base_env)
  res[[nm]] <- check(nm, e$p, e, simple[[nm]],
                     data_name = if (nm == "prep_line") "df" else "mpg")
}

# ---- tflspec's own templates: design -> code -> figure, then back ------------
adam <- tfl_example_adam()
prm <- unique(adam$ADTTE$PARAMCD)[1]
adam_env <- new.env()
for (n in names(adam)) assign(tolower(n), adam[[n]], envir = adam_env)
for (t in c("mean_se", "box_by_group", "scatter_xy", "pk_mean_log",
            "waterfall_response", "swimmer_bar", "km_simple", "km_risk_table",
            "forest_hr")) {
  kind <- tfl_fig_templates()$kind[tfl_fig_templates()$template == t]
  args <- switch(kind, km = list(param = prm, group = "TRT01P"),
                 forest = list(param = prm), list())
  d0 <- do.call(tfl_fig_template, c(list(t), args))
  code <- tfl_fig_design_code(d0, t)
  e <- tryCatch(run_code(code, adam_env), error = function(err) err)
  if (inherits(e, "error")) {
    res[[t]] <- data.frame(subject = paste0("template ", t), route = "-", layers = NA,
                           labels = NA, theme = NA, pieces = NA,
                           not_converted = paste("original does not run:", conditionMessage(e)))
    next
  }
  # the object route needs the data the layers name: the original's env
  r <- check(paste0("template ", t), e$fig, e, paste(code, collapse = "\n"),
             data_name = "df")
  res[[t]] <- r
}

tab <- do.call(rbind, res)
rownames(tab) <- NULL
cat("\n==== round trip ====\n")
print(tab[, c("subject", "route", "layers", "labels", "theme", "pieces")], right = FALSE)
cat("\n==== not converted (listed, not dropped) ====\n")
for (i in seq_len(nrow(tab))) {
  if (nzchar(tab$not_converted[i])) {
    cat(sprintf("- %s [%s]: %s\n", tab$subject[i], tab$route[i], tab$not_converted[i]))
  }
}
saveRDS(tab, file.path(tempdir(), "poc-tab.rds"))
