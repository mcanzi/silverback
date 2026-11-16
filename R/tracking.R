#' Read eye tracking data
#'
#' Reads the files that the Eye Tracking (Webgazer) component of Task
#' Builder 2 saves for each trial. 'Gorilla' does not put these recordings in
#' the main export but in files of their own, named like
#' `123456-3-9100037-task-ab12-50000037-collection-10-2.csv` (gaze) and
#' `...-calibration-1-2.csv` (calibration).
#'
#' Positions are given in normalised coordinates: `0` to `1` across the
#' area of the task, with the origin at the bottom left, as in the export.
#' Raw coordinates in pixels are kept as `x_raw` and `y_raw`, but they depend
#' on the participant's screen. Predictions outside the area of the task,
#' below `0` or above `1`, are kept; webcam eye tracking produces them when
#' participants look away or the prediction is poor.
#'
#' Each gaze sample is assigned to the zone of the screen it falls in. When
#' zones overlap, the smallest zone containing the sample wins. Use `zones`
#' to test only some zones, for example the pictures of a visual world task
#' and not the response buttons placed on them.
#'
#' The recordings do not say which task they belong to or, for gaze data, the
#' name of the screen. Pass the main export as `x` to add `task_name` and
#' `screen`, so that the samples can be joined to [gorilla_trials()] by
#' `participant_private_id`, `tree_node_key`, `display`, `trial` and `screen`.
#'
#' @param path Paths to folders, CSV files or ZIP archives. Folders and ZIP
#'   archives are searched recursively for files whose names contain
#'   `-collection-` or `-calibration-`. CSV files named directly are read
#'   whatever their name.
#' @param x Optional `gorilla_data` object from [read_gorilla()] of the same
#'   experiment, used to add the task and screen names.
#' @param zones Names of the zones to assign samples to. All by default.
#' @param quiet If `TRUE`, no message about files that could not be used is
#'   shown.
#'
#' @return An object of class `gorilla_eyetracking`: a list with
#' \describe{
#'   \item{gaze}{One row per gaze sample, with the participant, node, task,
#'     spreadsheet, trial and screen, the kind of sample (`type`, usually
#'     `"prediction"`), the time of the sample in UTC
#'     (`time`), the time since the start of the recording in milliseconds
#'     (`elapsed`), the predicted gaze position (`x`, `y`, `x_raw`, `y_raw`)
#'     and the zone it falls in (`zone_id`, `zone_name`).}
#'   \item{zones}{One row per zone and recording, with the object ID
#'     (`zone_id`), the name, and the edges `left`, `right`, `bottom` and
#'     `top` in normalised coordinates.}
#'   \item{calibration}{One row per calibration point and attempt, with the
#'     outcome of the attempt (`"succeeded"`, `"failed - retrying"` or
#'     `"failed - max failures"`), the position of the point, the centre and
#'     standard deviation of the gaze predictions while the participant
#'     looked at it, and `error`, the distance between point and centre,
#'     all in normalised coordinates.
#'     Attempts that ended before any point was measured have one row with
#'     missing point values.}
#'   \item{files}{One row per file read, with its kind and number of rows.}
#' }
#'
#' @seealso [read_mousetracking()] for the Mouse Tracking component.
#'
#' @examples
#' \dontrun{
#' g <- read_gorilla("data")
#' eye <- read_eyetracking("data", x = g)
#' eye$gaze
#' eye$calibration
#' }
#' @export
read_eyetracking <- function(path, x = NULL, zones = NULL, quiet = FALSE) {
  if (!is.null(x)) check_gorilla(x)
  parts <- read_tracking(path, "-(collection|calibration)-", c("collection", "calibration"),
                         quiet = quiet)
  gaze <- NULL
  zone_table <- NULL
  if (!is.null(parts$collection)) {
    d <- parts$collection
    zone_table <- tracking_zones(d, x)
    p <- d |> dplyr::filter(!type %in% "zone")
    gaze <- tracking_keys(p, x) |>
      dplyr::mutate(type = as.character(col_of(p, "type")),
                    time = as_time(col_of(p, "timestamp")),
                    elapsed = as_num(col_of(p, "elapsed")),
                    x = as_num(col_of(p, "predicted_gaze_x_normalised")),
                    y = as_num(col_of(p, "predicted_gaze_y_normalised")),
                    x_raw = as_num(col_of(p, "predicted_gaze_x")),
                    y_raw = as_num(col_of(p, "predicted_gaze_y"))) |>
      assign_zones(zone_table, zones)
  }
  out <- list(
    gaze = gaze,
    zones = zone_table,
    calibration = if (!is.null(parts$calibration)) calibration_points(parts$calibration, x),
    files = parts$files
  )
  class(out) <- "gorilla_eyetracking"
  out
}

