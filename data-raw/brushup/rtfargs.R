ns <- asNamespace("rtfreporter")
for (f in sort(grep("^(plan_|table_plan|style_|set_)", getNamespaceExports("rtfreporter"), value = TRUE))) {
  cat(f, "(", paste(names(formals(get(f, ns))), collapse = ", "), ")\n")
}
