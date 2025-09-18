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
    user_html = rtf_to_html(
      system.file(
        "prompts",
        "example-4.rtf",
        package = "artful"
      )
    ),
    user_pdf = content_pdf_file(
      system.file(
        "prompts",
        "example-4.pdf",
        package = "artful"
      )
    ),
    example_1_html = rtf_to_html(
      system.file(
        "prompts",
        "example-1.rtf",
        package = "artful"
      )
    ),
    example_1_pdf = content_pdf_file(
      system.file(
        "prompts",
        "example-1.pdf",
        package = "artful"
      )
    ),
    example_2_html = rtf_to_html(
      system.file(
        "prompts",
        "example-2.rtf",
        package = "artful"
      )
    ),
    example_2_pdf = content_pdf_file(
      system.file(
        "prompts",
        "example-2.pdf",
        package = "artful"
      )
    ),
    example_3_html = rtf_to_html(
      system.file(
        "prompts",
        "example-3.rtf",
        package = "artful"
      )
    ),
    example_3_pdf = content_pdf_file(
      system.file(
        "prompts",
        "example-3.pdf",
        package = "artful"
      )
    )
  )

  chat <- chat_openai(
    system_prompt = system_prompt(),
    model = "gpt-4o",
  )

  result <- chat$chat(prompt, echo = "output")
}
