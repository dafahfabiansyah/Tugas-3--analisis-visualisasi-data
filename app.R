library(shiny)
library(readxl)
library(ggplot2)
library(dplyr)      
library(plotly)
library(DT)

# ---- Load & Preprocess Data ----
df_raw <- read_excel("Data set Tugas tutorial 3 STSI 4204.xlsx")

numeric_cols <- c(
  "MinTemp", "MaxTemp", "Rainfall", "Evaporation", "Sunshine",
  "WindGustSpeed", "WindSpeed9am", "WindSpeed3pm",
  "Humidity9am", "Humidity3pm",
  "Pressure9am", "Pressure3pm",
  "Cloud9am", "Cloud3pm",
  "Temp9am", "Temp3pm", "RISK_MM"
)

df <- df_raw
for (col in numeric_cols) {
  df[[col]] <- suppressWarnings(as.numeric(df[[col]]))
}

# Tambahkan kolom urutan hari
df$Day <- seq_len(nrow(df))

# Kolom numerik yang valid (tanpa terlalu banyak NA)
valid_numeric <- numeric_cols[sapply(numeric_cols, function(col) sum(!is.na(df[[col]])) > 50)]
categorical_cols <- c("WindGustDir", "WindDir9am", "WindDir3pm", "RainToday", "RainTomorrow")