#' Read mouse tracking data
#'
#' Reads the files that the Mouse Tracking component of Task Builder 2 saves
#' for each trial. 'Gorilla' does not put these recordings in the main export
#' but in files of their own, named like
#' `123456-3-9100037-task-ab12-50000037-mousetracking-10-2.csv`.
#'
#' Positions are given in normalised coordinates: `0` to `1` across the area
#' of the task, with the origin at the bottom left, as in the export. Raw
#' coordinates in pixels are kept as `x_raw` and `y_raw`; in these, as
#' recorded by the browser, `y` counts from the top of the window.
#'
#' Each sample is assigned to the zone of the screen it falls in. When zones
#' overlap, the smallest zone containing the sample wins. Use `zones` to
#' test only some zones.
#'
#' The recordings do not say which task they belong to. Pass the main export
#' as `x` to add `task_name`, so that the samples can be joined to
#' [gorilla_trials()] by `participant_private_id`, `tree_node_key`, `display`,
#' `trial` and `screen`.
#'
#' @inheritParams read_eyetracking
#' @param path Paths to folders, CSV files or ZIP archives. Folders and ZIP
#'   archives are searched recursively for files whose names contain
#'   `-mousetracking-`. CSV files named directly are read whatever their name.
#'
#' @return An object of class `gorilla_mousetracking`: a list with
#' \describe{
#'   \item{mouse}{One row per sample, with the participant, node, task,
#'     spreadsheet, trial and screen, the kind of sample (`type`, usually
#'     `"mouse"`), a timer of the browser in milliseconds (`timestamp`, not
#'     a date), the time since the start of the recording in
#'     milliseconds (`elapsed`), the position of the pointer (`x`, `y`,
#'     `x_raw`, `y_raw`) and the zone it is in (`zone_id`, `zone_name`).}
#'   \item{zones}{One row per zone and recording, with the object ID
#'     (`zone_id`), the name, and the edges `left`, `right`, `bottom` and
#'     `top` in normalised coordinates.}
#'   \item{files}{One row per file read, with its kind and number of rows.}
#' }
#'
#' @seealso [read_eyetracking()] for the Eye Tracking component.
#'
#' @examples
#' \dontrun{
#' g <- read_gorilla("data")
#' mouse <- read_mousetracking("data", x = g)
#' mouse$mouse
#' }
#' @export
read_mousetracking <- function(path, x = NULL, zones = NULL, quiet = FALSE) {
  if (!is.null(x)) check_gorilla(x)
  parts <- read_tracking(path, "-mousetracking-", "mousetracking", quiet = quiet)
  d <- parts$mousetracking
  zone_table <- tracking_zones(d, x)
  m <- d |> dplyr::filter(!type %in% "zone")
  mouse <- tracking_keys(m, x) |>
    dplyr::mutate(type = as.character(col_of(m, "type")),
                  timestamp = as_num(col_of(m, "timestamp")),
                  elapsed = as_num(col_of(m, "elapsed")),
                  x = as_num(col_of(m, "x_normalised")),
                  y = as_num(col_of(m, "y_normalised")),
                  x_raw = as_num(col_of(m, "x_raw")),
                  y_raw = as_num(col_of(m, "y_raw"))) |>
    assign_zones(zone_table, zones)
  out <- list(mouse = mouse, zones = zone_table, files = parts$files)
  class(out) <- "gorilla_mousetracking"
  out
}

