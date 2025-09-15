## TASK

You are being provided with two synchronized inputs representing the same clinical trial table:

<image>
{{user_pdf}}
</image>

<html>
{{user_html}}
</html>

Your task is to parse the table using both the <image> and <html> inputs, and structure the data into a single JSON array of objects.
Each object in the array must represent a single statistical result, as per the ARD standard.

## ARD STANDARD

ARD is a standardised, machine-readable format specifically designed for encoding statistical analysis summaries derived from clinical trial data.
An ARD data frame should abide to the following criteria:

1. Each row represents a single statistical value (e.g., a count and a percentage must be separated into unique rows and not share the same cell such as "10 (15%)" as is commonly observed in the RTF tables).
   This means ARD data frames are somewhat adjacent to tidy data frames in a long format.

2. Each row can provide the context to uniquely identify the unique statistical result value.
   For example, a row in an ARD would not just contain a p-value; it would be linked to the specific study, subject group, parameter, and statistical test that generated it.

## METHODOLOGY

- Use the <image> as the definitive source for the table's visual layout, hierarchy, and relationships between rows and columns.
- Use the <html> code and its tags (`<tr>`, `<td>`, `<th>`, `colspan`, etc.) to confirm structure and ensure accuracy of every character and number you extract.
- Cross-reference both sources to achieve the most accurate parsing possible.

## CRITICAL RULES

1. **Process All Pages:** You must iterate through every page provided in the image input.
   Do not stop after finding the first table.
   Ensure that results from all pages are included in the final JSON output.

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

## JSON OUTPUT SCHEMA

1. Your response must be ONLY a single, valid JSON array.
2. Each object in your JSON array must have exactly these keys:

- `table_id`: (String) Table identifier from title (e.g., "Table 14.1.1")
- `group_id`: (String) Name of grouping variable (e.g., "TRT01P", "AVISIT")
- `group_level`: (String) Specific level of that group (e.g., "Placebo", "Week 8")
- `variable`: (String) Primary variable being analyzed (e.g., "Age", "Sex")
- `variable_level`: (String or null) Specific level for categorical variables (e.g., "Female"). Use `null` for continuous variables or summary rows
- `stat_name`: (String) Standardized statistic name from mapping table (e.g., "n", "mean", "p")
- `stat_label`: (String) Human-readable statistic label as it appears in table (e.g., "Mean", "n", "%")
- `stat`: (Number or String) The numeric or text value. Represent percentages as numbers (e.g., 15.4 for "15.4%")

Each object in your JSON array may also have these additional, optional, keys:

- `variable<N>_level` (String) N additional group levels that capture more context about a single statistic.

3. Do not include any explanatory text, comments, or markdown formatting.
4. Do not use code blocks or any other formatting.
5. Start your response with `[` and end with `]`.

## EXAMPLES

{{example_1_html}} and {{example_1_pdf}} should produce the following JSON:

