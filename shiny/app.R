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
  expected_annual_cost <- probability_any_cost * positive_cost_mean

  data.frame(
    probability_any_cost = probability_any_cost,
    positive_cost_mean = positive_cost_mean,
    expected_annual_cost = expected_annual_cost
  )
}

format_money <- function(x) {
  paste0("SEK ", scales::comma(round(x, 0)))
}

profile_inputs <- function(prefix, include_state = TRUE) {
  tagList(
    if (include_state) {
      selectInput(paste0(prefix, "state_uc"), "Dementia state", choices = state_levels, selected = "No dementia")
    },
    selectInput(paste0(prefix, "age_band"), "Age group", choices = age_levels, selected = "75-84"),
    selectInput(paste0(prefix, "sex"), "Sex", choices = sex_levels, selected = "FEMALE"),
    selectInput(paste0(prefix, "ysdx"), "Years since diagnosis / index interval", choices = ysdx_levels, selected = "0"),
    selectInput(paste0(prefix, "died"), "Death during interval", choices = died_levels, selected = "Alive"),
    selectInput(paste0(prefix, "inst_flag"), "Institutionalized during interval", choices = inst_levels, selected = "No")
  )
}

ui <- fluidPage(
  titlePanel("Annual Formal-Care Cost Calculator for Alzheimer Disease Dementia"),

  tags$div(
    class = "alert alert-info",
    tags$strong("Interpretation: "),
    "This calculator estimates conditional expected annual formal-care costs for specified interval-level covariates. ",
    "It is intended for research and economic-model scenarios, not causal inference or individual clinical decision-making."
  ),

  tabsetPanel(
    id = "main_tabs",

    tabPanel(
      "Calculator",
      sidebarLayout(
        sidebarPanel(
          profile_inputs("calc_", include_state = TRUE)
        ),
        mainPanel(
          h3("Selected profile estimate"),
          uiOutput("calc_profile_summary"),
          fluidRow(
            column(
              4,
              wellPanel(
                h4("Expected annual cost"),
                h2(textOutput("calc_total"))
              )
            ),
            column(
              4,
              wellPanel(
                h4("Probability of any cost"),
                h2(textOutput("calc_prob"))
              )
            ),
            column(
              4,
              wellPanel(
                h4("Mean cost if positive"),
                h2(textOutput("calc_positive"))
              )
            )
          ),
          uiOutput("calc_constructed_warning"),
          tags$hr(),
          tags$p(
            class = "text-muted",
            "This tab estimates one selected profile. It does not compare dementia states."
          )
        )
      )
    ),

    tabPanel(
      "Compare dementia states",
      sidebarLayout(
        sidebarPanel(
          profile_inputs("cmp_", include_state = FALSE),
          hr(),
          downloadButton("download_state_table", "Download comparison")
        ),
        mainPanel(
          h3("Dementia-state scenario comparison"),
          tags$p(
            class = "text-muted",
            "This tab keeps age group, sex, years since diagnosis/index interval, death during interval, and institutionalization fixed, ",
            "then recalculates expected annual cost after changing only the dementia-state input."
          ),
          uiOutput("cmp_interaction_warning"),
          plotOutput("cmp_state_plot", height = "390px"),
          tableOutput("cmp_state_table"),
          tags$hr(),
          tags$p(
            class = "text-muted",
            "Differences are conditional scenario contrasts versus the no-dementia profile with the same non-state covariates. ",
            "They should not be interpreted as causal effects."
          )
        )
      )
    ),

    tabPanel(
      "About",
      h3("Model"),
      tags$p("The calculator implements a two-part annual formal-care cost function."),
      tags$ul(
        tags$li("Part 1: logistic regression for probability of any formal-care cost."),
        tags$li("Part 2: Gamma generalized linear model with log link for positive annual formal-care costs."),
        tags$li("Expected annual cost = probability of any cost multiplied by mean cost among positive-cost observations.")
      ),
      h3("Predictors"),
      tags$p(
        "Predictors include dementia state, age group, sex, years since diagnosis/index interval, death during interval, ",
        "and institutionalization during interval. Death and institutionalization are interval-level descriptors."
      ),
      h3("Use"),
      tags$p(
        "The app is intended for research use in economic evaluation and care-resource planning scenarios. ",
        "It is not a causal model, not an individual clinical decision tool, and not a replacement for local costing rules."
      ),
      h3("Implementation"),
      tags$p(
        "The public app uses coefficient tables only. It does not contain patient-level data, registry extracts, or fitted model objects."
      ),
      tags$p(
        tags$a(href = "https://github.com/yohannesbalcha/ad-formal-care-cost-calculator", "View source code on GitHub")
      )
    )
  )
)

