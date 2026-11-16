q_keys <- c("participant_private_id", "experiment_version", "tree_node_key", "task_name")

q_ids <- function(raw) {
  tibble::tibble(
    participant_private_id = as.character(col_of(raw, "Participant Private ID")),
    experiment_version = as.character(col_of(raw, "Experiment Version")),
    tree_node_key = as.character(col_of(raw, "Tree Node Key")),
    task_name = as.character(col_of(raw, "Task Name"))
  )
}

is_quantised_key <- function(key) {
  !is.na(key) & (key == "quantised" | stringr::str_ends(key, "-quantised"))
}

item_from_key <- function(object, key) {
  base <- stringr::str_remove(key, "-quantised$")
  dplyr::case_when(
    key %in% c("value", "quantised") & !is.na(object) ~ object,
    is.na(object) ~ base,
    .default = paste0(object, "-", base)
  )
}

wide_columns <- function(cols) {
  m <- stringr::str_match(cols, "^(.*) object-[0-9]+ (.*)$")
  object <- stringr::str_trim(m[, 2])
  suffix <- stringr::str_trim(m[, 3])
  key <- dplyr::case_when(
    suffix %in% c("Response", "Value") ~ "value",
    suffix == "Quantised" ~ "quantised",
    suffix == "Other" ~ "other",
    stringr::str_detect(suffix, ". Quantised$") ~
      suffix |> stringr::str_remove(" Quantised$") |> stringr::str_trim() |> paste0("-quantised"),
    .default = suffix
  )
  tibble::tibble(
    column = cols,
    item = dplyr::if_else(is.na(object), stringr::str_remove(cols, "-quantised$"),
                          item_from_key(object, key)),
    is_quantised = dplyr::if_else(is.na(object), stringr::str_ends(cols, "-quantised"),
                                  is_quantised_key(key))
  )
}

questionnaire_long <- function(raw, builder) {
  parts <- list()
  if (builder %in% c("questionnaire_builder_1", "questionnaire_mixed")) {
    parts$qb1 <- q_ids(raw) |>
      dplyr::mutate(key = raw[["Question Key"]], value = raw[["Response"]]) |>
      dplyr::filter(!is.na(key), !is_marker(key)) |>
      dplyr::mutate(item = stringr::str_remove(key, "-quantised$"),
                    is_quantised = stringr::str_ends(key, "-quantised")) |>
      dplyr::select(dplyr::all_of(q_keys), item, is_quantised, value)
  }
  if (builder %in% c("questionnaire_builder_2", "questionnaire_mixed")) {
    parts$qb2 <- q_ids(raw) |>
      dplyr::mutate(type = col_of(raw, "Response Type"),
                    question_key = col_of(raw, "Question Key"),
                    object = as.character(col_of(raw, "Object Name")),
                    key = raw[["Key"]],
                    value = raw[["Response"]]) |>
      dplyr::filter(type %in% "response", is.na(question_key)) |>
      dplyr::mutate(item = item_from_key(object, key), is_quantised = is_quantised_key(key)) |>
      dplyr::select(dplyr::all_of(q_keys), item, is_quantised, value)
  }
  if (builder %in% c("questionnaire_builder_1_wide", "questionnaire_builder_2_wide")) {
    raw <- raw[!is.na(raw[["Participant Private ID"]]), ]
    cols <- setdiff(names(raw), c(meta_cols, "BEGIN QUESTIONNAIRE", "END QUESTIONNAIRE"))
    cols <- cols[!stringr::str_detect(cols, node_col_pattern) &
                   !stringr::str_detect(cols, "^(Store|Manipulation): ")]
    parts$wide <- q_ids(raw) |>
      dplyr::bind_cols(raw[cols]) |>
      tidyr::pivot_longer(dplyr::all_of(cols), names_to = "column", values_to = "value",
                          values_drop_na = TRUE) |>
      dplyr::arrange(match(column, cols)) |>
      dplyr::left_join(wide_columns(cols), by = "column") |>
      dplyr::select(dplyr::all_of(q_keys), item, is_quantised, value)
  }
  long <- bind(parts)
  if (is.null(long)) return(NULL)
  merge_quantised(long)
}

