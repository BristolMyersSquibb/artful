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

gtsummary_table <- function(data) {
  data |>
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
    mutate(
      stat = if_else(
        str_detect(variable_label1, "n \\(%\\)$") & stat == "0",
        "0 ( 0)",
        stat
      )
    ) |>
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
      group1_level = map(group1_level, ~.x),
      variable_level = map(variable_level, ~ if (is.na(.x)) NULL else .x),
      stat = map(stat, ~ as.numeric(.x)),
      context = case_when(
        str_detect(variable, "AGE|WEIGHT|BMI|HEIGHT") ~ "continuous",
        .default = "categorical"
      ),
      fmt_fun = map(context, ~ if (.x == "continuous") 1L else 0L),
      warning = map(1:n(), ~NULL),
      error = map(1:n(), ~NULL)
    ) |>
    filter(
      !(context == "continuous" & stat_name %in% c("n", "p"))
    ) |>
    cards::as_card()

  return(ard_card)
}

# Method 1. Use ard "card" dataset to produce the table
rt_dm_demo() |>
  gtsummary_table()

# # Method 2: just recreate the GT table exactly, bypassing the use of the ARD:
# rt_dm_demo_table <- function() {
#   rt_dm_demo_gt_data <- data.frame(
#     Demographics = c(
#       "Age, median (range), years",
#       "Weight, median (range), kg",
#       "BMI, median (range), kg/m²",
#       "Female, n (%)",
#       "Race, n (%)",
#       "&nbsp;&nbsp;&nbsp;&nbsp;American Indian or Alaska Native",
#       "&nbsp;&nbsp;&nbsp;&nbsp;Asian",
#       "&nbsp;&nbsp;&nbsp;&nbsp;Black or African American",
#       "&nbsp;&nbsp;&nbsp;&nbsp;White",
#       "&nbsp;&nbsp;&nbsp;&nbsp;Other",
#       "Ethnicity, n (%)",
#       "&nbsp;&nbsp;&nbsp;&nbsp;Hispanic or Latino",
#       "&nbsp;&nbsp;&nbsp;&nbsp;Not Hispanic or Latino",
#       "&nbsp;&nbsp;&nbsp;&nbsp;Not Reported",
#       "Geographic region, n (%)",
#       "&nbsp;&nbsp;&nbsp;&nbsp;Asia",
#       "&nbsp;&nbsp;&nbsp;&nbsp;Europe",
#       "&nbsp;&nbsp;&nbsp;&nbsp;North America",
#       "&nbsp;&nbsp;&nbsp;&nbsp;South/Latin America",
#       "&nbsp;&nbsp;&nbsp;&nbsp;Rest of the world"
#     ),
#     PBO = c(
#       "52.0 (21-83)",
#       "80.40 (43.0-33.6)",
#       "29.19 (17.0-46.2)",
#       "170 (50.9)",
#       "",
#       "19 (5.7)",
#       "14 (4.2)",
#       "1 (0.3)",
#       "279 (83.5)",
#       "21 (6.3)",
#       "",
#       "94 (28.1)",
#       "165 (49.4)",
#       "75 (22.5)",
#       "",
#       "13 (3.9)",
#       "172 (51.5)",
#       "50 (15.0)",
#       "97 (29.0)",
#       "2 (0.6)"
#     ),
#     DEUC = c(
#       "52.0 (23-86)",
#       "83.00 (38.5-138.5)",
#       "29.40 (15.6-57.2)",
#       "164 (48.8)",
#       "",
#       "17 (5.1)",
#       "25 (7.4)",
#       "4 (1.2)",
#       "263 (78.3)",
#       "27 (8.0)",
#       "",
#       "101 (30.1)",
#       "165 (49.1)",
#       "70 (20.8)",
#       "",
#       "25 (7.4)",
#       "171 (50.9)",
#       "51 (15.2)",
#       "88 (26.2)",
#       "1 (0.3)"
#     )
#   )

#   # Create the gt table
#   rt_dm_demo_gt_data |>
#     gt() |>
#     cols_label(
#       Demographics = "Demographics",
#       PBO = html("PBO<br>(n = 334)"),
#       DEUC = html("DEUC<br>6 mg QD<br>(n = 336)")
#     ) |>
#     tab_style(
#       style = cell_text(weight = "bold", align = "center"),
#       locations = cells_column_labels()
#     ) |>
#     tab_style(
#       cell_fill(color = "#a69f9f"),
#       locations = cells_column_labels(columns = PBO)
#     ) |>
#     tab_style(
#       cell_fill(color = "#eee7e7"),
#       locations = cells_column_labels(columns = Demographics)
#     ) |>
#     tab_style(
#       cell_fill(color = "#33d6f1"),
#       locations = cells_column_labels(columns = DEUC)
#     ) |>
#     cols_align(
#       align = "center",
#       columns = c(PBO, DEUC)
#     ) |>
#     tab_style(
#       style = cell_borders(
#         sides = "all",
#         color = "black",
#         weight = px(1)
#       ),
#       locations = cells_body()
#     ) |>
#     tab_style(
#       style = cell_borders(
#         sides = "all",
#         color = "black",
#         weight = px(2)
#       ),
#       locations = cells_column_labels()
#     ) |>
#     tab_style(
#       style = cell_text(weight = "bold"),
#       locations = cells_body(
#         columns = Demographics,
#         rows = Demographics %in%
#           c(
#             "Age, median (range), years",
#             "Weight, median (range), kg",
#             "BMI, median (range), kg/m²",
#             "Female, n (%)",
#             "Race, n (%)",
#             "Ethnicity, n (%)",
#             "Geographic region, n (%)"
#           )
#       )
#     ) |>
#     fmt_markdown(columns = Demographics)
# }

