ns <- asNamespace("rtfreporter")
for (f in c("listing_col","listing_spec","listing_take","listing_wrap","listing_split_after","listing_disp_width","plan_listing","listing_code","rtf_page","rtf_document","rtf_titles","rtf_footnotes","rtf_header","rtf_footer","rtf_section","rtf_figures","rtf_watermark","rtf_replace_text","rtf_config"))
  cat(f, "(", paste(names(formals(get(f, ns))), collapse = ", "), ")\n")
