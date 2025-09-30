# Helpers for convert tests
# Framework: testthat (edition 3)
expect_html_or_pandoc_error <- function(x, pattern = NULL) {
  if (inherits(x, "error")) {
    testthat::expect_match(conditionMessage(x), "Pandoc failed", ignore.case = TRUE)
  } else {
    testthat::expect_type(x, "character")
    if (\!is.null(pattern)) {
      testthat::expect_match(x, pattern, ignore.case = TRUE)
    }
  }
}