# rt_dm_demo_table()

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
    mutate(
      stat = if_else(
        str_detect(variable_label1, "n \\(%\\)$") & stat == "0",
        "0 ( 0)",
        stat
      )
    ) |>
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
      group1_level = map(group1_level, ~.x),
      variable_level = map(variable_level, ~ if (is.na(.x)) NULL else .x),
      stat = map(stat, ~ as.numeric(.x)),
      context = if_else(
        stat_name %in% c("n", "p"),
        "categorical",
        "continuous"
      ),
      fmt_fun = map(context, ~ if (.x == "continuous") 1L else 0L),
      warning = map(1:n(), ~NULL),
      error = map(1:n(), ~NULL)
    ) |>
    cards::as_card()

  return(ard_card)
}

rt_dm_basedz() |>
  gtsummary_table()

# # Method 2: bypass ARD and produce GT table directly:
# rt_dm_basedz_table <- function() {
#   rt_dm_basedz_gt_data <- tibble(
#     characteristic = c(
#       "Baseline csDMARD use, n (%)",
#       "Duration of disease, mean (SD)",
#       "hsCRP, mean (SD), mg/L",
#       "DAS28-CRP, mean (SD)",
#       "Tender joint count (68), mean (SD)",
#       "Swollen joint count (66), mean (SD)",
#       "HAQ-DI score, mean (SD)",
#       "PASI score > 1, n (%)^a^",
#       "PASI score, mean (SD)",
#       "BSA > 3%, n (%)",
#       "Enthesitis, LEI, mean (SD)",
#       "Tender enthesial points > 1, n (%)^b^",
#       "Dactylitis, LDI, mean (SD)",
#       "Tender dactylitis count ≥ 1, n (%)^a^",
#       "FACIT-Fatigue score, mean (SD)",
#       "SF-36 PCS score, mean (SD)",
#       "PsA-modified SydH score, mean (SD)"
#     ),
#     pbo = c(
#       "231 (69.2)",
#       "8.03 (7.604)",
#       "14.180 (19.3990)",
#       "5.018 (0.9432)",
#       "19.0 (13.74)",
#       "10.3 (7.47)",
#       "1.3308 (0.61844)",
#       "261 (78.1)",
#       "5.75 (6.944)",
#       "193 (57.8)",
#       "1.1 (1.53)",
#       "107 (32.0)",
#       "53.543 (78.2663)",
#       "108 (32.3)",
#       "29.4 (10.77)",
#       "35.175 (7.9406)",
#       "25.564 (38.0108)"
#     ),
#     deuc = c(
#       "237 (70.5)",
#       "7.27 (8.287)",
#       "12.909 (16.0611)",
#       "4.985 (0.9356)",
#       "19.0 (12.79)",
#       "10.7 (6.86)",
#       "1.4061 (0.62753)",
#       "262 (78.0)",
#       "5.25 (5.737)",
#       "178 (53.0)",
#       "1.4 (1.70)",
#       "127 (37.8)",
#       "67.328 (122.9399)",
#       "132 (39.3)",
#       "28.9 (11.11)",
#       "34.802 (7.6539)",
#       "18.400 (31.8434)"
#     )
#   )

#   rt_dm_basedz_gt_data |>
#     gt() |>
#     cols_label(
#       characteristic = "Disease and Clinical Characteristics",
#       pbo = md("PBO<br>(n = 334)"),
#       deuc = md("**DEUC<br>6 mg QD<br>(n = 336)**")
#     ) |>
#     tab_style(
#       style = cell_text(weight = "bold"),
#       locations = cells_column_labels()
#     ) |>
#     tab_style(
#       style = list(
#         cell_fill(color = "#eee7e7"),
#         cell_text(weight = "bold", color = "black")
#       ),
#       locations = cells_column_labels(columns = characteristic)
#     ) |>
#     tab_style(
#       style = list(
#         cell_fill(color = "#a69f9f"),
#         cell_text(weight = "bold", color = "black")
#       ),
#       locations = cells_column_labels(columns = pbo)
#     ) |>
#     tab_style(
#       style = list(
#         cell_fill(color = "#33d6f1"),
#         cell_text(weight = "bold", color = "black")
#       ),
#       locations = cells_column_labels(columns = deuc)
#     ) |>
#     tab_style(
#       style = cell_borders(
#         sides = "all",
#         color = "black",
#         weight = px(1)
#       ),
#       locations = cells_body()
#     ) |>
#     tab_style(
#       style = cell_borders(
#         sides = "all",
#         color = "black",
#         weight = px(2)
#       ),
#       locations = cells_column_labels()
#     ) |>
#     cols_align(
#       align = "center",
#       columns = c(pbo, deuc)
#     ) |>
#     fmt_markdown(columns = everything())
# }

# rt_dm_basedz_table()

# ---- Slide 9 -----------------------------------------------------------------
