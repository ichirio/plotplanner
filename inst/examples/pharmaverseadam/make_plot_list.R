# Builds plot_list.xlsx (run once; the xlsx is what users edit)
source("prepare_adam.R")
library(tflspec)

wk <- 'AVISIT == "Baseline" | (grepl("^Week", AVISIT) & ANL01FL == "Y")'
wk_post <- 'grepl("^Week", AVISIT) & ANL01FL == "Y"'
q <- function(x) paste0("'", x, "'")

rows <- tibble::tribble(
  ~plot_id, ~type,        ~style,       ~title,                                        ~param,  ~group,   ~pop,    ~legend,  ~args,
  "F-01",   "km",         "risk_table", "Progression-free survival",                   "PFS",   "TRT01P", "SAFFL", NA,       "x_by = 3",
  "F-02",   "km",         "single_arm", "Overall survival (all subjects)",             "OS",    NA,       "SAFFL", NA,       "x_by = 3",
  "F-03",   "waterfall",  "response",   "Best percent change in tumour size",          "BPCHG", NA,       "SAFFL", NA,       'y_label = "Best change from baseline in sum of diameters (%)"',
  "F-04",   "swimmer",    "full",       "Treatment duration and tumour response",      NA,      NA,       "RSFL",  NA,       'events = c(Death = "DTHADY"), ongoing = NULL, x_by = 1',
  "F-05",   "forest",     "hr",         "PFS: hazard ratio by subgroup",               "PFS",    "TRT01P", "SAFFL", NA,       paste0("where = ", q('TRT01P %in% c("Placebo", "Xanomeline High Dose")')),
  "F-06",   "bar",        "stacked",    "ALT normal range category at Week 24",        "ALT",   "TRT01A", "SAFFL", "right",  paste0('data = "ADLB", category = "ANRIND", palette = "okabe_ito", where = ', q('AVISIT == "Week 24" & ANL01FL == "Y"')),
  "F-07",   "mean",       "se_n",       "ALT over time",                               "ALT",   "TRT01A", "SAFFL", "bottom", paste0("where = ", q(wk)),
  "F-08",   "mean",       "se",         "Change from baseline in ALT",                 "ALT",   "TRT01A", "SAFFL", "bottom", paste0('value = "CHG", where = ', q(wk_post)),
  "F-09",   "individual", "spaghetti",  "ALT by subject",                              "ALT",   "TRT01A", "SAFFL", "right",  paste0("where = ", q(wk)),
  "F-10",   "individual", "spider",     "Tumour size over time",                       "SDIAM", NA,       "SAFFL", "right",  NA,
  "F-11",   "box",        "by_visit",   "ALT by visit",                                "ALT",   "TRT01A", "SAFFL", "bottom", paste0("where = ", q(wk)),
  "F-12",   "box",        "change",     "Change from baseline in ALT by visit",        "ALT",   "TRT01A", "SAFFL", "bottom", paste0("where = ", q(wk_post)),
  "F-13",   "ae_dot",     "risk_diff",  "Most frequent treatment-emergent AEs",        NA,      "TRT01A", "SAFFL", "bottom", "top = 15, min_pct = 5",
  "F-14",   "butterfly",  "soc",        "Treatment-emergent AEs by SOC",               NA,      "TRT01A", "SAFFL", "bottom", "top = 15",
  "F-15",   "edish",      "alt_ast",    "eDISH",                                       NA,      "TRT01A", "SAFFL", "inside", paste0("post_baseline = ", q('grepl("^Week", AVISIT)'), ', palette = "treatment"'),
  "F-16",   "scatter",    "shift",      "ALT: baseline vs Week 24",                    "ALT",   "TRT01A", "SAFFL", NA,       paste0('at_visit = "Week 24", where = ', q('ANL01FL == "Y"')),
  "F-17",   "pk",         "mean_log",   "Xanomeline plasma concentration, Day 1",      "XAN",   "TRT01A", "SAFFL", NA,       paste0("where = ", q('PARCAT1 == "PLASMA" & ATPTREF == "Day 1"')),
  "F-18",   "pk",         "individual", "Xanomeline plasma concentration by subject",  "XAN",   "TRT01A", "SAFFL", NA,       paste0("where = ", q('PARCAT1 == "PLASMA" & ATPTREF == "Day 1"')),
  "F-19",   "bar",        "dodged",     "ALT normal range category at Week 24",        "ALT",   "TRT01A", "SAFFL", "bottom", paste0('data = "ADLB", category = "ANRIND", where = ', q('AVISIT == "Week 24" & ANL01FL == "Y"'))
)

tfl_fig_list_template("plot_list.xlsx", adam, rows = as.data.frame(rows))
