set.seed(2026)

out_dir <- file.path("inst", "extdata", "example")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
unlink(list.files(out_dir, full.names = TRUE))

meta_names <- c(
  "Event Index", "UTC Timestamp", "UTC Date and Time", "Local Timestamp",
  "Local Timezone", "Local Date and Time", "Experiment ID", "Experiment Version",
  "Tree Node Key", "Repeat Key", "Schedule ID", "Participant Public ID",
  "Participant Private ID", "Participant Starting Group", "Participant Status",
  "Participant Completion Code", "Participant External Session ID",
  "Participant Device Type", "Participant Device", "Participant OS",
  "Participant Browser", "Participant Monitor Size", "Participant Viewport Size",
  "Checkpoint", "Room ID", "Room Order", "Task Name", "Task Version",
  "randomiser-ab12"
)

n_participants <- 6L
people <- data.frame(
  private = as.character(9100000L + seq_len(n_participants) * 37L),
  public = vapply(seq_len(n_participants), function(i) {
    sample(c(0:9, letters[1:6]), 24, replace = TRUE) |> paste(collapse = "")
  }, ""),
  group = rep(c("List A", "List B"), length.out = n_participants),
  status = c(rep("complete", n_participants - 1L), "live"),
  browser = sample(c("Chrome 141.0.0.0", "Firefox 144.0", "Safari 18.6"), n_participants, replace = TRUE),
  os = sample(c("Windows 10", "Mac OS 10.15.7"), n_participants, replace = TRUE),
  start = as.numeric(as.POSIXct("2026-03-02 09:00:00", tz = "UTC")) * 1000 +
    sort(sample(0:(5 * 24 * 3600), n_participants)) * 1000,
  stringsAsFactors = FALSE
)

