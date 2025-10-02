#' Helper to return prompt path
prompt_path <- function(file) {
  system.file(
    "prompts",
    file,
    package = "artful"
  )
}

#' Convert an RTF to ARD via Open WebUI
#'
#' @noRd
#'
#' @examples
#' \dontrun{
#' openwebui_rtf_to_ard("inst/extdata/examples/rt-ae-ae1.rtf")
#' }
openwebui_rtf_to_ard <- function(rtf) {
  # Prevent time outs due to long processing times
  withr::local_options(ellmer_timeout_s = 60 * 30)

  system_prompt <-
    "
    You are an expert data scientist specialised in generating CDISC
    Analysis-Ready Data (ARD).
    "

  prompt <- interpolate_file(
    prompt_path("prompt.md"),
    user_json = jsonlite::toJSON(rtf_to_df(rtf)),
    example_1_raw = readr::read_file(prompt_path("example-1-raw.json")),
    example_1_ard = readr::read_file(prompt_path("example-1-ard.json")),
    example_2_raw = readr::read_file(prompt_path("example-2-raw.json")),
    example_2_ard = readr::read_file(prompt_path("example-2-ard.json"))
  )

  chat <- chat_openai(
    system_prompt = system_prompt,
    base_url = "http://10.13.13.19:3000/api",
    api_key = Sys.getenv("OPENWEBUI_API_KEY"),
    model = "gpt-oss:120b"
  )

  chat_output <- chat$chat_structured(
    prompt,
    type = type_ard_array(),
    echo = "output"
  )

  tibble::as_tibble(chat_output)
}
