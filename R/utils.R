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
