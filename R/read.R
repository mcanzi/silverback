meta_cols <- c(
  "Event Index", "UTC Timestamp", "UTC Date and Time", "Local Timestamp",
  "Local Timezone", "Local Date and Time", "Experiment ID", "Experiment Version",
  "Tree Node Key", "Repeat Key", "Schedule ID", "Participant Public ID",
  "Participant Private ID", "Participant Starting Group", "Participant Status",
  "Participant Completion Code", "Participant External Session ID",
  "Participant Device Type", "Participant Device", "Participant OS",
  "Participant Browser", "Participant Monitor Size", "Participant Viewport Size",
  "Checkpoint", "Room ID", "Room Order", "Task Name", "Task Version",
  "Randomise questionnaire elements?"
)

tb1_cols <- c(
  "Spreadsheet", "Spreadsheet Name", "Spreadsheet Row", "Trial Number",
  "Screen Number", "Screen Name", "Zone Name", "Zone Type", "Reaction Time",
  "Reaction Onset", "Response Type", "Response", "Attempt", "Correct",
  "Incorrect", "Dishonest", "X Coordinate", "Y Coordinate", "Timed Out"
)

node_types <- c("randomiser", "branch", "checkpoint", "order", "counterbalance", "repeat",
                "switch", "delay", "quota", "redirect", "reject", "allocator")
node_col_pattern <- paste0("^(", paste(node_types, collapse = "|"), ")-")

#' Read Gorilla exports
#'
#' Reads the CSV files downloaded from the Data tab of the 'Gorilla'
#' Experiment Builder and sorts them into tasks, questionnaires and
#' participants. Both kinds of download are read: one file per node of the
#' experiment tree (`data_exp_12345-v6_task-ab12.csv`) and the combined files
#' (`data_exp_12345-v6_tasks.csv`, `data_exp_12345-v6_questionnaires.csv`).
#'
#' Files from Task Builder 1 and 2 and from Questionnaire Builder 1 and 2
#' can be mixed, and so can files from several versions of the experiment.
#' The `END OF FILE` row at the end of each file is removed, and files from
#' nodes that no participant reached, which hold no data, are skipped. Files
#' that were opened in a spreadsheet program and saved again with semicolons
#' as separators are read too. If the files include both kinds of download,
#' a warning says so, because the same rows would then be read twice. Lines
#' with the wrong number of columns, as in a file that was cut off or edited
#' by hand, also give a warning.
#'
#' Column names are converted to snake case: `Participant Private ID`
#' becomes `participant_private_id`, `Spreadsheet: Speaker` becomes
#' `spreadsheet_speaker` and `Store: Alter` becomes `store_alter`. Spreadsheet
#' columns from Task Builder 1, which have no prefix in the export, get the
#' same `spreadsheet_` prefix.
#'
#' A column becomes numeric only if every value in it is a number without
#' leading zeros, so codes such as `007` and response keys such as `T` and
#' `F` stay text. Identifiers and responses always stay text.
#'
#' @param path Paths to folders, CSV files or ZIP archives. Folders and ZIP
#'   archives are searched recursively for CSV files whose names start with
#'   `data_exp_`, the names 'Gorilla' gives its downloads. CSV files named
#'   directly are read whatever their name. Excel downloads cannot be read;
#'   download the data as CSV instead.
#' @param quiet If `TRUE`, no message about skipped files is shown.
#'
#' @return An object of class `gorilla_data`: a list with
#' \describe{
#'   \item{tasks}{All rows of all task files, one row per event, with
#'     cleaned column names, plus `builder` (the task builder that made the
#'     file) and `file` (the file the row comes from). See [gorilla_trials()]
#'     for one row per response.}
#'   \item{questionnaires}{All questionnaire answers in long format, one row
#'     per participant and item, with columns `item`, `response`,
#'     `quantised` and `file`. See [gorilla_wide()] for one row per
#'     participant.}
#'   \item{participants}{One row per participant. See
#'     [gorilla_participants()].}
#'   \item{files}{One row per file read, with the experiment, version, node,
#'     builder, task and number of rows.}
#' }
#'
#' @seealso [gorilla_trials()], [gorilla_wide()], [gorilla_participants()]
#'
#' @examples
#' path <- gorilla_example()
#' g <- read_gorilla(path)
#' g
#' g$files
#' @export
read_gorilla <- function(path, quiet = FALSE) {
  tmp <- tempfile("silverback")
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  files <- find_gorilla_files(path, tmp)
  if (length(files) == 0L) {
    stop("No Gorilla files (data_exp_*.csv) found in `path`.", call. = FALSE)
  }
  parsed <- files |> purrr::map(read_gorilla_file)
  info <- parsed |> purrr::map("info") |> dplyr::bind_rows()
  combined <- stringr::str_detect(info$file, "_(tasks|questionnaires)\\.csv$")
  per_node <- stringr::str_detect(info$file, "_(task|questionnaire)-[a-z0-9]+\\.csv$")
  if (any(combined & info$rows > 0L) && any(per_node & info$rows > 0L)) {
    warning("The files include both combined downloads (",
            info$file[combined] |> paste(collapse = ", "),
            ") and files for single nodes. The same rows are probably read twice; ",
            "read one kind of download only.", call. = FALSE)
  }
  empty <- info$rows == 0L
  if (any(empty) && !quiet) {
    message("Skipped ", sum(empty), " file", if (sum(empty) > 1L) "s",
            " without data (nodes no participant reached): ",
            info$file[empty] |> paste(collapse = ", "))
  }
  tasks <- parsed |> purrr::map("task") |> bind()
  if (!is.null(tasks)) {
    tasks <- tasks |> convert_types(keep = c(id_cols, "response", "trial_number"))
  }
  questionnaires <- parsed |> purrr::map("questionnaire") |> bind()
  if (!is.null(questionnaires)) {
    questionnaires <- questionnaires |>
      dplyr::mutate(experiment_version = as_num(experiment_version),
                    quantised = as_num(quantised))
  }
  out <- list(
    tasks = tasks,
    questionnaires = questionnaires,
    participants = parsed |> purrr::map("meta") |> build_participants(),
    files = info
  )
  class(out) <- "gorilla_data"
  out
}

