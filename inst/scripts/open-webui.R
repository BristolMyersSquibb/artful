pkgload::load_all()

base_url <- "http://10.13.13.19:3000/api"
api_key <- Sys.getenv("OPENWEBUI_API_KEY")

# Step 1: Upload the file to Open WebUI using httr2
upload_file_to_openwebui <- function(file_path, base_url, api_key) {
  upload_url <- paste0(base_url, "/v1/files/")

  request <- httr2::request(upload_url) |>
    httr2::req_auth_bearer_token(api_key) |>
    httr2::req_headers(Accept = "application/json") |>
    httr2::req_body_multipart(
      file = curl::form_file(file_path)
    )

  response <- httr2::req_perform(request)

  if (httr2::resp_status(response) == 200) {
    result <- httr2::resp_body_json(response)
    message("File uploaded successfully. File ID: ", result$id)
    return(result$id)
  } else {
    stop("Failed to upload file: ", httr2::resp_body_string(response))
  }
}

file <- system.file("prompts", "example-4.rtf", package = "artful")

file_id <- upload_file_to_openwebui(file, base_url, api_key)

# Step 2: Create chat instance with the file reference
chat <- ellmer::chat_openai(
  base_url = base_url,
  api_key = api_key,
  model = "gpt-oss:120b",
  api_args = list(
    files = list(
      list(type = "file", id = file_id)
    )
  )
)

response <- chat$chat("Can you extract the data from the attached file?")
