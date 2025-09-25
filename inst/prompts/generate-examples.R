# ------------------------------------------------------------------------------
# README:
# All of the examples in this file are derived from the cards package vignettes:
# https://github.com/insightsengineering/cards/tree/main/vignettes/articles
# ------------------------------------------------------------------------------

pkgload::load_all()
library(cards)
library(dplyr)
gtsummary::theme_gtsummary_compact()

# ------------------------------------------------------------------------------
# Example 1
# ------------------------------------------------------------------------------
example_1_tbl <- ADSL |>
  select(ARM, AGE, AGEGR1, SEX) |>
  mutate(
    ARM = factor(
      ARM,
      levels = c("Placebo", "Xanomeline Low Dose", "Xanomeline High Dose")
    ),
    AGEGR1 = factor(
      AGEGR1,
      levels = c("<65", "65-80", ">80"),
      labels = c("<65", "65-80", ">80")
    )
  ) |>
  gtsummary::tbl_summary(
    by = ARM,
    type = AGE ~ "continuous2",
    statistic = AGE ~
      c("{median} ({p25}, {p75})", "{mean} ({sd})", "{min} - {max}"),
    value = SEX ~ "F",
    label = list(SEX = "Female", AGEGR1 = "Age Group"),
    digits = ~ list(p = cards::label_round(digits = 1, scale = 100, width = 4))
  ) |>
  gtsummary::add_stat_label() |>
  gtsummary::modify_header(
    gtsummary::all_stat_cols() ~ "**{level}**  \nN = {n}"
  ) |>
  gtsummary::modify_column_alignment(columns = -label, "right") |>
  gtsummary::as_gt() |>
  gt::opt_table_font(stack = "monospace-code")

# PDF
example_1_tbl |>
  gt::gtsave("inst/prompts/example-1.pdf")

# RTF
example_1_tbl |>
  gt::gtsave("inst/prompts/example-1.rtf")

# HTML
rtf_to_html("inst/prompts/example-1.rtf") |>
  writeLines("inst/prompts/example-1.html")

# ARD
df_continuous_ard <-
  ard_summary(
    ADSL,
    by = ARM,
    variables = AGE,
    statistic = ~ continuous_summary_fns(c(
      "median",
      "p25",
      "p75",
      "mean",
      "sd",
      "min",
      "max"
    ))
  )

df_categorical_ard <-
  ard_tabulate(
    ADSL,
    by = ARM,
    variables = AGEGR1
  )

df_dichotomous_ard <-
  ard_tabulate_value(
    ADSL,
    by = ARM,
    variables = SEX,
    value = list(SEX = "F")
  )

example_1_ard <- bind_ard(
  df_continuous_ard,
  df_categorical_ard,
  df_dichotomous_ard
) |>
  tibble::as_tibble() |>
  select(-context, -fmt_fun, -warning, -error) |>
  tidyr::unnest(c(group1_level, variable_level, stat))

# JSON (ARD)
example_1_ard |>
  jsonlite::toJSON() |>
  jsonlite::write_json("inst/prompts/example-1.json")

# ------------------------------------------------------------------------------
# Example 2
# ------------------------------------------------------------------------------
adsl <- ADSL
adae <- ADAE |>
  filter(.by = AETERM, n() > 25, TRTEMFL == "Y")

example_2_tbl <- ADAE |>
  filter(.by = AETERM, n() > 25, TRTEMFL == "Y") |>
  gtsummary::tbl_hierarchical(
    by = TRTA,
    variables = c(AEBODSYS, AEDECOD),
    id = USUBJID,
    denominator = ADSL,
    overall_row = TRUE,
    digits = ~ list(p = cards::label_round(digits = 1, scale = 100, width = 4)),
    label = list(..ard_hierarchical_overall.. = "Any Adverse Event")
  ) |>
  gtsummary::modify_column_alignment(
    columns = gtsummary::all_stat_cols(),
    "right"
  ) |>
  gtsummary::as_gt() |>
  gt::opt_table_font(stack = "monospace-code")

# PDF
example_2_tbl |>
  gt::gtsave("inst/prompts/example-2.pdf")

# RTF
example_2_tbl |>
  gt::gtsave("inst/prompts/example-2.rtf")

# HTML
rtf_to_html("inst/prompts/example-2.rtf") |>
  writeLines("inst/prompts/example-2.html")

