# Public cost-function implementation using coefficient tables.
# This script does not require patient-level data or fitted model objects.

predict_ad_formal_care_cost <- function(newdata,
                                        coef_part1_path = "shiny/model_coefficients_part1_logit.csv",
                                        coef_part2_path = "shiny/model_coefficients_part2_gamma_log.csv") {
  coef_p1 <- read.csv(coef_part1_path, stringsAsFactors = FALSE, check.names = FALSE)
  coef_p2 <- read.csv(coef_part2_path, stringsAsFactors = FALSE, check.names = FALSE)

  beta_p1 <- setNames(coef_p1$estimate, coef_p1$term)
  beta_p2 <- setNames(coef_p2$estimate, coef_p2$term)

  state_levels <- c("No dementia", "Very mild", "Mild", "Moderate", "Severe")
  age_levels <- c("<65", "65-74", "75-84", "85-89", "90+")
  sex_levels <- c("FEMALE", "MALE")
  ysdx_levels <- as.character(0:7)
  died_levels <- c("Alive", "Died")
  inst_levels <- c("No", "Yes")

  newdata$state_uc <- factor(newdata$state_uc, levels = state_levels)
  newdata$age_band <- factor(newdata$age_band, levels = age_levels)
  newdata$sex <- factor(newdata$sex, levels = sex_levels)
  newdata$ysdx <- factor(newdata$ysdx, levels = ysdx_levels)
  newdata$died <- factor(newdata$died, levels = died_levels)
  newdata$inst_flag <- factor(newdata$inst_flag, levels = inst_levels)

  x1 <- model.matrix(~ state_uc + age_band + sex + ysdx + died, data = newdata)
  x2 <- model.matrix(~ (age_band + sex + ysdx + state_uc) * died * inst_flag, data = newdata)

  p_any <- plogis(as.numeric(x1 %*% beta_p1[colnames(x1)]))
  mean_positive_cost <- exp(as.numeric(x2 %*% beta_p2[colnames(x2)]))

  data.frame(
    newdata,
    probability_any_cost = p_any,
    mean_positive_cost = mean_positive_cost,
    expected_annual_cost = p_any * mean_positive_cost
  )
}

example_data <- read.csv("inst/synthetic_model_input.csv", stringsAsFactors = FALSE)
predictions <- predict_ad_formal_care_cost(example_data)
print(predictions)
