clean_names <- function(x) {
  x <- x |>
    stringr::str_trim() |>
    stringr::str_to_lower() |>
    stringr::str_replace_all("\\W+", "_") |>
    stringr::str_replace_all("_+", "_") |>
    stringr::str_remove_all("^_|_$")
  x[x == ""] <- "x"
  make.unique(x, sep = "_")
}

bind <- function(dfs) {
  out <- dplyr::bind_rows(dfs)
  if (nrow(out) == 0L) NULL else out
}

col_of <- function(d, ...) {
  for (col in c(...)) if (col %in% names(d)) return(d[[col]])
  rep(NA, nrow(d))
}

convert_value <- function(v) {
  if (!is.character(v)) return(v)
  v[v %in% c("", "NA")] <- NA_character_
  distinct <- unique(v[!is.na(v)])
  if (length(distinct) == 0L) return(rep(NA, length(v)))
  number <- "^-?(0|[1-9][0-9]*)(\\.[0-9]+)?([eE][-+]?[0-9]+)?$"
  if (!all(stringr::str_detect(distinct, number))) return(v)
  num <- as.numeric(v)
  whole <- !any(stringr::str_detect(distinct, "[.eE]")) &&
    all(abs(num) < .Machine$integer.max, na.rm = TRUE)
  if (whole) as.integer(num) else num
}

convert_types <- function(df, keep = character()) {
  df |>
    dplyr::mutate(
      dplyr::across(!dplyr::any_of(keep), convert_value),
      dplyr::across(dplyr::any_of(keep), as.character)
    )
}

drop_empty_cols <- function(df, keep = character()) {
  filled <- purrr::map_lgl(df, \(v) !all(is.na(v)))
  df[filled | names(df) %in% keep]
}

as_num <- function(v) {
  v |> as.numeric() |> suppressWarnings()
}

as_flag <- function(v) {
  as_num(v) != 0
}

as_time <- function(ms) {
  (as_num(ms) / 1000) |> as.POSIXct(origin = "1970-01-01", tz = "UTC")
}

is_marker <- function(v) {
  !is.na(v) & stringr::str_detect(v, "^(BEGIN|END)( TASK| QUESTIONNAIRE| OF FILE)?$")
}

id_cols <- c("participant_public_id", "participant_private_id",
             "participant_external_session_id", "participant_completion_code",
             "schedule_id", "tree_node_key", "repeat_key", "room_id")

add_missing <- function(df, cols) {
  missing <- setdiff(cols, names(df))
  df[missing] <- NA_character_
  df
}

# Rows of the same event in more than one file mean that the same data were
# read twice, for example from a second copy of a download. Events can only
# be shared by files that have the same participant and node, so only those
# rows are compared.
shared_event_files <- function(metas, files) {
  keys <- c("Participant Private ID", "Tree Node Key", "Event Index", "UTC Timestamp")
  events <- metas |>
    purrr::map2(files, \(m, f) {
      if (is.null(m) || !all(keys %in% names(m))) return(NULL)
      m |>
        dplyr::select(dplyr::all_of(keys), dplyr::any_of("Repeat Key")) |>
        dplyr::rename_with(clean_names) |>
        dplyr::mutate(.file = f)
    }) |>
    dplyr::bind_rows()
  if (nrow(events) == 0L) return(character())
  both <- events |>
    dplyr::distinct(participant_private_id, tree_node_key, .file) |>
    dplyr::filter(dplyr::n() > 1L, .by = c(participant_private_id, tree_node_key))
  if (nrow(both) == 0L) return(character())
  events |>
    dplyr::semi_join(both, by = c("participant_private_id", "tree_node_key", ".file")) |>
    dplyr::filter(!is.na(event_index), !is.na(utc_timestamp)) |>
    dplyr::distinct() |>
    dplyr::filter(dplyr::n_distinct(.file) > 1L, .by = -.file) |>
    dplyr::pull(.file) |>
    unique()
}

check_flag <- function(x, arg) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    stop("`", arg, "` must be TRUE or FALSE.", call. = FALSE)
  }
}

check_number <- function(x, arg, min = -Inf, max = Inf) {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) || x < min || x > max) {
    range <- if (is.finite(max)) paste0(" between ", min, " and ", max) else
      if (is.finite(min)) paste0(" of at least ", min) else ""
    stop("`", arg, "` must be a single number", range, ".", call. = FALSE)
  }
}

check_names <- function(x, arg) {
  if (!is.null(x) && !is.character(x)) {
    stop("`", arg, "` must be a character vector or NULL.", call. = FALSE)
  }
}
