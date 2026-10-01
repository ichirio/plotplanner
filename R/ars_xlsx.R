# ============================================================================
#  CDISC ARS: the reporting event as CDISC's Excel template
# ============================================================================
#
#  CDISC's ARS repository has an Excel template (utilities/python, "ARS
#  Template.xlsx") and a converter from it to the JSON (excel2ars.py).
#  tfl_write_ars_xlsx() writes the reporting event as that template: its 25
#  sheets in their order, each with the template's columns.  It is the form
#  for people to read; the JSON stays the one to exchange.
#
#  The template's ways: one row per list item, group, operation, display
#  sub-section; a WhereClause as rows of `level` / `order` (a compound row
#  with its logicalOperator, its clauses one level below); several values
#  of a condition joined by " | ".
# ============================================================================

.ars_xlsx_sheets <- list(
  ReportingEvent = c("id", "version", "name", "description", "label"),
  ReferenceDocuments = c("id", "name", "description", "label", "location"),
  Categorizations = c("id", "label", "parent_category_id", "category_id",
                      "category_label"),
  MainListOfContents = c("name", "description", "label", "listItem_level",
                         "listItem_name", "listItem_description",
                         "listItem_label", "listItem_order",
                         "listItem_analysisId", "listItem_outputId"),
  OtherListsOfContents = c("name", "description", "label", "listItem_level",
                           "listItem_name", "listItem_description",
                           "listItem_label", "listItem_order",
                           "listItem_analysisId", "listItem_outputId"),
  GlobalDisplaySections = c("sectionType", "subSection_id",
                            "subSection_text"),
  Outputs = c("id", "version", "name", "description", "label", "categoryIds",
              "display1_id", "display2_id"),
  OutputFiles = c("output_id", "name", "description", "label", "location",
                  "fileType"),
  Displays = c("id", "name", "description", "label", "version",
               "displayTitle", "displaySection_sectionType",
               "displaySection_orderedSubSection_order",
               "displaySection_subSection_id",
               "displaySection_subSection_text"),
  OutputProgrammingCode = c("output_id", "context", "specifiedAs", "code"),
  OutputCodeParameters = c("output_id", "parameter_name",
                           "parameter_description", "parameter_label",
                           "parameter_value"),
  OutputDocumentRefs = c("output_id", "referenceType", "refDocumentId",
                         "pageRef_refType", "pageRef_label",
                         "pageRef_pages"),
  DataSubsets = c("id", "name", "description", "label", "level", "order",
                  "compoundExpression_logicalOperator",
                  "compoundExpression_subClauseId", "condition_dataset",
                  "condition_variable", "condition_comparator",
                  "condition_value"),
  AnalysisSets = c("id", "name", "description", "label", "level", "order",
                   "compoundExpression_logicalOperator",
                   "compoundExpression_subClauseId", "condition_dataset",
                   "condition_variable", "condition_comparator",
                   "condition_value"),
  AnalysisGroupings = c("id", "name", "description", "label",
                        "groupingDataset", "groupingVariable", "dataDriven",
                        "group_id", "group_name", "group_description",
                        "group_label", "group_level", "group_order",
                        "group_compoundExpression_logicalOperator",
                        "group_compoundExpression_subClauseId",
                        "group_condition_dataset", "group_condition_variable",
                        "group_condition_comparator",
                        "group_condition_value"),
  Analyses = c("id", "version", "name", "description", "label",
               "categoryIds", "reason", "purpose", "analysisSetId",
               "groupingId1", "resultsByGroup1", "groupingId2",
               "resultsByGroup2", "groupingId3", "resultsByGroup3",
               "dataSubsetId", "dataset", "variable", "method_id",
               "referencedAnalysisOperations_referencedOperationId1",
               "referencedAnalysisOperations_analysisId1",
               "referencedAnalysisOperations_referencedOperationId2",
               "referencedAnalysisOperations_analysisId2"),
  AnalysisProgrammingCode = c("analysis_id", "context", "specifiedAs",
                              "code"),
  AnalysisCodeParameters = c("analysis_id", "parameter_name",
                             "parameter_description", "parameter_label",
                             "parameter_value"),
  AnalysisDocumentRefs = c("analysis_id", "referenceType", "refDocumentId",
                           "pageRef_refType", "pageRef_label",
                           "pageRef_pages"),
  AnalysisMethods = c(
    "id", "name", "description", "label", "operation_id", "operation_name",
    "operation_description", "operation_label", "operation_order",
    "operation_resultPattern",
    paste0("operation_referencedResultRelationships1_",
           c("id", "referencedOperationRole", "operationId", "analysisId",
             "description")),
    paste0("operation_referencedResultRelationships2_",
           c("id", "referencedOperationRole", "operationId", "analysisId",
             "description"))),
  AnalysisMethodCodeTemplate = c("method_id", "context", "specifiedAs",
                                 "templateCode"),
  AnalysisMethodCodeParameters = c("method_id", "parameter_name",
                                   "parameter_description", "parameter_label",
                                   "parameter_valueSource", "parameter_value"),
  AnalysisMethodDocumentRefs = c("method_id", "referenceType",
                                 "refDocumentId", "pageRef_refType",
                                 "pageRef_label", "pageRef_pages"),
  AnalysisResults = c(
    "id", "analysisSet_label", "method_id", "method_label", "operation_id",
    "operation_label", "operation_resultPattern",
    paste0(rep(paste0("resultGroup", 1:3, "_"), each = 4),
           c("groupingId", "groupId", "group_label", "groupValue")),
    "rawValue", "formattedValue"),
  TerminologyExtensions = c("id", "enumeration", "sponsorTerm_id",
                            "sponsorTerm_submissionValue",
                            "sponsorTerm_description"))

