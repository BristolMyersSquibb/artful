#' Upload a file to Open WebUI
openwebui_file_upload <- function(file) {
  request <-
    httr2::request("http://10.13.13.19:3000/api/v1/files/") |>
    httr2::req_auth_bearer_token(Sys.getenv("OPENWEBUI_API_KEY")) |>
    httr2::req_headers(Accept = "application/json") |>
    httr2::req_body_multipart(file = curl::form_file(file))

  response <- httr2::req_perform(request)

  if (httr2::resp_status(response) == 200) {
    result <- httr2::resp_body_json(response)
    message("File uploaded successfully. File ID: ", result$id)
    return(result$id)
  } else {
    stop("Failed to upload file: ", httr2::resp_body_string(response))
  }
}

#' Helper to return prompt path
prompt_path <- function(file) {
  system.file(
    "prompts",
    file,
    package = "artful"
  )
}

#' Helper function to upload HTML
openwebui_read_html <- function(example) {
  prompt_path(example) |>
    readLines() |>
    paste0(collapse = "\n")
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

  user_pdf <- tempfile(fileext = ".pdf")
  rtf_to_pdf(rtf, pdf_path = user_pdf)

  user_file_id <- openwebui_file_upload(user_pdf)
  example_1_file_id <- openwebui_file_upload(prompt_path("example-1.pdf"))
  example_2_file_id <- openwebui_file_upload(prompt_path("example-2.pdf"))
  example_3_file_id <- openwebui_file_upload(prompt_path("example-3.pdf"))

  system_prompt <- function() {
    "
    You are an expert data scientist specialised in generating CDISC
    Analysis-Ready Data (ARD) from RTF files.
    "
  }

  prompt <- interpolate_file(
    prompt_path("prompt-openwebui.md"),
    user_html = rtf_to_html(rtf),
    user_pdf = user_file_id,
    example_1_pdf = example_1_file_id,
    example_2_pdf = example_2_file_id,
    example_3_pdf = example_3_file_id,
    example_1_html = openwebui_read_html("example-1.rtf"),
    example_2_html = openwebui_read_html("example-2.rtf"),
    example_3_html = openwebui_read_html("example-3.rtf"),
    example_1_json = jsonlite::read_json(prompt_path("example-1.json")),
    example_2_json = jsonlite::read_json(prompt_path("example-2.json")),
    example_3_json = jsonlite::read_json(prompt_path("example-3.json")),
  )

  chat <- chat_openai(
    system_prompt = system_prompt(),
    base_url = "http://10.13.13.19:3000/api",
    api_key = Sys.getenv("OPENWEBUI_API_KEY"),
    model = "gpt-oss:120b",
    api_args = list(
      files = list(
        list(type = "file", id = user_file_id),
        list(type = "file", id = example_1_file_id),
        list(type = "file", id = example_2_file_id),
        list(type = "file", id = example_3_file_id)
      )
    )
  )

  chat_output <- chat$chat_structured(
    prompt,
    type = type_ard_array(),
    echo = "output"
  )

  tibble::as_tibble(chat_output)
}
