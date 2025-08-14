library(tidyverse)
library(artful)

# options(tibble.print_max = Inf)

stat_lookup <- tribble(
  ~stat_name, ~stat_label,
  "n", "n",
  "N", "N",
  "N_obs", "N Observed",
  "N_miss", "N Missing",
  "p", "%" ,
  "pct", "%" ,
  "mean", "Mean" ,
  "sd", "SD",
  "se", "SE",
  "median", "Median" ,
  "p25", "Q1",
  "p75", "Q3",
  "iqr", "IQR" ,
  "min", "Min",
  "max", "Max",
  "range", "Range",
  "geom_mean", "Geometric Mean",
  "cv", "CV (%)",
  "ci_low", "CI Lower Bound",
  "ci_high", "CI Upper Bound",
  "p_value", "p",
  "estimate", "est"
)

example_data <- function(...) {
  system.file("extdata", "examples", ..., package = "artful")
}

# ---- Slide 7 -----------------------------------------------------------------

# ---- rt-dm-demo.rtf ----
rt_dm_demo <- function(input = example_data("rt-dm-demo.rtf")) {
  temp_rtf <- withr::local_tempfile(fileext = ".rtf")

  input |>
    read_file() |>
    artful:::rtf_indentation() |>
    artful:::rtf_linebreaks() |>
    write_file(temp_rtf)

  ard_ish <- artful:::rtf_to_html(temp_rtf) |>
    artful:::html_to_dataframe() |>
    artful:::manage_exceptions() |>
    artful:::strip_pagination() |>
    artful:::strip_indentation() |>
    artful:::pivot_group()

  ard_ish_parsed <- ard_ish |>
    separate_longer_delim(
      cols = c(variable_level, stat),
      delim = ", "
    ) |>
    mutate(
      stat_name = case_when(
        variable_level == "N" ~ "N",
        variable_level == "MEAN" ~ "mean",
        variable_level == "MEDIAN" ~ "median",
        variable_level == "SD" ~ "sd",
        variable_level == "Q1" ~ "p25",
        variable_level == "Q3" ~ "p75",
        variable_level == "MAX" ~ "min",
        variable_level == "MIN" ~ "max",
        .default = NA
      )
    ) |>
    mutate(
      .id = row_number(),
      stat_list = str_extract_all(stat, "[\\d.]+")
    ) |>
    mutate(
      n_values = lengths(stat_list)
    ) |>
    unnest(stat_list) |>
    mutate(
      stat_name = case_when(
        n_values > 1 & row_number() == 1 ~ "n",
        n_values > 1 & row_number() == 2 ~ "p",
        .default = stat_name
      ),
      stat = stat_list,
      .by = .id
    ) |>
    select(
      -c(.id, stat_list, n_values)
    ) |>
    mutate(stat_name = if_else(is.na(stat_name), "n", stat_name)) |>
    dplyr::filter(!is.na(stat)) |>
    left_join(stat_lookup)

  ard <- ard_ish_parsed |>
    mutate(
      group1_level = stringr::str_extract(
        group1_level,
        ".*?\\S+(?=\\s*(?:\\(N = |N = ))"
      )
    )

  ard <- ard |>
    rename(variable = variable_label1, variable2_level = variable_label2) |>
    relocate(variable, .after = group1_level)

  ard_age_sex <- ard |>
    slice(1:54)

  ard_race <- ard |>
    slice(55:95) |>
    select(
      starts_with("group"),
      variable = variable2_level,
      variable_level = variable,
      variable2_level = variable_level,
      starts_with("stat")
    )

  ard_ethnicity <- ard |>
    slice(96:113)

  ard_country <- ard |>
    slice(114:280) |>
    select(
      starts_with("group"),
      variable = variable2_level,
      variable_level = variable,
      variable2_level = variable_level,
      starts_with("stat")
    )

  ard_weight <- ard |>
    slice(281:345)

  ard_card <- bind_rows(
    ard_age_sex,
    ard_race,
    ard_ethnicity,
    ard_country,
    ard_weight
  ) |>
    mutate(
      variable_level = if_else(
        variable_level %in%
          c("N", "MEAN", "SD", "MEDIAN", "Q1", "Q3", "MIN", "MAX"),
        NA,
        variable_level
      ),
      # Convert to proper ARD list column structure
      group1_level = map(group1_level, ~.x),
      variable_level = map(variable_level, ~ if (is.na(.x)) NULL else .x),
      stat = map(stat, ~ as.numeric(.x)),
      # Add required ARD columns for gtsummary compatibility
      context = case_when(
        str_detect(variable, "AGE|WEIGHT|BMI|HEIGHT") ~ "continuous",
        .default = "categorical"
      ),
      fmt_fun = map(context, ~ if (.x == "continuous") 1L else 0L),
      warning = map(1:n(), ~NULL),
      error = map(1:n(), ~NULL)
    ) |>
    # Filter out inappropriate statistics for continuous variables
    filter(
      !(context == "continuous" & stat_name %in% c("n", "p"))
    ) |>
    cards::as_card()

  return(ard_card)
}

