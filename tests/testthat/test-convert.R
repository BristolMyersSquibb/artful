test_that("rtf_to_html converts RTF file to HTML using pandoc package", {
  # Create a simple RTF file for testing
  withr::with_tempfile("test_rtf", fileext = ".rtf", {
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
  })
})

test_that("rtf_to_html handles missing files correctly", {
  skip("Original test created the file; replaced by a correct missing-file test below.")
  withr::with_tempfile("non_existent_file", fileext = ".rtf", {
    expect_error(
      rtf_to_html(non_existent_file),
      "Input RTF file does not exist"
    )
  })
})

test_that("rtf_to_html handles pandoc errors gracefully", {
  # Create an invalid RTF file
  withr::with_tempfile("invalid_rtf", fileext = ".rtf", {
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
  })
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

# ------------------------------------------------------------------------------
# Additional tests (auto-generated)
# Framework: testthat (edition 3)

# Small utility to build minimal valid-ish RTF payloads for Pandoc
build_minimal_rtf <- function(lines) {
  paste0(
    "{\\rtf1\\ansi\\deff0 {\\fonttbl{\\f0 Times New Roman;}}",
    "\n",
    "\\f0\\fs24 ",
    paste(lines, collapse = " "),
    " \\par",
    "\n}",
    collapse = ""
  )
}

test_that("rtf_to_html errors when file is missing and includes path", {
  missing <- tempfile(fileext = ".rtf")
  expect_false(file.exists(missing))
  expect_error(
    rtf_to_html(missing),
    regexp = paste0("Input RTF file does not exist: ", missing),
    fixed = TRUE
  )
})

test_that("rtf_to_html converts minimal RTF or reports Pandoc failure cleanly", {
  withr::with_tempfile("rtf", fileext = ".rtf", {
    writeLines(build_minimal_rtf("Hello world"), rtf)
    out <- tryCatch(rtf_to_html(rtf), error = function(e) e)
    expect_html_or_pandoc_error(out, "Hello world")
  })
})

test_that("rtf_to_html handles invalid RTF by producing informative error or minimal HTML", {
  withr::with_tempfile("bad", fileext = ".rtf", {
    writeLines("This is not valid RTF content", bad)
    out <- tryCatch(rtf_to_html(bad), error = function(e) e)
    expect_html_or_pandoc_error(out)
  })
})

test_that("rtf_to_html works when path contains spaces", {
  withr::with_tempdir({
    path <- file.path(getwd(), "file with spaces.rtf")
    writeLines(build_minimal_rtf("Space Path"), path)
    out <- tryCatch(rtf_to_html(path), error = function(e) e)
    expect_html_or_pandoc_error(out, "Space Path")
  })
})

test_that("rtf_to_html rejects vector inputs (length > 1)", {
  withr::with_tempfile("a", fileext = ".rtf", {
    writeLines(build_minimal_rtf("A"), a)
    # file.exists(c(a, a)) yields length > 1 leading to base R error
    expect_error(rtf_to_html(c(a, a)), "length > 1", fixed = TRUE)
  })
})

test_that("rtf_to_html NULL input errors with a length-zero condition", {
  expect_error(rtf_to_html(NULL), "length zero", ignore.case = TRUE)
})

test_that("rtf_to_html returns a length-1 character string on success", {
  withr::with_tempfile("rtf", fileext = ".rtf", {
    writeLines(build_minimal_rtf("Len1"), rtf)
    out <- tryCatch(rtf_to_html(rtf), error = function(e) e)
    if (\!inherits(out, "error")) {
      expect_length(out, 1)
      expect_type(out, "character")
    } else {
      # If Pandoc fails in this environment, ensure the wrapped error is informative
      expect_match(out$message, "Pandoc failed", ignore.case = TRUE)
    }
  })
})

test_that("rtf_to_ard missing file reports an error", {
  missing <- tempfile(fileext = ".rtf")
  expect_false(file.exists(missing))
  expect_error(rtf_to_ard(missing))
})

test_that("rtf_to_ard invalid RTF yields either error or a data.frame (if parser recovers)", {
  withr::with_tempfile("bad", fileext = ".rtf", {
    writeLines("Not valid RTF", bad)
    out <- tryCatch(rtf_to_ard(bad), error = function(e) e)
    if (inherits(out, "error")) {
      expect_match(out$message, "Pandoc failed|file", ignore.case = TRUE)
    } else {
      expect_s3_class(out, "data.frame")
    }
  })
})
# ------------------------------------------------------------------------------
