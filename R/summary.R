share <- function(v) if (length(v)) v |> mean(na.rm = TRUE) |> round(3) else NA_real_

#' Summarise Gorilla data
#'
#' Describes each task and questionnaire in one row, as a first check of the
#' data after reading them.
#'
#' @param object A `gorilla_data` object from [read_gorilla()].
#' @param fast,slow Reaction times in milliseconds below `fast` or above
#'   `slow` are counted as fast or slow responses.
#' @param ... Not used.
#'
#' @return An object of class `gorilla_summary`: a list with two tibbles.
#' \describe{
#'   \item{tasks}{One row per task: builder, number of participants, number
#'     of responses per participant (minimum, median and maximum), the
#'     proportion of responses marked as correct, the median reaction time,
#'     the proportions of fast and slow responses and the median time
#'     participants spent on the task, in minutes. The proportion correct
#'     only means something for tasks with scoring set up in 'Gorilla':
#'     components without scoring mark every response as correct, and rating
#'     scales count a response as correct only if it matches the answer
#'     column of the spreadsheet.}
#'   \item{questionnaires}{One row per questionnaire: number of participants,
#'     number of items and the proportion of items left unanswered.}
#' }
#'
#' @seealso [gorilla_checks()] to list participants who may need a closer
#'   look.
#'
#' @examples
#' g <- read_gorilla(gorilla_example(), quiet = TRUE)
#' summary(g)
#' summary(g)$tasks
#' @export
summary.gorilla_data <- function(object, fast = 200, slow = 10000, ...) {
  out <- list(tasks = NULL, questionnaires = NULL)
  if (!is.null(object$tasks)) {
    tr <- gorilla_trials(object)
    tasks <- object$tasks |>
      dplyr::summarise(
        builder = builder |> unique() |> paste(collapse = ", ") |>
          stringr::str_replace_all("task_builder_", "Task Builder "),
        participants = dplyr::n_distinct(participant_private_id),
        .by = task_name
      )
    responses <- tr |>
      dplyr::count(task_name, participant_private_id) |>
      dplyr::summarise(responses_min = min(n), responses_median = stats::median(n),
                       responses_max = max(n), .by = task_name)
    scores <- tr |>
      dplyr::summarise(correct = share(correct),
                       rt_median = rt |> stats::median(na.rm = TRUE) |> round(1),
                       fast = share(rt < fast), slow = share(rt > slow),
                       .by = task_name)
    minutes <- object$tasks |>
      dplyr::mutate(t = as_num(utc_timestamp)) |>
      dplyr::summarise(span = if (all(is.na(t))) NA_real_ else t |> range(na.rm = TRUE) |> diff(),
                       .by = c(participant_private_id, task_name)) |>
      dplyr::summarise(minutes = stats::median(span / 60000, na.rm = TRUE) |> round(1),
                       .by = task_name)
    out$tasks <- tasks |>
      dplyr::left_join(responses, by = "task_name") |>
      dplyr::left_join(scores, by = "task_name") |>
      dplyr::left_join(minutes, by = "task_name") |>
      dplyr::mutate(responses_min = dplyr::coalesce(responses_min, 0L),
                    responses_median = dplyr::coalesce(responses_median, 0),
                    responses_max = dplyr::coalesce(responses_max, 0L)) |>
      dplyr::arrange(task_name)
  }
  if (!is.null(object$questionnaires)) {
    q <- object$questionnaires
    answered <- q |>
      dplyr::filter(!is.na(response), response != "") |>
      dplyr::distinct(task_name, participant_private_id, item) |>
      dplyr::count(task_name, name = "cells")
    out$questionnaires <- q |>
      dplyr::summarise(participants = dplyr::n_distinct(participant_private_id),
                       items = dplyr::n_distinct(item), .by = task_name) |>
      dplyr::left_join(answered, by = "task_name") |>
      dplyr::mutate(unanswered = (1 - dplyr::coalesce(cells, 0L) / (participants * items)) |>
                      round(3)) |>
      dplyr::select(-cells) |>
      dplyr::arrange(task_name)
  }
  out$participants <- if (is.null(object$participants)) 0L else nrow(object$participants)
  out$status <- if (!is.null(object$participants)) table(object$participants$participant_status)
  class(out) <- "gorilla_summary"
  out
}

#' @export
print.gorilla_summary <- function(x, ...) {
  cat(x$participants, " participant", if (x$participants != 1L) "s", sep = "")
  if (length(x$status)) {
    cat(" (", paste(names(x$status), x$status, sep = ": ", collapse = ", "), ")", sep = "")
  }
  cat("\n")
  if (!is.null(x$tasks)) {
    cat("\nTasks\n")
    x$tasks |> as.data.frame() |> print(row.names = FALSE)
  }
  if (!is.null(x$questionnaires)) {
    cat("\nQuestionnaires\n")
    x$questionnaires |> as.data.frame() |> print(row.names = FALSE)
  }
  invisible(x)
}
