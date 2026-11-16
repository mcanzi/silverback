check_gorilla <- function(x) {
  if (!inherits(x, "gorilla_data")) {
    stop("`x` must be the output of `read_gorilla()`.", call. = FALSE)
  }
  invisible(x)
}

#' @export
print.gorilla_data <- function(x, ...) {
  f <- x$files |> dplyr::filter(rows > 0L)
  if (nrow(f) == 0L) {
    cat("<gorilla_data> no data: all ", nrow(x$files), " files are empty\n", sep = "")
    return(invisible(x))
  }
  versions <- f$version |> stringr::str_split(", ") |> unlist() |> unique()
  versions <- versions[order(as_num(versions), versions)]
  n <- if (is.null(x$participants)) 0L else nrow(x$participants)
  cat("<gorilla_data> experiment ", paste(unique(f$experiment), collapse = ", "),
      ", version", if (length(versions) > 1L) "s", " ", paste(versions, collapse = ", "),
      "\n", n, " participant", if (n != 1L) "s", "\n", sep = "")
  if (!is.null(x$participants)) {
    status <- x$participants |>
      dplyr::filter(!is.na(participant_status)) |>
      dplyr::count(participant_status)
    cat("  ", paste(status$participant_status, status$n, sep = ": ", collapse = ", "), "\n",
        sep = "")
  }
  if (!is.null(x$tasks)) {
    labels <- c(task_builder_1 = "Task Builder 1", task_builder_2 = "Task Builder 2",
                task_unknown = "unknown builder")
    tasks <- x$tasks |>
      dplyr::filter(!is.na(task_name)) |>
      dplyr::summarise(builder = paste(labels[unique(builder)], collapse = ", "),
                       n = dplyr::n_distinct(participant_private_id), .by = task_name) |>
      dplyr::arrange(task_name)
    cat("Tasks:\n", paste0("  ", tasks$task_name, " (", tasks$builder, "): ", tasks$n,
                           " participants\n"), sep = "")
  }
  if (!is.null(x$questionnaires)) {
    quest <- x$questionnaires |>
      dplyr::summarise(items = dplyr::n_distinct(item),
                       n = dplyr::n_distinct(participant_private_id), .by = task_name) |>
      dplyr::arrange(task_name)
    cat("Questionnaires:\n", paste0("  ", quest$task_name, ": ", quest$items, " items, ",
                                    quest$n, " participants\n"), sep = "")
  }
  skipped <- sum(x$files$rows == 0L)
  if (skipped) cat(skipped, " empty file", if (skipped > 1L) "s", " skipped\n", sep = "")
  invisible(x)
}
