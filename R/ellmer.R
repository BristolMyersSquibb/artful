#' Convert RTF Clinical Trial Tables to Analysis Results Data (ARD) Format
#'
#' Extracts structured statistical data from RTF-formatted clinical trial tables
#' and converts them to ARD (Analysis Results Data) standard format using
#' Large Language Model (LLM) processing with structured data extraction.
#'
#' @param rtf Character string specifying the path to an RTF file containing a
#' clinical trial table to be converted to ARD format.
#'
#' @return A \code{tibble} containing the extracted ARD records with columns:
#' \describe{
#'   \item{table_id}{Table identifier from title (optional)}
#'   \item{group1, group1_level}{First grouping variable and its level (optional)}
#'   \item{group2, group2_level}{Second grouping variable and its level (optional)}
#'   \item{group3, group3_level}{Third grouping variable and its level (optional)}
#'   \item{variable}{Primary variable being analyzed}
#'   \item{variable_level}{Level for categorical variables (optional)}
#'   \item{stat_name}{Standardized statistic name from ARD mapping}
#'   \item{stat_label}{Human-readable statistic label}
#'   \item{stat}{The statistical value as string}
#' }
#'
#' @note
#' Requires valid OpenAI API credentials to be configured. The function
#' relies on example files included in the package for multi-shot prompting.
#'
#' @examples
#' \dontrun{
#' rtf_to_ard("inst/extdata/examples/rt-ae-ae1.rtf")
#' }
#'
#' @export
rtf_to_ard <- function(rtf) {
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

  # chat <- chat_openai(
  #   system_prompt = system_prompt,
  #   base_url = "http://10.13.13.19:3000/api",
  #   api_key = Sys.getenv("OPENWEBUI_API_KEY"),
  #   model = "gpt-oss:120b"
  # )

  chat <- chat_openai(
    system_prompt = system_prompt,
    model = "gpt-4o",
  )

  chat_output <- chat$chat_structured(
    prompt,
    type = type_ard_array(),
    echo = "output"
  )

  tibble::as_tibble(chat_output)
}


#' Create ARD Array Type Specification for Structured Data Extraction
#'
#' Creates a type specification for extracting Analysis Results Data (ARD)
#' formatted data from clinical trial tables using ellmer's structured data
#' functionality. This ensures LLM responses conform to the ARD standard
#' with properly typed and validated fields.
#'
#' @details
#' The ARD (Analysis Results Data) standard requires each statistical result
#' to be represented as a separate record with context about grouping variables,
#' the variable being analyzed, and standardized statistic names and labels.
#'
#' The type specification includes:
#' \itemize{
#'   \item Optional table identifier
#'   \item Up to 3 levels of grouping variables (group1, group2, group3)
#'   \item Primary variable and optional variable level for categorical data
#'   \item Standardized statistic names and labels from the ARD mapping table
#'   \item The statistical value as a string
#' }
#'
#' @return A \code{type_array} object containing \code{type_object}
#' specifications that can be used with \code{chat_structured()} to ensure
#' ARD-compliant JSON output from LLMs.
#'
#' @keywords internal
type_ard_array <- function() {
  type_ard_record <- type_object(
    "A single ARD statistical result record",
    table_id = type_string(
      "Table identifier from title (e.g., 'Table 14.1.1')",
      required = FALSE
    ),
    group1 = type_string(
      "Name of first grouping variable (e.g., 'ARM', 'TRTA')",
      required = TRUE
    ),
    group1_level = type_string(
      "Specific level of first group (e.g., 'Placebo', 'Week 8')",
      required = TRUE
    ),
    group2 = type_string(
      "Name of second grouping variable if present",
      required = FALSE
    ),
    group2_level = type_string(
      "Specific level of second group if present",
      required = FALSE
    ),
    group3 = type_string(
      "Name of third grouping variable if present",
      required = FALSE
    ),
    group3_level = type_string(
      "Specific level of third group if present",
      required = FALSE
    ),
    variable = type_string(
      "Primary variable being analyzed (e.g., 'Age', 'Sex', 'AVAL')",
      required = TRUE
    ),
    variable_level = type_string(
      "Specific level for categorical variables (e.g., 'Female'). NULL for continuous variables",
      required = FALSE
    ),
    stat_name = type_enum(
      c(
        "n",
        "N",
        "N_obs",
        "N_miss",
        "p",
        "pct",
        "mean",
        "sd",
        "se",
        "median",
        "geom_mean",
        "cv",
        "min",
        "max",
        "range",
        "p25",
        "p75",
        "iqr",
        "estimate",
        "conf.low",
        "conf.high",
        "p.value",
        "statistic",
        "df",
        "null"
      ),
      "Standardized statistic name from ARD mapping table",
      required = TRUE
    ),
    stat_label = type_enum(
      c(
        "n",
        "Count",
        "N",
        "Total N",
        "N Observed",
        "N Missing",
        "%",
        "Percent",
        "Mean",
        "SD",
        "Std Dev",
        "SE",
        "Std Err",
        "Median",
        "Geometric Mean",
        "CV (%)",
        "Min",
        "Minimum",
        "Max",
        "Maximum",
        "Range",
        "Q1",
        "25th Pctl",
        "Q3",
        "75th Pctl",
        "IQR",
        "Estimate",
        "Lower CL",
        "Upper CL",
        "p-value",
        "Statistic",
        "df",
        "Unknown"
      ),
      "Human-readable statistic label from ARD mapping table",
      required = TRUE
    ),
    stat = type_string(
      "The numeric or text value. Percentages as decimals (e.g., '0.154' for '15.4%')",
      required = TRUE
    )
  )

  type_array(
    type_ard_record,
    "Array of ARD records representing all statistical results from the clinical trial table"
  )
}
