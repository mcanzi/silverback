test_that("quantised values are joined to their answers", {
  g <- read_gorilla(gorilla_example(), quiet = TRUE)
  q <- g$questionnaires
  gender <- q[q$item == "Gender", ]
  expect_equal(nrow(gender), 6L)
  expect_false(any(is.na(gender$quantised)))
  expect_false(any(grepl("quantised", q$item)))
  expect_true("Languages-German" %in% q$item)
})

test_that("gorilla_wide gives one row per participant", {
  g <- read_gorilla(gorilla_example(), quiet = TRUE)
  w <- gorilla_wide(g)
  expect_equal(nrow(w), 6L)
  expect_true(all(c("age", "gender", "gender_quantised", "languages_german", "consent_data") %in% names(w)))
  expect_type(w$age, "integer")
  w2 <- gorilla_wide(g, task = "Consent", quantised = FALSE)
  expect_equal(names(w2), c("participant_private_id", "consent_data", "consent_withdraw"))
  expect_error(gorilla_wide(g, task = "Nope"), "Unknown questionnaire")
})

test_that("short format questionnaires from both builders are read", {
  dir <- tempfile()
  dir.create(dir)
  wide_qb2(dir)
  wide_qb1(dir)
  g <- read_gorilla(dir)
  expect_equal(nrow(g$participants), 2L)
  q <- g$questionnaires
  expect_setequal(unique(q$task_name), c("Survey", "Consent"))
  expect_equal(q$quantised[q$item == "mood" & q$participant_private_id == "102"], 3)
  expect_equal(q$response[q$item == "pets-Dog" & q$participant_private_id == "101"], "1")
  expect_equal(q$quantised[q$item == "grid-Reading" & q$participant_private_id == "101"], 4)
  expect_false("END QUESTIONNAIRE" %in% q$item)
  expect_message(w <- gorilla_wide(g), "more than once")
  expect_true(all(c("age", "age__2", "mood_quantised", "consent_1", "consent_1_quantised") %in% names(w)))
  expect_equal(w$age__2[w$participant_private_id == "101"], 6L)
})

test_that("combined files mixing both questionnaire builders are read", {
  dir <- tempfile()
  dir.create(dir)
  combined_questionnaires(dir)
  g <- read_gorilla(dir)
  expect_equal(g$files$builder, "questionnaire_mixed")
  q <- g$questionnaires
  expect_setequal(q$item, c("agree", "Reading"))
  expect_equal(q$quantised[q$item == "agree"], c(1, 1))
  orphan <- q[q$item == "Reading" & q$participant_private_id == "202", ]
  expect_true(is.na(orphan$response))
  expect_equal(orphan$quantised, 2)
  ch <- gorilla_checks(g)
  expect_true(all(c("versions", "device") %in% ch$check))
  expect_equal(ch$participant_private_id[ch$check == "device"], "202")
})
