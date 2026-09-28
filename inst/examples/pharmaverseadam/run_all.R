# pharmaverseadam example: Excel plot list -> programs -> figures ------------
#
#   1. data preparation (what tflspec does not derive)   prepare_adam.R
#   2. one program per row of plot_list.xlsx              programs/F-xx.R
#   3. run the programs                                   output/F-xx.png

source("prepare_adam.R")        # creates the list `adam`
library(tflspec)

# how the programs read the data, and where they save the figures
options(
  tflspec.data_expr = "adam${DS}",
  tflspec.fig_path  = 'file.path("output", "{plot_id}.png")'
)

# 2. generate: one .R file per row (group values and colours come from `adam`)
code <- plot_list_code("plot_list.xlsx", adam = adam, dir = "programs")

# 3. run every program
for (f in list.files("programs", pattern = "[.]R$", full.names = TRUE)) {
  message("running ", f)
  source(f, local = new.env())
}