# Example of how to replicate table in top-line slides
rt_dm_demo() |>
  filter(group1_level != "Total") |>
  gtsummary::tbl_ard_summary(by = "TRT") |>
  gtsummary::add_stat_label() |>
  gtsummary::modify_header(
    gtsummary::all_stat_cols() ~ "**{level}**"
  ) |>
  gtsummary::as_gt() |>
  gt::tab_style(
    gt::cell_fill("#eee7e7"),
    gt::cells_column_labels(label)
  ) |>
  gt::tab_style(
    gt::cell_fill("#a69f9f"),
    gt::cells_column_labels(stat_1)
  ) |>
  gt::tab_style(
    gt::cell_fill("#33d6f1"),
    gt::cells_column_labels(stat_2)
  )

# ---- rt-dm-basedz.rtf ----
rt_dm_basedz <- function(input = example_data("rt-dm-basedz.rtf")) {
  temp_rtf <- withr::local_tempfile(fileext = ".rtf")

  input |>
    read_file() |>
    artful:::rtf_indentation() |>
    write_file(temp_rtf)

  ard_ish <- artful:::rtf_to_html(temp_rtf) |>
    artful:::html_to_dataframe() |>
    artful:::manage_exceptions() |>
    artful:::strip_pagination() |>
    artful:::strip_indentation() |>
    artful:::pivot_group()

  ard_ish_parsed <- ard_ish |>
    separate_longer_delim(
      cols = c(variable_level, stat),
      delim = ", "
    ) |>
    mutate(
      stat_name = case_when(
        variable_level == "N" ~ "N",
        variable_level == "MEAN" ~ "mean",
        variable_level == "MEDIAN" ~ "median",
        variable_level == "SD" ~ "sd",
        variable_level == "Q1" ~ "p25",
        variable_level == "Q3" ~ "p75",
        variable_level == "MAX" ~ "min",
        variable_level == "MIN" ~ "max",
        .default = NA
      )
    ) |>
    mutate(
      .id = row_number(),
      stat_list = str_extract_all(stat, "[\\d.]+")
    ) |>
    mutate(
      n_values = lengths(stat_list)
    ) |>
    unnest(stat_list) |>
    mutate(
      stat_name = case_when(
        n_values > 1 & row_number() == 1 ~ "n",
        n_values > 1 & row_number() == 2 ~ "p",
        .default = stat_name
      ),
      stat = stat_list,
      .by = .id
    ) |>
    select(
      -c(.id, stat_list, n_values)
    ) |>
    mutate(stat_name = if_else(is.na(stat_name), "n", stat_name)) |>
    dplyr::filter(!is.na(stat)) |>
    left_join(stat_lookup)

  ard <- ard_ish_parsed |>
    mutate(
      group1_level = stringr::str_extract(
        group1_level,
        ".*?\\S+(?=\\s*(?:\\(N=|N=))"
      )
    )

  ard <- ard |>
    rename(variable = variable_label1, variable2_level = variable_label2) |>
    relocate(variable, .after = group1_level)

  ard_card <- ard |>
    mutate(
      variable_level = if_else(
        variable_level %in%
          c("N", "MEAN", "SD", "MEDIAN", "Q1", "Q3", "MIN", "MAX"),
        NA,
        variable_level
      ),
      # Convert to proper ARD list column structure
      group1_level = map(group1_level, ~.x),
      variable_level = map(variable_level, ~ if (is.na(.x)) NULL else .x),
      stat = map(stat, ~ as.numeric(.x)),
      # Add required ARD columns for gtsummary compatibility
      context = case_when(
        variable %in%
          c(
            "DURATION OF DISEASE (YEARS)",
            "BASELINE TENDER (68) JOINT COUNT",
            "BASELINE SWOLLEN (66) JOINT COUNT",
            "BASELINE SUBJECT GLOBAL ASSESSMENT OF DISEASE ACTIVITY",
            "BASELINE PHYSICIAN GLOBAL ASSESSMENT OF PSORIATIC ARTHRITIS",
            "BASELINE SUBJECT GLOBAL ASSESSMENT OF PAIN",
            "BASELINE HAQ-DI SCORE",
            "BASELINE HSCRP (MG/L)",
            "BASELINE PASI SCORE",
            "BASELINE LEEDS ENTHESITIS INDEX (LEI)",
            "BASELINE SPARCC ENTHESITIS INDEX",
            "BASELINE TENDER DACTYLITIS COUNT",
            "BASELINE DACTYLITIS INDEX (LDI)",
            "BASELINE DAS28-CRP SCORE",
            "BASELINE TENDER (28) JOINT COUNT",
            "BASELINE SWOLLEN (28) JOINT COUNT",
            "BASELINE FACIT-FATIGUE SCORE",
            "BASELINE SF-36 PCS SCORE",
            "BASELINE PSA-MODIFIED SVDH SCORE"
          ) ~
          "continuous",
        .default = "categorical"
      ),
      fmt_fun = map(context, ~ if (.x == "continuous") 1L else 0L),
      warning = map(1:n(), ~NULL),
      error = map(1:n(), ~NULL)
    ) |>
    # Filter out inappropriate statistics for continuous variables
    filter(
      !(context == "continuous" & stat_name == "p")
    ) |>
    cards::as_card()

  return(ard_card)
}

# This still needs some work to make work with gtsummary
rt_dm_basedz()