# ---- UI ----
ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      body { background-color: #f5f7fa; font-family: 'Segoe UI', sans-serif; }
      .navbar { background-color: #1a3c5e; }
      .header-box {
        background: linear-gradient(135deg, #1a3c5e, #2e86c1);
        color: white;
        padding: 20px 30px;
        border-radius: 8px;
        margin-bottom: 20px;
        box-shadow: 0 4px 10px rgba(0,0,0,0.2);
      }
      .header-box h2 { margin: 0; font-size: 1.6em; font-weight: 700; }
      .header-box p  { margin: 5px 0 0; font-size: 0.95em; opacity: 0.85; }
      .well { border-radius: 8px; background: #ffffff; border: 1px solid #dce3ec; }
      .control-label { font-weight: 600; color: #1a3c5e; }
      .plot-card {
        background: white;
        border-radius: 8px;
        padding: 15px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.08);
      }
      .info-text { color: #555; font-size: 0.85em; margin-top: 4px; }
    "))
  ),

  # Header
  div(class = "header-box",
    h2("Visualisasi Data Cuaca Australia"),
    p("Dataset: 366 Observasi x 22 Variabel | STSI 4204 - Tugas Tutorial 3")
  ),

  sidebarLayout(
    sidebarPanel(
      width = 3,

      h4(icon("chart-bar"), " Pengaturan Visualisasi", style = "color:#1a3c5e; font-weight:700;"),
      hr(),

      # Jenis Plot
      selectInput("plot_type", "Jenis Visualisasi:",
        choices = c(
          "Scatter Plot Interaktif" = "scatter",
          "Line Plot Interaktif"   = "line",
          "Bar Plot Interaktif"    = "bar",
          "Tabel Data"             = "table"
        ),
        selected = "scatter"
      ),

      # Variabel X
      conditionalPanel(
        condition = "input.plot_type != 'table'",
        selectInput("var_x", "Variabel Sumbu X:",
          choices = valid_numeric,
          selected = valid_numeric[1]
        )
      ),

      # Variabel Y (hanya untuk scatter & line)
      conditionalPanel(
        condition = "input.plot_type == 'scatter' || input.plot_type == 'line'",
        selectInput("var_y", "Variabel Sumbu Y:",
          choices = valid_numeric,
          selected = valid_numeric[2]
        )
      ),

      # Variabel Bar (hanya untuk bar plot)
      conditionalPanel(
        condition = "input.plot_type == 'bar'",
        selectInput("var_bar", "Variabel (Bar Chart):",
          choices = categorical_cols,
          selected = categorical_cols[1]
        ),
        radioButtons("bar_stat", "Statistik Bar:",
          choices = c("Jumlah (Count)" = "count", "Rata-rata" = "mean"),
          selected = "count"
        ),
        conditionalPanel(
          condition = "input.bar_stat == 'mean'",
          selectInput("var_bar_y", "Variabel Numerik (Y):",
            choices = valid_numeric,
            selected = "Rainfall"
          )
        )
      ),

      # Warna titik (scatter)
      conditionalPanel(
        condition = "input.plot_type == 'scatter'",
        selectInput("color_by", "Warna berdasarkan:",
          choices = c("Tidak ada" = "none", categorical_cols),
          selected = "none"
        )
      ),

      # Opsi tampilan
      conditionalPanel(
        condition = "input.plot_type != 'table'",
        hr(),
        checkboxInput("show_smooth", "Tampilkan Garis Trend (LOESS)", value = FALSE),
        sliderInput("point_size", "Ukuran Titik:", min = 2, max = 10, value = 5, step = 1)
      ),

      # Opsi tabel
      conditionalPanel(
        condition = "input.plot_type == 'table'",
        checkboxGroupInput("table_cols", "Pilih Kolom Tabel:",
          choices  = names(df)[names(df) != "Day"],
          selected = valid_numeric[1:6]
        )
      ),

      hr(),
      div(class = "info-text",
        icon("info-circle"), " Dataset cuaca Australia dari ",
        strong("Canberra"), " (2008–2009). Sumber: Bureau of Meteorology."
      )
    ),

    mainPanel(
      width = 9,
      div(class = "plot-card",

        # Info bar
        fluidRow(
          column(12,
            uiOutput("plot_title_ui"),
            hr(style = "margin: 8px 0 14px;")
          )
        ),

        # Output utama
        conditionalPanel(
          condition = "input.plot_type != 'table'",
          plotlyOutput("main_plot", height = "520px")
        ),
        conditionalPanel(
          condition = "input.plot_type == 'table'",
          DTOutput("data_table")
        ),

        # Statistik ringkas
        conditionalPanel(
          condition = "input.plot_type != 'table'",
          hr(),
          h5("Statistik Ringkas", style = "color:#1a3c5e; font-weight:600;"),
          verbatimTextOutput("summary_stats")
        )
      )
    )
  )
)

# ---- Server ----
server <- function(input, output, session) {

  # Reactive: sinkronisasi var_x != var_y
  observe({
    req(input$var_x)
    choices_y <- setdiff(valid_numeric, input$var_x)
    updateSelectInput(session, "var_y",
      choices  = choices_y,
      selected = if (input$var_y %in% choices_y) input$var_y else choices_y[1]
    )
  })

  # Judul dinamis
  output$plot_title_ui <- renderUI({
    type_label <- switch(input$plot_type,
      scatter = "Scatter Plot",
      line    = "Line Plot",
      bar     = "Bar Plot",
      table   = "Tabel Data"
    )
    subtitle <- switch(input$plot_type,
      scatter = paste0(input$var_x, " vs ", input$var_y),
      line    = paste0(input$var_x, " vs ", input$var_y, "  (berdasarkan urutan observasi)"),
      bar     = paste0("Distribusi: ", input$var_bar),
      table   = paste0("Menampilkan ", length(input$table_cols), " kolom dari dataset")
    )
    tagList(
      h4(type_label, style = "color:#1a3c5e; margin:0; font-weight:700; display:inline;"),
      span(paste0(" — ", subtitle), style = "color:#666; font-size:0.9em;")
    )
  })

  # ---- Plot utama ----
  output$main_plot <- renderPlotly({
    req(input$plot_type)

    # ---- SCATTER PLOT ----
    if (input$plot_type == "scatter") {
      req(input$var_x, input$var_y)
      d <- dplyr::filter(df, !is.na(.data[[input$var_x]]), !is.na(.data[[input$var_y]]))

      color_var <- if (input$color_by == "none") NULL else input$color_by

      p <- ggplot(d, aes(
        x    = .data[[input$var_x]],
        y    = .data[[input$var_y]],
        text = paste0("Hari ke-", Day,
                      "<br>", input$var_x, ": ", round(.data[[input$var_x]], 2),
                      "<br>", input$var_y, ": ", round(.data[[input$var_y]], 2))
      ))

      if (!is.null(color_var)) {
        p <- p + geom_point(aes(color = .data[[color_var]]),
                            size = input$point_size * 0.5, alpha = 0.75)
      } else {
        p <- p + geom_point(color = "#2e86c1",
                            size = input$point_size * 0.5, alpha = 0.75)
      }

      if (input$show_smooth) {
        p <- p + geom_smooth(method = "loess", se = TRUE,
                             color = "#e74c3c", linewidth = 0.8, formula = y ~ x)
      }

      p <- p +
        labs(x = input$var_x, y = input$var_y,
             color = color_var) +
        theme_minimal(base_size = 13) +
        theme(legend.position = "bottom")

      ggplotly(p, tooltip = "text") %>%
        layout(legend = list(orientation = "h", x = 0, y = -0.2))
    }

    # ---- LINE PLOT ----
    else if (input$plot_type == "line") {
      req(input$var_x, input$var_y)
      d <- dplyr::filter(df, !is.na(.data[[input$var_x]]), !is.na(.data[[input$var_y]]))

      p <- ggplot(d, aes(
        x    = .data[[input$var_x]],
        y    = .data[[input$var_y]],
        text = paste0("Hari ke-", Day,
                      "<br>", input$var_x, ": ", round(.data[[input$var_x]], 2),
                      "<br>", input$var_y, ": ", round(.data[[input$var_y]], 2))
      )) +
        geom_line(color = "#2e86c1", linewidth = 0.7, alpha = 0.8) +
        geom_point(color = "#1a3c5e", size = input$point_size * 0.3, alpha = 0.6)

      if (input$show_smooth) {
        p <- p + geom_smooth(method = "loess", se = TRUE,
                             color = "#e74c3c", linewidth = 0.8, formula = y ~ x)
      }

      p <- p +
        labs(x = input$var_x, y = input$var_y) +
        theme_minimal(base_size = 13)

      ggplotly(p, tooltip = "text")
    }

    # ---- BAR PLOT ----
    else if (input$plot_type == "bar") {
      req(input$var_bar)
      d <- dplyr::filter(df, !is.na(.data[[input$var_bar]]))

      if (input$bar_stat == "count") {
        d_agg <- d %>%
          dplyr::group_by(Category = .data[[input$var_bar]]) %>%
          summarise(Value = n(), .groups = "drop") %>%
          arrange(desc(Value))

        p <- ggplot(d_agg, aes(
          x    = reorder(Category, -Value),
          y    = Value,
          fill = Category,
          text = paste0(input$var_bar, ": ", Category, "<br>Jumlah: ", Value)
        )) +
          geom_col(alpha = 0.85, show.legend = FALSE) +
          labs(x = input$var_bar, y = "Jumlah (Count)") +
          theme_minimal(base_size = 12) +
          theme(axis.text.x = element_text(angle = 45, hjust = 1))

      } else {
        req(input$var_bar_y)
        d_agg <- d %>%
          dplyr::filter(!is.na(.data[[input$var_bar_y]])) %>%
          dplyr::group_by(Category = .data[[input$var_bar]]) %>%
          summarise(Value = mean(.data[[input$var_bar_y]], na.rm = TRUE), .groups = "drop") %>%
          arrange(desc(Value))

        p <- ggplot(d_agg, aes(
          x    = reorder(Category, -Value),
          y    = Value,
          fill = Category,
          text = paste0(input$var_bar, ": ", Category,
                        "<br>Rata-rata ", input$var_bar_y, ": ", round(Value, 2))
        )) +
          geom_col(alpha = 0.85, show.legend = FALSE) +
          labs(x = input$var_bar, y = paste0("Rata-rata ", input$var_bar_y)) +
          theme_minimal(base_size = 12) +
          theme(axis.text.x = element_text(angle = 45, hjust = 1))
      }

      ggplotly(p, tooltip = "text")
    }
  })

  # ---- TABEL DATA ----
  output$data_table <- renderDT({
    req(input$table_cols)
    cols <- intersect(input$table_cols, names(df))
    if (length(cols) == 0) return(NULL)

    datatable(
      df[, cols, drop = FALSE],
      options = list(
        pageLength  = 15,
        scrollX     = TRUE,
        autoWidth   = TRUE,
        dom         = "Bfrtip",
        buttons     = c("csv", "excel"),
        language    = list(
          search    = "Cari:",
          lengthMenu = "Tampilkan _MENU_ baris",
          info       = "Menampilkan _START_ – _END_ dari _TOTAL_ baris"
        )
      ),
      extensions = "Buttons",
      rownames   = FALSE,
      class      = "stripe hover compact"
    ) %>%
      formatRound(columns = intersect(cols, valid_numeric), digits = 2)
  })

  # ---- Statistik Ringkas ----
  output$summary_stats <- renderPrint({
    if (input$plot_type == "scatter" || input$plot_type == "line") {
      req(input$var_x, input$var_y)
      d <- df[, c(input$var_x, input$var_y)]
      cat("=== Statistik Ringkas ===\n")
      print(summary(d))
      if (!is.na(cor(df[[input$var_x]], df[[input$var_y]], use = "complete.obs"))) {
        cat("\nKorelasi Pearson:", round(cor(df[[input$var_x]], df[[input$var_y]],
                                            use = "complete.obs"), 4), "\n")
      }
    } else if (input$plot_type == "bar") {
      req(input$var_bar)
      cat("=== Distribusi Frekuensi:", input$var_bar, "===\n")
      print(table(df[[input$var_bar]], useNA = "ifany"))
    }
  })
}

# ---- Jalankan Aplikasi ----
shinyApp(ui = ui, server = server)
