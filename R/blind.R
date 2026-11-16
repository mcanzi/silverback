#' Replace participant identifiers
#'
#' Replaces the public identifiers that can link participants to a
#' recruitment platform, such as Prolific or SONA IDs, with codes such as
#' `P001`.
#' The same participant gets the same code in all tables. The private
#' identifiers assigned by 'Gorilla' are kept, because they do not identify
#' anyone outside 'Gorilla'. Answers that participants typed in, such as an
#' ID entered in a questionnaire, are not changed.
#'
#' @param x A `gorilla_data` object from [read_gorilla()].
#' @param columns Columns to replace. By default the public ID, the external
#'   session ID and the completion code.
#'
#' @return `x` with the identifiers replaced. Participants without a value
#'   keep `NA`.
#'
#' @examples
#' g <- read_gorilla(gorilla_example())
#' gorilla_participants(blind_ids(g))
#' @export
blind_ids <- function(x, columns = c("participant_public_id",
                                     "participant_external_session_id",
                                     "participant_completion_code")) {
  check_gorilla(x)
  ids <- x$participants$participant_private_id
  code <- sprintf(paste0("P%0", max(3L, nchar(length(ids))), "d"), seq_along(ids))
  recode <- function(v, id) {
    dplyr::if_else(is.na(v), NA_character_, code[match(as.character(id), ids)])
  }
  for (part in c("participants", "tasks")) {
    if (is.null(x[[part]])) next
    x[[part]] <- x[[part]] |>
      dplyr::mutate(dplyr::across(dplyr::any_of(columns), \(v) recode(v, participant_private_id)))
  }
  x
}