# Reads the recordings and sorts them by kind. Files with the same header are
# read together, which is much faster than one file at a time.
read_tracking <- function(path, pattern, kinds, quiet = FALSE) {
  tmp <- tempfile("silverback")
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  files <- find_gorilla_files(path, tmp, pattern = paste0(pattern, ".*\\.csv$"))
  if (length(files) == 0L) {
    stop("No ", paste(kinds, collapse = " or "), " files found in `path`.", call. = FALSE)
  }
  header <- purrr::map_chr(files, \(f) {
    first <- readLines(f, n = 1L, warn = FALSE)
    if (length(first)) first else ""
  })
  groups <- split(files, header)
  read <- purrr::map(groups, \(fs) {
    d <- withCallingHandlers(
      readr::read_delim(fs, delim = detect_delim(fs[1L]), id = "file",
                        col_types = readr::cols(.default = readr::col_character()),
                        na = "", trim_ws = FALSE, name_repair = "minimal",
                        progress = FALSE, lazy = FALSE),
      vroom_parse_issue = function(w) invokeRestart("muffleWarning")
    )
    bad <- nrow(readr::problems(d))
    if (bad) {
      warning(bad, " line", if (bad > 1L) "s", " with the wrong number of columns in ",
              length(fs), " recording", if (length(fs) > 1L) "s", " starting with ",
              basename(fs[1L]), ". Files may have been edited or cut off.", call. = FALSE)
    }
    d <- d |>
      dplyr::rename_with(clean_names, -file) |>
      dplyr::mutate(file = file_names(fs, file))
    if (ncol(d) < 2L) return(d)
    d |> dplyr::filter(!stringr::str_trim(dplyr::pick(2L)[[1L]]) %in% "END OF FILE")
  })
  kind <- purrr::map_chr(read, tracking_kind)
  info <- seq_along(read) |>
    purrr::map(\(i) {
      tibble::tibble(file = basename(groups[[i]]), kind = kind[[i]]) |>
        dplyr::left_join(dplyr::count(read[[i]], file, name = "rows"), by = "file") |>
        dplyr::mutate(rows = dplyr::coalesce(rows, 0L))
    }) |>
    dplyr::bind_rows()
  unused <- info$file[!info$kind %in% kinds | info$rows == 0L]
  if (length(unused) && !quiet) {
    message("Skipped ", length(unused), " file", if (length(unused) > 1L) "s",
            " without ", paste(kinds, collapse = " or "), " data: ",
            unused |> utils::head(5L) |> paste(collapse = ", "),
            if (length(unused) > 5L) ", ...")
  }
  out <- kinds |>
    purrr::set_names() |>
    purrr::map(\(k) {
      # Sorting is stable, so rows keep their order within each file.
      rows <- bind(read[kind == k])
      if (is.null(rows)) rows else dplyr::arrange(rows, file)
    })
  if (all(purrr::map_lgl(out, is.null))) {
    stop("No ", paste(kinds, collapse = " or "), " data found in `path`.", call. = FALSE)
  }
  out$files <- info |> dplyr::arrange(kind, file)
  out
}

# The `file` column that readr adds is very slow to access for thousands of
# files. The number of rows per file is the number of lines minus the header
# unless a value contains a line break or there are blank lines, so count the
# lines and fall back to readr's column if the totals disagree.
file_names <- function(fs, id) {
  rows <- purrr::map_int(fs, \(f) {
    bytes <- readBin(f, "raw", file.size(f))
    newline <- as.raw(10L)
    sum(bytes == newline) + (length(bytes) > 0L && bytes[length(bytes)] != newline) - 1L
  })
  rows <- pmax(rows, 0L)
  if (sum(rows) == length(id)) rep(basename(fs), rows) else basename(id)
}

tracking_kind <- function(d) {
  cols <- names(d)
  if (!"participant_private_id" %in% cols || !"type" %in% cols) return("unknown")
  if ("x_of_point_normalised" %in% cols) return("calibration")
  if ("predicted_gaze_x_normalised" %in% cols) return("collection")
  if (all(c("x_normalised", "unique_id") %in% cols)) return("mousetracking")
  "unknown"
}

