test_that("participants hold status, randomiser and store values", {
  g <- read_gorilla(gorilla_example(), quiet = TRUE)
  p <- gorilla_participants(g)
  expect_equal(sum(p$participant_status == "complete"), 5L)
  expect_true(all(c("randomiser_ab12", "store_score", "start", "end", "minutes") %in% names(p)))
  expect_s3_class(p$start, "POSIXct")
  expect_true(all(p$end >= p$start))
  expect_equal(nrow(gorilla_participants(g, status = "complete")), 5L)
  expect_true(is.na(p$store_score[p$participant_status == "live"]))
})

test_that("blind_ids replaces public identifiers consistently", {
  g <- read_gorilla(gorilla_example(), quiet = TRUE)
  b <- blind_ids(g)
  expect_true(all(grepl("^P[0-9]{3}$", b$participants$participant_public_id)))
  id <- b$participants$participant_private_id[2]
  code <- b$participants$participant_public_id[2]
  expect_true(all(b$tasks$participant_public_id[b$tasks$participant_private_id == id] == code))
  expect_false(any(b$tasks$participant_public_id %in% g$participants$participant_public_id))
})