server <- function(input, output, session) {
  calc_data <- reactive({
    make_newdata(
      state_uc = input$calc_state_uc,
      age_band = input$calc_age_band,
      sex = input$calc_sex,
      ysdx = input$calc_ysdx,
      died = input$calc_died,
      inst_flag = input$calc_inst_flag
    )
  })

  calc_prediction <- reactive({
    predict_from_coefficients(calc_data())
  })

  output$calc_profile_summary <- renderUI({
    tags$p(
      class = "text-muted",
      paste(
        input$calc_state_uc,
        "| age", input$calc_age_band,
        "|", ifelse(input$calc_sex == "FEMALE", "female", "male"),
        "| year", input$calc_ysdx,
        "|", tolower(input$calc_died),
        "| institutionalized:", tolower(input$calc_inst_flag)
      )
    )
  })

  output$calc_constructed_warning <- renderUI({
    if (input$calc_state_uc == "No dementia" && input$calc_ysdx != "0") {
      tags$div(
        class = "alert alert-warning",
        "No dementia with years since diagnosis/index interval greater than 0 is a constructed scenario. ",
        "For controls, year 0 is usually the natural reference profile."
      )
    }
  })

  output$calc_total <- renderText({
    format_money(calc_prediction()$expected_annual_cost)
  })

  output$calc_prob <- renderText({
    scales::percent(calc_prediction()$probability_any_cost, accuracy = 0.1)
  })

  output$calc_positive <- renderText({
    format_money(calc_prediction()$positive_cost_mean)
  })

  compare_predictions <- reactive({
    nd <- make_newdata(
      state_uc = state_levels,
      age_band = input$cmp_age_band,
      sex = input$cmp_sex,
      ysdx = input$cmp_ysdx,
      died = input$cmp_died,
      inst_flag = input$cmp_inst_flag
    )
    pred <- predict_from_coefficients(nd)
    out <- data.frame(
      state = factor(state_levels, levels = state_levels),
      probability_any_cost = pred$probability_any_cost,
      mean_positive_cost = pred$positive_cost_mean,
      expected_annual_cost = pred$expected_annual_cost
    )
    out$conditional_difference_vs_no_dementia <- out$expected_annual_cost - out$expected_annual_cost[out$state == "No dementia"]
    out
  })

  output$cmp_interaction_warning <- renderUI({
    if (input$cmp_died == "Died" || input$cmp_inst_flag == "Yes") {
      tags$div(
        class = "alert alert-warning",
        "This is a high-cost interval scenario. Because the model includes interactions with death and institutionalization, ",
        "the comparison is a conditional model prediction and may not show a monotonic severity gradient."
      )
    }
  })

  output$cmp_state_plot <- renderPlot({
    plot_data <- compare_predictions()
    plot_data$plot_state <- factor(as.character(plot_data$state), levels = rev(state_levels))
    ggplot(plot_data, aes(x = plot_state, y = expected_annual_cost)) +
      geom_col(fill = "#0072B2", width = 0.68) +
      geom_text(
        aes(label = scales::comma(round(expected_annual_cost, 0))),
        hjust = -0.08,
        size = 3.7
      ) +
      coord_flip() +
      scale_y_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.16))) +
      labs(
        x = NULL,
        y = "Expected annual formal-care cost (SEK)"
      ) +
      theme_bw(base_size = 13) +
      theme(
        panel.grid.minor = element_blank(),
        panel.grid.major.y = element_blank()
      )
  })

  output$cmp_state_table <- renderTable({
    x <- compare_predictions()
    data.frame(
      "Dementia state" = as.character(x$state),
      "Probability of any cost" = scales::percent(x$probability_any_cost, accuracy = 0.1),
      "Mean cost if positive" = format_money(x$mean_positive_cost),
      "Expected annual cost" = format_money(x$expected_annual_cost),
      "Conditional difference vs no dementia" = format_money(x$conditional_difference_vs_no_dementia),
      check.names = FALSE
    )
  })

  output$download_state_table <- downloadHandler(
    filename = function() {
      "ad_formal_care_cost_state_comparison.csv"
    },
    content = function(file) {
      write.csv(compare_predictions(), file, row.names = FALSE)
    }
  )
}

shinyApp(ui, server)
