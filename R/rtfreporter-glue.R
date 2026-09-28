# ----------------------------------------------------------------------------
#  The seam with rtfreporter.  Everything else here reaches rtfreporter only
#  through its exports; these are the two places that needed more.
# ----------------------------------------------------------------------------

# rtfreporter reads a plan the way it reads a gt table: rtf_tables(doc, plan)
# and as_rtftables(plan) both work, because this method is registered on
# rtfreporter's as_rtftables() generic.  rtfreporter itself never names
# the tfl_plan class.

#' @importFrom rtfreporter as_rtftables
#' @export
as_rtftables.tfl_plan <- function(x, ...) tfl_apply_plan(x, "pages")

# The rounding family.  rtfreporter owns the rule (round_num() and the
# `rtfreporter.rounding` option); these two only resolve and apply it, so a
# plan and a hand-written table round the same way.
.rounding_type <- function(rounding = NULL) {
  if (is.null(rounding)) rounding <- getOption("rtfreporter.rounding", "r")
  if (!is.character(rounding) || length(rounding) != 1L ||
      !rounding %in% c("r", "sas")) {
    stop("`rounding` must be \"r\" (half to even, as base::round() does) ",
         "or \"sas\" (half away from zero, as SAS ROUND() does).",
         call. = FALSE)
  }
  rounding
}

.rounder <- function(rounding = NULL) {
  rounding <- .rounding_type(rounding)
  function(x, digits = 0) rtfreporter::round_num(x, digits, rounding = rounding)
}

# NULL-only, as in base R (>= 4.4) and rtfreporter: the ARD / plan code was
# written against this meaning.  The plot code's blank-aware one is `%or%`.
`%||%` <- function(a, b) if (is.null(a)) b else a
