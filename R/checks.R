findings <- function(check, detail, participant_private_id = NA_character_,
                     task_name = NA_character_) {
  tibble::tibble(check = check, participant_private_id = as.character(participant_private_id),
                 task_name = as.character(task_name), detail = detail)
}

#' Check Gorilla data for common problems
#'
#' Lists participants and tasks that may need a closer look before the
#' analysis. Each row describes one finding. The function removes nothing,
#' so you decide what to exclude.
#'
#' The checks are
#' \describe{
#'   \item{status}{Participants whose status is not `complete`, such as live
#'     or rejected participants included by hand. Skipped if the export has
#'     no status column.}
#'   \item{versions}{Data from more than one version of the experiment.}
#'   \item{duplicate}{The same public ID under several private IDs, which
#'     usually means that someone took part more than once.}
#'   \item{missing_task}{Participants who did not do a task that most
#'     participants with the same outcomes of randomiser, branch, order,
#'     counterbalance and allocator nodes did.}
#'   \item{unbalanced}{Randomiser nodes whose groups differ in size by more
#'     than the ratio `balance`.}
#'   \item{device}{Participants who used a different type of device from
#'     most participants.}
#'   \item{fast}{Participants with more than the proportion `max_fast` of
#'     responses in a task faster than `fast` milliseconds.}
#'   \item{same_response}{Participants who gave the same response in more
#'     than the proportion `max_same` of at least `min_responses` responses in
#'     a task where other responses were possible. For components that
#'     recorded no response values, the object clicked or chosen counts as the
#'     response.}
#' }
#'
#' @param x A `gorilla_data` object from [read_gorilla()].
#' @param fast Reaction time in milliseconds below which a response counts
#'   as fast.
#' @param max_fast Largest acceptable proportion of fast responses.
#' @param max_same Largest acceptable proportion of identical responses.
#' @param min_responses Fewest responses in a task for the `same_response`
#'   check to apply.
#' @param balance Largest acceptable ratio between the largest and the
#'   smallest group of a randomiser node.
#'
#' @return A tibble with columns `check`, `participant_private_id`,
#'   `task_name` and `detail`, with no rows if nothing was found.
#'
#' @seealso [summary.gorilla_data()] for an overview of each task.
#'
#' @examples
#' g <- read_gorilla(gorilla_example(), quiet = TRUE)
#' gorilla_checks(g)
#' @export
gorilla_checks <- function(x, fast = 200, max_fast = 0.1, max_same = 0.9,
                           min_responses = 10, balance = 1.5) {
  check_gorilla(x)
  check_number(fast, "fast", min = 0)
  check_number(max_fast, "max_fast", min = 0, max = 1)
  check_number(max_same, "max_same", min = 0, max = 1)
  check_number(min_responses, "min_responses", min = 0)
  check_number(balance, "balance", min = 1)
  p <- x$participants
  out <- list()
  if (!is.null(p)) {
    # Without a status column in the export there is nothing to check.
    incomplete <- p |>
      dplyr::filter(any(!is.na(participant_status)), !participant_status %in% "complete")
    out$status <- findings(check = "status",
                           detail = paste0("status is ", incomplete$participant_status),
                           participant_private_id = incomplete$participant_private_id)
    if ("experiment_version" %in% names(p)) {
      versions <- p |> dplyr::count(experiment_version)
      if (nrow(versions) > 1L) {
        out$versions <- findings(check = "versions", detail = paste0(
          "participants by experiment version: ",
          paste(versions$experiment_version, versions$n, sep = ": ", collapse = ", ")))
      }
    }
    if ("participant_public_id" %in% names(p)) {
      shared <- p |>
        dplyr::filter(!is.na(participant_public_id),
                      !toupper(participant_public_id) %in% c("BLIND", "BLINDED")) |>
        dplyr::mutate(n = dplyr::n(), ids = paste(participant_private_id, collapse = ", "),
                      .by = participant_public_id) |>
        dplyr::filter(n > 1L)
      out$duplicate <- findings(check = "duplicate",
                                detail = paste0("public ID shared by private IDs ", shared$ids),
                                participant_private_id = shared$participant_private_id)
    }
    for (col in grep("^randomiser_", names(p), value = TRUE)) {
      n <- table(p[[col]])
      if (length(n) > 1L && max(n) / min(n) > balance) {
        out[[col]] <- findings(check = "unbalanced", detail = paste0(
          sub("_", "-", col), " groups: ", paste(names(n), n, sep = ": ", collapse = ", ")))
      }
    }
    if ("participant_device_type" %in% names(p)) {
      devices <- p |> dplyr::filter(!is.na(participant_device_type)) |>
        dplyr::count(participant_device_type, sort = TRUE)
      if (nrow(devices) > 1L) {
        main <- devices$participant_device_type[1L]
        odd <- p |> dplyr::filter(!is.na(participant_device_type), participant_device_type != main)
        out$device <- findings(check = "device",
                               detail = paste0("device type ", odd$participant_device_type,
                                               "; most participants used ", main),
                               participant_private_id = odd$participant_private_id)
      }
    }
  }
  if (!is.null(x$tasks) && !is.null(p)) {
    node_cols <- names(p) |>
      stringr::str_subset("^(randomiser|branch|order|counterbalance|allocator)_")
    groups <- p |>
      dplyr::select(participant_private_id, dplyr::all_of(node_cols)) |>
      dplyr::mutate(signature = "")
    if (length(node_cols)) {
      groups <- groups |>
        dplyr::select(-signature) |>
        tidyr::unite("signature", dplyr::all_of(node_cols), sep = "|", na.rm = FALSE)
    }
    done <- x$tasks |>
      dplyr::filter(!is.na(task_name)) |>
      dplyr::distinct(participant_private_id, task_name)
    expected <- groups |>
      dplyr::inner_join(done, by = "participant_private_id") |>
      dplyr::count(signature, task_name, name = "did") |>
      dplyr::left_join(dplyr::count(groups, signature, name = "size"), by = "signature") |>
      dplyr::filter(size >= 2L, did > size / 2)
    missing <- groups |>
      dplyr::inner_join(expected, by = "signature", relationship = "many-to-many") |>
      dplyr::anti_join(done, by = c("participant_private_id", "task_name"))
    out$missing <- findings(
      check = "missing_task",
      detail = paste0("not done, although ", missing$did, " of ", missing$size,
                      " participants with the same node outcomes did it"),
      participant_private_id = missing$participant_private_id,
      task_name = missing$task_name
    )
  }
  if (!is.null(x$tasks)) {
    tr <- gorilla_trials(x, quiet = TRUE)
    # Components that recorded no response values: the object is the answer.
    no_value <- empty_responses(tr) |> dplyr::mutate(no_value = TRUE)
    tr <- tr |>
      dplyr::left_join(no_value, by = c("task_name", "component")) |>
      dplyr::mutate(response = dplyr::if_else(no_value %in% TRUE, object, response))
    speed <- tr |>
      dplyr::summarise(n = dplyr::n(), timed = sum(!is.na(rt)),
                       quick = sum(rt < fast, na.rm = TRUE),
                       .by = c(participant_private_id, task_name)) |>
      dplyr::filter(timed > 0L, quick / timed > max_fast)
    out$fast <- findings(
      check = "fast",
      detail = sprintf("%.0f%% of %d responses faster than %g ms",
                       100 * speed$quick / speed$timed, speed$n, fast),
      participant_private_id = speed$participant_private_id,
      task_name = speed$task_name
    )
    answered <- tr |> dplyr::filter(!is.na(response))
    options <- answered |>
      dplyr::summarise(options = dplyr::n_distinct(response), .by = task_name)
    same <- answered |>
      dplyr::count(participant_private_id, task_name, response) |>
      dplyr::mutate(total = sum(n), .by = c(participant_private_id, task_name)) |>
      dplyr::slice_max(n, n = 1L, with_ties = FALSE, by = c(participant_private_id, task_name)) |>
      dplyr::left_join(options, by = "task_name") |>
      dplyr::filter(total >= min_responses, options > 1L, n / total > max_same)
    out$same <- findings(
      check = "same_response",
      detail = sprintf("response '%s' in %d of %d responses", same$response, same$n, same$total),
      participant_private_id = same$participant_private_id,
      task_name = same$task_name
    )
  }
  c(list(findings(check = character(), detail = character())), out) |> dplyr::bind_rows()
}