find_gorilla_files <- function(path, tmp) {
  if (!is.character(path) || length(path) == 0L) {
    stop("`path` must be one or more paths to folders, CSV files or ZIP files.", call. = FALSE)
  }
  path |>
    purrr::map(\(p) {
      if (dir.exists(p)) {
        listed <- list.files(p, recursive = TRUE, full.names = TRUE)
        listed <- listed[!stringr::str_detect(listed, "(^|/)__MACOSX/|(^|/)\\._")]
        name <- basename(listed)
        excel <- name |>
          stringr::str_detect(stringr::regex("^data_exp_.*\\.xlsx$", ignore_case = TRUE))
        if (any(excel)) {
          warning("Skipped ", sum(excel), " Excel file", if (sum(excel) > 1L) "s",
                  ". Download the data from Gorilla as CSV to read them.", call. = FALSE)
        }
        listed[stringr::str_detect(name, stringr::regex("^data_exp_.*\\.csv$", ignore_case = TRUE))]
      } else if (file.exists(p) &&
                 stringr::str_detect(p, stringr::regex("\\.zip$", ignore_case = TRUE))) {
        dest <- file.path(tmp, length(list.files(tmp)) + 1L)
        dir.create(dest, recursive = TRUE, showWarnings = FALSE)
        utils::unzip(p, exdir = dest)
        find_gorilla_files(dest, tmp)
      } else if (file.exists(p)) {
        p
      } else {
        stop("Path not found: ", p, call. = FALSE)
      }
    }) |>
    unlist() |>
    unique()
}

parse_file_name <- function(file) {
  m <- basename(file) |>
    stringr::str_match("^data_exp_([0-9]+)-v([0-9]+|all)_([a-z]+)(-([a-z0-9]+))?")
  kind <- stringr::str_remove(m[1, 4], "s$")
  list(experiment = m[1, 2], version = m[1, 3], kind = kind,
       node = if (is.na(m[1, 6])) NA_character_ else paste0(kind, "-", m[1, 6]))
}

