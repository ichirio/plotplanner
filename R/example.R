#' Example ADaM-like data for trying tflspec
#'
#' Synthetic oncology data (no real subjects): `ADSL`, `ADTTE` (OS / PFS /
#' DOR, days), `ADRS` (OVR per visit + BOR) and `ADTR` (best percent change in
#' sum of diameters).
#'
#' @param n Number of subjects.
#' @param seed Random seed.
#' @return A named list of data frames.
#' @export
pp_example_adam <- function(n = 40, seed = 1) {
  set.seed(seed)
  lab <- function(x, l) { attr(x, "label") <- l; x }
  id <- sprintf("PP-01-%04d", seq_len(n))
  arm <- rep(c("Drug A", "Drug B"), length.out = n)
  armn <- ifelse(arm == "Drug A", 1, 2)
  dur <- round(stats::rexp(n, 1 / 200)) + 30
  eos <- sample(c("ONGOING", "DISCONTINUED", "COMPLETED"), n, replace = TRUE, prob = c(0.4, 0.45, 0.15))
  dth <- ifelse(eos == "DISCONTINUED" & stats::runif(n) < 0.5, dur + round(stats::runif(n, 5, 90)), NA)
  nact <- ifelse(eos == "DISCONTINUED" & stats::runif(n) < 0.6, dur + round(stats::runif(n, 1, 40)), NA)
  eosdy <- ifelse(eos == "DISCONTINUED", dur + 1, NA)

  pchg <- round(pmax(-100, stats::rnorm(n, -20, 35)), 1)
  bor <- ifelse(pchg <= -99, "CR", ifelse(pchg <= -30, "PR", ifelse(pchg > 20, "PD", "SD")))
  bor[sample(n, 2)] <- "NE"

  adsl <- data.frame(
    STUDYID = "PP-01", USUBJID = id, SUBJID = substr(id, 7, 10),
    TRT01P = arm, TRT01PN = armn, FASFL = "Y", SAFFL = "Y",
    TRTDURD = dur, EOSSTT = eos, DTHADY = dth, NACTDY = nact, EOSDY = eosdy,
    stringsAsFactors = FALSE
  )
  adsl$FASFL[sample(n, 2)] <- "N"
  labels <- c(USUBJID = "Unique Subject Identifier", SUBJID = "Subject Identifier for the Study",
              TRT01P = "Planned Treatment for Period 01", TRT01PN = "Planned Treatment for Period 01 (N)",
              FASFL = "Full Analysis Set Population Flag", SAFFL = "Safety Population Flag",
              TRTDURD = "Total Treatment Duration (Days)", EOSSTT = "End of Study Status",
              DTHADY = "Relative Day of Death", NACTDY = "Study Day of Subsequent Anti-Cancer Therapy",
              EOSDY = "Study Day of End of Study")
  for (v in names(labels)) adsl[[v]] <- lab(adsl[[v]], labels[[v]])

  tte <- do.call(rbind, lapply(c("OS", "PFS", "DOR"), function(pc) {
    scale <- c(OS = 540, PFS = 240, DOR = 200)[[pc]] * ifelse(armn == 2, 1.4, 1)
    t <- round(stats::rexp(n, 1 / scale)) + 1
    c_t <- round(stats::runif(n, 150, 720))
    data.frame(USUBJID = id, TRT01P = arm, TRT01PN = armn, FASFL = adsl$FASFL,
               PARAMCD = pc,
               PARAM = c(OS = "Overall Survival (days)", PFS = "Progression Free Survival (days)",
                         DOR = "Duration of Response (days)")[[pc]],
               AVAL = pmin(t, c_t), CNSR = as.integer(c_t < t), stringsAsFactors = FALSE)
  }))
  tte$AVAL <- lab(tte$AVAL, "Analysis Value")
  tte$CNSR <- lab(tte$CNSR, "Censor")

  resp_levels <- c("CR", "PR", "SD", "PD", "NE")
  ovr <- do.call(rbind, lapply(seq_len(n), function(i) {
    days <- if (dur[i] >= 42) seq(42, dur[i], by = 42) else dur[i]
    r <- sample(resp_levels, length(days), replace = TRUE, prob = c(0.1, 0.3, 0.4, 0.15, 0.05))
    data.frame(USUBJID = id[i], PARAMCD = "OVR", PARAM = "Overall Response by Investigator",
               ADY = days, AVISIT = paste("WEEK", days / 7), AVALC = r, stringsAsFactors = FALSE)
  }))
  borr <- data.frame(USUBJID = id, PARAMCD = "BOR", PARAM = "Best Overall Response by Investigator",
                     ADY = NA, AVISIT = NA, AVALC = bor, stringsAsFactors = FALSE)
  adrs <- rbind(ovr, borr)
  adrs$AVALC <- lab(adrs$AVALC, "Analysis Value (C)")
  adrs$ADY <- lab(adrs$ADY, "Analysis Relative Day")

  adtr <- data.frame(USUBJID = id, TRT01P = arm, FASFL = adsl$FASFL, PARAMCD = "BPCHG",
                     PARAM = "Best Percent Change from Baseline in Sum of Diameters",
                     AVAL = pchg, stringsAsFactors = FALSE)
  adtr$AVAL <- lab(adtr$AVAL, "Best % Change in Sum of Target Lesion Diameters")

  list(ADSL = adsl, ADTTE = tte, ADRS = adrs, ADTR = adtr)
}
