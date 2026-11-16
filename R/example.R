#' Path to the example exports
#'
#' The package includes a small invented experiment downloaded in the
#' one-file-per-node format: a lexical decision task made with Task Builder
#' 2, a rhyme judgement task made with Task Builder 1, a consent form made
#' with Questionnaire Builder 1 and a background questionnaire made with
#' Questionnaire Builder 2. One participant stopped during the lexical
#' decision task, and one node was never reached, so its file is empty. The
#' data were simulated and the identifiers are made up.
#'
#' @param file Name of one file. If `NULL`, the path to the folder.
#'
#' @return A path.
#'
#' @examples
#' gorilla_example()
#' list.files(gorilla_example())
#' @export
gorilla_example <- function(file = NULL) {
  dir <- system.file("extdata", "example", package = "silverback", mustWork = TRUE)
  if (is.null(file)) return(dir)
  path <- file.path(dir, file)
  if (!all(file.exists(path))) {
    stop("No example file named ", paste(file[!file.exists(path)], collapse = ", "),
         ". See `list.files(gorilla_example())`.", call. = FALSE)
  }
  path
}
