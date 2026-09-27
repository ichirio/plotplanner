library(tflspec)
adam <- pp_example_adam()
path <- "C:/Yrepo/tflspec/inst/examples/plot_spec_example.xlsx"
write_plot_spec_template(adam, path, spec = pp_example_spec())
spec2 <- read_plot_spec(path)
print(spec2)
check_plot_spec(spec2, adam)
stopifnot(identical(plot_code(spec2, adam = adam), plot_code(pp_example_spec(), adam = adam)))
cat("roundtrip identical\n")
bad <- pp_example_spec(); bad$filters$value[1] <- "OSX"; bad$roles$variable[1] <- "AVALX"
check_plot_spec(bad, adam)
