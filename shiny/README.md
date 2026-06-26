# Shiny App

Run locally from the repository root:

```r
shiny::runApp("shiny")
```

The app uses public coefficient tables:

- `model_coefficients_part1_logit.csv`
- `model_coefficients_part2_gamma_log.csv`

It does not load fitted model objects or patient-level data.

## Deployment

For shinyapps.io deployment, create a shinyapps.io account and copy the `rsconnect::setAccountInfo(...)` command from **Account > Tokens**. Run that command locally in R. Do not save it in this repository.

From the repository root, deploy with:

```r
source("deploy/deploy_shinyapps.R")
```

Do not commit account tokens, local deployment logs, or private data files.

