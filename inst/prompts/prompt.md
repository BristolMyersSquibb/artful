## TASK

You will be provided with two synchronized inputs representing the same clinical trial table:

<image>
{{user_pdf}}
</image>

<html>
{{user_html}}
</html>

Your task is to parse the table using both the <image> and <html> inputs, and structure the data into a single JSON array of objects.
Each object in the array must represent a single statistical result, as per the ARD standard.

## METHODOLOGY

- Use the IMAGE as the definitive source for the table's visual layout, hierarchy, and relationships between rows and columns
- Use the HTML code and its tags (`<tr>`, `<td>`, `<th>`, `colspan`, etc.) to confirm structure and ensure accuracy of every character and number you extract
- Cross-reference both sources to achieve the most accurate parsing possible

## ARD STANDARD

ARD is a standardised, machine-readable format specifically designed for encoding statistical analysis summaries derived from clinical trial data.
An ARD data frame should abide to the following criteria:

1. Each row represents a single statistical value (e.g., a count and a percentage must be separated into unique rows and not share the same cell such as "10 (15%)" as is commonly observed in the RTF tables).
   This means ARD data frames are somewhat adjacent to tidy data frames in a long format.

2. Each row can provide the context to uniquely identify the unique statistical result value.
   This means the data frame should include at least the follow columns (with recommended column names in brackets):

- group names (`group<N>`)
- group levels (`group<N>_level`)
- variable names (`variable`)
- variable levels (`variable_level`)
- statistical names (`stat_name`)
- statistical label (`stat_label`)
- statistical value (`stat`)

## CRITICAL RULES

1. **Process All Pages:** You must iterate through every page provided in the image input.
   Do not stop after finding the first table.
   Ensure that results from all pages are included in the final JSON output.

2. **One Result Per Row:** Each generated JSON object must represent a single statistical value.

3. **Split Compound Statistics:** If a single stat cell contains multiple values (e.g., "12 (15.4%)" for count and percentage), you MUST generate separate JSON members for each stat.
   For example, one for the count (n) with value 12, and one for the percentage (p) with value 15.4.
   The values of the other cells in the original row will just repeat across the members.

4. **Standardize Statistic Names:** You MUST populate the `stat_name` and `stat_label` fields using the standardized names from this mapping table:

| `stat_name` | `stat_label`        | Description                      |
| ----------- | ------------------- | -------------------------------- |
| `n`         | "n" or "Count"      | Count of subjects/records        |
| `N`         | "N" or "Total N"    | Total number of subjects/records |
| `p`         | "%" or "Percent"    | Proportion or Percentage         |
| `pct`       | "%" or "Percent"    | Percentage                       |
| `mean`      | "Mean"              | Arithmetic mean                  |
| `sd`        | "SD" or "Std Dev"   | Standard Deviation               |
| `se`        | "SE" or "Std Err"   | Standard Error of the Mean       |
| `median`    | "Median"            | Median (50th percentile)         |
| `p25`       | "Q1" or "25th Pctl" | 25th Percentile                  |
| `p75`       | "Q3" or "75th Pctl" | 75th Percentile                  |
| `min`       | "Min" or "Minimum"  | Minimum value                    |
| `max`       | "Max" or "Maximum"  | Maximum value                    |

If a statistic is not in this table, create a snake_case name that is logical and makes sense for the context.

5. **Data Integrity:** Only extract data present in the provided inputs.
   Do not calculate, infer, or hallucinate any values. If a value is missing, represent it as `null`.

## JSON OUTPUT SCHEMA

Each object in your JSON array must have exactly these keys:

- `table_id`: (String) Table identifier from title (e.g., "Table 14.1.1")
- `group_id`: (String) Name of grouping variable (e.g., "TRT01P", "AVISIT")
- `group_level`: (String) Specific level of that group (e.g., "Placebo", "Week 8")
- `variable`: (String) Primary variable being analyzed (e.g., "Age", "Sex")
- `variable_level`: (String or null) Specific level for categorical variables (e.g., "Female"). Use `null` for continuous variables or summary rows
- `stat_name`: (String) Standardized statistic name from mapping table (e.g., "n", "mean", "p")
- `stat_label`: (String) Human-readable statistic label as it appears in table (e.g., "Mean", "n", "%")
- `stat`: (Number or String) The numeric or text value. Represent percentages as numbers (e.g., 15.4 for "15.4%")

## Examples

{{exampl_html}} and {{example_pdf}} should produce the following JSON:

```json
[
  {
    "table_id": "Table 14.1.1",
    "group_id": "TRT01P",
    "group_level": "Placebo",
    "variable": "Age",
    "variable_level": null,
    "stat_name": "n",
    "stat_label": "n",
    "stat": 150
  },
  {
    "table_id": "Table 14.1.1",
    "group_id": "TRT01P",
    "group_level": "Placebo",
    "variable": "Age",
    "variable_level": null,
    "stat_name": "mean",
    "stat_label": "Mean",
    "stat": 65.2
  }
]
```

## OUTPUT REQUIREMENTS

- Your response must be ONLY a single, valid JSON array
- Do not include any explanatory text, comments, or markdown formatting
- Do not use code blocks or any other formatting
- Start your response with `[` and end with `]`