# Rows (named lists) as a sheet with the given columns, in their order; a
# column a row names that the template does not have is added at the end.
.ars_rows_df <- function(rows, cols) {
  extra <- setdiff(unique(unlist(lapply(rows, names))), cols)
  cols <- c(cols, extra)
  if (!length(rows)) {
    return(as.data.frame(stats::setNames(replicate(length(cols), character(),
                                                   simplify = FALSE), cols),
                         stringsAsFactors = FALSE, check.names = FALSE))
  }
  out <- lapply(cols, function(cn) {
    v <- lapply(rows, function(r) r[[cn]])
    if (all(vapply(v, function(z) is.null(z) || is.logical(z), NA)) &&
        any(vapply(v, is.logical, NA))) {
      return(vapply(v, function(z) if (is.null(z)) NA else as.logical(z), NA))
    }
    if (all(vapply(v, function(z) is.null(z) || is.numeric(z), NA)) &&
        any(vapply(v, is.numeric, NA))) {
      return(vapply(v, function(z) if (is.null(z)) NA_real_ else
        as.numeric(z), 0))
    }
    vapply(v, function(z) if (is.null(z)) NA_character_ else
      paste(as.character(unlist(z)), collapse = " | "), "")
  })
  as.data.frame(stats::setNames(out, cols), stringsAsFactors = FALSE,
                check.names = FALSE)
}

# A term: a CDISC controlled term or a sponsor's id.
.ars_term <- function(x) {
  if (is.null(x)) return(NULL)
  x$controlledTerm %||% x$sponsorTermId
}

