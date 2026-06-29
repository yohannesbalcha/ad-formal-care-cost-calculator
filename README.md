# Alzheimer's disease dementia Formal-Care Cost Calculator

This repository provides a public implementation of a two-part cost function for estimating annual formal-care costs in Alzheimer's disease dementia.

The calculator is intended for health economic modeling and scenario analysis. It estimates conditional expected annual formal-care costs from interval-level covariates.

## Model

The cost function uses a two-part generalized linear model:

1. Logistic regression for the probability of any formal-care cost.
2. Gamma generalized linear model with log link for positive annual formal-care costs.

The expected annual cost is calculated as:

```text
Pr(any formal-care cost) * E(cost | positive formal-care cost)
```

Predictors include dementia state, age group, sex, years since diagnosis/index interval, institutionalization during the interval, and death during the interval. Institutionalization and death are interval-level descriptors, not baseline-only prognostic predictors.

## Repository Structure

```text
shiny/
  app.R                                  # public Shiny calculator
  model_coefficients_part1_logit.csv     # public coefficient table
  model_coefficients_part2_gamma_log.csv # public coefficient table

inst/
  example_input.csv
  variable_dictionary.csv

docs/
  model_specification.md
  validation_summary.md
  data_availability.md
```

## Live Calculator

Try the calculator here: [AD Formal-Care Cost Calculator](https://yohannesbalcha.shinyapps.io/ad-formal-care-cost-calculator/)

## Running the App Locally

Install required R packages:

```r
install.packages(c("shiny", "ggplot2", "scales"))
```

Run:

```r
shiny::runApp("shiny")
```

## Data Availability

The underlying individual-level registry data cannot be shared publicly because they are subject to Swedish legal, ethical, and data-transfer restrictions. This repository does not contain patient-level data, registry extracts, fitted model objects, audit files, or internal analysis outputs.

## Interpretation

The calculator returns conditional expected annual costs. It should not be interpreted as a causal model, an individual-level clinical prediction tool, or a replacement for local costing rules. Model outputs are intended for research use in economic evaluation and resource-planning scenarios.

## Run From GitHub

Technical users can run the app directly from GitHub with R:

```r
install.packages(c("shiny", "ggplot2", "scales"))
shiny::runGitHub(
  repo = "ad-formal-care-cost-calculator",
  username = "yohannesbalcha",
  subdir = "shiny"
)
```


## Public Template Scripts

The `R/` folder contains public-safe scripts for using the coefficient tables, documenting the model structure, and generating synthetic example data. These scripts do not contain registry data, private paths, or fitted model objects.

## Synthetic Trial Data

Synthetic input files are provided in `inst/` for testing the app structure and prediction code. These data are randomly generated and are not derived from the Swedish registry data.
