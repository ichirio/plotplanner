# ============================================================================
#  tflspec_ai_manual() -- hand the AI briefing to the user
# ============================================================================
#
#  The manual ships in `inst/ai/` so that it is the same artefact as the
#  code it describes: a user is on whichever release they installed, and a
#  manual read against another version is worse than none -- an assistant
#  quotes a function that will not resolve with exactly the confidence it
#  quotes one that will.  (rtfreporter does the same: rtfreporter_ai_manual().)

#' The AI assistant manual that ships with this package
#'
#' tflspec is too new to be in any chat model's training data: asked for a
#' table specification or the program made from one, an assistant invents
#' sheet columns and function names and flags neither as a guess.  The fix
#' is to give it the facts first, and this file is those facts -- the
#' specification formats (ARD, table, report, listing, figure design), the
#' functions that turn them into R code, what that code looks like, the
#' former names that are refused, and the complete export list -- sized to
#' sit in one chat session.
#'
#' `tflspec_ai_manual()` returns the path to the copy **installed with this
#' package**, so the manual you attach always describes the version you
#' actually have.  For the rendering side attach rtfreporter's own manual
#' instead (`rtfreporter::rtfreporter_ai_manual()`).
#'
#' @param file Optional destination.  When given, the manual is copied there
#'   (ready to attach to a chat session) and the destination is returned
#'   invisibly.  A directory is accepted, and the file keeps its own name.
#' @param overwrite Overwrite `file` if it already exists.  Default `FALSE`.
#'
#' @return The path to the manual -- the installed file when `file` is `NULL`,
#'   otherwise the copy, returned invisibly.
#'
#' @examples
#' # where the manual lives
#' tflspec_ai_manual()
#'
#' # read it here, or copy it out to attach to a chat session
#' writeLines(head(readLines(tflspec_ai_manual()), 3))
#' tflspec_ai_manual(file = tempfile(fileext = ".md"))
#' @export
tflspec_ai_manual <- function(file = NULL, overwrite = FALSE) {
  name <- "tflspec-ai-user-manual.md"
  src  <- system.file("ai", name, package = "tflspec")
  if (!nzchar(src) || !file.exists(src)) {
    stop(sprintf(paste0(
      "`tflspec_ai_manual()`: %s is not in this installation.\n",
      "  It ships in inst/ai/ from tflspec 0.0.24 on: reinstall."), name),
      call. = FALSE)
  }
  if (is.null(file)) return(src)

  dest <- if (dir.exists(file)) file.path(file, name) else file
  if (file.exists(dest) && !isTRUE(overwrite)) {
    stop(sprintf(paste0(
      "`tflspec_ai_manual()`: '%s' already exists; pass `overwrite = TRUE` ",
      "to replace it."), dest), call. = FALSE)
  }
  if (!file.copy(src, dest, overwrite = isTRUE(overwrite))) {
    stop(sprintf("`tflspec_ai_manual()`: could not write '%s'.", dest),
         call. = FALSE)
  }
  invisible(dest)
}
