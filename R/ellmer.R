parse <- function(prompt, pdf, html) {
  tryCatch(
    {
      chat_gpt_40 <- chat_openai(
        model = "gpt-4o",
        params = params(temperature = 0)
      )

      pdf <- content_pdf_file(pdf)

      raw_result <- chat_gpt_40$chat(
        prompt,
        pdf,
        html
      )

      cleaned_result <- gsub("```json\n|\n```", "", raw_result)

      if (!jsonlite::validate(cleaned_result)) {
        stop("Invalid JSON returned from API")
      }

      final_ard <- jsonlite::fromJSON(cleaned_result, flatten = TRUE)

      return(final_ard)
    },
    error = function(e) {
      stop(paste("Error in parse function:", e$message))
    }
  )
}


prompt <- function() {
  "
### ROLE ###
You are an expert data extraction bot specializing in pharmaceutical clinical trial data. Your sole purpose is to convert a table, provided as both an IMAGE and its corresponding HTML code, into a structured JSON format that strictly complies with the Analysis Results Data (ARD) standard. You are precise, methodical, and never invent data.

### CONTEXT ###
I am providing you with two synchronized inputs representing the same table:
1.  An IMAGE of the clinical trial table. Use this as the definitive source for the table's visual layout, hierarchy, and the relationships between rows and columns.
2.  The table's content formatted as HTML code. Use the HTML tags (`<tr>`, `<td>`, `<th>`, `colspan`, etc.) and the text content within them to confirm the structure and to ensure the accuracy of every character and number you extract.

Your task is to synthesize information from both sources to achieve the most accurate parsing possible, adhering to the ARD principles outlined below.

### TASK ###
Parse the table using both the image and HTML inputs, and structure the data into a single JSON array of objects. Each object in the array must represent a single statistical result, as per the ARD standard.

### RULES ###
1.  **Process All Pages:** You must iterate through every page provided in the image input. Do not stop after finding the first table. Ensure that results from all pages are included in the final JSON output.
2.  **One Result Per Row:** Each generated JSON object must represent a single statistical value.
3.  **Split Compound Statistics:** If a single cell in the source table contains multiple values (e.g., \"12 (15.4%)\" for count and percentage), you MUST generate a separate JSON object for each value. One for the count (n) with the value 12, and one for the percentage (p) with the value 15.4.
4.  **Synthesize Inputs:** Cross-reference the visual layout in the image with the structure defined in the HTML code. The image is the primary source for visual structure, and the HTML is the primary source for textual content and structural verification.
5.  **Standardize Statistic Names (`stat_name`):** You MUST populate the `stat_name` field using the standardized names from the mapping table provided below. Match the statistic label found in the table (e.g., \"Mean\", \"SD\", \"%\") to its corresponding `stat_name` (e.g., \"mean\", \"sd\", \"p\"). If a statistic is not in the table, use your best judgment to create a logical snake_case name.
6.  **Data Integrity:** Only extract data present in the provided inputs. Do not calculate, infer, or hallucinate any values. If a value is missing in a cell, represent it as `null`.
7.  **Output Format:** The output MUST be a single, valid JSON object. Do not include any explanatory text, comments, or markdown formatting before or after the JSON block.

### STATISTIC NAME MAPPING TABLE ###
| `stat_name` | `stat_label`         | Description                     |
|-------------|----------------------|---------------------------------|
| `n`         | \"n\" or \"Count\"       | Count of subjects/records.      |
| `N`         | \"N\" or \"Total N\"     | Total number of subjects/records|
| `p`         | \"%\" or \"Percent\"     | Proportion or Percentage.       |
| `pct`       | \"%\" or \"Percent\"     | Percentage.                     |
| `mean`      | \"Mean\"               | Arithmetic mean.                |
| `sd`        | \"SD\" or \"Std Dev\"    | Standard Deviation.             |
| `se`        | \"SE\" or \"Std Err\"    | Standard Error of the Mean.     |
| `median`    | \"Median\"             | Median (50th percentile).       |
| `p25`       | \"Q1\" or \"25th Pctl\"  | 25th Percentile (First Quartile)|
| `p75`       | \"Q3\" or \"75th Pctl\"  | 75th Percentile (Third Quartile)|
| `min`       | \"Min\" or \"Minimum\"   | Minimum value.                  |
| `max`       | \"Max\" or \"Maximum\"   | Maximum value.                  |


### OUTPUT SCHEMA ###
Produce a JSON array where each object has the following keys. Adhere strictly to this schema:
- `table_id`: (String) The table identifier from its title (e.g., \"Table 14.1.1\").
- `group_id`: (String) The name of the grouping variable (e.g., \"TRT01P\", \"AVISIT\").
- `group_level`: (String) The specific level of that group (e.g., \"Placebo\", \"Week 8\").
- `variable`: (String) The primary variable being analyzed (e.g., \"Age\", \"Sex\").
- `variable_level`: (String or null) The specific level for categorical variables (e.g., \"Female\"). For continuous variables or summary rows, this should be `null`.
- `stat_name`: (String) The standardized, machine-readable name of the statistic, based on the mapping table provided (e.g., \"n\", \"mean\", \"p\").
- `stat_label`: (String) The human-readable statistic label as it appears in the table (e.g., \"Mean\", \"n\", \"%\").
- `stat`: (Number or String) The numeric or text value of the statistic. Ensure percentages are represented as numbers (e.g., 15.4 for \"15.4%\").
  "
}

# Example
# result <- parse(
#   prompt(),
#   "inst/extdata/qc/example.pdf",
#   rtf_to_html("inst/extdata/qc/example.rtf")
# )