tracking_keys <- function(d, x = NULL) {
  keys <- tibble::tibble(
    participant_private_id = as.character(col_of(d, "participant_private_id")),
    experiment_version = as_num(col_of(d, "experiment_version")),
    tree_node_key = as.character(col_of(d, "tree_node_key")),
    task_name = NA_character_,
    spreadsheet = as.character(col_of(d, "spreadsheet")),
    spreadsheet_index = as_num(col_of(d, "spreadsheet_index")),
    display = as.character(col_of(d, "display")),
    trial = as_num(col_of(d, "trial_number", "trial_count")),
    screen = as.character(col_of(d, "screen")),
    screen_id = as.character(col_of(d, "screen_id")),
    file = d$file
  )
  add_task_info(keys, x)
}

# The recordings have the node but not the task name, and gaze recordings
# leave the screen name empty. Both are in the main export.
add_task_info <- function(keys, x) {
  tasks <- if (!is.null(x)) x$tasks
  if (is.null(tasks) || nrow(keys) == 0L) return(keys)
  text <- function(col) as.character(col_of(tasks, col))
  ref <- tibble::tibble(tree_node_key = text("tree_node_key"), task = text("task_name"),
                        screen_id = text("screen_id"), screen_name = text("screen"))
  nodes <- ref |>
    dplyr::filter(!is.na(task)) |>
    dplyr::distinct(tree_node_key, .keep_all = TRUE) |>
    dplyr::select(tree_node_key, task)
  screens <- ref |>
    dplyr::filter(!is.na(screen_id), !is.na(screen_name)) |>
    dplyr::distinct(tree_node_key, screen_id, .keep_all = TRUE) |>
    dplyr::select(tree_node_key, screen_id, screen_name)
  keys |>
    dplyr::left_join(nodes, by = "tree_node_key") |>
    dplyr::left_join(screens, by = c("tree_node_key", "screen_id")) |>
    dplyr::mutate(task_name = dplyr::coalesce(task_name, task),
                  screen = dplyr::coalesce(screen, screen_name)) |>
    dplyr::select(-task, -screen_name)
}

# Zones are given by their top left corner, with the origin of the
# coordinates at the bottom left, so a zone reaches down from `y` to `y - h`.
tracking_zones <- function(d, x = NULL) {
  z <- d |> dplyr::filter(type %in% "zone")
  num <- function(...) as_num(col_of(z, ...))
  left <- num("zone_x_normalised", "x_normalised")
  top <- num("zone_y_normalised", "y_normalised")
  tracking_keys(z, x) |>
    dplyr::mutate(zone_id = as.character(col_of(z, "zone_uid", "unique_id")),
                  zone_name = as.character(col_of(z, "zone_name", "name")),
                  left = left,
                  right = left + num("zone_w_normalised", "w_normalised"),
                  bottom = top - num("zone_h_normalised", "h_normalised"),
                  top = top) |>
    dplyr::distinct(file, zone_id, .keep_all = TRUE)
}

assign_zones <- function(samples, zone_table, names = NULL) {
  samples <- samples |> dplyr::mutate(zone_id = NA_character_, zone_name = NA_character_)
  if (is.null(zone_table) || nrow(zone_table) == 0L || nrow(samples) == 0L) return(samples)
  z <- zone_table |>
    dplyr::filter(is.null(names) | zone_name %in% names,
                  !is.na(left), !is.na(right), !is.na(bottom), !is.na(top)) |>
    dplyr::transmute(file, hit_id = zone_id, hit_name = zone_name, left, right, bottom, top,
                     area = (right - left) * (top - bottom))
  # An inequality join finds every zone containing a sample; the smallest wins.
  hits <- samples |>
    dplyr::transmute(.row = dplyr::row_number(), file, px = x, py = y) |>
    dplyr::filter(!is.na(px), !is.na(py)) |>
    dplyr::inner_join(z, by = dplyr::join_by(file, px >= left, px <= right,
                                             py >= bottom, py <= top)) |>
    dplyr::arrange(.row, area) |>
    dplyr::distinct(.row, .keep_all = TRUE)
  samples |>
    dplyr::mutate(.row = dplyr::row_number()) |>
    dplyr::left_join(dplyr::select(hits, .row, hit_id, hit_name), by = ".row") |>
    dplyr::mutate(zone_id = hit_id, zone_name = hit_name) |>
    dplyr::select(-.row, -hit_id, -hit_name)
}