read_csv_chr <- function(file, delim = ",") {
  df <- withCallingHandlers(
    readr::read_delim(file, delim = delim,
                      col_types = readr::cols(.default = readr::col_character()),
                      na = "", trim_ws = FALSE, name_repair = "minimal",
                      progress = FALSE, lazy = FALSE),
    vroom_parse_issue = function(w) invokeRestart("muffleWarning")
  )
  if (ncol(df) == 0L) return(df)
  if (delim == "," && ncol(df) == 1L && stringr::str_detect(names(df), ";")) {
    return(read_csv_chr(file, delim = ";"))
  }
  eof <- stringr::str_trim(df[[1L]]) %in% "END OF FILE"
  bad <- readr::problems(df)$row |> unique() |> setdiff(which(eof) + 1L)
  if (length(bad)) {
    warning(basename(file), ": ", length(bad), " line", if (length(bad) > 1L) "s",
            " with the wrong number of columns (line ",
            bad |> utils::head(5L) |> paste(collapse = ", "),
            if (length(bad) > 5L) ", ...", "). The file may have been edited or cut off.",
            call. = FALSE)
  }
  df[!eof, ]
}

detect_builder <- function(cols, kind) {
  if ("Zone Type" %in% cols) return("task_builder_1")
  if ("Component Name" %in% cols || all(c("Display", "Screen") %in% cols)) {
    return("task_builder_2")
  }
  if ("Question Key" %in% cols && "Key" %in% cols) return("questionnaire_mixed")
  if ("Question Key" %in% cols) return("questionnaire_builder_1")
  if (all(c("Key", "Response Type") %in% cols)) return("questionnaire_builder_2")
  if (identical(kind, "task")) return("task_unknown")
  if (any(stringr::str_detect(cols, " object-[0-9]+ "))) return("questionnaire_builder_2_wide")
  "questionnaire_builder_1_wide"
}

read_gorilla_file <- function(file) {
  raw <- read_csv_chr(file)
  if (!"Participant Private ID" %in% names(raw)) {
    stop(basename(file), " does not look like a Gorilla export: it has no ",
         "`Participant Private ID` column.", call. = FALSE)
  }
  fn <- parse_file_name(file)
  builder <- detect_builder(names(raw), fn$kind)
  kind <- if (startsWith(builder, "task")) "task" else "questionnaire"
  values <- function(col, fallback) {
    if (nrow(raw) == 0L || !col %in% names(raw)) return(fallback)
    v <- raw[[col]] |> stats::na.omit() |> unique()
    if (length(v) == 0L) fallback else v[order(as_num(v), v)] |> paste(collapse = ", ")
  }
  info <- tibble::tibble(
    file = basename(file),
    experiment = values("Experiment ID", fn$experiment),
    version = values("Experiment Version", fn$version),
    node = values("Tree Node Key", fn$node),
    kind = kind,
    builder = builder,
    task = values("Task Name", NA_character_),
    rows = nrow(raw)
  )
  out <- list(info = info, task = NULL, questionnaire = NULL, meta = NULL)
  if (nrow(raw) == 0L) return(out)
  out$meta <- raw |>
    dplyr::select(dplyr::any_of(meta_cols), dplyr::matches(node_col_pattern),
                  dplyr::starts_with("Store: "))
  if (kind == "task") {
    if (builder == "task_builder_1") {
      extra <- setdiff(names(raw), c(meta_cols, tb1_cols))
      extra <- extra[!stringr::str_detect(extra, node_col_pattern) &
                       !stringr::str_detect(extra, "^(Manipulation|Store|Spreadsheet): ")]
      raw <- raw |> dplyr::rename_with(\(n) paste0("Spreadsheet: ", n), dplyr::all_of(extra))
    }
    out$task <- raw |>
      dplyr::rename_with(clean_names) |>
      dplyr::mutate(builder = builder, file = basename(file))
  } else {
    out$questionnaire <- questionnaire_long(raw, builder)
    if (!is.null(out$questionnaire)) {
      out$questionnaire <- out$questionnaire |> dplyr::mutate(file = basename(file))
    }
  }
  out
}