# A WhereClause (the condition / compoundExpression of a class) as the
# template's rows: level / order, a compound with its operator, its
# clauses one level below.
.ars_where_rows <- function(w, prefix = "", level = 1L, order = 1L) {
  f <- function(n) paste0(prefix, n)
  if (!is.null(w$condition)) {
    c <- w$condition
    r <- list(level, order, c$dataset, c$variable, c$comparator,
              as.character(unlist(c$value)))
    names(r) <- c(if (nzchar(prefix)) c(f("level"), f("order")) else
      c("level", "order"), f(c("condition_dataset", "condition_variable",
                               "condition_comparator", "condition_value")))
    return(list(r))
  }
  ce <- w$compoundExpression
  if (is.null(ce)) {
    r <- list(level, order)
    names(r) <- if (nzchar(prefix)) c(f("level"), f("order")) else
      c("level", "order")
    return(list(r))
  }
  r <- list(level, order, ce$logicalOperator)
  names(r) <- c(if (nzchar(prefix)) c(f("level"), f("order")) else
    c("level", "order"), f("compoundExpression_logicalOperator"))
  c(list(r), unlist(lapply(seq_along(ce$whereClauses), function(k)
    .ars_where_rows(ce$whereClauses[[k]], prefix, level + 1L,
                    ce$whereClauses[[k]]$order %||% k)), recursive = FALSE))
}

# An object's document references as the template's rows: one per page
# reference (or one without), its programming code's document as a
# "ProgrammingCode" reference.
.ars_docref_rows <- function(x, idcol) {
  rows <- list()
  one <- function(d, type) {
    base <- stats::setNames(list(x$id, type, d$referenceDocumentId),
                            c(idcol, "referenceType", "refDocumentId"))
    if (!length(d$pageRefs)) {
      rows[[length(rows) + 1L]] <<- base
    }
    for (p in d$pageRefs) {
      pages <- if (!is.null(p$pageNumbers)) {
        paste(unlist(p$pageNumbers), collapse = "|")
      } else if (!is.null(p$firstPage)) {
        paste0(p$firstPage, "-", p$lastPage)
      } else if (!is.null(p$pageNames)) {
        paste(unlist(p$pageNames), collapse = "|")
      }
      rows[[length(rows) + 1L]] <<- c(base, list(
        pageRef_refType = p$refType, pageRef_label = p$label,
        pageRef_pages = pages))
    }
  }
  for (d in x$documentRefs) one(d, "Documentation")
  pc <- x$programmingCode %||% x$codeTemplate
  if (!is.null(pc$documentRef)) one(pc$documentRef, "ProgrammingCode")
  rows
}

# A programming code as the template's row: its code, or the document it
# is in.
.ars_code_row <- function(pc, idcol, id) {
  stats::setNames(list(id, pc$context,
                       if (is.null(pc$code) && !is.null(pc$documentRef))
                         "DocumentRef" else "Code", pc$code),
                  c(idcol, "context", "specifiedAs", "code"))
}