calibration_points <- function(d, x = NULL) {
  outcome_types <- c("calibration succeeded", "calibration failed - retrying",
                     "calibration failed - max failures")
  d <- d |>
    dplyr::mutate(attempt = 1L + cumsum(dplyr::lag(type %in% "calibration failed - retrying",
                                                   default = FALSE)),
                  .by = file)
  outcomes <- d |>
    dplyr::filter(type %in% outcome_types) |>
    dplyr::transmute(file, attempt, outcome = stringr::str_remove(type, "^calibration ")) |>
    dplyr::distinct(file, attempt, .keep_all = TRUE)
  p <- d |> dplyr::filter(type %in% "accuracy")
  num <- function(col) as_num(col_of(p, col))
  points <- tracking_keys(p, x) |>
    dplyr::mutate(attempt = p$attempt,
                  point_x = num("x_of_point_normalised"),
                  point_y = num("y_of_point_normalised"),
                  centroid_x = num("x_of_centroid_normalised"),
                  centroid_y = num("y_of_centroid_normalised"),
                  sd_x = num("sd_of_x_centroid_normalised"),
                  sd_y = num("sd_of_y_centroid_normalised"),
                  error = sqrt((centroid_x - point_x)^2 + (centroid_y - point_y)^2))
  # Attempts that failed before any point was measured still get a row.
  bare <- d |>
    dplyr::distinct(file, .keep_all = TRUE) |>
    dplyr::select(-attempt) |>
    dplyr::inner_join(outcomes |> dplyr::anti_join(points, by = c("file", "attempt")),
                      by = "file")
  if (nrow(bare)) {
    points <- points |>
      dplyr::bind_rows(tracking_keys(bare, x) |> dplyr::mutate(attempt = bare$attempt))
  }
  points |>
    dplyr::left_join(outcomes, by = c("file", "attempt")) |>
    dplyr::relocate(attempt, outcome, .after = screen_id) |>
    dplyr::arrange(participant_private_id, file, attempt)
}

#' @export
print.gorilla_eyetracking <- function(x, ...) {
  cat("<gorilla_eyetracking>\n")
  if (!is.null(x$gaze)) {
    cat(plural(nrow(x$gaze), "gaze sample"), " from ",
        plural(dplyr::n_distinct(x$gaze$participant_private_id), "participant"), " in ",
        plural(dplyr::n_distinct(x$gaze$file), "recording"), "; ",
        round(100 * mean(!is.na(x$gaze$zone_id)), 1), "% in a zone\n", sep = "")
  }
  if (!is.null(x$calibration)) {
    attempts <- x$calibration |> dplyr::distinct(file, attempt, outcome)
    cat(plural(nrow(attempts), "calibration attempt"), " (",
        paste(names(table(attempts$outcome)), table(attempts$outcome), sep = ": ",
              collapse = ", "), ")\n", sep = "")
  }
  invisible(x)
}

#' @export
print.gorilla_mousetracking <- function(x, ...) {
  cat("<gorilla_mousetracking>\n")
  cat(plural(nrow(x$mouse), "sample"), " from ",
      plural(dplyr::n_distinct(x$mouse$participant_private_id), "participant"), " in ",
      plural(dplyr::n_distinct(x$mouse$file), "recording"), "; ",
      round(100 * mean(!is.na(x$mouse$zone_id)), 1), "% in a zone\n", sep = "")
  invisible(x)
}

plural <- function(n, word) {
  paste0(format(n, big.mark = ","), " ", word, if (n != 1L) "s")
}
