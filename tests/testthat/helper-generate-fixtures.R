files <- list.files(
  system.file("extdata/examples", package = "artful"),
  full.names = TRUE
)

for (f in files) {
  df <- rtf_to_df(f)
  saveRDS(
    df,
    file.path(
      "tests/testthat/fixtures",
      paste0(tools::file_path_sans_ext(basename(f)), ".rds")
    )
  )
}