# The sheets of the template, filled from a reporting event.
.ars_xlsx_book <- function(re) {
  S <- .ars_xlsx_sheets
  sheets <- list()
  sheets$ReportingEvent <- .ars_rows_df(list(list(
    id = re$id, version = re$version, name = re$name,
    description = re$description, label = re$label)), S$ReportingEvent)
  sheets$ReferenceDocuments <- .ars_rows_df(lapply(
    re$referenceDocuments, function(d) d[intersect(names(d),
                                                   S$ReferenceDocuments)]),
    S$ReferenceDocuments)
  cat_rows <- list()
  cats <- function(cz, parent = NULL) {
    for (ct in cz$categories) {
      cat_rows[[length(cat_rows) + 1L]] <<- list(
        id = cz$id, label = cz$label, parent_category_id = parent,
        category_id = ct$id, category_label = ct$label)
    }
    for (ct in cz$categories) {
      for (sc in ct$subCategorizations) cats(sc, ct$id)
    }
  }
  for (cz in re$analysisOutputCategorizations) cats(cz)
  sheets$Categorizations <- .ars_rows_df(cat_rows, S$Categorizations)
  loc <- function(l) {
    rows <- list()
    walk <- function(items) {
      for (it in items) {
        rows[[length(rows) + 1L]] <<- list(
          name = l$name, description = l$description, label = l$label,
          listItem_level = it$level, listItem_name = it$name,
          listItem_description = it$description, listItem_label = it$label,
          listItem_order = it$order, listItem_analysisId = it$analysisId,
          listItem_outputId = it$outputId)
        walk(it$sublist$listItems)
      }
    }
    walk(l$contentsList$listItems)
    rows
  }
  sheets$MainListOfContents <- .ars_rows_df(loc(re$mainListOfContents),
                                            S$MainListOfContents)
  sheets$OtherListsOfContents <- .ars_rows_df(
    unlist(lapply(re$otherListsOfContents, loc), recursive = FALSE),
    S$OtherListsOfContents)
  g_rows <- list()
  for (gs in re$globalDisplaySections) {
    for (z in gs$subSections) {
      g_rows[[length(g_rows) + 1L]] <- list(sectionType = gs$sectionType,
                                            subSection_id = z$id,
                                            subSection_text = z$text)
    }
  }
  sheets$GlobalDisplaySections <- .ars_rows_df(g_rows,
                                               S$GlobalDisplaySections)

  o_rows <- list()
  f_rows <- list()
  d_rows <- list()
  pc_rows <- list()
  odr_rows <- list()
  for (o in re$outputs) {
    odr_rows <- c(odr_rows, .ars_docref_rows(o, "output_id"))
    r <- list(id = o$id, version = o$version, name = o$name,
              description = o$description, label = o$label,
              categoryIds = o$categoryIds)
    for (k in seq_along(o$displays)) {
      r[[paste0("display", k, "_id")]] <- o$displays[[k]]$display$id
    }
    o_rows[[length(o_rows) + 1L]] <- r
    for (f in o$fileSpecifications) {
      f_rows[[length(f_rows) + 1L]] <- list(
        output_id = o$id, name = f$name, description = f$description,
        label = f$label, location = f$location,
        fileType = .ars_term(f$fileType))
    }
    if (!is.null(o$programmingCode)) {
      pc_rows[[length(pc_rows) + 1L]] <- .ars_code_row(o$programmingCode,
                                                       "output_id", o$id)
    }
    for (dd in o$displays) {
      d <- dd$display
      base <- list(id = d$id, name = d$name, description = d$description,
                   label = d$label, version = d$version,
                   displayTitle = d$displayTitle)
      secs <- d$displaySections
      if (!length(secs)) {
        # the template has no row for a display without sections: its name
        # is written as its title
        secs <- list(list(sectionType = "Title", orderedSubSections = list(
          list(order = 1L, subSection = list(
            id = paste0(d$id, "_Title_1"),
            text = d$displayTitle %||% d$name)))))
      }
      for (s in secs) {
        for (z in s$orderedSubSections) {
          d_rows[[length(d_rows) + 1L]] <- c(base, list(
            displaySection_sectionType = s$sectionType,
            displaySection_orderedSubSection_order = z$order,
            displaySection_subSection_id = z[["subSection"]][["id"]] %||%
              z[["subSectionId"]],
            displaySection_subSection_text = z[["subSection"]][["text"]]))
        }
      }
    }
  }
  sheets$Outputs <- .ars_rows_df(o_rows, S$Outputs)
  sheets$OutputFiles <- .ars_rows_df(f_rows, S$OutputFiles)
  sheets$Displays <- .ars_rows_df(d_rows, S$Displays)
  sheets$OutputProgrammingCode <- .ars_rows_df(pc_rows,
                                               S$OutputProgrammingCode)
  sheets$OutputCodeParameters <- .ars_rows_df(list(), S$OutputCodeParameters)
  sheets$OutputDocumentRefs <- .ars_rows_df(odr_rows, S$OutputDocumentRefs)

  set_rows <- function(items) {
    unlist(lapply(items, function(s) {
      lapply(.ars_where_rows(s, level = s$level %||% 1L,
                             order = s$order %||% 1L), function(r)
        c(list(id = s$id, name = s$name, description = s$description,
               label = s$label), r))
    }), recursive = FALSE)
  }
  sheets$DataSubsets <- .ars_rows_df(set_rows(re$dataSubsets), S$DataSubsets)
  sheets$AnalysisSets <- .ars_rows_df(set_rows(re$analysisSets),
                                      S$AnalysisSets)
  ag_rows <- list()
  for (g in re$analysisGroupings) {
    base <- list(id = g$id, name = g$name, description = g$description,
                 label = g$label, groupingDataset = g$groupingDataset,
                 groupingVariable = g$groupingVariable,
                 dataDriven = isTRUE(g$dataDriven))
    if (!length(g$groups)) ag_rows[[length(ag_rows) + 1L]] <- base
    for (gr in g$groups) {
      gb <- c(base, list(group_id = gr$id, group_name = gr$name,
                         group_description = gr$description,
                         group_label = gr$label))
      for (r in .ars_where_rows(gr, prefix = "group_",
                                level = gr$level %||% 1L,
                                order = gr$order %||% 1L)) {
        ag_rows[[length(ag_rows) + 1L]] <- c(gb, r)
      }
    }
  }
  sheets$AnalysisGroupings <- .ars_rows_df(ag_rows, S$AnalysisGroupings)

  # an operation's id from a relationship id: the template's Analyses
  # column names the relationship (referencedOperationId)
  a_rows <- list()
  apc_rows <- list()
  adr_rows <- list()
  for (a in re$analyses) {
    adr_rows <- c(adr_rows, .ars_docref_rows(a, "analysis_id"))
    r <- list(id = a$id, version = a$version, name = a$name,
              description = a$description, label = a$label,
              categoryIds = a$categoryIds, reason = .ars_term(a$reason),
              purpose = .ars_term(a$purpose),
              analysisSetId = a$analysisSetId)
    for (k in seq_along(a$orderedGroupings)) {
      g <- a$orderedGroupings[[k]]
      r[[paste0("groupingId", k)]] <- g$groupingId
      r[[paste0("resultsByGroup", k)]] <- isTRUE(g$resultsByGroup)
    }
    r <- c(r, list(dataSubsetId = a$dataSubsetId, dataset = a$dataset,
                   variable = a$variable, method_id = a$methodId))
    for (k in seq_along(a$referencedAnalysisOperations)) {
      ro <- a$referencedAnalysisOperations[[k]]
      r[[paste0("referencedAnalysisOperations_referencedOperationId", k)]] <-
        ro$referencedOperationRelationshipId
      r[[paste0("referencedAnalysisOperations_analysisId", k)]] <-
        ro$analysisId
    }
    a_rows[[length(a_rows) + 1L]] <- r
    if (!is.null(a$programmingCode)) {
      apc_rows[[length(apc_rows) + 1L]] <- .ars_code_row(a$programmingCode,
                                                         "analysis_id", a$id)
    }
  }
  sheets$Analyses <- .ars_rows_df(a_rows, S$Analyses)
  sheets$AnalysisProgrammingCode <- .ars_rows_df(apc_rows,
                                                 S$AnalysisProgrammingCode)
  sheets$AnalysisCodeParameters <- .ars_rows_df(list(),
                                                S$AnalysisCodeParameters)
  sheets$AnalysisDocumentRefs <- .ars_rows_df(adr_rows,
                                              S$AnalysisDocumentRefs)

  m_rows <- list()
  t_rows <- list()
  p_rows <- list()
  mdr_rows <- list()
  for (m in re$methods) {
    mdr_rows <- c(mdr_rows, .ars_docref_rows(m, "method_id"))
    base <- list(id = m$id, name = m$name, description = m$description,
                 label = m$label)
    for (o in m$operations) {
      r <- c(base, list(operation_id = o$id, operation_name = o$name,
                        operation_description = o$description,
                        operation_label = o$label, operation_order = o$order,
                        operation_resultPattern = o$resultPattern))
      for (k in seq_along(o$referencedOperationRelationships)) {
        rr <- o$referencedOperationRelationships[[k]]
        p <- paste0("operation_referencedResultRelationships", k, "_")
        r[[paste0(p, "id")]] <- rr$id
        r[[paste0(p, "referencedOperationRole")]] <-
          .ars_term(rr$referencedOperationRole)
        r[[paste0(p, "operationId")]] <- rr$operationId
        r[[paste0(p, "analysisId")]] <- rr$analysisId
        r[[paste0(p, "description")]] <- rr$description
      }
      m_rows[[length(m_rows) + 1L]] <- r
    }
    ct <- m$codeTemplate
    if (!is.null(ct)) {
      tr <- .ars_code_row(ct, "method_id", m$id)
      names(tr)[names(tr) == "code"] <- "templateCode"
      t_rows[[length(t_rows) + 1L]] <- tr
      for (p in ct$parameters) {
        p_rows[[length(p_rows) + 1L]] <- list(
          method_id = m$id, parameter_name = p$name,
          parameter_description = p$description, parameter_label = p$label,
          parameter_valueSource = p$valueSource, parameter_value = p$value)
      }
    }
  }
  sheets$AnalysisMethods <- .ars_rows_df(m_rows, S$AnalysisMethods)
  sheets$AnalysisMethodCodeTemplate <- .ars_rows_df(
    t_rows, S$AnalysisMethodCodeTemplate)
  sheets$AnalysisMethodCodeParameters <- .ars_rows_df(
    p_rows, S$AnalysisMethodCodeParameters)
  sheets$AnalysisMethodDocumentRefs <- .ars_rows_df(
    mdr_rows, S$AnalysisMethodDocumentRefs)
  sheets$AnalysisResults <- .ars_rows_df(list(), S$AnalysisResults)
  te_rows <- list()
  for (te in re$terminologyExtensions) {
    for (st in te$sponsorTerms) {
      te_rows[[length(te_rows) + 1L]] <- list(
        id = te$id, enumeration = te$enumeration, sponsorTerm_id = st$id,
        sponsorTerm_submissionValue = st$submissionValue,
        sponsorTerm_description = st$description)
    }
  }
  sheets$TerminologyExtensions <- .ars_rows_df(te_rows,
                                               S$TerminologyExtensions)
  sheets[names(S)]
}

