# ------------------------------------------------------------------------------
# HELPERS
# ------------------------------------------------------------------------------
# options(tibble.print_max = Inf)

stat_lookup <- tibble::tribble(
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

gtsummary_table <- function(
  data,
  stats_continuous = "{median} ({p25}, {p75})",
  stats_categorical = "{n} ({p}%)"
) {
  data |>
    filter(group1_level != "Total") |>
    gtsummary::tbl_ard_summary(
      by = "TRT",
      statistic = list(
        gtsummary::all_continuous() ~ stats_continuous,
        gtsummary::all_categorical() ~ stats_categorical
      )
    ) |>
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

# ------------------------------------------------------------------------------
# rt-dm-demo.rtf
# ------------------------------------------------------------------------------
rt_dm_demo <- function(input = example_data("rt-dm-demo.rtf")) {
  temp_rtf <- withr::local_tempfile(fileext = ".rtf")

  input |>
    readr::read_file() |>
    artful:::rtf_spaces_to_nbsp() |>
    artful:::rtf_line_to_spaces() |>
    readr::write_file(temp_rtf)

  ard_ish <- artful:::rtf_to_html(temp_rtf) |>
    artful:::html_to_dataframe() |>
    artful:::manage_exceptions() |>
    artful:::strip_pagination() |>
    artful:::strip_indentation() |>
    artful:::pivot_group()

  ard_ish_parsed <- ard_ish |>
    dplyr::mutate(
      stat = dplyr::if_else(
        stringr::str_detect(variable_label1, "n \\(%\\)$") & stat == "0",
        "0 ( 0)",
        stat
      )
    ) |>
    tidyr::separate_longer_delim(
      cols = c(variable_level, stat),
      delim = ", "
    ) |>
    dplyr::mutate(
      stat_name = dplyr::case_when(
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
    dplyr::mutate(
      .id = dplyr::row_number(),
      stat_list = stringr::str_extract_all(stat, "[\\d.]+")
    ) |>
    dplyr::mutate(
      n_values = lengths(stat_list)
    ) |>
    tidyr::unnest(stat_list) |>
    dplyr::mutate(
      stat_name = dplyr::case_when(
        n_values > 1 & dplyr::row_number() == 1 ~ "n",
        n_values > 1 & dplyr::row_number() == 2 ~ "p",
        .default = stat_name
      ),
      stat = stat_list,
      .by = .id
    ) |>
    dplyr::select(
      -c(.id, stat_list, n_values)
    ) |>
    dplyr::mutate(
      stat_name = dplyr::if_else(is.na(stat_name), "n", stat_name)
    ) |>
    dplyr::filter(!is.na(stat)) |>
    dplyr::left_join(stat_lookup)

  ard <- ard_ish_parsed |>
    dplyr::mutate(
      group1_level = stringr::str_extract(
        group1_level,
        ".*?\\S+(?=\\s*(?:\\(N = |N = ))"
      )
    )

  ard <- ard |>
    dplyr::rename(
      variable = variable_label1,
      variable2_level = variable_label2
    ) |>
    dplyr::relocate(variable, .after = group1_level)

  ard_age_sex <- ard |>
    dplyr::slice(1:54)

  ard_race <- ard |>
    dplyr::slice(55:95) |>
    dplyr::select(
      tidyselect::starts_with("group"),
      variable = variable2_level,
      variable_level = variable,
      variable2_level = variable_level,
      tidyselect::starts_with("stat")
    )

  ard_ethnicity <- ard |>
    dplyr::slice(96:113)

  ard_country <- ard |>
    dplyr::slice(114:280) |>
    dplyr::select(
      tidyselect::starts_with("group"),
      variable = variable2_level,
      variable_level = variable,
      variable2_level = variable_level,
      tidyselect::starts_with("stat")
    )

  ard_weight <- ard |>
    dplyr::slice(281:345)

  ard_card <- dplyr::bind_rows(
    ard_age_sex,
    ard_race,
    ard_ethnicity,
    ard_country,
    ard_weight
  ) |>
    dplyr::mutate(variable = stringr::str_remove_all(variable, "n\\(%\\)")) |>
    dplyr::mutate(variable = stringr::str_remove_all(variable, "n \\(%\\)")) |>
    dplyr::mutate(
      variable_level = dplyr::if_else(
        variable_level %in%
          c("N", "MEAN", "SD", "MEDIAN", "Q1", "Q3", "MIN", "MAX"),
        NA,
        variable_level
      ),
      group1_level = purrr::map(group1_level, ~.x),
      variable_level = purrr::map(
        variable_level,
        ~ if (is.na(.x)) NULL else .x
      ),
      stat = purrr::map(stat, ~ as.numeric(.x)),
      context = dplyr::if_else(
        stat_name %in% c("n", "p"),
        "categorical",
        "continuous"
      ),
      fmt_fun = purrr::map(context, ~ if (.x == "continuous") 1L else 0L),
      warning = purrr::map(1:dplyr::n(), ~NULL),
      error = purrr::map(1:dplyr::n(), ~NULL)
    ) |>
    cards::as_card()

  return(ard_card)
}

# ------------------------------------------------------------------------------
# rt-dm-basedz.rtf
# ------------------------------------------------------------------------------
rt_dm_basedz <- function(input = example_data("rt-dm-basedz.rtf")) {
  temp_rtf <- withr::local_tempfile(fileext = ".rtf")

  input |>
    readr::read_file() |>
    artful:::rtf_spaces_to_nbsp() |>
    readr::write_file(temp_rtf)

  ard_ish <- artful:::rtf_to_html(temp_rtf) |>
    artful:::html_to_dataframe() |>
    artful:::manage_exceptions() |>
    artful:::strip_pagination() |>
    artful:::strip_indentation() |>
    artful:::pivot_group()

  ard_ish_parsed <- ard_ish |>
    dplyr::mutate(
      stat = dplyr::if_else(
        stringr::str_detect(variable_label1, "n \\(%\\)$") & stat == "0",
        "0 ( 0)",
        stat
      )
    ) |>
    tidyr::separate_longer_delim(
      cols = c(variable_level, stat),
      delim = ", "
    ) |>
    dplyr::mutate(
      stat_name = dplyr::case_when(
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
    dplyr::mutate(
      .id = dplyr::row_number(),
      stat_list = stringr::str_extract_all(stat, "[\\d.]+")
    ) |>
    dplyr::mutate(
      n_values = lengths(stat_list)
    ) |>
    tidyr::unnest(stat_list) |>
    dplyr::mutate(
      stat_name = dplyr::case_when(
        n_values > 1 & dplyr::row_number() == 1 ~ "n",
        n_values > 1 & dplyr::row_number() == 2 ~ "p",
        .default = stat_name
      ),
      stat = stat_list,
      .by = .id
    ) |>
    dplyr::select(
      -c(.id, stat_list, n_values)
    ) |>
    dplyr::mutate(
      stat_name = dplyr::if_else(is.na(stat_name), "n", stat_name)
    ) |>
    dplyr::filter(!is.na(stat)) |>
    dplyr::left_join(stat_lookup)

  ard <- ard_ish_parsed |>
    dplyr::mutate(
      group1_level = stringr::str_extract(
        group1_level,
        ".*?\\S+(?=\\s*(?:\\(N=|N=))"
      )
    )

  ard <- ard |>
    dplyr::rename(
      variable = variable_label1,
      variable2_level = variable_label2
    ) |>
    dplyr::relocate(variable, .after = group1_level) |>
    dplyr::mutate(variable = stringr::str_remove_all(variable, "n \\(%\\)"))

  ard_card <- ard |>
    dplyr::mutate(
      variable_level = dplyr::if_else(
        variable_level %in%
          c("N", "MEAN", "SD", "MEDIAN", "Q1", "Q3", "MIN", "MAX"),
        NA,
        variable_level
      ),
      group1_level = purrr::map(group1_level, ~.x),
      variable_level = purrr::map(
        variable_level,
        ~ if (is.na(.x)) NULL else .x
      ),
      stat = purrr::map(stat, ~ as.numeric(.x)),
      context = dplyr::if_else(
        stat_name %in% c("n", "p"),
        "categorical",
        "continuous"
      ),
      fmt_fun = purrr::map(context, ~ if (.x == "continuous") 1L else 0L),
      warning = purrr::map(1:dplyr::n(), ~NULL),
      error = purrr::map(1:dplyr::n(), ~NULL)
    ) |>
    cards::as_card()

  return(ard_card)
}

# ------------------------------------------------------------------------------
# rt-ef-acr20.rtf
# ------------------------------------------------------------------------------
rt_ef_acr20 <- function(input = example_data("rt-ef-acr20.rtf")) {
  temp_rtf <- withr::local_tempfile(fileext = ".rtf")

  input |>
    readr::read_file() |>
    artful:::rtf_spaces_to_nbsp() |>
    artful:::rtf_line_to_spaces() |>
    readr::write_file(temp_rtf)

  ard_ish <- artful:::rtf_to_html(temp_rtf) |>
    artful:::html_to_dataframe() |>
    artful:::manage_exceptions() |>
    artful:::strip_pagination() |>
    artful:::strip_indentation() |>
    artful:::pivot_group()

  ard_ish_parsed <- ard_ish |>
    dplyr::slice(-1:-2) |>
    dplyr::mutate(stat = dplyr::if_else(stat == "N.A.", NA, stat)) |>
    dplyr::mutate(
      .id = dplyr::row_number(),
      stat_list = stringr::str_extract_all(stat, "[\\d.]+")
    ) |>
    dplyr::mutate(
      n_values = lengths(stat_list)
    ) |>
    tidyr::unnest(stat_list) |>
    dplyr::mutate(
      stat_name = dplyr::case_when(
        stringr::str_detect(variable_level, "n \\(%\\)$") &
          n_values > 1 &
          dplyr::row_number() == 1 ~
          "n",
        stringr::str_detect(variable_level, "n \\(%\\)$") &
          n_values > 1 &
          dplyr::row_number() == 2 ~
          "p",
        stringr::str_detect(variable_level, "\\(95% CI\\)") &
          n_values > 1 &
          dplyr::row_number() == 1 ~
          "ci_low",
        stringr::str_detect(variable_level, "\\(95% CI\\)") &
          n_values > 1 &
          dplyr::row_number() == 2 ~
          "ci_high",
        variable_level == "P-VALUE" ~ "p_value",
        .default = NA
      ),
      stat = stat_list,
      .by = .id
    ) |>
    dplyr::select(
      -c(.id, stat_list, n_values)
    ) |>
    dplyr::filter(!is.na(stat)) |>
    dplyr::left_join(stat_lookup)

  big_n <- ard_ish_parsed |>
    dplyr::distinct(group1_level) |>
    tidyr::separate_wider_regex(
      group1_level,
      patterns = c(
        variable_label1 = ".*?\\S+",
        "\\s+",
        "(?:\\(N = |N = )",
        stat = "\\d+",
        "\\)?"
      )
    ) |>
    dplyr::mutate(stat_name = "N_header", stat_label = "N", .before = "stat")

  ard <- ard_ish_parsed |>
    dplyr::mutate(
      group1_level = stringr::str_extract(
        group1_level,
        ".*?\\S+(?=\\s*(?:\\(N = |N = ))"
      )
    )

  rt_ef_acr20 <- dplyr::bind_rows(big_n, ard) |>
    dplyr::select(
      tidyselect::starts_with("group"),
      tidyselect::starts_with("variable"),
      tidyselect::starts_with("stat")
    )

  rt_ef_acr20 |>
    dplyr::mutate(
      group1 = "Week 16",
      group1_level = dplyr::if_else(
        stat_name == "N_header",
        variable_label1,
        group1_level,
        group1_level
      ),
      variable_label1 = dplyr::if_else(
        stat_name == "N_header",
        "TOTAL NUMBER OF SUBJECTS",
        variable_label1,
        variable_label1
      ),
      stat_name = dplyr::if_else(
        stat_name == "N_header",
        "n",
        stat_name,
        stat_name
      ),
      stat_label = dplyr::if_else(
        stat_label == "N",
        "n",
        stat_label,
        stat_label
      )
    ) |>
    dplyr::bind_rows(
      tibble::tibble(
        group1 = rep("Week 16", 2),
        group1_level = c("DEUC 6 mg", "PBO"),
        variable_label1 = rep("TOTAL NUMBER OF SUBJECTS", 2),
        stat_name = rep("p", 2),
        stat_label = rep("%", 2),
        stat = rep("100", 2)
      )
    ) |>
    dplyr::mutate(
      variable = dplyr::if_else(
        is.na(variable_label1),
        variable_level,
        variable_label1
      ),
      variable_level = dplyr::if_else(
        is.na(variable_label1) | variable_level == "(95% CI)",
        NA,
        variable_level
      )
    ) |>
    dplyr::select(-variable_label1) |>
    dplyr::relocate(variable, .after = group1_level) |>
    dplyr::mutate(
      stat_name = dplyr::if_else(
        variable == "ODDS RATIO VS PLACEBO" & is.na(stat_name),
        "est",
        stat_name
      ),
      stat_label = dplyr::if_else(
        variable == "ODDS RATIO VS PLACEBO" & is.na(stat_label),
        "estimate",
        stat_label
      )
    ) |>
    dplyr::mutate(
      stat_name = dplyr::if_else(
        is.na(stat_name),
        dplyr::if_else(grepl(".", stat, fixed = TRUE), "p", "n"),
        stat_name
      ),
      stat_label = dplyr::if_else(
        is.na(stat_label),
        dplyr::if_else(grepl(".", stat, fixed = TRUE), "%", "n"),
        stat_label
      )
    ) |>
    dplyr::mutate(
      variable_level = dplyr::if_else(
        variable == "NON RESPONDERS n (%)" & is.na(variable_level),
        "TOTAL",
        variable_level
      )
    ) |>
    cards::as_card()
}

# ------------------------------------------------------------------------------
# rt-ef-aacr50.rtf
# ------------------------------------------------------------------------------
rt_ef_aacr50 <- function(input = example_data("rt-ef-aacr50.rtf")) {
  temp_rtf <- withr::local_tempfile(fileext = ".rtf")

  input |>
    readr::read_file() |>
    artful:::rtf_spaces_to_nbsp() |>
    artful:::rtf_line_to_spaces() |>
    readr::write_file(temp_rtf)

  ard_ish <- artful:::rtf_to_html(temp_rtf) |>
    artful:::html_to_dataframe() |>
    artful:::manage_exceptions() |>
    artful:::strip_pagination() |>
    artful:::strip_indentation() |>
    artful:::pivot_group()

  ard_ish_parsed <- ard_ish |>
    dplyr::filter(variable_label1 != "TOTAL NUMBER OF SUBJECTS") |>
    dplyr::mutate(stat = dplyr::if_else(stat == "N.A.", NA, stat)) |>
    dplyr::mutate(
      .id = dplyr::row_number(),
      stat_list = stringr::str_extract_all(stat, "[\\d.]+")
    ) |>
    dplyr::mutate(
      n_values = lengths(stat_list)
    ) |>
    tidyr::unnest(stat_list) |>
    dplyr::mutate(
      stat_name = dplyr::case_when(
        stringr::str_detect(variable_level, "n \\(%\\)$") &
          n_values > 1 &
          dplyr::row_number() == 1 ~
          "n",
        stringr::str_detect(variable_level, "n \\(%\\)$") &
          n_values > 1 &
          dplyr::row_number() == 2 ~
          "p",
        stringr::str_detect(variable_label1, "n \\(%\\)$") &
          n_values > 1 &
          dplyr::row_number() == 1 ~
          "n",
        stringr::str_detect(variable_label1, "n \\(%\\)$") &
          n_values > 1 &
          dplyr::row_number() == 2 ~
          "p",
        stringr::str_detect(variable_level, "\\(95% CI\\)") &
          n_values > 1 &
          dplyr::row_number() == 1 ~
          "ci_low",
        stringr::str_detect(variable_level, "\\(95% CI\\)") &
          n_values > 1 &
          dplyr::row_number() == 2 ~
          "ci_high",
        variable_label1 == "P-VALUE" & !is.na(stat) ~ "p_value",
        variable_level == "NON RESPONDERS DUE TO MISSING DATA n (%)" &
          variable_label1 == "RESPONSE RATE (%)" ~
          "p",
        .default = NA
      ),
      stat = stat_list,
      .by = .id
    ) |>
    dplyr::mutate(
      stat_name = dplyr::case_when(
        variable_label1 == "DIFFERENCE VS PLACEBO (%)" &
          !is.na(stat) &
          is.na(stat_name) ~
          "p",
        variable_label1 == "ODDS RATIO VS PLACEBO" &
          !is.na(stat) &
          is.na(stat_name) ~
          "estimate",
        .default = stat_name
      ),
    ) |>
    dplyr::select(
      -c(.id, stat_list, n_values)
    ) |>
    dplyr::left_join(stat_lookup) |>
    dplyr::filter(!is.na(stat))

  big_n <- ard_ish_parsed |>
    dplyr::distinct(group1_level) |>
    tidyr::separate_wider_regex(
      group1_level,
      patterns = c(
        variable_label1 = ".*?\\S+",
        "\\s+",
        "(?:\\(N = |N = )",
        stat = "\\d+",
        "\\)?"
      )
    ) |>
    dplyr::mutate(stat_name = "N_header", stat_label = "N", .before = "stat")

  ard <- ard_ish_parsed |>
    dplyr::mutate(
      group1_level = stringr::str_extract(
        group1_level,
        ".*?\\S+(?=\\s*(?:\\(N = |N = ))"
      )
    )

  rt_ef_aacr50 <- dplyr::bind_rows(
    dplyr::mutate(big_n, variable_label2 = "WEEK 2"),
    dplyr::mutate(big_n, variable_label2 = "WEEK 4"),
    dplyr::mutate(big_n, variable_label2 = "WEEK 8"),
    dplyr::mutate(big_n, variable_label2 = "WEEK 12"),
    dplyr::mutate(big_n, variable_label2 = "WEEK 16"),
    ard
  ) |>
    dplyr::select(
      tidyselect::starts_with("group"),
      tidyselect::starts_with("variable"),
      tidyselect::starts_with("stat")
    )

  rt_ef_aacr50 |>
    dplyr::mutate(
      group1 = variable_label2,
      variable_label2 = NULL
    ) |>
    dplyr::mutate(
      group1_level = dplyr::if_else(
        stat_name == "N_header",
        variable_label1,
        group1_level,
        group1_level
      ),
      variable_label1 = dplyr::if_else(
        stat_name == "N_header",
        "TOTAL NUMBER OF SUBJECTS",
        variable_label1,
        variable_label1
      ),
      stat_name = dplyr::if_else(
        stat_name == "N_header",
        "n",
        stat_name,
        stat_name
      ),
      stat_label = dplyr::if_else(
        stat_label == "N",
        "n",
        stat_label,
        stat_label
      )
    ) |>
    dplyr::bind_rows(
      tibble::tibble(
        group1 = rep(paste("WEEK", c(2, 4, 8, 12, 16)), each = 2),
        group1_level = rep(c("DEUC 6 mg", "PBO"), 5),
        variable_label1 = rep("TOTAL NUMBER OF SUBJECTS", 10),
        stat_name = rep("p", 10),
        stat_label = rep("%", 10),
        stat = rep("100", 10)
      )
    ) |>
    dplyr::mutate(
      variable = dplyr::if_else(
        is.na(variable_label1),
        variable_level,
        variable_label1
      ),
      variable_level = dplyr::if_else(
        is.na(variable_label1) | variable_level == "(95% CI)",
        NA,
        variable_level
      )
    ) |>
    dplyr::select(-variable_label1) |>
    dplyr::relocate(variable, .after = group1_level) |>
    dplyr::mutate(
      variable_level = dplyr::if_else(
        variable == "NON RESPONDERS n (%)" & is.na(variable_level),
        "TOTAL",
        dplyr::if_else(
          variable_level == "(95% CI)",
          NA,
          dplyr::if_else(variable == "RESPONSE RATE (%)", NA, variable_level)
        )
      )
    ) |>
    cards::as_card()
}

# ------------------------------------------------------------------------------
# rt-ef-aacr70.rtf
# ------------------------------------------------------------------------------
rt_ef_aacr70 <- function(input = example_data("rt-ef-aacr70.rtf")) {
  temp_rtf <- withr::local_tempfile(fileext = ".rtf")

  input |>
    readr::read_file() |>
    artful:::rtf_spaces_to_nbsp() |>
    artful:::rtf_line_to_spaces() |>
    readr::write_file(temp_rtf)

  ard_ish <- artful:::rtf_to_html(temp_rtf) |>
    artful:::html_to_dataframe() |>
    artful:::manage_exceptions() |>
    artful:::strip_pagination() |>
    artful:::strip_indentation() |>
    artful:::pivot_group()

  ard_ish_parsed <- ard_ish |>
    dplyr::filter(variable_label1 != "TOTAL NUMBER OF SUBJECTS") |>
    dplyr::mutate(stat = dplyr::if_else(stat == "N.A.", NA, stat)) |>
    dplyr::filter(!stringr::str_detect(stat, "N.E.")) |>
    dplyr::mutate(
      .id = dplyr::row_number(),
      stat_list = stringr::str_extract_all(stat, "[\\d.]+")
    ) |>
    dplyr::mutate(
      n_values = lengths(stat_list)
    ) |>
    tidyr::unnest(stat_list) |>
    dplyr::mutate(
      stat_name = dplyr::case_when(
        stringr::str_detect(variable_level, "n \\(%\\)$") &
          n_values > 1 &
          dplyr::row_number() == 1 ~
          "n",
        stringr::str_detect(variable_level, "n \\(%\\)$") &
          n_values > 1 &
          dplyr::row_number() == 2 ~
          "p",
        stringr::str_detect(variable_label1, "n \\(%\\)$") &
          n_values > 1 &
          dplyr::row_number() == 1 ~
          "n",
        stringr::str_detect(variable_label1, "n \\(%\\)$") &
          n_values > 1 &
          dplyr::row_number() == 2 ~
          "p",
        stringr::str_detect(variable_level, "\\(95% CI\\)") &
          n_values > 1 &
          dplyr::row_number() == 1 ~
          "ci_low",
        stringr::str_detect(variable_level, "\\(95% CI\\)") &
          n_values > 1 &
          dplyr::row_number() == 2 ~
          "ci_high",
        variable_label1 == "P-VALUE" & !is.na(stat) ~ "p_value",
        variable_level == "NON RESPONDERS DUE TO MISSING DATA n (%)" &
          variable_label1 == "RESPONSE RATE (%)" ~
          "p",
        variable_label1 == "RESPONDERS n (%)" & stat == "0" ~ "n",
        .default = NA
      ),
      stat = stat_list,
      .by = .id
    ) |>
    dplyr::mutate(
      stat_name = dplyr::case_when(
        variable_label1 == "DIFFERENCE VS PLACEBO (%)" &
          !is.na(stat) &
          is.na(stat_name) ~
          "p",
        variable_label1 == "ODDS RATIO VS PLACEBO" &
          !is.na(stat) &
          is.na(stat_name) ~
          "estimate",
        .default = stat_name
      ),
    ) |>
    dplyr::select(
      -c(.id, stat_list, n_values)
    ) |>
    dplyr::left_join(stat_lookup) |>
    dplyr::filter(!is.na(stat))

  big_n <- ard_ish_parsed |>
    dplyr::distinct(group1_level) |>
    tidyr::separate_wider_regex(
      group1_level,
      patterns = c(
        variable_label1 = ".*?\\S+",
        "\\s+",
        "(?:\\(N = |N = )",
        stat = "\\d+",
        "\\)?"
      )
    ) |>
    dplyr::mutate(stat_name = "N_header", stat_label = "N", .before = "stat")

  ard <- ard_ish_parsed |>
    dplyr::mutate(
      group1_level = stringr::str_extract(
        group1_level,
        ".*?\\S+(?=\\s*(?:\\(N = |N = ))"
      )
    )

  rt_ef_aacr70 <- dplyr::bind_rows(
    dplyr::mutate(big_n, variable_label2 = "WEEK 2"),
    dplyr::mutate(big_n, variable_label2 = "WEEK 4"),
    dplyr::mutate(big_n, variable_label2 = "WEEK 8"),
    dplyr::mutate(big_n, variable_label2 = "WEEK 12"),
    dplyr::mutate(big_n, variable_label2 = "WEEK 16"),
    ard
  ) |>
    dplyr::select(
      tidyselect::starts_with("group"),
      tidyselect::starts_with("variable"),
      tidyselect::starts_with("stat")
    )

  rt_ef_aacr70 |>
    dplyr::mutate(
      group1 = variable_label2,
      variable_label2 = NULL
    ) |>
    dplyr::mutate(
      group1_level = dplyr::if_else(
        stat_name == "N_header",
        variable_label1,
        group1_level,
        group1_level
      ),
      variable_label1 = dplyr::if_else(
        stat_name == "N_header",
        "TOTAL NUMBER OF SUBJECTS",
        variable_label1,
        variable_label1
      ),
      stat_name = dplyr::if_else(
        stat_name == "N_header",
        "n",
        stat_name,
        stat_name
      ),
      stat_label = dplyr::if_else(
        stat_label == "N",
        "n",
        stat_label,
        stat_label
      )
    ) |>
    dplyr::bind_rows(
      tibble::tibble(
        group1 = rep(paste("WEEK", c(2, 4, 8, 12, 16)), each = 2),
        group1_level = rep(c("DEUC 6 mg", "PBO"), 5),
        variable_label1 = rep("TOTAL NUMBER OF SUBJECTS", 10),
        stat_name = rep("p", 10),
        stat_label = rep("%", 10),
        stat = rep("100", 10)
      )
    ) |>
    dplyr::mutate(
      variable = dplyr::if_else(
        is.na(variable_label1),
        variable_level,
        variable_label1
      ),
      variable_level = dplyr::if_else(
        is.na(variable_label1) | variable_level == "(95% CI)",
        NA,
        variable_level
      )
    ) |>
    dplyr::select(-variable_label1) |>
    dplyr::relocate(variable, .after = group1_level) |>
    dplyr::mutate(
      variable_level = dplyr::if_else(
        variable == "NON RESPONDERS n (%)" & is.na(variable_level),
        "TOTAL",
        dplyr::if_else(
          variable_level == "(95% CI)",
          NA,
          dplyr::if_else(variable == "RESPONSE RATE (%)", NA, variable_level)
        )
      )
    ) |>
    cards::as_card()
}

# ------------------------------------------------------------------------------
# rt-ae-ae1.rtf | Overall Safety Summary: Weeks 0-16
# ------------------------------------------------------------------------------
rt_ae_ae1 <- function(input = example_data("rt-ae-ae1.rtf")) {
  temp_rtf <- withr::local_tempfile(fileext = ".rtf")

  input |>
    readr::read_file() |>
    artful:::rtf_spaces_to_nbsp() |>
    artful:::rtf_line_to_spaces() |>
    readr::write_file(temp_rtf)

  ard_ish <- artful:::rtf_to_html(temp_rtf) |>
    artful:::html_to_dataframe() |>
    artful:::manage_exceptions() |>
    artful:::strip_pagination() |>
    artful:::strip_indentation() |>
    artful:::pivot_group()

  ard_ish_parsed <- ard_ish |>
    dplyr::rename(variable = variable_level) |>
    dplyr::mutate(
      .id = dplyr::row_number(),
      stat_list = stringr::str_extract_all(stat, "[\\d.]+")
    ) |>
    dplyr::mutate(
      n_values = lengths(stat_list)
    ) |>
    tidyr::unnest(stat_list) |>
    dplyr::mutate(
      stat_name = dplyr::case_when(
        variable != "DEATHs" &
          n_values > 1 &
          dplyr::row_number() == 1 ~
          "n",
        variable != "DEATHs" &
          n_values > 1 &
          dplyr::row_number() == 2 ~
          "p",
        .default = "n"
      ),
      stat = stat_list,
      .by = .id
    ) |>
    dplyr::select(
      -c(.id, stat_list, n_values)
    ) |>
    dplyr::left_join(stat_lookup)

  ard <- ard_ish_parsed |>
    dplyr::mutate(
      group1_level = stringr::str_extract(
        group1_level,
        ".*?\\S+(?=\\s*(?:\\(N = |N = ))"
      )
    )

  ard_card <- ard |>
    dplyr::mutate(
      group1_level = purrr::map(group1_level, ~.x),
      variable = purrr::map(
        variable,
        ~ if (is.na(.x)) NULL else .x
      ),
      stat = purrr::map(stat, ~ as.numeric(.x)),
      context = dplyr::if_else(
        stat_name %in% c("n", "p"),
        "categorical",
        "continuous"
      ),
      fmt_fun = purrr::map(context, ~ if (.x == "continuous") 1L else 0L),
      warning = purrr::map(1:dplyr::n(), ~NULL),
      error = purrr::map(1:dplyr::n(), ~NULL)
    ) |>
    cards::as_card() |>
    dplyr::mutate(
      dplyr::across(
        c(group1_level, variable),
        unlist
      )
    ) |>
    mutate(variable_level = NA, .after = variable)

  return(ard_card)
}

# ------------------------------------------------------------------------------
# rt-ae-saesoc1.rtf | Overall Safety Summary: Weeks 0-16
# ------------------------------------------------------------------------------
rt_ae_saesoc1 <- function(input = example_data("rt-ae-saesoc1.rtf")) {
  temp_rtf <- withr::local_tempfile(fileext = ".rtf")

  input |>
    readr::read_file() |>
    artful:::rtf_spaces_to_nbsp() |>
    artful:::rtf_line_to_spaces() |>
    readr::write_file(temp_rtf)

  ard_ish <- artful:::rtf_to_html(temp_rtf) |>
    artful:::html_to_dataframe() |>
    artful:::manage_exceptions() |>
    artful:::strip_pagination() |>
    artful:::strip_indentation() |>
    artful:::pivot_group()

  ard_ish_parsed <- ard_ish |>
    dplyr::mutate(stat = dplyr::if_else(stat == "N.A.", NA, stat)) |>
    dplyr::mutate(
      .id = dplyr::row_number(),
      stat_list = stringr::str_extract_all(stat, "[\\d.]+")
    ) |>
    dplyr::mutate(
      n_values = lengths(stat_list)
    ) |>
    tidyr::unnest(stat_list) |>
    dplyr::filter(!is.na(stat)) |>
    dplyr::mutate(
      stat_name = dplyr::case_when(
        variable_level == "RATE DIFFERENCE VS PLACEBO (95% CI)" &
          n_values == 3 &
          dplyr::row_number() == 1 ~
          "estimate",
        variable_level == "RATE DIFFERENCE VS PLACEBO (95% CI)" &
          n_values == 3 &
          dplyr::row_number() == 2 ~
          "ci_low",
        variable_level == "RATE DIFFERENCE VS PLACEBO (95% CI)" &
          n_values == 3 &
          dplyr::row_number() == 3 ~
          "ci_high",
        stat != "0" &
          n_values > 1 &
          dplyr::row_number() == 1 ~
          "n",
        variable_level != "DEATHs" &
          n_values > 1 &
          dplyr::row_number() == 2 ~
          "p",
        .default = "n"
      ),
      stat = stat_list,
      .by = .id
    ) |>
    dplyr::select(
      -c(.id, stat_list, n_values)
    ) |>
    dplyr::left_join(stat_lookup)

  ard <- ard_ish_parsed |>
    dplyr::mutate(
      group1_level = stringr::str_extract(
        group1_level,
        ".*?\\S+(?=\\s*(?:\\(N = |N = ))"
      )
    )

  ard <- ard |>
    dplyr::rename(variable = variable_label1) |>
    dplyr::relocate(variable, .after = group1_level) |>
    dplyr::mutate(variable_level = stringr::str_squish(variable_level))

  ard_card <- ard |>
    dplyr::mutate(
      group1_level = purrr::map(group1_level, ~.x),
      variable_level = purrr::map(
        variable_level,
        ~ if (is.na(.x)) NULL else .x
      ),
      stat = purrr::map(stat, ~ as.numeric(.x)),
      context = dplyr::if_else(
        stat_name %in% c("n", "p"),
        "categorical",
        "continuous"
      ),
      fmt_fun = purrr::map(context, ~ if (.x == "continuous") 1L else 0L),
      warning = purrr::map(1:dplyr::n(), ~NULL),
      error = purrr::map(1:dplyr::n(), ~NULL)
    ) |>
    dplyr::filter(context != "continuous") |> # We don't want "estimate", "ci_low", "ci_high"
    tidyr::complete(
      # All combinations of variable an variable_level must contain n and p stats otherwise gtsummary complains
      tidyr::nesting(group1, group1_level),
      tidyr::nesting(variable, variable_level),
      stat_name = c("n", "p"),
      fill = list(
        stat = list(NA),
        stat_label = NA_character_,
        context = "categorical",
        fmt_fun = list(0L),
        warning = list(NULL),
        error = list(NULL)
      )
    ) |>
    dplyr::mutate(
      stat_label = dplyr::case_when(
        stat_name == "n" ~ "n",
        stat_name == "p" ~ "%",
        TRUE ~ stat_label
      )
    ) |>
    cards::as_card()

  return(ard_card)
}

# ------------------------------------------------------------------------------
# ? | AEs of Special Interest Summary Occurring in ≥ 2 Participantsa: Weeks 0-16
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# ALL FUNS
# ------------------------------------------------------------------------------
# rt_dm_demo()
# rt_dm_basedz()
# rt_ef_acr20()
# rt_ef_aacr50()
# rt_ef_aacr70()
# rt_ae_ae1()
# rt_ae_saesoc1()

# ------------------------------------------------------------------------------
# GTSUMMARY hacks
# ------------------------------------------------------------------------------
# pkgload::load_all()

# rt_ae_ae1() |>
#   dplyr::filter(group1_level != "Total") |>
#   gtsummary::tbl_ard_summary(
#     by = "TRT",
#     statistic = list(
#       "DEATHs" ~ "{n}",
#       "AEs" ~ "{n} ({p}%)",
#       "TREATMENT RELATED AEs" ~ "{n} ({p}%)",
#       "SAEs" ~ "{n} ({p}%)",
#       "TREATMENT RELATED SAEs" ~ "{n} ({p}%)",
#       "AEs LEADING TO DC" ~ "{n} ({p}%)"
#     )
#   ) |>
#   gtsummary::add_stat_label() |>
#   gtsummary::modify_header(
#     gtsummary::all_stat_cols() ~ "**{level}**"
#   ) |>
#   gtsummary::as_gt() |>
#   gt::tab_style(
#     gt::cell_fill("#eee7e7"),
#     gt::cells_column_labels(label)
#   ) |>
#   gt::tab_style(
#     gt::cell_fill("#a69f9f"),
#     gt::cells_column_labels(stat_1)
#   ) |>
#   gt::tab_style(
#     gt::cell_fill("#33d6f1"),
#     gt::cells_column_labels(stat_2)
#   )

# rt_ae_saesoc1() |>
#   dplyr::filter(group1_level != "Total") |>
#   gtsummary::tbl_ard_summary(
#     by = "TRT",
#     statistic = list(
#       "TOTAL SUBJECTS WITH AN EVENT" ~ "{n}",
#       "Infections and infestations" ~ "{n} ({p}%)",
#       "Injury, poisoning and procedural complications" ~ "{n} ({p}%)",
#       "Cardiac disorders" ~ "{n} ({p}%)",
#       "Eye disorders" ~ "{n} ({p}%)",
#       "Gastrointestinal disorders" ~ "{n} ({p}%)",
#       "Nervous system disorders" ~ "{n} ({p}%)",
#       "Psychiatric disorders" ~ "{n} ({p}%)",
#       "Reproductive system and breast disorders" ~ "{n} ({p}%)",
#       "Skin and subcutaneous tissue disorders" ~ "{n} ({p}%)"
#     )
#   ) |>
#   gtsummary::add_stat_label() |>
#   gtsummary::modify_header(
#     gtsummary::all_stat_cols() ~ "**{level}**"
#   ) |>
#   gtsummary::as_gt() |>
#   gt::tab_style(
#     gt::cell_fill("#eee7e7"),
#     gt::cells_column_labels(label)
#   ) |>
#   gt::tab_style(
#     gt::cell_fill("#a69f9f"),
#     gt::cells_column_labels(stat_1)
#   ) |>
#   gt::tab_style(
#     gt::cell_fill("#33d6f1"),
#     gt::cells_column_labels(stat_2)
#   )
