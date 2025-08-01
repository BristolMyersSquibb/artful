#' Convert an RTF file to HTML using Pandoc
#'
#' This function takes the path to an input RTF file and uses the Pandoc
#' command-line tool to convert it to HTML.
#'
#' @param file A string, the path to the input .rtf file.
#'
#' @return Character vector of HTML.
#'
#' @keywords internal
rtf_to_html <- function(file) {
  if (!file.exists(file)) {
    stop("Input RTF file does not exist: ", file)
  }

  if (Sys.which("pandoc") == "") {
    stop(
      "Pandoc command not found. ",
      "Please ensure Pandoc is installed and in your system's PATH."
    )
  }

  result <- system2(
    "pandoc",
    args = c("--from", "rtf", "--to", "html", shQuote(file)),
    stdout = TRUE,
    stderr = TRUE
  )

  status <- attr(result, "status", TRUE)
  if (length(status) > 0 && status > 0) {
    stop(c("Running Pandoc failed with following error", result))
  }

  return(paste0(result, collapse = "\n"))
}

#' Convert a string of HTML into a dataframe
#'
#' Convert the HTML generated by calling [rtf_to_html]() into a data frame.
#'
#' @param html A string, HTML generated by calling [rtf_to_html]().
#'
#' @return A data frame containing an R native version of the original RTF
#' table.
#'
#' @keywords internal
html_to_dataframe <- function(html) {
  html |>
    rvest::minimal_html() |>
    rvest::html_element("table") |>
    rvest::html_table()
}

#' Convert an RTF Table into an ARD data frame
#'
#' This function converts a table in RTF format into a data frame in R,
#' following the ARD standard. This is the top-level function of this package
#' which acts as a glue to the lower-level functions.
#'
#' @param file A string, the path to the input .rtf file.
#'
#' @return an R data frame following the ARD standard.
#'
#' @export
rtf_to_ard <- function(file) {
  temp_rtf <- tempfile(fileext = ".rtf")

  file |>
    readr::read_file() |>
    rtf_indentation() |>
    rtf_linebreaks() |>
    readr::write_file(temp_rtf)

  rtf_to_html(temp_rtf) |>
    html_to_dataframe() |>
    manage_exceptions() |>
    strip_pagination() |>
    strip_indentation() |>
    pivot_group()
}

#' Convert RTF file to PDF
#'
#' Converts an RTF file to PDF using LibreOffice's command-line interface.
#'
#' @param rtf_path Character string. Path to the input RTF file.
#' @param pdf_path Character string or NULL. Path for the output PDF file or
#'   directory. If NULL, the PDF will be created in the same location as the
#'   RTF file with a .pdf extension.
#' @param soffice_path Character string. Path to the LibreOffice executable.
#'   Defaults to the standard macOS LibreOffice installation path.
#'
#' @return No return value. The function is called for its side effect of
#'   creating a PDF file.
#'
#' @examples
#' \dontrun{
#' # Convert RTF to PDF in the same directory
#' rtf_to_pdf(rtf_path = "inst/extdata/examples/rt-ae-aesoc2.rtf")
#'
#' # Convert RTF to PDF in a specific directory
#' rtf_to_pdf(rtf_path = "inst/extdata/examples/rt-ae-aesoc2.rtf", pdf_path = "inst/qc/")
#' }
#'
#' @export
rtf_to_pdf <- function(
  rtf_path,
  pdf_path = NULL,
  soffice_path = "/Applications/LibreOffice.app/Contents/MacOS/soffice"
) {
  if (!file.exists(rtf_path)) {
    stop("RTF file not found: ", rtf_path)
  }

  if (is.null(pdf_path)) {
    pdf_path <- sub("\\.rtf$", ".pdf", rtf_path)
  }

  if (dir.exists(pdf_path) || endsWith(pdf_path, "/")) {
    outdir <- pdf_path
    if (!dir.exists(outdir)) {
      dir.create(outdir, recursive = TRUE)
    }
  } else {
    outdir <- dirname(pdf_path)
    if (!dir.exists(outdir)) {
      dir.create(outdir, recursive = TRUE)
    }
  }

  result <- system2(
    soffice_path,
    args = c(
      "--headless",
      "--convert-to",
      "pdf",
      "--outdir",
      shQuote(outdir),
      shQuote(rtf_path)
    ),
    stdout = FALSE,
    stderr = FALSE
  )

  if (result != 0) {
    stop("LibreOffice conversion failed with exit code: ", result)
  }

  # If pdf_path was specified as a file (not directory),
  # LibreOffice creates the PDF with the same base name as the RTF
  # so we may need to rename it
  if (!dir.exists(pdf_path) && !endsWith(pdf_path, "/")) {
    rtf_basename <- tools::file_path_sans_ext(basename(rtf_path))
    generated_pdf <- file.path(outdir, paste0(rtf_basename, ".pdf"))

    if (file.exists(generated_pdf) && generated_pdf != pdf_path) {
      file.rename(generated_pdf, pdf_path)
    }
  }

  return(invisible(pdf_path))
}
