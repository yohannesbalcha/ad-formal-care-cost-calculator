## Deploy the public Shiny calculator to shinyapps.io.
##
## One-time setup:
##   1. Open https://www.shinyapps.io/
##   2. Go to Account > Tokens
##   3. Copy the rsconnect::setAccountInfo(...) command shown there
##   4. Run that command locally in R, but do not save it in this repository
##
## Deploy:
##   source("deploy/deploy_shinyapps.R")

if (!requireNamespace("rsconnect", quietly = TRUE)) {
  install.packages("rsconnect")
}

this_file <- if (!is.null(sys.frames()[[1]]$ofile)) {
  sys.frames()[[1]]$ofile
} else if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  rstudioapi::getActiveDocumentContext()$path
} else {
  file.path(getwd(), "deploy", "deploy_shinyapps.R")
}

repo_root <- normalizePath(file.path(dirname(this_file), ".."), mustWork = TRUE)
app_dir <- file.path(repo_root, "shiny")

required_files <- file.path(
  app_dir,
  c(
    "app.R",
    "model_coefficients_part1_logit.csv",
    "model_coefficients_part2_gamma_log.csv"
  )
)

missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files) > 0L) {
  stop(
    "Cannot deploy. Missing required app file(s):\n",
    paste(missing_files, collapse = "\n"),
    call. = FALSE
  )
}

rsconnect::deployApp(
  appDir = app_dir,
  appName = "ad-formal-care-cost-calculator",
  appTitle = "AD Formal-Care Cost Calculator"
)