meta_rows <- function(p, n, node, task, offset) {
  t <- p$start + offset + seq_len(n) * 1500
  data.frame(
    `Event Index` = as.character(seq_len(n)),
    `UTC Timestamp` = sprintf("%.0f", t),
    `UTC Date and Time` = format(as.POSIXct(t / 1000, origin = "1970-01-01", tz = "UTC"), "%d/%m/%Y %H:%M:%S"),
    `Local Timestamp` = sprintf("%.0f", t + 3600000),
    `Local Timezone` = "1",
    `Local Date and Time` = format(as.POSIXct(t / 1000 + 3600, origin = "1970-01-01", tz = "UTC"), "%d/%m/%Y %H:%M:%S"),
    `Experiment ID` = "123456",
    `Experiment Version` = "3",
    `Tree Node Key` = node,
    `Repeat Key` = "",
    `Schedule ID` = as.character(50000000L + as.integer(p$private) %% 100000L),
    `Participant Public ID` = p$public,
    `Participant Private ID` = p$private,
    `Participant Starting Group` = "",
    `Participant Status` = p$status,
    `Participant Completion Code` = "",
    `Participant External Session ID` = "",
    `Participant Device Type` = "computer",
    `Participant Device` = "Desktop or Laptop",
    `Participant OS` = p$os,
    `Participant Browser` = p$browser,
    `Participant Monitor Size` = "1920x1080",
    `Participant Viewport Size` = "1903x969",
    `Checkpoint` = "",
    `Room ID` = "",
    `Room Order` = "",
    `Task Name` = task,
    `Task Version` = "2",
    `randomiser-ab12` = p$group,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

write_export <- function(df, file) {
  eof <- as.data.frame(matrix("", nrow = 1L, ncol = ncol(df)), stringsAsFactors = FALSE)
  names(eof) <- names(df)
  eof[1, 1] <- "END OF FILE"
  df <- rbind(df, eof)
  df[is.na(df)] <- ""
  utils::write.csv(df, file.path(out_dir, file), row.names = FALSE, fileEncoding = "UTF-8")
}

words <- data.frame(
  word = c("garden", "blanket", "pencil", "window", "mirror", "basket", "candle", "ladder",
           "plimet", "drosk", "fenulat", "sorbit", "trandel", "mukket", "glorp", "venisk"),
  lexicality = rep(c("word", "nonword"), each = 8L),
  stringsAsFactors = FALSE
)
words$answer <- ifelse(words$lexicality == "word", "f", "j")

ld_rows <- function(p, i) {
  completed <- if (p$status == "complete") nrow(words) else 7L
  order <- sample(nrow(words))[seq_len(completed)]
  pieces <- list()
  info <- function(resp) {
    data.frame(`Trial Number` = "", Display = "", Screen = "", `Response Type` = "info",
               Response = resp, `Reaction Time` = "", Correct = "", `Component Name` = "",
               `Object Name` = "", check.names = FALSE, stringsAsFactors = FALSE)
  }
  pieces[[1]] <- info("BEGIN")
  pieces[[2]] <- data.frame(`Trial Number` = "1", Display = "Instructions", Screen = "Screen 1",
                            `Response Type` = "continue", Response = "",
                            `Reaction Time` = sprintf("%.1f", stats::runif(1, 3000, 15000)),
                            Correct = "1", `Component Name` = "Click To Continue",
                            `Object Name` = "Continue Button", check.names = FALSE, stringsAsFactors = FALSE)
  for (k in seq_along(order)) {
    w <- words[order[k], ]
    acc <- stats::runif(1) < if (w$lexicality == "word") 0.95 else 0.88
    resp <- if (acc) w$answer else setdiff(c("f", "j"), w$answer)
    rt <- stats::rlnorm(1, log(if (w$lexicality == "word") 620 else 710), 0.25)
    pieces[[length(pieces) + 1L]] <- data.frame(
      `Trial Number` = as.character(k), Display = "Trial", Screen = "Target",
      `Response Type` = "response", Response = resp, `Reaction Time` = sprintf("%.1f", rt),
      Correct = as.character(as.integer(acc)), `Component Name` = "Keyboard Response",
      `Object Name` = "Keyboard Response", check.names = FALSE, stringsAsFactors = FALSE)
  }
  body <- do.call(rbind, pieces)
  if (p$status == "complete") body <- rbind(body, info("END"))
  sheet <- rbind(data.frame(word = "", lexicality = "", answer = "", stringsAsFactors = FALSE)[rep(1, 2), ],
                 words[order, c("word", "lexicality", "answer")])
  if (p$status == "complete") sheet <- rbind(sheet, sheet[1, ])
  names(sheet) <- paste0("Spreadsheet: ", c("Word", "Lexicality", "ANSWER"))
  m <- meta_rows(p, nrow(body), "task-ld2k", "Lexical decision", 120000)
  cbind(m, `Spreadsheet` = paste0("Spreadsheet ", substr(p$group, 6, 6)),
        `Current Spreadsheet` = paste0("Spreadsheet ", substr(p$group, 6, 6)),
        body, sheet, `Store: score` = "")
}

ld <- do.call(rbind, lapply(seq_len(n_participants), function(i) ld_rows(people[i, ], i)))
complete_ids <- people$private[people$status == "complete"]
score <- tapply(ld$Correct == "1" & ld$`Response Type` == "response", ld$`Participant Private ID`, sum)
end_row <- ld$`Response Type` == "info" & ld$Response == "END"
ld$`Store: score`[end_row] <- as.character(score[ld$`Participant Private ID`[end_row]])
write_export(ld, "data_exp_123456-v3_task-ld2k.csv")

pairs <- data.frame(
  `Word 1` = c("cat", "light", "stone", "cake", "fair", "bloom", "hand", "seal"),
  `Word 2` = c("hat", "kite", "phone", "bake", "fear", "bright", "sand", "soul"),
  rhyme = c("yes", "yes", "yes", "yes", "no", "no", "yes", "no"),
  check.names = FALSE, stringsAsFactors = FALSE
)

rh_rows <- function(p) {
  order <- sample(nrow(pairs))
  rows <- list(data.frame(`Spreadsheet Name` = "", `Spreadsheet Row` = "", `Trial Number` = "BEGIN TASK",
                          `Screen Number` = "", `Screen Name` = "", `Zone Name` = "", `Zone Type` = "",
                          `Reaction Time` = "", Response = "", Attempt = "", Correct = "", Incorrect = "",
                          `Timed Out` = "", check.names = FALSE, stringsAsFactors = FALSE))
  sheet <- list(pairs[0, ][1, ])
  for (k in seq_along(order)) {
    pr <- pairs[order[k], ]
    acc <- stats::runif(1) < 0.9
    resp <- if (acc) pr$rhyme else setdiff(c("yes", "no"), pr$rhyme)
    base <- data.frame(`Spreadsheet Name` = "Pairs", `Spreadsheet Row` = as.character(order[k]),
                       `Trial Number` = as.character(k), check.names = FALSE, stringsAsFactors = FALSE)
    rows[[length(rows) + 1L]] <- cbind(base, data.frame(
      `Screen Number` = "1", `Screen Name` = "Fixation", `Zone Name` = "fixation", `Zone Type` = "fixation",
      `Reaction Time` = sprintf("%.1f", stats::runif(1, 499, 501)), Response = "", Attempt = "0", Correct = "0",
      Incorrect = "0", `Timed Out` = "", check.names = FALSE, stringsAsFactors = FALSE))
    rows[[length(rows) + 1L]] <- cbind(base, data.frame(
      `Screen Number` = "2", `Screen Name` = "Pair", `Zone Name` = if (resp == "yes") "Zone1" else "Zone2",
      `Zone Type` = "response_button_text", `Reaction Time` = sprintf("%.1f", stats::rlnorm(1, log(900), 0.3)),
      Response = resp, Attempt = "1", Correct = as.character(as.integer(acc)),
      Incorrect = as.character(as.integer(!acc)), `Timed Out` = "", check.names = FALSE, stringsAsFactors = FALSE))
    sheet[[length(sheet) + 1L]] <- pr
    sheet[[length(sheet) + 1L]] <- pr
  }
  rows[[length(rows) + 1L]] <- rows[[1]]
  rows[[length(rows)]]$`Trial Number` <- "END TASK"
  sheet[[length(sheet) + 1L]] <- pairs[0, ][1, ]
  body <- do.call(rbind, rows)
  sh <- do.call(rbind, sheet)
  sh[is.na(sh)] <- ""
  m <- meta_rows(p, nrow(body), "task-rh7p", "Rhyme judgement", 900000)
  cbind(m, Spreadsheet = "Pairs", body, sh)
}

done <- people[people$status == "complete", ]
rh <- do.call(rbind, lapply(seq_len(nrow(done)), function(i) rh_rows(done[i, ])))
write_export(rh, "data_exp_123456-v3_task-rh7p.csv")

consent_rows <- function(p) {
  keys <- c("BEGIN QUESTIONNAIRE", "consent-data", "consent-data-quantised",
            "consent-withdraw", "consent-withdraw-quantised", "END QUESTIONNAIRE")
  resp <- c("", "I agree", "1", "I agree", "1", sprintf("%.0f", stats::runif(1, 20000, 90000)))
  m <- meta_rows(p, length(keys), "questionnaire-cn4x", "Consent", 0)
  cbind(m, `Randomise questionnaire elements?` = "No", `Question Key` = keys, Response = resp)
}
consent <- do.call(rbind, lapply(seq_len(n_participants), function(i) consent_rows(people[i, ])))
write_export(consent, "data_exp_123456-v3_questionnaire-cn4x.csv")

bg_rows <- function(p) {
  age <- as.character(sample(19:34, 1))
  gender <- sample(c("Female", "Male", "Non-binary"), 1, prob = c(0.5, 0.4, 0.1))
  langs <- c("English", "German", "Italian", "Portuguese")
  picked <- stats::runif(4) < c(0.9, 0.6, 0.2, 0.15)
  obj <- c("Info", "Age", "Gender", "Gender", rep("Languages", 4), "Handedness", "Handedness")
  key <- c("", "value", "value", "quantised", langs, "value", "quantised")
  hand <- sample(c("Right", "Left"), 1, prob = c(0.85, 0.15))
  resp <- c("", age, gender, as.character(match(gender, c("Female", "Male", "Non-binary"))),
            as.character(as.integer(picked)), hand, as.character(match(hand, c("Right", "Left"))))
  type <- c("info", rep("response", length(key) - 1L))
  resp[1] <- "BEGIN"
  key[1] <- ""
  obj[1] <- ""
  m <- meta_rows(p, length(key) + 1L, "questionnaire-bg9q", "Background", 60000)
  cbind(m, Page = "Page 1", `Page ID` = "pg1a", `Page Counter` = "1", Question = "",
        `Response Type` = c(type, "info"), Key = c(key, ""), Response = c(resp, "END"),
        Tag = "", OptionOrder = "", `Object Name` = c(obj, ""), `Object Number` = "", `Object ID` = "")
}
bg <- do.call(rbind, lapply(seq_len(n_participants), function(i) bg_rows(people[i, ])))
write_export(bg, "data_exp_123456-v3_questionnaire-bg9q.csv")

empty <- bg[0, ]
write_export(empty, "data_exp_123456-v3_questionnaire-zz1e.csv")
