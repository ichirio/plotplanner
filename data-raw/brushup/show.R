t <- readRDS("data-raw/brushup/ard_coverage.rds")
cat(nrow(t), "cases;", sum(t$same %in% TRUE), "same\n")
print(t[!(t$same %in% TRUE) | grepl("pairwise|car_anova", t$id), c("id", "status", "same", "n", "error")], right = FALSE)
