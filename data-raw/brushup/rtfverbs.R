ex <- sort(getNamespaceExports("rtfreporter"))
cat(length(ex), "exports\n")
v <- grep("^(plan_|table_plan|set_|style_|rtf_|add_|figure|listing|normalize)", ex, value = TRUE)
cat(paste(v, collapse = " "), "\n")
