#' Example ADaM-like data for trying tflspec
#'
#' Synthetic oncology data (no real subjects): `ADSL`, `ADTTE` (OS / PFS /
#' DOR, days), `ADRS` (OVR per visit + BOR) and `ADTR` (best percent change in
#' sum of diameters; `SDIAM` over time), `ADLOT` (lines of therapy), `ADAE`,
#' `ADLB` (ALT / AST / BILI) and `ADPC` (concentrations).
#'
#' @param n Number of subjects.
#' @param seed Random seed.
#' @return A named list of data frames.
#' @export
tfl_example_adam <- function(n = 40, seed = 1) {
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

  # lines of therapy: one row per subject and line (drawn after the other
  # data so their values do not change)
  classes <- c("Chemo", "Immunotherapy", "Targeted")
  lot <- do.call(rbind, lapply(seq_len(n), function(i) {
    k <- sample(1:4, 1, prob = c(0.35, 0.3, 0.2, 0.15))
    trt <- character(k)
    trt[1] <- sample(classes, 1, prob = c(0.5, 0.3, 0.2))
    for (j in seq_len(k)[-1]) trt[j] <- sample(setdiff(classes, trt[j - 1]), 1)
    data.frame(USUBJID = id[i], LINE = seq_len(k), TRT = trt, stringsAsFactors = FALSE)
  }))
  lot$FASFL <- adsl$FASFL[match(lot$USUBJID, id)]
  lot$AGEGR1 <- ifelse(match(lot$USUBJID, id) %% 3 == 0, ">=65", "<65")
  lot$LINE <- lab(lot$LINE, "Line of Therapy")
  lot$TRT <- lab(lot$TRT, "Treatment Class")

  # ---- datasets added later: a separate random stream so that the ones
  # above keep their values ----
  set.seed(seed + 1000)
  sex <- sample(c("F", "M"), n, replace = TRUE)
  agegr <- ifelse(seq_len(n) %% 3 == 0, ">=65", "<65")
  adsl$SEX <- lab(sex, "Sex")
  adsl$AGEGR1 <- lab(agegr, "Pooled Age Group 1")
  adsl$TRT01A <- lab(adsl$TRT01P, "Actual Treatment for Period 01")
  adsl$RANDDY <- 1
  adsl$TRTSDY <- lab(1 + round(stats::runif(n, 0, 21)), "Treatment Start Day (from Randomization)")
  adsl$TRTEDY <- lab(adsl$TRTSDY + adsl$TRTDURD - 1, "Treatment End Day (from Randomization)")
  addsl <- function(d) cbind(d, adsl[match(d$USUBJID, id), c("SEX", "AGEGR1")])
  tte <- addsl(tte)
  adtr <- addsl(adtr)

  # tumour size over time (SDIAM): percent change from baseline by visit
  sd_rows <- do.call(rbind, lapply(seq_len(n), function(i) {
    days <- c(1, seq(42, max(42, dur[i]), by = 42))
    slope <- pchg[i] / max(1, length(days) - 1)
    pc <- c(0, round(slope * seq_along(days[-1]) + stats::rnorm(length(days) - 1, 0, 6), 1))
    data.frame(USUBJID = id[i], TRT01P = arm[i], FASFL = adsl$FASFL[i], PARAMCD = "SDIAM",
               PARAM = "Sum of Diameters of Target Lesions", AVAL = NA, ADY = days,
               PCHG = pmax(-100, pc), stringsAsFactors = FALSE)
  }))
  sd_rows$AVAL <- round(60 * (1 + sd_rows$PCHG / 100), 1)
  sd_rows <- addsl(sd_rows)
  adtr$ADY <- NA
  adtr$PCHG <- NA
  adtr <- rbind(adtr, sd_rows[names(adtr)])
  adtr$PCHG <- lab(adtr$PCHG, "Percent Change from Baseline")

  # adverse events
  pts <- c("Nausea", "Fatigue", "Diarrhoea", "Headache", "Rash", "Anaemia", "Neutropenia",
           "Vomiting", "Decreased appetite", "Pyrexia", "Cough", "Arthralgia")
  socs <- c("Gastrointestinal disorders", "General disorders", "Gastrointestinal disorders",
            "Nervous system disorders", "Skin disorders", "Blood disorders", "Blood disorders",
            "Gastrointestinal disorders", "Metabolism disorders", "General disorders",
            "Respiratory disorders", "Musculoskeletal disorders")
  base_p <- c(0.35, 0.3, 0.25, 0.2, 0.15, 0.15, 0.12, 0.12, 0.1, 0.1, 0.08, 0.08)
  adae <- do.call(rbind, lapply(seq_len(n), function(i) {
    p <- base_p * ifelse(armn[i] == 2, 1.5, 1)
    hit <- which(stats::runif(length(pts)) < pmin(p, 0.95))
    if (!length(hit)) return(NULL)
    data.frame(USUBJID = id[i], AEDECOD = pts[hit], AEBODSYS = socs[hit], TRTEMFL = "Y",
               AETOXGR = sample(c("1", "2", "3"), length(hit), TRUE, c(0.6, 0.3, 0.1)),
               stringsAsFactors = FALSE)
  }))

  # laboratory (ALT, AST, BILI) with upper limit of normal
  visits <- data.frame(AVISITN = c(0, 2, 4, 8, 12), AVISIT = c("BASELINE", "WEEK 2", "WEEK 4", "WEEK 8", "WEEK 12"))
  adlb <- do.call(rbind, lapply(c("ALT", "AST", "BILI"), function(pc) {
    uln <- c(ALT = 40, AST = 35, BILI = 21)[[pc]]
    do.call(rbind, lapply(seq_len(n), function(i) {
      b <- uln * stats::runif(1, 0.3, 0.9)
      drift <- ifelse(armn[i] == 2, 1.15, 1.02)^(visits$AVISITN / 4)
      spike <- if (stats::runif(1) < 0.08) c(1, 1, 3.5, 2, 1.2) else 1
      v <- round(b * drift * spike * exp(stats::rnorm(nrow(visits), 0, 0.15)), 1)
      data.frame(USUBJID = id[i], PARAMCD = pc,
                 PARAM = c(ALT = "Alanine Aminotransferase (U/L)", AST = "Aspartate Aminotransferase (U/L)",
                           BILI = "Bilirubin (umol/L)")[[pc]],
                 AVISITN = visits$AVISITN, AVISIT = visits$AVISIT, AVAL = v, BASE = v[1],
                 CHG = v - v[1], ANRHI = uln, stringsAsFactors = FALSE)
    }))
  }))
  adlb$AVAL <- lab(adlb$AVAL, "Analysis Value")

  # pharmacokinetic concentrations
  times <- c(0, 0.5, 1, 2, 4, 6, 8, 12, 24)
  adpc <- do.call(rbind, lapply(seq_len(n), function(i) {
    dose <- ifelse(armn[i] == 2, 200, 100)
    ka <- 1.2 * exp(stats::rnorm(1, 0, 0.2)); ke <- 0.15 * exp(stats::rnorm(1, 0, 0.2))
    cc <- dose / 20 * ka / (ka - ke) * (exp(-ke * times) - exp(-ka * times))
    cc <- round(cc * exp(stats::rnorm(length(times), 0, 0.1)), 2)
    data.frame(USUBJID = id[i], PARAMCD = "DRUGX", PARAM = "Drug X Concentration (ng/mL)",
               NFRLT = times, AVAL = pmax(cc, 0), stringsAsFactors = FALSE)
  }))
  adpc$NFRLT <- lab(adpc$NFRLT, "Nominal Relative Time from First Dose (h)")

  list(ADSL = adsl, ADTTE = tte, ADRS = adrs, ADTR = adtr, ADLOT = lot,
       ADAE = adae, ADLB = adlb, ADPC = adpc)
}
