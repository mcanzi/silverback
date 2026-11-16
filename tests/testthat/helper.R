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
