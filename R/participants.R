first_present <- function(v) dplyr::first(v[!is.na(v)])

last_present <- function(v) dplyr::last(v[!is.na(v)])

build_participants <- function(metas) {
  meta <- bind(metas)
  if (is.null(meta) || !"Participant Private ID" %in% names(meta)) return(NULL)
  first_cols <- c("participant_public_id", "experiment_id", "participant_starting_group",
                  "participant_completion_code", "participant_external_session_id",
                  "participant_device_type", "participant_device", "participant_os",
                  "participant_browser", "participant_monitor_size",
                  "participant_viewport_size", "local_timezone")
  last_cols <- c("experiment_version", "participant_status", "checkpoint")
  node_pattern <- paste0("^(", paste(node_types, collapse = "|"), ")_")
  meta <- meta |>
    dplyr::rename_with(clean_names) |>
    add_missing(c("task_name", "utc_timestamp", "participant_status")) |>
    dplyr::filter(!is.na(participant_private_id)) |>
    dplyr::mutate(time = as_num(utc_timestamp)) |>
    dplyr::arrange(participant_private_id, time)
  out <- meta |>
    dplyr::summarise(
      dplyr::across(dplyr::any_of(first_cols), first_present),
      dplyr::across(dplyr::any_of(last_cols), last_present),
      start = first_present(time),
      end = last_present(time),
      tasks = dplyr::n_distinct(task_name, na.rm = TRUE),
      dplyr::across(dplyr::matches(node_pattern), first_present),
      dplyr::across(dplyr::starts_with("store_"), last_present),
      .by = participant_private_id
    )
  keep <- c(intersect(id_cols, names(out)), "participant_starting_group")
  out |>
    convert_types(keep = keep) |>
    dplyr::mutate(start = as_time(start), end = as_time(end),
                  minutes = difftime(end, start, units = "mins") |> as.numeric() |> round(2)) |>
    drop_empty_cols(keep = c("participant_private_id", "participant_status", "start", "end"))
}

#' Participants
#'
#' One row per participant, with the identifiers, the status, the device,
#' operating system and browser, and the times of the first and last
#' recorded event. `tasks` counts the tasks and questionnaires the
#' participant has data for. The outcome of each randomiser, branch and
#' checkpoint node follows, and then the last value of each store field.
#' Columns that are empty for all participants are dropped.
#'
#' @param x A `gorilla_data` object from [read_gorilla()].
#' @param status Keep only participants with these values of
#'   `participant_status`, such as `"complete"`. All by default.
#'
#' @return A tibble. `start` and `end` are in UTC; `minutes` is the time
#'   between them.
#'
#' @examples
#' g <- read_gorilla(gorilla_example())
#' gorilla_participants(g)
#' @export
gorilla_participants <- function(x, status = NULL) {
  check_gorilla(x)
  check_names(status, "status")
  p <- x$participants
  if (!is.null(status)) p <- p |> dplyr::filter(participant_status %in% status)
  p
}
