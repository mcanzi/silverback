#' Responses in task data
#'
#' Keeps the rows of the task data that hold a participant's response and
#' gives them the same columns whether the task was made with Task Builder 1
#' or 2. Rows with instructions, continue buttons, fixation crosses, media
#' events and other information are dropped.
#'
#' In Task Builder 2 a response is a row with `response_type` `"response"`.
#' In Task Builder 1 it is a row from a response zone (`zone_type` starting
#' with `response_`).
#'
#' @param x A `gorilla_data` object from [read_gorilla()].
#' @param task Names of the tasks to include, as in the `task_name` column.
#'   All by default.
#' @param all_rows Keep all rows of the trials, not only the responses. A
#'   column `response_type` then says what each row is, such as
#'   `"response"`, `"info"` or a zone type.
#'
#' @return A tibble with one row per response and columns
#' \describe{
#'   \item{participant_private_id, experiment_version, tree_node_key,
#'     repeat_key, task_name, task_version}{Who did which task, in which
#'     version and node of the experiment, with Gorilla's Repeat Key.}
#'   \item{spreadsheet}{Name of the spreadsheet used.}
#'   \item{trial}{Trial number.}
#'   \item{display, screen}{Display and screen of the response. Task
#'     Builder 1 has no displays.}
#'   \item{component, object}{Component and object that recorded the
#'     response in Task Builder 2; zone type and zone name in Task Builder 1.}
#'   \item{response}{The response, as text.}
#'   \item{rt}{Reaction time in milliseconds.}
#'   \item{correct}{Whether the response was scored as correct.}
#'   \item{time}{Time of the response, in UTC.}
#' }
#' followed by the timing columns of the export, such as `reaction_onset`
#' in Task Builder 1 or `onset_time`, `absolute_reaction_time` and
#' `response_duration` in Task Builder 2, and by the spreadsheet
#' (`spreadsheet_`) and store (`store_`) columns. Only columns with values
#' for the selected tasks are kept. All columns of the export remain in
#' `x$tasks`.
#'
#' @examples
#' g <- read_gorilla(gorilla_example())
#' gorilla_trials(g)
#' gorilla_trials(g, task = "Lexical decision")
#' @export
gorilla_trials <- function(x, task = NULL, all_rows = FALSE) {
  check_gorilla(x)
  d <- x$tasks
  if (is.null(d)) stop("The data contain no tasks.", call. = FALSE)
  if (!is.null(task)) {
    unknown <- setdiff(task, d$task_name)
    if (length(unknown)) {
      stop("Unknown task: ", paste(unknown, collapse = ", "), call. = FALSE)
    }
    d <- d |> dplyr::filter(task_name %in% task)
  }
  tb1 <- d$builder == "task_builder_1"
  zone_type <- as.character(col_of(d, "zone_type"))
  keep <- !is_marker(col_of(d, "trial_number"))
  if (!all_rows) {
    tb1_response <- !is.na(zone_type) & stringr::str_starts(zone_type, "response_")
    tb2_response <- col_of(d, "response_type") %in% "response"
    keep <- keep & dplyr::if_else(tb1, tb1_response, tb2_response)
  }
  d <- d[keep, ]
  tb1 <- tb1[keep]
  text <- function(...) as.character(col_of(d, ...))
  either <- function(builder_1, builder_2) dplyr::if_else(tb1, builder_1, builder_2)
  out <- tibble::tibble(
    participant_private_id = text("participant_private_id"),
    experiment_version = col_of(d, "experiment_version"),
    tree_node_key = text("tree_node_key"),
    repeat_key = text("repeat_key"),
    task_name = text("task_name"),
    task_version = col_of(d, "task_version"),
    spreadsheet = either(text("spreadsheet_name", "spreadsheet", "manipulation_spreadsheet"),
                         text("current_spreadsheet", "spreadsheet", "manipulation_spreadsheet")),
    trial = as_num(col_of(d, "trial_number")),
    display = either(NA_character_, text("display")),
    screen = either(text("screen_name"), text("screen")),
    component = either(text("zone_type"), text("component_name")),
    object = either(text("zone_name"), text("object_name")),
    response = text("response"),
    rt = as_num(col_of(d, "reaction_time")),
    correct = as_flag(col_of(d, "correct")),
    time = as_time(col_of(d, "utc_timestamp"))
  )
  if (all_rows) {
    out <- out |> dplyr::mutate(response_type = either(text("zone_type"), text("response_type")))
  }
  timing <- d |>
    dplyr::select(dplyr::any_of(timing_cols)) |>
    dplyr::mutate(dplyr::across(dplyr::everything(), as_num)) |>
    drop_empty_cols()
  extra <- d |>
    dplyr::select(dplyr::matches("^(spreadsheet|store)_"), -dplyr::any_of("spreadsheet_name")) |>
    drop_empty_cols()
  dplyr::bind_cols(out, timing, extra)
}

timing_cols <- c("reaction_onset", "onset_time", "clock_time", "absolute_onset_time",
                 "absolute_reaction_time", "absolute_clock_time", "response_duration")
