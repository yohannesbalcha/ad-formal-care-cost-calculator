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

For shinyapps.io deployment:

```r
install.packages("rsconnect")
rsconnect::setAccountInfo(
  name = "YOUR_ACCOUNT",
  token = "YOUR_TOKEN",
  secret = "YOUR_SECRET"
)
rsconnect::deployApp("shiny")
```

Do not commit `rsconnect` account tokens, local deployment logs, or private data files.

