#' Convert an RTF file to HTML using Pandoc
#'
#' This function takes the path to an input RTF file and uses the Pandoc
#' R package to convert it to HTML.
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

  temp_html <- tempfile(fileext = ".html")

  # The pandoc package will automatically handle installation of pandoc binary
  # if unavailable.
  tryCatch(
    {
      pandoc::pandoc_convert(
        file = file,
        from = "rtf",
        to = "html",
        output = temp_html
      )
    },
    error = function(e) {
      stop("Running Pandoc failed with following error: ", e$message)
    }
  )

  html_content <- readr::read_file(temp_html)

  unlink(temp_html)

  return(html_content)
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
