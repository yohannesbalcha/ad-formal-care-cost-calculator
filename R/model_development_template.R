# Public template: two-part annual formal-care cost-function development.
#
# This template documents the model structure used in the study. It is intended
# for users with approved access to an analysis dataset containing the variables
# listed below. The Swedish registry data used in the study are not included in
# this repository.

suppressPackageStartupMessages({
  library(stats)
})

required_cols <- c(
  "LopNr",
  "cost_total",
  "any_cost",
  "state_uc",
  "age_band",
  "sex",
  "ysdx",
  "died",
  "inst_flag"
)

# Replace this with an approved local dataset.
# analysis_data <- readRDS("path/to/approved_analysis_dataset.rds")

prepare_cost_function_data <- function(analysis_data) {
  missing_cols <- setdiff(required_cols, names(analysis_data))
  if (length(missing_cols) > 0L) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)
  }

  analysis_data$state_uc <- factor(
    analysis_data$state_uc,
    levels = c("No dementia", "Very mild", "Mild", "Moderate", "Severe")
  )
  analysis_data$age_band <- factor(
    analysis_data$age_band,
    levels = c("<65", "65-74", "75-84", "85-89", "90+")
  )
  analysis_data$sex <- factor(analysis_data$sex, levels = c("FEMALE", "MALE"))
  analysis_data$ysdx <- factor(analysis_data$ysdx, levels = as.character(0:7))
  analysis_data$died <- factor(analysis_data$died, levels = c("Alive", "Died"))
  analysis_data$inst_flag <- factor(analysis_data$inst_flag, levels = c("No", "Yes"))

  analysis_data
}

fit_cost_function <- function(analysis_data) {
  dt <- prepare_cost_function_data(analysis_data)

  part1_formula <- any_cost ~ state_uc + age_band + sex + ysdx + died
  part2_formula <- cost_total ~ (age_band + sex + ysdx + state_uc) * died * inst_flag

  part1 <- glm(part1_formula, data = dt, family = binomial("logit"))
  part2 <- glm(part2_formula, data = dt[dt$any_cost == 1, ], family = Gamma("log"))

  list(part1 = part1, part2 = part2)
}

predict_cost_function <- function(fits, newdata) {
  nd <- prepare_cost_function_data(newdata)
  p_any <- predict(fits$part1, newdata = nd, type = "response")
  mean_positive_cost <- predict(fits$part2, newdata = nd, type = "response")

  data.frame(
    nd,
    probability_any_cost = p_any,
    mean_positive_cost = mean_positive_cost,
    expected_annual_cost = p_any * mean_positive_cost
  )
}
