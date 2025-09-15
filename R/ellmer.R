parse_rtf <- function() {
  system_prompt <- function() {
    "
    You are an expert data extraction bot specializing in pharmaceutical
    clinical trial data. Your sole purpose is to convert tables into structured
    JSON format that strictly complies with the Analysis Results Data (ARD)
    standard. You are precise, methodical, and never invent data.
  "
  }

  prompt <- interpolate_file(
    system.file("prompts", "prompt.md", package = "artful"),
    example_html = rtf_to_html("inst/extdata/ellmer/example_1.rtf"),
    example_pdf = content_pdf_file("inst/extdata/ellmer/example_1.pdf"),
    user_html = rtf_to_html("inst/extdata/ellmer/example_2.rtf"), # Missing
    user_pdf = content_pdf_file("inst/extdata/ellmer/example_2.pdf"), # Missing
  )

  chat <- chat_openai(
    system_prompt = system_prompt(),
    model = "gpt-4o",
  )

  result <- chat$chat(prompt)
}
