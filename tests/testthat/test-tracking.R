test_that("gaze samples are read and assigned to the smallest zone", {
  dir <- tempfile()
  dir.create(dir)
  gaze_file(dir)
  eye <- read_eyetracking(dir)
  expect_s3_class(eye, "gorilla_eyetracking")
  g <- eye$gaze
  expect_equal(nrow(g), 3L)
  expect_equal(g$x, c(0.15, 0.3, 0.9))
  expect_equal(g$elapsed, c(0, 40, 80))
  expect_s3_class(g$time, "POSIXct")
  expect_equal(g$zone_name, c("Button", "Picture", NA))
  expect_equal(g$zone_id, c("object-2", "object-1", NA))
  z <- eye$zones
  expect_equal(z$zone_id, c("object-1", "object-2"))
  expect_equal(z$bottom, c(0.5, 0.8))
  expect_equal(z$right, c(0.5, 0.2))
  only <- read_eyetracking(dir, zones = "Picture")$gaze
  expect_equal(only$zone_name, c("Picture", "Picture", NA))
  expect_null(eye$calibration)
  expect_output(print(eye), "3 gaze samples from 1 participant in 1 recording;")
})

test_that("calibration attempts and outcomes are numbered", {
  dir <- tempfile()
  dir.create(dir)
  calibration_file(dir)
  cal <- read_eyetracking(dir)$calibration
  expect_equal(cal$attempt, c(1L, 1L, 2L))
  expect_equal(cal$outcome, c("failed - retrying", "failed - retrying", "failed - max failures"))
  expect_equal(cal$point_x, c(0.5, 0.2, NA))
  expect_equal(cal$error, c(0.05, 0, NA))
  expect_equal(cal$display[3], "Calibration 1")
})

test_that("the main export adds task and screen names", {
  dir <- tempfile()
  dir.create(dir)
  gaze_file(dir)
  mouse_file(dir)
  task <- meta("701", "Visual world", "task-et1", 2)
  task$`Trial Number` <- "1"
  task$Display <- "Trial"
  task$Screen <- "Choice"
  task$`Screen ID` <- "scr1"
  task$`Response Type` <- c("info", "response")
  task$`Component Name` <- "Click Response"
  task$Response <- c("", "left")
  write_export(dir, "data_exp_55555-v1_task-et1.csv", task)
  g <- read_gorilla(dir)
  eye <- read_eyetracking(dir, x = g)
  expect_equal(unique(eye$gaze$task_name), "Visual world")
  expect_equal(unique(eye$gaze$screen), "Choice")
  expect_true(all(is.na(read_eyetracking(dir)$gaze$task_name)))
  joined <- dplyr::inner_join(
    eye$gaze, gorilla_trials(g),
    by = c("participant_private_id", "tree_node_key", "display", "trial", "screen")
  )
  expect_equal(nrow(joined), 3L)
  expect_equal(unique(read_mousetracking(dir, x = g)$mouse$task_name), "Visual world")
  expect_error(read_eyetracking(dir, x = list()), "read_gorilla")
})

test_that("mouse tracking samples are read", {
  dir <- tempfile()
  dir.create(dir)
  mouse_file(dir)
  gaze_file(dir)
  mo <- read_mousetracking(dir)
  expect_s3_class(mo, "gorilla_mousetracking")
  m <- mo$mouse
  expect_equal(nrow(m), 2L)
  expect_equal(m$type, c("mouse", "mouse"))
  expect_equal(m$trial, c(1, 1))
  expect_equal(m$screen, c("Choice", "Choice"))
  expect_equal(m$timestamp, c(1010.5, 1027))
  expect_equal(m$x_raw, c(200, 700))
  expect_equal(m$zone_name, c(NA, "Target"))
  expect_equal(mo$files$kind, "mousetracking")
  expect_output(print(mo), "2 samples")
})

test_that("recordings are found in ZIP archives and missing ones give an error", {
  dir <- tempfile()
  dir.create(dir)
  f <- c(gaze_file(dir), calibration_file(dir))
  zip <- file.path(tempdir(), "tracking.zip")
  utils::zip(zip, f, flags = "-jq")
  eye <- read_eyetracking(zip)
  expect_equal(nrow(eye$gaze), 3L)
  expect_setequal(eye$files$kind, c("calibration", "collection"))
  expect_error(read_mousetracking(dir), "No mousetracking files")
  expect_error(read_eyetracking(gorilla_example()), "No collection or calibration files")
})

test_that("rows of other types are kept and broken files give a warning", {
  dir <- tempfile()
  dir.create(dir)
  f <- gaze_file(dir)
  d <- readr::read_csv(f, col_types = readr::cols(.default = "c"))
  d$Type[4] <- "face lost"
  readr::write_csv(d, f, na = "")
  g <- read_eyetracking(dir)$gaze
  expect_equal(g$type, c("prediction", "face lost", "prediction"))
  cat("55555,1,task-et1\n", file = f, append = TRUE)
  expect_warning(read_eyetracking(dir), "wrong number of columns")
})

test_that("a missing path gives a plain error", {
  expect_error(read_eyetracking("no/such/folder"), "^Path not found: no/such/folder$")
  expect_error(read_gorilla("no/such/folder"), "^Path not found: no/such/folder$")
})

test_that("rows keep the right file when a value contains a line break", {
  dir <- tempfile()
  dir.create(dir)
  f <- gaze_file(dir, "701")
  gaze_file(dir, "702")
  d <- readr::read_csv(f, col_types = readr::cols(.default = "c"))
  d$Display <- "Trial\nblock 1"
  readr::write_csv(d, f, na = "")
  g <- read_eyetracking(dir)$gaze
  expect_equal(nrow(g), 6L)
  expect_equal(g$participant_private_id, rep(c("701", "702"), each = 3))
  expect_equal(unique(g$display), c("Trial\nblock 1", "Trial"))
  expect_true(all(stringr::str_detect(g$file, paste0("-", g$participant_private_id, "-task-"))))
})
