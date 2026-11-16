#' Write tidy data to CSV files
#'
#' Writes the tidy tables to a folder of CSV files, for analysis in other
#' software or for sharing. The folder gets up to four files:
#' `participants.csv` from [gorilla_participants()], `trials.csv` from
#' [gorilla_trials()], and `questionnaires.csv` from [gorilla_wide()] with
#' one row per participant. `questionnaires_long.csv` has the questionnaire
#' answers with one row per answer, as in `x$questionnaires`. Files for data
#' the export does not have are not written.
#'
#' The files are UTF-8 with a comma as separator. Missing values are left
#' empty, and times are written in ISO 8601 format in UTC. The exports contain
#' the identifiers Gorilla collected, so use [blind_ids()] first if the files
#' will be shared.
#'
#' @param x A `gorilla_data` object from [read_gorilla()].
#' @param path Folder to write to. It is created if it does not exist.
#' @param by_task Write the trials of each task to its own file, named after
#'   the task, instead of one `trials.csv`.
#' @param overwrite Replace files that already exist in `path`.
#'
#' @return The paths of the written files, invisibly.
#'
#' @examples
#' g <- read_gorilla(gorilla_example())
#' out <- file.path(tempdir(), "gorilla_csv")
#' files <- write_gorilla(g, out)
#' basename(files)
#' readr::read_csv(files[1], show_col_types = FALSE)
#' unlink(out, recursive = TRUE)
#' @export
write_gorilla <- function(x, path, by_task = FALSE, overwrite = FALSE) {
  check_gorilla(x)
  check_flag(by_task, "by_task")
  check_flag(overwrite, "overwrite")
  if (!is.character(path) || length(path) != 1L || is.na(path)) {
    stop("`path` must be a single folder name.", call. = FALSE)
  }
  if (file.exists(path) && !dir.exists(path)) {
    stop("`path` is a file, not a folder: ", path, call. = FALSE)
  }
  tables <- list(participants = gorilla_participants(x))
  if (!is.null(x$tasks)) {
    trials <- gorilla_trials(x, quiet = TRUE)
    if (by_task) {
      # Rows without a task name, from exports without that column, still get
      # a file.
      tasks <- unique(trials$task_name)
      files <- paste0("trials_", clean_names(dplyr::coalesce(tasks, "unknown task")))
      tables[files] <- tasks |>
        purrr::map(\(t) trials |> dplyr::filter(task_name %in% t) |> drop_empty_cols())
    } else {
      tables$trials <- trials
    }
  }
  if (!is.null(x$questionnaires)) {
    tables$questionnaires <- gorilla_wide(x)
    tables$questionnaires_long <- x$questionnaires
  }
  tables <- purrr::compact(tables)
  if (length(tables) == 0L) {
    message("Nothing to write: the data are empty.")
    return(invisible(character()))
  }
  files <- file.path(path, paste0(names(tables), ".csv"))
  existing <- files[file.exists(files)]
  if (length(existing) && !overwrite) {
    stop("These files exist already: ", paste(basename(existing), collapse = ", "),
         ". Use `overwrite = TRUE` to replace them.", call. = FALSE)
  }
  dir.create(path, showWarnings = FALSE, recursive = TRUE)
  purrr::walk2(tables, files, \(table, file) readr::write_csv(table, file, na = ""))
  invisible(files)
}
