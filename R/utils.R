#' @noRd
'%!in%' <- function(x, y) !('%in%'(x, y))

#' @noRd
prinf <- function(x) print(x, n = Inf)

#' @noRd
rtf_example <- function(example_num) {
  example_files <- system.file("extdata", "examples", package = "artful") |>
    list.files()

  if (!is.numeric(example_num) || length(example_num) != 1) {
    stop("example_num must be a single integer")
  }

  if (example_num < 1 || example_num > length(example_files)) {
    stop(sprintf("example_num must be between 1 and %d", length(example_files)))
  }

  system.file(
    "extdata",
    "examples",
    example_files[example_num],
    package = "artful",
    mustWork = TRUE
  )
}

#' @noRd
prompt_path <- function(file) {
  system.file(
    "prompts",
    file,
    package = "artful"
  )
}
