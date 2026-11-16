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