#' Write a CDISC ARS reporting event as CDISC's Excel template
#'
#' The reporting event in the shape of the Excel template of CDISC's ARS
#' repository ("ARS Template.xlsx"): its 25 sheets in their order, each with
#' the template's columns -- one row per list item, group, operation and
#' display sub-section, a condition as rows of `level` / `order`, several
#' values joined by `" | "`.  It is the form to read and to set beside
#' other ARS workbooks; CDISC's converter (`excel2ars.py`) reads it back to
#' the JSON.  The JSON ([tfl_write_ars_json()]) stays the one to exchange.
#' Results (`AnalysisResults`) are not written: a reporting event of
#' [tfl_ars()] has none.  A display without sections has no row in the
#' template: its name is written as its one title line.
#'
#' @param ars A [tfl_ars()] or [tfl_read_ars_json()].
#' @param path Destination `.xlsx`.
#' @param overwrite Replace an existing file.
#' @return `path`, invisibly.
#' @seealso [tfl_write_ars_json()]
#' @export
tfl_write_ars_xlsx <- function(ars, path, overwrite = FALSE) {
  if (!inherits(ars, "tfl_ars")) {
    .ard_stop("`ars` must be a tfl_ars() or tfl_read_ars_json().")
  }
  .ard_spec_xlsx_path(path, "tfl_write_ars_xlsx")
  if (file.exists(path) && !isTRUE(overwrite)) {
    .ard_stop(sprintf("%s exists; overwrite = TRUE replaces it.", path))
  }
  # writexl: a workbook every reader opens (openpyxl, so CDISC's
  # excel2ars.py, too), the header row in bold
  .ard_need("writexl", "tfl_write_ars_xlsx()")
  sheets <- .ars_xlsx_book(.ars_plain(ars))
  writexl::write_xlsx(sheets, path, format_headers = TRUE)
  invisible(path)
}
