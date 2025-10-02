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

# RTF
example_1_tbl |>
  gt::gtsave("inst/prompts/example-1.rtf")

# JSON
rtf_to_html("inst/prompts/example-1.rtf") |>
  html_to_dataframe() |>
  rename(
    "Characteristic" = X1,
    "Placebo\nN = 86" = X2,
    "Xanomeline Low Dose\nN = 84" = X3,
    "Xanomeline High Dose\nN = 84" = X4
  ) |>
  slice(-1) |>
  mutate(
    Characteristic = if_else(
      Characteristic %!in% c("Age", "Age Group, n (%)", "Female, n (%)"),
      paste0("    ", Characteristic),
      Characteristic
    )
  ) |>
  jsonlite::write_json("inst/prompts/example-1-raw.json")

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
  jsonlite::write_json("inst/prompts/example-1-ard.json")

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

# RTF
example_2_tbl |>
  gt::gtsave("inst/prompts/example-2.rtf")

# JSON
rtf_to_html("inst/prompts/example-2.rtf") |>
  html_to_dataframe() |>
  rename(
    "Body System or Organ Class\n    Dictionary-Derived Term" = X1,
    "Placebo\nN = 861" = X2,
    "Xanomeline High Dose\nN = 841" = X3,
    "Xanomeline Low Dose\nN = 841" = X4
  ) |>
  slice(-1) |>
  slice(-13) |>
  mutate(
    `Body System or Organ Class\n    Dictionary-Derived Term` = if_else(
      `Body System or Organ Class\n    Dictionary-Derived Term` %!in%
        c(
          "Any Adverse Event",
          "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",
          "NERVOUS SYSTEM DISORDERS",
          "SKIN AND SUBCUTANEOUS TISSUE DISORDERS"
        ),
      paste0("    ", `Body System or Organ Class\n    Dictionary-Derived Term`),
      `Body System or Organ Class\n    Dictionary-Derived Term`
    )
  ) |>
  jsonlite::write_json("inst/prompts/example-2-raw.json")

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
  jsonlite::write_json("inst/prompts/example-2-ard.json")