```json
[
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGE",
    "stat_name": "median",
    "stat_label": "Median",
    "stat": 76
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGE",
    "stat_name": "p25",
    "stat_label": "Q1",
    "stat": 69
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGE",
    "stat_name": "p75",
    "stat_label": "Q3",
    "stat": 82
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGE",
    "stat_name": "mean",
    "stat_label": "Mean",
    "stat": 75.2093
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGE",
    "stat_name": "sd",
    "stat_label": "SD",
    "stat": 8.5902
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGE",
    "stat_name": "min",
    "stat_label": "Min",
    "stat": 52
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGE",
    "stat_name": "max",
    "stat_label": "Max",
    "stat": 89
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGE",
    "stat_name": "median",
    "stat_label": "Median",
    "stat": 76
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGE",
    "stat_name": "p25",
    "stat_label": "Q1",
    "stat": 70.5
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGE",
    "stat_name": "p75",
    "stat_label": "Q3",
    "stat": 80
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGE",
    "stat_name": "mean",
    "stat_label": "Mean",
    "stat": 74.381
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGE",
    "stat_name": "sd",
    "stat_label": "SD",
    "stat": 7.8861
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGE",
    "stat_name": "min",
    "stat_label": "Min",
    "stat": 56
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGE",
    "stat_name": "max",
    "stat_label": "Max",
    "stat": 88
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGE",
    "stat_name": "median",
    "stat_label": "Median",
    "stat": 77.5
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGE",
    "stat_name": "p25",
    "stat_label": "Q1",
    "stat": 71
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGE",
    "stat_name": "p75",
    "stat_label": "Q3",
    "stat": 82
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGE",
    "stat_name": "mean",
    "stat_label": "Mean",
    "stat": 75.6667
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGE",
    "stat_name": "sd",
    "stat_label": "SD",
    "stat": 8.2861
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGE",
    "stat_name": "min",
    "stat_label": "Min",
    "stat": 51
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGE",
    "stat_name": "max",
    "stat_label": "Max",
    "stat": 88
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGEGR1",
    "variable_level": "<65",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 14
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGEGR1",
    "variable_level": "<65",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 86
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGEGR1",
    "variable_level": "<65",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.1628
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGEGR1",
    "variable_level": ">80",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 30
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGEGR1",
    "variable_level": ">80",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 86
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGEGR1",
    "variable_level": ">80",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.3488
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGEGR1",
    "variable_level": "65-80",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 42
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGEGR1",
    "variable_level": "65-80",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 86
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGEGR1",
    "variable_level": "65-80",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.4884
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGEGR1",
    "variable_level": "<65",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 11
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGEGR1",
    "variable_level": "<65",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGEGR1",
    "variable_level": "<65",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.131
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGEGR1",
    "variable_level": ">80",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 18
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGEGR1",
    "variable_level": ">80",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGEGR1",
    "variable_level": ">80",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.2143
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGEGR1",
    "variable_level": "65-80",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 55
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGEGR1",
    "variable_level": "65-80",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGEGR1",
    "variable_level": "65-80",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.6548
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGEGR1",
    "variable_level": "<65",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 8
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGEGR1",
    "variable_level": "<65",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGEGR1",
    "variable_level": "<65",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.0952
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGEGR1",
    "variable_level": ">80",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 29
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGEGR1",
    "variable_level": ">80",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGEGR1",
    "variable_level": ">80",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.3452
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGEGR1",
    "variable_level": "65-80",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 47
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGEGR1",
    "variable_level": "65-80",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGEGR1",
    "variable_level": "65-80",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.5595
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "SEX",
    "variable_level": "F",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 53
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "SEX",
    "variable_level": "F",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 86
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "SEX",
    "variable_level": "F",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.6163
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "SEX",
    "variable_level": "F",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 40
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "SEX",
    "variable_level": "F",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "SEX",
    "variable_level": "F",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.4762
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "SEX",
    "variable_level": "F",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 50
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "SEX",
    "variable_level": "F",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "SEX",
    "variable_level": "F",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.5952
  }
]
>
> example_1_ard |>
+   jsonlite::toJSON(pretty = TRUE)
[
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGE",
    "stat_name": "median",
    "stat_label": "Median",
    "stat": 76
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGE",
    "stat_name": "p25",
    "stat_label": "Q1",
    "stat": 69
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGE",
    "stat_name": "p75",
    "stat_label": "Q3",
    "stat": 82
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGE",
    "stat_name": "mean",
    "stat_label": "Mean",
    "stat": 75.2093
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGE",
    "stat_name": "sd",
    "stat_label": "SD",
    "stat": 8.5902
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGE",
    "stat_name": "min",
    "stat_label": "Min",
    "stat": 52
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGE",
    "stat_name": "max",
    "stat_label": "Max",
    "stat": 89
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGE",
    "stat_name": "median",
    "stat_label": "Median",
    "stat": 76
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGE",
    "stat_name": "p25",
    "stat_label": "Q1",
    "stat": 70.5
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGE",
    "stat_name": "p75",
    "stat_label": "Q3",
    "stat": 80
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGE",
    "stat_name": "mean",
    "stat_label": "Mean",
    "stat": 74.381
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGE",
    "stat_name": "sd",
    "stat_label": "SD",
    "stat": 7.8861
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGE",
    "stat_name": "min",
    "stat_label": "Min",
    "stat": 56
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGE",
    "stat_name": "max",
    "stat_label": "Max",
    "stat": 88
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGE",
    "stat_name": "median",
    "stat_label": "Median",
    "stat": 77.5
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGE",
    "stat_name": "p25",
    "stat_label": "Q1",
    "stat": 71
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGE",
    "stat_name": "p75",
    "stat_label": "Q3",
    "stat": 82
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGE",
    "stat_name": "mean",
    "stat_label": "Mean",
    "stat": 75.6667
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGE",
    "stat_name": "sd",
    "stat_label": "SD",
    "stat": 8.2861
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGE",
    "stat_name": "min",
    "stat_label": "Min",
    "stat": 51
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGE",
    "stat_name": "max",
    "stat_label": "Max",
    "stat": 88
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGEGR1",
    "variable_level": "<65",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 14
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGEGR1",
    "variable_level": "<65",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 86
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGEGR1",
    "variable_level": "<65",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.1628
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGEGR1",
    "variable_level": ">80",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 30
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGEGR1",
    "variable_level": ">80",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 86
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGEGR1",
    "variable_level": ">80",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.3488
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGEGR1",
    "variable_level": "65-80",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 42
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGEGR1",
    "variable_level": "65-80",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 86
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "AGEGR1",
    "variable_level": "65-80",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.4884
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGEGR1",
    "variable_level": "<65",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 11
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGEGR1",
    "variable_level": "<65",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGEGR1",
    "variable_level": "<65",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.131
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGEGR1",
    "variable_level": ">80",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 18
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGEGR1",
    "variable_level": ">80",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGEGR1",
    "variable_level": ">80",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.2143
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGEGR1",
    "variable_level": "65-80",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 55
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGEGR1",
    "variable_level": "65-80",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "AGEGR1",
    "variable_level": "65-80",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.6548
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGEGR1",
    "variable_level": "<65",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 8
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGEGR1",
    "variable_level": "<65",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGEGR1",
    "variable_level": "<65",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.0952
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGEGR1",
    "variable_level": ">80",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 29
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGEGR1",
    "variable_level": ">80",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGEGR1",
    "variable_level": ">80",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.3452
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGEGR1",
    "variable_level": "65-80",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 47
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGEGR1",
    "variable_level": "65-80",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "AGEGR1",
    "variable_level": "65-80",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.5595
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "SEX",
    "variable_level": "F",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 53
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "SEX",
    "variable_level": "F",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 86
  },
  {
    "group1": "ARM",
    "group1_level": "Placebo",
    "variable": "SEX",
    "variable_level": "F",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.6163
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "SEX",
    "variable_level": "F",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 40
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "SEX",
    "variable_level": "F",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline High Dose",
    "variable": "SEX",
    "variable_level": "F",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.4762
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "SEX",
    "variable_level": "F",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 50
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "SEX",
    "variable_level": "F",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "ARM",
    "group1_level": "Xanomeline Low Dose",
    "variable": "SEX",
    "variable_level": "F",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.5952
  }
]
```

