test_that("rtf_to_html converts RTF file to HTML using pandoc package", {
  # Create a simple RTF file for testing
  test_rtf <- tempfile(fileext = ".rtf")
  writeLines(
    c(
      "{\\rtf1\\ansi\\deff0 {\\fonttbl{\\f0 Times New Roman;}}",
      "\\f0\\fs24 Test content \\par",
      "}"
    ),
    test_rtf
  )

  # Test successful conversion
  result <- rtf_to_html(test_rtf)

  # Check that result is a character string containing HTML
  expect_type(result, "character")
  # Pandoc may generate minimal HTML without <html> tag, so check for content
  expect_match(result, "Test content", ignore.case = TRUE)

  # Clean up
  unlink(test_rtf)
})

test_that("rtf_to_html handles missing files correctly", {
  non_existent_file <- tempfile(fileext = ".rtf")

  expect_error(
    rtf_to_html(non_existent_file),
    "Input RTF file does not exist"
  )
})

test_that("rtf_to_html handles pandoc errors gracefully", {
  # Create an invalid RTF file
  invalid_rtf <- tempfile(fileext = ".rtf")
  writeLines("This is not valid RTF content", invalid_rtf)

  # This should process but may produce minimal HTML
  # or could error depending on pandoc's handling
  result <- tryCatch(
    rtf_to_html(invalid_rtf),
    error = function(e) e
  )

  # Either it succeeds with some HTML or it errors gracefully
  if (inherits(result, "error")) {
    expect_match(result$message, "Pandoc failed", ignore.case = TRUE)
  } else {
    expect_type(result, "character")
  }

  # Clean up
  unlink(invalid_rtf)
})

test_that("rtf_to_ard works with pandoc package", {
  # Use one of the example files
  example_file <- system.file(
    "extdata",
    "examples",
    "rt-ae-aesoc2.rtf",
    package = "artful"
  )

  skip_if(!file.exists(example_file), "Example file not found")

  # Test that rtf_to_ard still works with the new implementation
  result <- rtf_to_ard(example_file)

  # Check that result is a data frame
  expect_s3_class(result, "data.frame")
  expect_true(nrow(result) > 0)
})