merge_quantised <- function(long) {
  keys <- c(q_keys, "item")
  long <- long |>
    dplyr::mutate(occ = dplyr::row_number(), .by = c(dplyr::all_of(keys), is_quantised))
  answers <- long |> dplyr::filter(!is_quantised) |> dplyr::select(-is_quantised)
  quantised <- long |>
    dplyr::filter(is_quantised) |>
    dplyr::select(dplyr::all_of(keys), occ, quantised = value)
  answers |>
    dplyr::full_join(quantised, by = c(keys, "occ")) |>
    dplyr::select(dplyr::all_of(keys), response = value, quantised)
}

#' Questionnaire answers with one row per participant
#'
#' Turns the questionnaire answers of [read_gorilla()] into a wide table with
#' one row per participant and one column per item. Items with a quantised
#' value, such as the position of the chosen option in a dropdown or a
#' Likert scale, get a second column ending in `_quantised`.
#'
#' Questionnaires from Questionnaire Builder 1 and 2, downloaded in long or
#' short format, give the same columns. An item that appears in more than
#' one questionnaire gets the questionnaire name as a prefix. If a
#' participant answered the same item more than once, for example after
#' repeating a node or because two questions share a name, the later answers
#' go into columns ending in `__2`, `__3` and so on. Cleaned item names never
#' contain a double underscore, so these columns cannot be confused with
#' items whose names end in a number.
#'
#' @param x A `gorilla_data` object from [read_gorilla()].
#' @param task Names of the questionnaires to include, as in the `task_name`
#'   column. All by default.
#' @param quantised Add the `_quantised` columns.
#'
#' @return A tibble with `participant_private_id` and one column per item.
#'   Column names are converted to snake case.
#'
#' @examples
#' g <- read_gorilla(gorilla_example())
#' gorilla_wide(g)
#' @export
gorilla_wide <- function(x, task = NULL, quantised = TRUE) {
  check_gorilla(x)
  q <- x$questionnaires
  if (is.null(q)) stop("The data contain no questionnaires.", call. = FALSE)
  if (!is.null(task)) {
    unknown <- setdiff(task, q$task_name)
    if (length(unknown)) {
      stop("Unknown questionnaire: ", paste(unknown, collapse = ", "), call. = FALSE)
    }
    q <- q |> dplyr::filter(task_name %in% task)
  }
  shared <- q |>
    dplyr::distinct(task_name, item) |>
    dplyr::count(item) |>
    dplyr::filter(n > 1L) |>
    dplyr::pull(item)
  q <- q |>
    dplyr::mutate(column = dplyr::if_else(item %in% shared,
                                          paste(task_name, item, sep = "_"), item)) |>
    dplyr::mutate(occ = dplyr::row_number(), .by = c(participant_private_id, column))
  if (any(q$occ > 1L)) {
    repeated <- unique(q$column[q$occ > 1L])
    message("Some participants answered ", length(repeated), " item",
            if (length(repeated) > 1L) "s",
            " more than once; later answers are in columns ending in __2, __3 and so on: ",
            repeated |> utils::head(5L) |> paste(collapse = ", "),
            if (length(repeated) > 5L) ", ...")
  }
  columns <- unique(q$column)
  clean <- c("participant_private_id", columns) |> clean_names() |> utils::tail(-1L)
  q <- q |>
    dplyr::mutate(name = paste0(clean[match(column, columns)],
                                dplyr::if_else(occ > 1L, paste0("__", occ), "")))
  out <- q |>
    tidyr::pivot_wider(id_cols = participant_private_id, names_from = name,
                       values_from = response) |>
    dplyr::mutate(dplyr::across(-participant_private_id, convert_value))
  if (!quantised || all(is.na(q$quantised))) return(out)
  quant <- q |>
    dplyr::filter(!is.na(quantised)) |>
    tidyr::pivot_wider(id_cols = participant_private_id, names_from = name,
                       values_from = quantised, names_glue = "{name}_quantised")
  order <- names(out)[-1L] |>
    purrr::map(\(n) intersect(c(n, paste0(n, "_quantised")), c(names(out), names(quant)))) |>
    unlist()
  out |>
    dplyr::left_join(quant, by = "participant_private_id") |>
    dplyr::select(participant_private_id, dplyr::all_of(order))
}