{{example_2_html}} and {{example_2_pdf}} should produce the following JSON:

```json
[
  {
    "group1": "TRTA",
    "group1_level": "Placebo",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE DERMATITIS",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 5
  },
  {
    "group1": "TRTA",
    "group1_level": "Placebo",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE DERMATITIS",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 86
  },
  {
    "group1": "TRTA",
    "group1_level": "Placebo",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE DERMATITIS",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.0581
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline High Dose",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE DERMATITIS",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 7
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline High Dose",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE DERMATITIS",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline High Dose",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE DERMATITIS",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.0833
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline Low Dose",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE DERMATITIS",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 9
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline Low Dose",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE DERMATITIS",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline Low Dose",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE DERMATITIS",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.1071
  },
  {
    "group1": "TRTA",
    "group1_level": "Placebo",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE ERYTHEMA",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 3
  },
  {
    "group1": "TRTA",
    "group1_level": "Placebo",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE ERYTHEMA",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 86
  },
  {
    "group1": "TRTA",
    "group1_level": "Placebo",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE ERYTHEMA",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.0349
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline High Dose",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE ERYTHEMA",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 15
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline High Dose",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE ERYTHEMA",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline High Dose",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE ERYTHEMA",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.1786
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline Low Dose",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE ERYTHEMA",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 12
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline Low Dose",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE ERYTHEMA",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline Low Dose",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE ERYTHEMA",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.1429
  },
  {
    "group1": "TRTA",
    "group1_level": "Placebo",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE IRRITATION",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 3
  },
  {
    "group1": "TRTA",
    "group1_level": "Placebo",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE IRRITATION",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 86
  },
  {
    "group1": "TRTA",
    "group1_level": "Placebo",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE IRRITATION",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.0349
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline High Dose",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE IRRITATION",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 9
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline High Dose",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE IRRITATION",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline High Dose",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE IRRITATION",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.1071
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline Low Dose",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE IRRITATION",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 9
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline Low Dose",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE IRRITATION",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline Low Dose",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE IRRITATION",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.1071
  },
  {
    "group1": "TRTA",
    "group1_level": "Placebo",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE PRURITUS",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 6
  },
  {
    "group1": "TRTA",
    "group1_level": "Placebo",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE PRURITUS",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 86
  },
  {
    "group1": "TRTA",
    "group1_level": "Placebo",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE PRURITUS",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.0698
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline High Dose",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE PRURITUS",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 22
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline High Dose",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE PRURITUS",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline High Dose",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE PRURITUS",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.2619
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline Low Dose",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE PRURITUS",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 22
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline Low Dose",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE PRURITUS",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline Low Dose",
    "group2": "AEBODSYS",
    "group2_level": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
    "variable": "AEDECOD",
    "variable_level": "APPLICATION SITE PRURITUS",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.2619
  },
  {
    "group1": "TRTA",
    "group1_level": "Placebo",
    "group2": "AEBODSYS",
    "group2_level": "NERVOUS SYSTEM DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "DIZZINESS",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 2
  },
  {
    "group1": "TRTA",
    "group1_level": "Placebo",
    "group2": "AEBODSYS",
    "group2_level": "NERVOUS SYSTEM DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "DIZZINESS",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 86
  },
  {
    "group1": "TRTA",
    "group1_level": "Placebo",
    "group2": "AEBODSYS",
    "group2_level": "NERVOUS SYSTEM DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "DIZZINESS",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.0233
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline High Dose",
    "group2": "AEBODSYS",
    "group2_level": "NERVOUS SYSTEM DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "DIZZINESS",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 11
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline High Dose",
    "group2": "AEBODSYS",
    "group2_level": "NERVOUS SYSTEM DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "DIZZINESS",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline High Dose",
    "group2": "AEBODSYS",
    "group2_level": "NERVOUS SYSTEM DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "DIZZINESS",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.131
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline Low Dose",
    "group2": "AEBODSYS",
    "group2_level": "NERVOUS SYSTEM DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "DIZZINESS",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 8
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline Low Dose",
    "group2": "AEBODSYS",
    "group2_level": "NERVOUS SYSTEM DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "DIZZINESS",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline Low Dose",
    "group2": "AEBODSYS",
    "group2_level": "NERVOUS SYSTEM DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "DIZZINESS",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.0952
  },
  {
    "group1": "TRTA",
    "group1_level": "Placebo",
    "group2": "AEBODSYS",
    "group2_level": "SKIN AND SUBCUTANEOUS TISSUE DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "ERYTHEMA",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 8
  },
  {
    "group1": "TRTA",
    "group1_level": "Placebo",
    "group2": "AEBODSYS",
    "group2_level": "SKIN AND SUBCUTANEOUS TISSUE DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "ERYTHEMA",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 86
  },
  {
    "group1": "TRTA",
    "group1_level": "Placebo",
    "group2": "AEBODSYS",
    "group2_level": "SKIN AND SUBCUTANEOUS TISSUE DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "ERYTHEMA",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.093
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline High Dose",
    "group2": "AEBODSYS",
    "group2_level": "SKIN AND SUBCUTANEOUS TISSUE DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "ERYTHEMA",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 14
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline High Dose",
    "group2": "AEBODSYS",
    "group2_level": "SKIN AND SUBCUTANEOUS TISSUE DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "ERYTHEMA",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline High Dose",
    "group2": "AEBODSYS",
    "group2_level": "SKIN AND SUBCUTANEOUS TISSUE DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "ERYTHEMA",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.1667
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline Low Dose",
    "group2": "AEBODSYS",
    "group2_level": "SKIN AND SUBCUTANEOUS TISSUE DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "ERYTHEMA",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 14
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline Low Dose",
    "group2": "AEBODSYS",
    "group2_level": "SKIN AND SUBCUTANEOUS TISSUE DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "ERYTHEMA",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline Low Dose",
    "group2": "AEBODSYS",
    "group2_level": "SKIN AND SUBCUTANEOUS TISSUE DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "ERYTHEMA",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.1667
  },
  {
    "group1": "TRTA",
    "group1_level": "Placebo",
    "group2": "AEBODSYS",
    "group2_level": "SKIN AND SUBCUTANEOUS TISSUE DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "PRURITUS",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 8
  },
  {
    "group1": "TRTA",
    "group1_level": "Placebo",
    "group2": "AEBODSYS",
    "group2_level": "SKIN AND SUBCUTANEOUS TISSUE DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "PRURITUS",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 86
  },
  {
    "group1": "TRTA",
    "group1_level": "Placebo",
    "group2": "AEBODSYS",
    "group2_level": "SKIN AND SUBCUTANEOUS TISSUE DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "PRURITUS",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.093
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline High Dose",
    "group2": "AEBODSYS",
    "group2_level": "SKIN AND SUBCUTANEOUS TISSUE DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "PRURITUS",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 26
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline High Dose",
    "group2": "AEBODSYS",
    "group2_level": "SKIN AND SUBCUTANEOUS TISSUE DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "PRURITUS",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline High Dose",
    "group2": "AEBODSYS",
    "group2_level": "SKIN AND SUBCUTANEOUS TISSUE DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "PRURITUS",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.3095
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline Low Dose",
    "group2": "AEBODSYS",
    "group2_level": "SKIN AND SUBCUTANEOUS TISSUE DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "PRURITUS",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 21
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline Low Dose",
    "group2": "AEBODSYS",
    "group2_level": "SKIN AND SUBCUTANEOUS TISSUE DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "PRURITUS",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline Low Dose",
    "group2": "AEBODSYS",
    "group2_level": "SKIN AND SUBCUTANEOUS TISSUE DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "PRURITUS",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.25
  },
  {
    "group1": "TRTA",
    "group1_level": "Placebo",
    "group2": "AEBODSYS",
    "group2_level": "SKIN AND SUBCUTANEOUS TISSUE DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "RASH",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 5
  },
  {
    "group1": "TRTA",
    "group1_level": "Placebo",
    "group2": "AEBODSYS",
    "group2_level": "SKIN AND SUBCUTANEOUS TISSUE DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "RASH",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 86
  },
  {
    "group1": "TRTA",
    "group1_level": "Placebo",
    "group2": "AEBODSYS",
    "group2_level": "SKIN AND SUBCUTANEOUS TISSUE DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "RASH",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.0581
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline High Dose",
    "group2": "AEBODSYS",
    "group2_level": "SKIN AND SUBCUTANEOUS TISSUE DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "RASH",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 9
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline High Dose",
    "group2": "AEBODSYS",
    "group2_level": "SKIN AND SUBCUTANEOUS TISSUE DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "RASH",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline High Dose",
    "group2": "AEBODSYS",
    "group2_level": "SKIN AND SUBCUTANEOUS TISSUE DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "RASH",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.1071
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline Low Dose",
    "group2": "AEBODSYS",
    "group2_level": "SKIN AND SUBCUTANEOUS TISSUE DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "RASH",
    "stat_name": "n",
    "stat_label": "n",
    "stat": 13
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline Low Dose",
    "group2": "AEBODSYS",
    "group2_level": "SKIN AND SUBCUTANEOUS TISSUE DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "RASH",
    "stat_name": "N",
    "stat_label": "N",
    "stat": 84
  },
  {
    "group1": "TRTA",
    "group1_level": "Xanomeline Low Dose",
    "group2": "AEBODSYS",
    "group2_level": "SKIN AND SUBCUTANEOUS TISSUE DISORDERS",
    "variable": "AEDECOD",
    "variable_level": "RASH",
    "stat_name": "p",
    "stat_label": "%",
    "stat": 0.1548
  }
]
```

{{example_3_html}} and {{example_3_pdf}} should produce the following JSON:

```json

```
