# AD Formal-Care Cost Calculator

This repository provides a public implementation of a two-part cost function for estimating annual formal-care costs in Alzheimer disease dementia.

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