example_2_ard <- ard_stack_hierarchical(
  data = adae,
  by = TRTA,
  variables = c(AEBODSYS, AEDECOD),
  denominator = adsl,
  id = USUBJID,
  over_variables = TRUE
) |>
  tibble::as_tibble() |>
  select(-context, -fmt_fun, -warning, -error) |>
  tidyr::unnest(group1_level) |>
  tidyr::unnest(group2_level) |>
  tidyr::unnest(variable_level) |>
  tidyr::unnest(stat)

# JSON (ARD)
example_2_ard |>
  jsonlite::toJSON() |>
  jsonlite::write_json("inst/prompts/example-2.json")

# ------------------------------------------------------------------------------
# Example 3
# ------------------------------------------------------------------------------
example_3_tbl <- ADLB |>
  mutate(AVISIT = trimws(AVISIT)) |>
  filter(
    PARAMCD %in% c("BILI", "CREAT"),
    AVISIT %in% c("Baseline", "Week 24")
  ) |>
  gtsummary::tbl_strata_nested_stack(
    strata = PARAM,
    \(.x) {
      .x |>
        crane::tbl_baseline_chg(
          baseline_level = "Baseline",
          by = "TRTA",
          denominator = ADSL
        )
    }
  ) |>
  gtsummary::modify_bold(columns = label, rows = tbl_indent_id1 > 0L) |>
  gtsummary::modify_spanning_header(
    gtsummary::all_stat_cols() ~ "**{level}**  \nN = {n}"
  ) |>
  gtsummary::modify_header(
    label = "**Lab  \n\U00A0\U00A0\U00A0\U00A0 Visit**"
  ) |>
  gtsummary::modify_source_note(
    "Printing a few illustrative rows from the full table."
  ) |>
  gtsummary::as_gt() |>
  gt::opt_table_font(stack = "monospace-code")

# PDF
example_3_tbl |>
  gt::gtsave("inst/prompts/example-3.pdf")

# RTF
example_3_tbl |>
  gt::gtsave("inst/prompts/example-3.rtf")

# HTML
rtf_to_html("inst/prompts/example-3.rtf") |>
  writeLines("inst/prompts/example-3.html")

# ARD
example_3_ard <- ADLB |>
  filter(
    PARAMCD %in% c("BILI", "CREAT"),
    AVISIT %in% c("Baseline", "Week 24")
  ) |>
  ard_summary(
    strata = c("PARAM", "AVISIT"),
    by = "TRTA",
    variables = c("AVAL", "CHG")
  ) |>
  tibble::as_tibble() |>
  select(-context, -fmt_fun, -warning, -error) |>
  mutate(stat = as.character(stat)) |>
  tidyr::unnest(group1_level) |>
  tidyr::unnest(group2_level) |>
  tidyr::unnest(group3_level)

# JSON (ARD)
example_3_ard |>
  jsonlite::toJSON() |>
  jsonlite::write_json("inst/prompts/example-3.json")

# ------------------------------------------------------------------------------
# Example 4
# ------------------------------------------------------------------------------
example_4_tbl <- ADAE |>
  filter(.by = AETERM, dplyr::n() > 25, TRTEMFL == "Y") |>
  gtsummary::tbl_hierarchical_count(
    by = TRTA,
    variables = c(AEBODSYS, AEDECOD),
    denominator = ADSL,
    overall_row = TRUE,
    digits = ~ list(p = cards::label_round(digits = 1, scale = 100, width = 4)),
    label = list(
      ..ard_hierarchical_overall.. = "Total Number of Adverse Events"
    )
  ) |>
  gtsummary::modify_column_alignment(
    columns = gtsummary::all_stat_cols(),
    "right"
  ) |>
  gtsummary::as_gt() |>
  gt::opt_table_font(stack = "monospace-code")

# PDF
example_4_tbl |>
  gt::gtsave("inst/prompts/example-4.pdf")

# RTF
example_4_tbl |>
  gt::gtsave("inst/prompts/example-4.rtf")

# HTML
rtf_to_html("inst/prompts/example-4.rtf") |>
  writeLines("inst/prompts/example-4.html")

# ARD
example_4_ard <- ard_stack_hierarchical_count(
  data = adae,
  by = TRTA,
  variables = c(AEBODSYS, AETERM),
  over_variables = TRUE
) |>
  tibble::as_tibble() |>
  select(-context, -fmt_fun, -warning, -error) |>
  mutate(stat = as.character(stat)) |>
  tidyr::unnest(group1_level) |>
  tidyr::unnest(group2_level) |>
  tidyr::unnest(variable_level)

# JSON (ARD)
example_4_ard |>
  jsonlite::toJSON() |>
  jsonlite::write_json("inst/prompts/example-4.json")
