test_that("summary describes each task and questionnaire", {
  g <- read_gorilla(gorilla_example(), quiet = TRUE)
  s <- summary(g)
  expect_s3_class(s, "gorilla_summary")
  expect_equal(s$tasks$task_name, c("Lexical decision", "Rhyme judgement"))
  expect_equal(s$tasks$responses_min, c(7L, 8L))
  expect_equal(s$tasks$responses_max, c(16L, 8L))
  expect_true(all(s$tasks$correct > 0.5 & s$tasks$correct <= 1))
  expect_equal(s$questionnaires$items, c(7L, 2L))
  expect_output(print(s), "6 participants")
  expect_equal(summary(g, fast = 10000)$tasks$fast, c(1, 1))
})

test_that("checks find the incomplete participant and its missing task", {
  g <- read_gorilla(gorilla_example(), quiet = TRUE)
  ch <- gorilla_checks(g)
  expect_named(ch, c("check", "participant_private_id", "task_name", "detail"))
  live <- g$participants$participant_private_id[g$participants$participant_status == "live"]
  expect_true(all(c("status", "missing_task") %in% ch$check))
  expect_equal(unique(ch$participant_private_id), live)
  expect_equal(ch$task_name[ch$check == "missing_task"], "Rhyme judgement")
})

test_that("checks flag fast and identical responses, duplicates and imbalance", {
  g <- read_gorilla(gorilla_example(), quiet = TRUE)
  id <- g$participants$participant_private_id[1]
  rows <- g$tasks$participant_private_id == id & g$tasks$task_name == "Lexical decision" &
    g$tasks$response_type %in% "response"
  g$tasks$reaction_time[rows] <- 150
  g$tasks$response[rows] <- "f"
  g$participants$participant_public_id[2] <- g$participants$participant_public_id[3]
  g$participants$randomiser_ab12 <- c(rep("List A", 5), "List B")
  ch <- gorilla_checks(g)
  expect_true(all(c("fast", "same_response", "duplicate", "unbalanced") %in% ch$check))
  expect_equal(ch$participant_private_id[ch$check == "fast"], id)
  expect_equal(nrow(gorilla_checks(g, fast = 1, max_same = 1, balance = 10)[0, ]), 0L)
})

test_that("no findings give an empty tibble", {
  g <- read_gorilla(gorilla_example(), quiet = TRUE)
  g$participants <- g$participants[g$participants$participant_status == "complete", ]
  g$tasks <- g$tasks[g$tasks$participant_private_id %in% g$participants$participant_private_id, ]
  ch <- gorilla_checks(g)
  expect_equal(nrow(ch), 0L)
})
