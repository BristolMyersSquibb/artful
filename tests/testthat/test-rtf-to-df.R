test_that("rtf_to_df produces expected output for example files", {
  fixture_dir <- test_path("fixtures")
  skip_if_not(dir.exists(fixture_dir), "Fixture data not available")

  files <- list.files(
    system.file("extdata/examples", package = "artful"),
    full.names = TRUE
  )
  skip_if(length(files) == 0, "Example data not available")

  for (f in files) {
    fixture_path <- file.path(
      fixture_dir,
      paste0(tools::file_path_sans_ext(basename(f)), ".rds")
    )
    skip_if_not(file.exists(fixture_path))

    result <- rtf_to_df(f)
    expected <- readRDS(fixture_path)
    expect_equal(result, expected, label = basename(f))
  }
})
