# Damaged or unusual exports, as they turn up after downloading, copying or
# saving files again in a spreadsheet program.

example_copy <- function(files = list.files(gorilla_example())) {
  dir <- tempfile()
  dir.create(dir)
  file.copy(file.path(gorilla_example(), files), dir)
  dir
}

read_chr <- function(path) {
  readr::read_csv(path, col_types = readr::cols(.default = "c"), na = "")
}

tb1 <- "data_exp_123456-v3_task-rh7p.csv"
tb2 <- "data_exp_123456-v3_task-ld2k.csv"

test_that("an empty 0-byte file is skipped like a file without data", {
  dir <- example_copy()
  file.create(file.path(dir, tb2))
  expect_message(g <- read_gorilla(dir), "Skipped 2 files without data")
  expect_equal(g$files$rows[g$files$file == tb2], 0L)
  expect_false("Lexical decision" %in% g$tasks$task_name)
})

test_that("a binary file gives a plain error", {
  dir <- example_copy()
  writeBin(as.raw(c(0x50, 0x4b, 0x03, 0x04, 0x00, 0x00, 0xff)), file.path(dir, tb2))
  expect_error(read_gorilla(dir), paste0("^", tb2, " is not a text file\\.$"))
})

test_that("files saved as Windows-1252 or UTF-16 are read with a warning or silently", {
  f <- tempfile(fileext = ".csv")
  writeBin(c(charToRaw("Participant Private ID,Response\n1,Gr"), as.raw(c(0xf6, 0xdf)),
             charToRaw("e "), as.raw(0x80), charToRaw("\n")), f)
  expect_warning(d <- read_table_chr(f), "read as Windows-1252")
  expect_equal(d$Response, "Größe €")
  dir <- example_copy()
  path <- file.path(dir, tb2)
  tsv <- tempfile()
  readr::write_tsv(read_chr(path), tsv, na = "")
  text <- rawToChar(readBin(tsv, "raw", file.size(tsv)))
  Encoding(text) <- "UTF-8"
  writeBin(c(as.raw(c(0xff, 0xfe)), iconv(text, "UTF-8", "UTF-16LE", toRaw = TRUE)[[1L]]), path)
  expect_no_warning(g <- read_gorilla(dir, quiet = TRUE))
  csv <- read_gorilla(gorilla_example(), quiet = TRUE)
  expect_equal(dplyr::select(g$tasks, -file), dplyr::select(csv$tasks, -file))
})

test_that("a second copy of a download gives a warning", {
  dir <- example_copy()
  file.copy(file.path(dir, tb2), file.path(dir, sub("\\.csv$", " (1).csv", tb2)))
  expect_warning(read_gorilla(dir, quiet = TRUE),
                 "same events appear in more than one file: data_exp_123456-v3_task-ld2k \\(1\\)")
  expect_no_warning(read_gorilla(gorilla_example(), quiet = TRUE))
})

test_that("a column name that appears twice is kept with a number", {
  dir <- example_copy()
  d <- read_chr(file.path(dir, tb1))
  d$Clash <- ifelse(is.na(d$`Participant Private ID`), NA, "yes")
  names(d)[names(d) == "Clash"] <- "Correct"
  readr::write_csv(d, file.path(dir, tb1), na = "")
  expect_warning(g <- read_gorilla(dir, quiet = TRUE), "`Correct` is a column name that appears")
  tr <- gorilla_trials(g, task = "Rhyme judgement")
  csv <- gorilla_trials(read_gorilla(gorilla_example(), quiet = TRUE), task = "Rhyme judgement")
  expect_equal(tr$correct, csv$correct)
  expect_true(all(tr$spreadsheet_correct_1 == "yes"))
})

test_that("exports without status, task name or timestamp columns still work", {
  dir <- example_copy()
  for (f in list.files(dir, full.names = TRUE)) {
    d <- read_chr(f)
    keep <- setdiff(names(d), c("Participant Status", "Task Name", "UTC Timestamp"))
    readr::write_csv(d[keep], f, na = "")
  }
  g <- read_gorilla(dir, quiet = TRUE)
  expect_output(print(g), "6 participants")
  expect_no_error(summary(g))
  expect_equal(sum(gorilla_checks(g)$check == "status"), 0L)
  files <- write_gorilla(g, tempfile(), by_task = TRUE)
  expect_true("trials_unknown_task.csv" %in% basename(files))
})

test_that("writing an export without data writes nothing", {
  g <- read_gorilla(example_copy("data_exp_123456-v3_questionnaire-zz1e.csv"), quiet = TRUE)
  out <- tempfile()
  expect_message(files <- write_gorilla(g, out), "Nothing to write")
  expect_length(files, 0L)
  expect_false(dir.exists(out))
})

test_that("arguments of the wrong type give clear errors", {
  g <- read_gorilla(gorilla_example(), quiet = TRUE)
  expect_error(read_gorilla(gorilla_example(), quiet = "yes"), "`quiet` must be TRUE or FALSE")
  expect_error(gorilla_trials(g, all_rows = NA), "`all_rows` must be TRUE or FALSE")
  expect_error(gorilla_trials(g, task = 1), "`task` must be a character vector or NULL")
  expect_error(gorilla_wide(g, quantised = "no"), "`quantised` must be TRUE or FALSE")
  expect_error(gorilla_checks(g, fast = c(100, 200)), "`fast` must be a single number")
  expect_error(gorilla_checks(g, max_same = 2),
               "`max_same` must be a single number between 0 and 1")
  expect_error(gorilla_checks(g, balance = 0.5), "`balance` must be a single number of at least 1")
  expect_error(summary(g, slow = "long"), "`slow` must be a single number")
  expect_error(write_gorilla(g, tempfile(), by_task = NA), "`by_task` must be TRUE or FALSE")
  file <- tempfile()
  file.create(file)
  expect_error(write_gorilla(g, file), "`path` is a file, not a folder")
  expect_error(blind_ids(g, columns = 1), "`columns` must be a character vector or NULL")
  expect_error(gorilla_example("nope.csv"), "No example file named nope.csv")
  expect_error(read_eyetracking(gorilla_example(), zones = 1), "`zones` must be a character vector")
})

test_that("summary works on data whose tasks were filtered to no rows", {
  g <- read_gorilla(gorilla_example(), quiet = TRUE)
  g$tasks <- g$tasks[0, ]
  expect_no_warning(s <- summary(g))
  expect_null(s$tasks)
})
