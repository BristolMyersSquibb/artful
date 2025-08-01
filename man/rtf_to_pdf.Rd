% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/convert.R
\name{rtf_to_pdf}
\alias{rtf_to_pdf}
\title{Convert RTF file to PDF}
\usage{
rtf_to_pdf(
  rtf_path,
  pdf_path = NULL,
  soffice_path = "/Applications/LibreOffice.app/Contents/MacOS/soffice"
)
}
\arguments{
\item{rtf_path}{Character string. Path to the input RTF file.}

\item{pdf_path}{Character string or NULL. Path for the output PDF file or
directory. If NULL, the PDF will be created in the same location as the
RTF file with a .pdf extension.}

\item{soffice_path}{Character string. Path to the LibreOffice executable.
Defaults to the standard macOS LibreOffice installation path.}
}
\value{
No return value. The function is called for its side effect of
creating a PDF file.
}
\description{
Converts an RTF file to PDF using LibreOffice's command-line interface.
}
\examples{
\dontrun{
# Convert RTF to PDF in the same directory
rtf_to_pdf(rtf_path = "inst/extdata/examples/rt-ae-aesoc2.rtf")

# Convert RTF to PDF in a specific directory
rtf_to_pdf(rtf_path = "inst/extdata/examples/rt-ae-aesoc2.rtf", pdf_path = "inst/qc/")
}

}
