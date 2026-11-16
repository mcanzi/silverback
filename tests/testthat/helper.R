write_export <- function(dir, file, df, bom = FALSE) {
  eof <- df[1, , drop = FALSE]
  eof[1, ] <- ""
  eof[1, 1] <- "END OF FILE"
  df <- rbind(df, eof)
  path <- file.path(dir, file)
  readr::write_csv(df, path, na = "")
  if (bom) {
    bytes <- readBin(path, "raw", file.size(path))
    writeBin(c(as.raw(c(0xef, 0xbb, 0xbf)), bytes), path)
  }
  path
}

meta <- function(id, task, node, n, version = "1") {
  data.frame(
    `Event Index` = as.character(seq_len(n)),
    `UTC Timestamp` = as.character(1767225600000 + seq_len(n) * 1000 + as.numeric(id)),
    `Experiment ID` = "55555",
    `Experiment Version` = version,
    `Tree Node Key` = node,
    `Participant Public ID` = paste0("pub", id),
    `Participant Private ID` = id,
    `Participant Status` = "complete",
    `Task Name` = task,
    check.names = FALSE, stringsAsFactors = FALSE
  )
}

wide_qb2 <- function(dir, bom = FALSE) {
  labels <- data.frame(
    `Event Index` = "", `UTC Timestamp` = "", `Experiment ID` = "", `Experiment Version` = "",
    `Tree Node Key` = "", `Participant Public ID` = "", `Participant Private ID` = "",
    `Participant Status` = "", `Task Name` = "",
    check.names = FALSE, stringsAsFactors = FALSE
  )
  rows <- rbind(meta("101", "Survey", "questionnaire-wq2a", 1), meta("102", "Survey", "questionnaire-wq2a", 1))
  ans <- data.frame(
    `age object-3 Value` = c("How old are you?", "25", "31"),
    `mood object-4 Response` = c("Mood?", "Good", "Bad"),
    `mood object-4 Quantised` = c("Mood?", "1", "3"),
    `mood object-4 Other` = c("Mood?", "", ""),
    `pets object-5 Cat` = c("Pets?", "1", "0"),
    `pets object-5 Dog` = c("Pets?", "1", "1"),
    `grid object-6 Reading` = c("How often?", "Often", "Never"),
    `grid object-6 Reading Quantised` = c("How often?", "4", "1"),
    `age object-9 Value` = c("Age you started school?", "6", "5"),
    check.names = FALSE, stringsAsFactors = FALSE
  )
  df <- cbind(rbind(labels, rows), ans)
  write_export(dir, "data_exp_55555-v1_questionnaire-wq2a.csv", df, bom = bom)
}

wide_qb1 <- function(dir) {
  rows <- rbind(meta("101", "Consent", "questionnaire-wq1b", 1), meta("102", "Consent", "questionnaire-wq1b", 1))
  df <- cbind(rows, `Randomise questionnaire elements?` = "No",
              `consent-1` = c("Yes", "Yes"), `consent-1-quantised` = c("1", "1"),
              `END QUESTIONNAIRE` = c("40000", "52000"))
  write_export(dir, "data_exp_55555-v1_questionnaire-wq1b.csv", df)
}

combined_questionnaires <- function(dir) {
  qb1 <- rbind(meta("201", "Consent", "questionnaire-c1", 3, version = "1"),
               meta("202", "Consent", "questionnaire-c1", 3, version = "2"))
  qb1$`Participant Device Type` <- rep(c("computer", "mobile"), each = 3)
  qb1$`Question Key` <- rep(c("BEGIN QUESTIONNAIRE", "agree", "agree-quantised"), 2)
  qb1$Response <- rep(c("", "Yes", "1"), 2)
  qb2 <- rbind(meta("201", "Survey", "questionnaire-s2", 2, version = "1"),
               meta("202", "Survey", "questionnaire-s2", 2, version = "2"))
  qb2$`Participant Device Type` <- rep(c("computer", "mobile"), each = 2)
  qb2$`Question Key` <- ""
  qb2$Response <- c("Often", "3", "", "2")
  qb2$`Response Type` <- "response"
  qb2$Key <- c("value", "quantised", "value", "quantised")
  qb2$`Object Name` <- "Reading"
  qb1$`Response Type` <- ""
  qb1$Key <- ""
  qb1$`Object Name` <- ""
  write_export(dir, "data_exp_55555-vall_questionnaires.csv", rbind(qb1, qb2))
}

upload_keys <- function(n, id = "701", node = "task-et1", display = "Trial", trial = "1",
                        screen = "", screen_id = "scr1", index = "2") {
  data.frame(
    `Experiment ID` = "55555", `Experiment Version` = "1", `Tree Node Key` = node,
    `Schedule ID` = "900", `Participant Private ID` = id, Spreadsheet = "List1",
    `Spreadsheet Index` = index, Display = display, `Trial Number` = trial, `Screen ` = screen,
    `Screen ID` = screen_id, `Screen Index` = "2", `Screen Counter` = "2",
    check.names = FALSE, stringsAsFactors = FALSE
  )[rep(1L, n), ]
}

