required_packages <- c("shiny", "ggplot2", "scales")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0L) {
  stop(
    "Missing required package(s): ",
    paste(missing_packages, collapse = ", "),
    "\nInstall with: install.packages(c(",
    paste(sprintf('\"%s\"', missing_packages), collapse = ", "),
    "))",
    call. = FALSE
  )
}

suppressPackageStartupMessages({
  library(shiny)
  library(ggplot2)
  library(scales)
})

app_dir <- normalizePath(getwd(), mustWork = TRUE)
if (basename(app_dir) != "shiny" && dir.exists(file.path(app_dir, "shiny"))) {
  app_dir <- file.path(app_dir, "shiny")
}

coef_p1 <- read.csv(
  file.path(app_dir, "model_coefficients_part1_logit.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
coef_p2 <- read.csv(
  file.path(app_dir, "model_coefficients_part2_gamma_log.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

coef_vector <- function(coef_table) {
  out <- coef_table$estimate
  names(out) <- coef_table$term
  out
}

beta_p1 <- coef_vector(coef_p1)
beta_p2 <- coef_vector(coef_p2)

state_levels <- c("No dementia", "Very mild", "Mild", "Moderate", "Severe")
age_levels <- c("<65", "65-74", "75-84", "85-89", "90+")
sex_levels <- c("FEMALE", "MALE")
ysdx_levels <- as.character(0:7)
died_levels <- c("Alive", "Died")
inst_levels <- c("No", "Yes")

form_p1 <- ~ state_uc + age_band + sex + ysdx + died
form_p2 <- ~ (age_band + sex + ysdx + state_uc) * died * inst_flag

make_newdata <- function(state_uc, age_band, sex, ysdx, died, inst_flag) {
  data.frame(
    state_uc = factor(state_uc, levels = state_levels),
    age_band = factor(age_band, levels = age_levels),
    sex = factor(sex, levels = sex_levels),
    ysdx = factor(ysdx, levels = ysdx_levels),
    died = factor(died, levels = died_levels),
    inst_flag = factor(inst_flag, levels = inst_levels)
  )
}

predict_from_coefficients <- function(newdata) {
  x1 <- model.matrix(form_p1, data = newdata)
  x2 <- model.matrix(form_p2, data = newdata)

  missing_p1 <- setdiff(colnames(x1), names(beta_p1))
  missing_p2 <- setdiff(colnames(x2), names(beta_p2))
  if (length(missing_p1) > 0L || length(missing_p2) > 0L) {
    stop(
      "Coefficient table does not match model matrix. Missing terms: ",
      paste(c(missing_p1, missing_p2), collapse = ", "),
      call. = FALSE
    )
  }

  eta_p1 <- as.numeric(x1 %*% beta_p1[colnames(x1)])
  eta_p2 <- as.numeric(x2 %*% beta_p2[colnames(x2)])

  probability_any_cost <- plogis(eta_p1)
  positive_cost_mean <- exp(eta_p2)
  predicted_annual_cost <- probability_any_cost * positive_cost_mean

  data.frame(
    probability_any_cost = probability_any_cost,
    positive_cost_mean = positive_cost_mean,
    predicted_annual_cost = predicted_annual_cost
  )
}

format_money <- function(x) {
  paste0("SEK ", scales::comma(round(x, 0)))
}

ui <- fluidPage(
  titlePanel("Annual Formal-Care Cost Calculator for Alzheimer Disease Dementia"),

  tags$div(
    class = "alert alert-info",
    tags$strong("Interpretation: "),
    "This calculator estimates conditional expected annual formal-care costs for specified interval-level covariates. ",
    "It is intended for research and economic-model scenarios, not causal inference or individual clinical decision-making."
  ),

  sidebarLayout(
    sidebarPanel(
      selectInput("state_uc", "Dementia state", choices = state_levels, selected = "No dementia"),
      selectInput("age_band", "Age group", choices = age_levels, selected = "75-84"),
      selectInput("sex", "Sex", choices = sex_levels, selected = "FEMALE"),
      selectInput("ysdx", "Years since diagnosis / index interval", choices = ysdx_levels, selected = "0"),
      selectInput("died", "Death during interval", choices = died_levels, selected = "Alive"),
      selectInput("inst_flag", "Institutionalized during interval", choices = inst_levels, selected = "No"),
      hr(),
      downloadButton("download_state_table", "Download state comparison")
    ),

    mainPanel(
      h3("Single-scenario estimate"),
      fluidRow(
        column(
          4,
          wellPanel(
            h4("Expected annual cost"),
            h2(textOutput("pred_total"))
          )
        ),
        column(
          4,
          wellPanel(
            h4("Probability of any cost"),
            h2(textOutput("pred_prob"))
          )
        ),
        column(
          4,
          wellPanel(
            h4("Mean positive cost"),
            h2(textOutput("pred_positive"))
          )
        )
      ),

      conditionalPanel(
        condition = "input.state_uc == 'No dementia' && input.ysdx != '0'",
        tags$div(
          class = "alert alert-warning",
          "No dementia with years since diagnosis/index interval greater than 0 is a constructed scenario. ",
          "For controls, year 0 is usually the natural reference profile."
        )
      ),

      h3("Comparison across dementia states"),
      plotOutput("state_plot", height = "360px"),
      tableOutput("state_table"),

      tags$hr(),
      tags$p(
        class = "text-muted",
        "Costs are shown in Swedish kronor. Death and institutionalization are interval-level descriptors. ",
        "The app uses public coefficient tables and does not contain patient-level data or fitted model objects."
      )
    )
  )
)

server <- function(input, output, session) {
  scenario_data <- reactive({
    make_newdata(
      state_uc = input$state_uc,
      age_band = input$age_band,
      sex = input$sex,
      ysdx = input$ysdx,
      died = input$died,
      inst_flag = input$inst_flag
    )
  })

  scenario_prediction <- reactive({
    predict_from_coefficients(scenario_data())
  })

  state_predictions <- reactive({
    nd <- make_newdata(
      state_uc = state_levels,
      age_band = input$age_band,
      sex = input$sex,
      ysdx = input$ysdx,
      died = input$died,
      inst_flag = input$inst_flag
    )
    pred <- predict_from_coefficients(nd)
    data.frame(
      state = state_levels,
      probability_any_cost = pred$probability_any_cost,
      mean_positive_cost = pred$positive_cost_mean,
      expected_annual_cost = pred$predicted_annual_cost
    )
  })

  output$pred_total <- renderText({
    format_money(scenario_prediction()$predicted_annual_cost)
  })

  output$pred_prob <- renderText({
    scales::percent(scenario_prediction()$probability_any_cost, accuracy = 0.1)
  })

  output$pred_positive <- renderText({
    format_money(scenario_prediction()$positive_cost_mean)
  })

  output$state_plot <- renderPlot({
    plot_data <- state_predictions()
    ggplot(plot_data, aes(x = state, y = expected_annual_cost)) +
      geom_col(fill = "#0072B2", width = 0.68) +
      geom_text(
        aes(label = scales::comma(round(expected_annual_cost, 0))),
        vjust = -0.35,
        size = 3.7
      ) +
      scale_y_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.12))) +
      labs(
        x = NULL,
        y = "Expected annual formal-care cost (SEK)"
      ) +
      theme_bw(base_size = 13) +
      theme(
        panel.grid.minor = element_blank(),
        axis.text.x = element_text(angle = 15, hjust = 1)
      )
  })

  output$state_table <- renderTable({
    x <- state_predictions()
    data.frame(
      "Dementia state" = x$state,
      "Probability of any cost" = scales::percent(x$probability_any_cost, accuracy = 0.1),
      "Mean positive cost" = format_money(x$mean_positive_cost),
      "Expected annual cost" = format_money(x$expected_annual_cost),
      check.names = FALSE
    )
  })

  output$download_state_table <- downloadHandler(
    filename = function() {
      "ad_formal_care_cost_state_comparison.csv"
    },
    content = function(file) {
      write.csv(state_predictions(), file, row.names = FALSE)
    }
  )
}

shinyApp(ui, server)
