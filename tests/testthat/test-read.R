test_that("the example is read and sorted", {
  expect_message(g <- read_gorilla(gorilla_example()), "without data")
  expect_s3_class(g, "gorilla_data")
  expect_setequal(unique(g$tasks$task_name), c("Lexical decision", "Rhyme judgement"))
  expect_setequal(unique(g$questionnaires$task_name), c("Consent", "Background"))
  expect_equal(nrow(g$participants), 6L)
  expect_equal(nrow(g$files), 5L)
  expect_equal(sum(g$files$rows == 0L), 1L)
  expect_false(any(g$tasks$event_index %in% "END OF FILE"))
  expect_output(print(g), "experiment 123456")
})

test_that("quiet suppresses the message about empty files", {
  expect_silent(read_gorilla(gorilla_example(), quiet = TRUE))
})

test_that("builders are detected", {
  g <- read_gorilla(gorilla_example(), quiet = TRUE)
  b <- stats::setNames(g$files$builder, g$files$file)
  expect_equal(unname(b["data_exp_123456-v3_task-ld2k.csv"]), "task_builder_2")
  expect_equal(unname(b["data_exp_123456-v3_task-rh7p.csv"]), "task_builder_1")
  expect_equal(unname(b["data_exp_123456-v3_questionnaire-cn4x.csv"]), "questionnaire_builder_1")
  expect_equal(unname(b["data_exp_123456-v3_questionnaire-bg9q.csv"]), "questionnaire_builder_2")
})

test_that("Task Builder 1 spreadsheet columns get the spreadsheet_ prefix", {
  g <- read_gorilla(gorilla_example(), quiet = TRUE)
  expect_true(all(c("spreadsheet_word_1", "spreadsheet_word_2", "spreadsheet_rhyme") %in% names(g$tasks)))
  expect_true(all(c("spreadsheet_word", "spreadsheet_answer", "store_score") %in% names(g$tasks)))
})

test_that("single files and zip archives are read", {
  f <- gorilla_example("data_exp_123456-v3_task-rh7p.csv")
  g <- read_gorilla(f)
  expect_equal(unique(g$tasks$task_name), "Rhyme judgement")
  renamed <- file.path(tempdir(), "rhymes.csv")
  file.copy(f, renamed, overwrite = TRUE)
  expect_equal(nrow(read_gorilla(renamed)$tasks), nrow(g$tasks))
  skip_if(Sys.which("zip") == "", "no zip program")
  zip_file <- tempfile(fileext = ".zip")
  old <- setwd(gorilla_example())
  on.exit(setwd(old))
  utils::zip(zip_file, list.files(), flags = "-q")
  setwd(old)
  before <- list.files(tempdir())
  z <- read_gorilla(zip_file, quiet = TRUE)
  expect_equal(nrow(z$tasks), nrow(read_gorilla(gorilla_example(), quiet = TRUE)$tasks))
  expect_setequal(list.files(tempdir()), before)
})

test_that("a byte order mark is removed from the first column name", {
  dir <- tempfile()
  dir.create(dir)
  wide_qb2(dir, bom = TRUE)
  g <- read_gorilla(dir)
  expect_false(any(grepl("event", g$questionnaires$item, ignore.case = TRUE)))
})

test_that("missing paths, other files and folders without exports give errors", {
  expect_error(read_gorilla(tempfile()), "not found")
  expect_error(read_gorilla(1), "must be")
  other <- tempfile(fileext = ".csv")
  utils::write.csv(data.frame(a = 1), other, row.names = FALSE)
  expect_error(read_gorilla(other), "does not look like a Gorilla export")
  xl <- tempfile()
  dir.create(xl)
  file.create(file.path(xl, "data_exp_1-v1_tasks.xlsx"))
  expect_warning(expect_error(read_gorilla(xl), "No Gorilla files"), "Excel")
  dir <- tempfile()
  dir.create(dir)
  expect_error(read_gorilla(dir), "No Gorilla files")
})

test_that("numbers are converted only when no information is lost", {
  expect_identical(convert_value(c("1", "2", NA)), c(1L, 2L, NA))
  expect_identical(convert_value(c("1.5", "2")), c(1.5, 2))
  expect_identical(convert_value(c("007", "010")), c("007", "010"))
  expect_identical(convert_value(c("T", "F")), c("T", "F"))
  expect_identical(convert_value(c("", NA)), c(NA, NA))
  expect_type(convert_value("1767225600000"), "double")
})

test_that("a download with only empty files is reported as such", {
  dir <- tempfile()
  dir.create(dir)
  file.copy(gorilla_example("data_exp_123456-v3_questionnaire-zz1e.csv"), dir)
  g <- read_gorilla(dir, quiet = TRUE)
  expect_output(print(g), "no data")
  expect_null(g$participants)
  expect_equal(nrow(gorilla_checks(g)), 0L)
})

test_that("files saved again with semicolons are read", {
  f <- gorilla_example("data_exp_123456-v3_task-rh7p.csv")
  d <- readr::read_csv(f, col_types = readr::cols(.default = "c"), na = "")
  dir <- tempfile()
  dir.create(dir)
  readr::write_delim(d, file.path(dir, basename(f)), delim = ";", na = "")
  expect_equal(read_gorilla(dir)$tasks, read_gorilla(f)$tasks)
})

test_that("answers with line breaks and quotes survive", {
  dir <- tempfile()
  dir.create(dir)
  df <- cbind(meta("301", "Notes", "questionnaire-n1", 2), `Question Key` = c("note", "other"),
              Response = c("first line\nsecond line", "she said \"no\""))
  write_export(dir, "data_exp_55555-v1_questionnaire-n1.csv", df)
  q <- read_gorilla(dir)$questionnaires
  expect_equal(q$response, c("first line\nsecond line", "she said \"no\""))
})

test_that("mixing combined and per-node downloads gives a warning", {
  dir <- tempfile()
  dir.create(dir)
  file.copy(gorilla_example("data_exp_123456-v3_task-rh7p.csv"), dir)
  file.copy(gorilla_example("data_exp_123456-v3_task-rh7p.csv"),
            file.path(dir, "data_exp_123456-v3_tasks.csv"))
  expect_warning(read_gorilla(dir), "read twice")
})

test_that("a bare END OF FILE line gives no warning", {
  dir <- tempfile()
  dir.create(dir)
  path <- file.path(dir, "data_exp_55555-v1_task-ab12.csv")
  readr::write_csv(meta("101", "Task", "task-ab12", 2), path, na = "")
  write("END OF FILE", path, append = TRUE)
  expect_no_warning(g <- read_gorilla(dir))
  expect_equal(nrow(g$tasks), 2L)
})

test_that("rows with the wrong number of columns give a warning", {
  dir <- tempfile()
  dir.create(dir)
  path <- file.path(dir, "data_exp_55555-v1_task-ab12.csv")
  readr::write_csv(meta("101", "Task", "task-ab12", 2), path, na = "")
  write(c("1,2", "END OF FILE"), path, append = TRUE)
  expect_warning(read_gorilla(dir), "1 line with the wrong number of columns \\(line 4\\)")
})
