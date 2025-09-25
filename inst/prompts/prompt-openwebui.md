## TASK

You are being provided with two synchronized inputs representing the same clinical data.
A PDF accessible via the file <user-pdf>{{user_file_id}}</user-pdf> and the following HTML <user-html>{{user_html}}</user-html>.

Your task is to convert the <user-pdf> and <user-html> inputs to the Analysis‑Ready Data (ARD) standard.

## ARD STANDARD

ARD is a standardised, machine-readable format specifically designed for encoding statistical analysis summaries derived from clinical trial data.
An ARD data frame should abide to the following criteria:

1. Each row represents a single statistical value (e.g., a count and a percentage must be separated into unique rows and not share the same cell such as "10 (15%)" as is commonly observed in the RTF tables).
   This means ARD data frames are somewhat adjacent to tidy data frames in a long format.

2. Each row can provide the context to uniquely identify the unique statistical result value.
   For example, a row in an ARD would not just contain a p-value; it would be linked to the specific study, subject group, parameter, and statistical test that generated it.

## METHODOLOGY

- Use the <user-pdf> as the definitive source for the table's visual layout, hierarchy, and relationships between rows and columns.
- Use the <user-html> code and its tags (`<tr>`, `<td>`, `<th>`, `colspan`, etc.) to confirm structure and ensure accuracy of every character and number you extract.
- Cross-reference both sources to achieve the most accurate parsing possible.

## CRITICAL RULES

1. **Process All Data:** You must iterate through every page provided in the image input.
   Do not stop after finding the first table.
   Ensure that results from all pages are included in the final JSON output.
   Ensure that all values found in <user-html> appear at least once in your final output.

2. **Split Compound Statistics:** If a single stat cell contains multiple values (e.g., "12 (15.4%)" for count and percentage), you MUST generate separate JSON members for each stat.
   For example, one for the count (n) with value 12, and one for the percentage (p) with value 15.4.
   The values of the other cells in the original row will just repeat across the members.

3. **Standardize Statistic Names:** You MUST populate the `stat_name` and `stat_label` fields using the standardized names from this mapping table:

| `stat_name` | `stat_label`        | Description                                                       |
| :---------- | :------------------ | :---------------------------------------------------------------- |
| `n`         | "n" or "Count"      | Count of subjects or records in a specific category or group.     |
| `N`         | "N" or "Total N"    | Total number of subjects in a group, often used as a denominator. |
| `N_obs`     | "N Observed"        | Number of non-missing observations.                               |
| `N_miss`    | "N Missing"         | Number of missing observations.                                   |
| `p`         | "%" or "Percent"    | Proportion (value between 0 and 1).                               |
| `pct`       | "%" or "Percent"    | Percentage (proportion \* 100).                                   |
| `mean`      | "Mean"              | Arithmetic mean.                                                  |
| `sd`        | "SD" or "Std Dev"   | Standard Deviation.                                               |
| `se`        | "SE" or "Std Err"   | Standard Error of the Mean.                                       |
| `median`    | "Median"            | Median (50th percentile).                                         |
| `geom_mean` | "Geometric Mean"    | Geometric mean, often used for log-transformed data.              |
| `cv`        | "CV (%)"            | Coefficient of Variation.                                         |
| `min`       | "Min" or "Minimum"  | Minimum value.                                                    |
| `max`       | "Max" or "Maximum"  | Maximum value.                                                    |
| `range`     | "Range"             | The range of values (`max` - `min`).                              |
| `p25`       | "Q1" or "25th Pctl" | 25th Percentile (First Quartile).                                 |
| `p75`       | "Q3" or "75th Pctl" | 75th Percentile (Third Quartile).                                 |
| `iqr`       | "IQR"               | Interquartile Range (`p75` - `p25`).                              |
| `estimate`  | "Estimate"          | Model parameter estimate (e.g., difference in means).             |
| `conf.low`  | "Lower CL"          | Lower bound of the confidence interval.                           |
| `conf.high` | "Upper CL"          | Upper bound of the confidence interval.                           |
| `p.value`   | "p-value"           | The p-value from a statistical test.                              |
| `statistic` | "Statistic"         | The value of the test statistic (e.g., t-value, F-value).         |
| `df`        | "df"                | Degrees of Freedom.                                               |
| `null`      | "Unknown"           | An unknown statistics                                             |

4. **Data Integrity:** Only extract data present in the provided inputs.
   Do not calculate, infer, or hallucinate any values.
   If a value is missing, represent it as `null`.

## EXAMPLES

<example-1-pdf>{{file_id_example_1}}</example-1-pdf> and <example-1-html>{{example_1_html}}</example-1-html> produce <example-1-json>{{example_1_json}}</example-1-json>.
<example-2-pdf>{{file_id_example_2}}</example-2-pdf> and <example-2-html>{{example_2_html}}</example-2-html> produce <example-2-json>{{example_2_json}}</example-2-json>.
<example-3-pdf>{{file_id_example_3}}</example-3-pdf> and <example-3-html>{{example_3_html}}</example-3-html> produce <example-3-json>{{example_3_json}}</example-3-json>.
