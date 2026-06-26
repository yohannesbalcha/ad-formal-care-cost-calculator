# Generate synthetic example input data for the public cost calculator.
# These rows are artificial and are not derived from Swedish registry data.

set.seed(20260626)

n <- 100
state_levels <- c("No dementia", "Very mild", "Mild", "Moderate", "Severe")
age_levels <- c("<65", "65-74", "75-84", "85-89", "90+")
sex_levels <- c("FEMALE", "MALE")
ysdx_levels <- as.character(0:7)
died_levels <- c("Alive", "Died")
inst_levels <- c("No", "Yes")

synthetic <- data.frame(
  state_uc = sample(state_levels, n, replace = TRUE, prob = c(0.35, 0.18, 0.22, 0.18, 0.07)),
  age_band = sample(age_levels, n, replace = TRUE, prob = c(0.05, 0.18, 0.42, 0.23, 0.12)),
  sex = sample(sex_levels, n, replace = TRUE, prob = c(0.58, 0.42)),
  ysdx = sample(ysdx_levels, n, replace = TRUE, prob = c(0.24, 0.18, 0.16, 0.13, 0.11, 0.08, 0.06, 0.04)),
  died = sample(died_levels, n, replace = TRUE, prob = c(0.88, 0.12)),
  inst_flag = sample(inst_levels, n, replace = TRUE, prob = c(0.74, 0.26))
)

write.csv(synthetic, "inst/synthetic_model_input.csv", row.names = FALSE)