# A gaze recording with a large picture zone and a small button zone on top
# of it, and samples inside the button, inside the picture only, and outside.
gaze_file <- function(dir, id = "701") {
  zones <- cbind(upload_keys(2, id), Filename = "collection", Timestamp = "1767225600000",
                 Elapsed = "0", Type = "zone",
                 `Predicted Gaze X` = "", `Predicted Gaze Y` = "",
                 `Predicted Gaze X Normalised` = "", `Predicted Gaze Y Normalised` = "",
                 `Zone Name` = c("Picture", "Button"), `Zone UID` = c("object-1", "object-2"),
                 `Zone X` = "0", `Zone Y` = "0", `Zone W` = "0", `Zone H` = "0",
                 `Zone X Normalised` = c("0", "0.1"), `Zone Y Normalised` = c("1", "0.9"),
                 `Zone W Normalised` = c("0.5", "0.1"), `Zone H Normalised` = c("0.5", "0.1"))
  samples <- cbind(upload_keys(3, id), Filename = "collection",
                   Timestamp = as.character(1767225600000 + c(0, 40, 80)),
                   Elapsed = c("0", "40", "80"), Type = "prediction",
                   `Predicted Gaze X` = c("100", "300", "900"), `Predicted Gaze Y` = "1",
                   `Predicted Gaze X Normalised` = c("0.15", "0.3", "0.9"),
                   `Predicted Gaze Y Normalised` = c("0.85", "0.7", "0.2"),
                   `Zone Name` = "", `Zone UID` = "", `Zone X` = "", `Zone Y` = "",
                   `Zone W` = "", `Zone H` = "", `Zone X Normalised` = "",
                   `Zone Y Normalised` = "", `Zone W Normalised` = "", `Zone H Normalised` = "")
  path <- file.path(dir, paste0("55555-1-", id, "-task-et1-900-collection-1-2.csv"))
  readr::write_csv(rbind(zones, samples), path, na = "")
  path
}

# A calibration that fails once after measuring two points, then fails for
# good before measuring any.
calibration_file <- function(dir, id = "701") {
  type <- c("calibration", "accuracy", "accuracy", "calibration failed - retrying",
            "calibration", "calibration failed - max failures", "end of calibration")
  n <- length(type)
  num <- function(v) rep(v, length.out = n)
  d <- cbind(upload_keys(n, id, display = "Calibration 1", screen_id = "cal1", index = "1"),
             Filename = "calibration", Timestamp = as.character(1767225600000 + seq_len(n)),
             Elapsed = "0", Interval = "0", Type = type, Failures = "",
             `Predicted Gaze X` = "0", `Predicted Gaze Y` = "0",
             `Predicted Gaze X Normalised` = "0", `Predicted Gaze Y Normalised` = "0",
             `Face Detection Confidence` = "1", `X of Point` = "0", `Y of Point` = "0",
             `X of Point Normalised` = num(c("0", "0.5", "0.2", "0")),
             `Y of Point Normalised` = num(c("0", "0.5", "0.8", "0")),
             `X of Centroid` = "0", `Y of Centroid` = "0",
             `X of Centroid Normalised` = num(c("0", "0.53", "0.2", "0")),
             `Y of Centroid Normalised` = num(c("0", "0.54", "0.8", "0")),
             `SD of X Centroid` = "0", `SD of Y Centroid` = "0",
             `SD of X Centroid Normalised` = "0.01", `SD of Y Centroid Normalised` = "0.02")
  path <- file.path(dir, paste0("55555-1-", id, "-task-et1-900-calibration-1-2.csv"))
  readr::write_csv(d, path, na = "")
  path
}

mouse_file <- function(dir, id = "701") {
  keys <- function(n) {
    k <- upload_keys(n, id, screen = "Choice")
    names(k)[names(k) == "Trial Number"] <- "Trial Count"
    k
  }
  zones <- cbind(keys(1), Timestamp = "1000", Elapsed = "0", Type = "zone", Name = "Target",
                 `Unique ID` = "object-5", `X Normalised` = "0.5", `Y Normalised` = "0.5",
                 `W Normalised` = "0.5", `H Normalised` = "0.5", `X Raw` = "0", `Y Raw` = "0")
  moves <- cbind(keys(2), Timestamp = c("1010.5", "1027"), Elapsed = c("10.5", "27"),
                 Type = "mouse", Name = "", `Unique ID` = "",
                 `X Normalised` = c("0.2", "0.7"), `Y Normalised` = c("0.8", "0.3"),
                 `W Normalised` = "0", `H Normalised` = "0", `X Raw` = c("200", "700"),
                 `Y Raw` = c("200", "700"))
  path <- file.path(dir, paste0("55555-1-", id, "-task-et1-900-mousetracking-1-2.csv"))
  readr::write_csv(rbind(zones, moves), path, na = "")
  path
}
