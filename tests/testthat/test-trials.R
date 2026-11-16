test_that("trials have the same columns for both task builders", {
  g <- read_gorilla(gorilla_example(), quiet = TRUE)
  ld <- gorilla_trials(g, task = "Lexical decision")
  rh <- gorilla_trials(g, task = "Rhyme judgement")
  core <- c("participant_private_id", "task_name", "trial", "screen", "response", "rt", "correct", "time")
  expect_true(all(core %in% names(ld)))
  expect_true(all(core %in% names(rh)))
  expect_equal(nrow(ld), 5L * 16L + 7L)
  expect_equal(nrow(rh), 5L * 8L)
  expect_type(ld$rt, "double")
  expect_type(ld$correct, "logical")
  expect_true(all(is.na(rh$display)))
  expect_true(all(startsWith(rh$component, "response_")))
  expect_true("spreadsheet_word" %in% names(ld))
  expect_false("spreadsheet_rhyme" %in% names(ld))
})

test_that("all_rows keeps the non-response rows but drops markers", {
  g <- read_gorilla(gorilla_example(), quiet = TRUE)
  all <- gorilla_trials(g, task = "Rhyme judgement", all_rows = TRUE)
  expect_equal(nrow(all), 5L * 16L)
  expect_true("fixation" %in% all$response_type)
})

test_that("unknown tasks give an error", {
  g <- read_gorilla(gorilla_example(), quiet = TRUE)
  expect_error(gorilla_trials(g, task = "Stroop"), "Unknown task")
  expect_error(gorilla_trials(list()), "read_gorilla")
})

test_that("trials keep the repeat key, task version and timing columns", {
  dir <- tempfile()
  dir.create(dir)
  df <- cbind(meta("201", "Timing", "task-tm01", 2), `Repeat Key` = c("r1", "r2"),
              `Task Version` = "4", Display = "Trial", Screen = "Target",
              `Component Name` = "Keyboard Response", `Object Name` = "Keys",
              `Response Type` = "response", `Trial Number` = c("1", "2"), Response = c("f", "j"),
              `Reaction Time` = c("500", "600"), `Onset Time` = c("100", "110"),
              `Absolute Onset Time` = "", `Response Duration` = c("50", ""))
  write_export(dir, "data_exp_55555-v1_task-tm01.csv", df)
  t <- gorilla_trials(read_gorilla(dir, quiet = TRUE))
  expect_equal(t$repeat_key, c("r1", "r2"))
  expect_equal(as.numeric(t$task_version), c(4, 4))
  expect_equal(t$onset_time, c(100, 110))
  expect_equal(t$response_duration, c(50, NA))
  expect_false("absolute_onset_time" %in% names(t))
  expect_true(match("onset_time", names(t)) > match("time", names(t)))
})

test_that("components without response values give a message and count objects in checks", {
  dir <- tempfile()
  dir.create(dir)
  click <- function(id, objects) {
    d <- meta(id, "Melody test", "task-mt1", length(objects))
    d$`Trial Number` <- as.character(seq_along(objects))
    d$Display <- "Trial"
    d$Screen <- "Response"
    d$`Response Type` <- "response"
    d$`Component Name` <- "Click Response"
    d$`Object Name` <- objects
    d$Response <- ""
    d$`Reaction Time` <- "900"
    d
  }
  task <- rbind(click("801", rep("SAME", 12)), click("802", rep(c("SAME", "DIFFERENT"), 6)))
  write_export(dir, "data_exp_55555-v1_task-mt1.csv", task)
  g <- read_gorilla(dir)
  expect_message(tr <- gorilla_trials(g),
                 "Melody test: Click Response. These components recorded no response values")
  expect_true(all(is.na(tr$response)))
  expect_equal(tr$object[1:2], c("SAME", "SAME"))
  expect_no_message(gorilla_trials(g, quiet = TRUE))
  expect_no_message(gorilla_trials(g, all_rows = TRUE))
  expect_no_message(ch <- gorilla_checks(g))
  same <- ch[ch$check == "same_response", ]
  expect_equal(same$participant_private_id, "801")
  expect_match(same$detail, "response 'SAME' in 12 of 12")
  expect_no_message(summary(g))
  expect_no_message(write_gorilla(g, file.path(dir, "out")))
})

test_that("tasks with response values are left alone", {
  g <- read_gorilla(gorilla_example(), quiet = TRUE)
  expect_no_message(gorilla_trials(g))
})
