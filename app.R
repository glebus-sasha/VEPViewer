library(shiny)
library(shinythemes)
library(dplyr)
library(tidyr)
library(DT)
library(vcfR)

# === Функция для загрузки VCF ===
load_vcf <- function(file) {
  vcf <- read.vcfR(file$datapath)
  vcf_df <- as.data.frame(vcf@fix)
  
  csq_header <- strsplit(grep("##INFO=<ID=CSQ", vcf@meta, value = TRUE), "Format: ")[[1]][2]
  csq_cols <- unlist(strsplit(csq_header, "\\|"))
  
  vcf_df <- vcf_df %>%
    mutate(CSQ_split = strsplit(INFO, ";") %>%
             lapply(function(x) grep("^CSQ=", x, value = TRUE) %>%
                      gsub("^CSQ=", "", .))) %>%
    unnest(CSQ_split) %>%
    separate(CSQ_split, into = csq_cols, sep = "\\|", extra = "drop", fill = "right") %>%
    type.convert(as.is = TRUE) %>%
    mutate_if(is.character, as.factor)
  
  return(vcf_df)
}

# === UI ===
ui <- fluidPage(
  # theme = shinytheme("lumen"), # Изменяем тему
  titlePanel("VEPViewer"),
  
  sidebarLayout(
    sidebarPanel(
      fileInput("vcf_file", "Загрузите VCF/VEP файл", accept = c(".vcf", ".vep")),
      actionButton("select_all", "Выбрать все"),
      actionButton("clear_all", "Сбросить"),
      checkboxGroupInput("columns", "Выберите колонки", choices = NULL),
      downloadButton("download_csv", "Скачать CSV")
    ),
    mainPanel(
      DTOutput("vcf_table")
    )
  )
)

# === SERVER ===
server <- function(input, output, session) {
  vcf_data <- reactiveVal(NULL)
  
  observeEvent(input$vcf_file, {
    vcf_df <- load_vcf(input$vcf_file)
    vcf_data(vcf_df)
    updateCheckboxGroupInput(session, "columns", choices = colnames(vcf_df),
                             selected = c("CHROM", "POS", "ID", "REF", "ALT", "QUAL", "FILTER",
                                          "Consequence", "IMPACT", "SYMBOL", "Gene", 
                                          "Feature_type", "Feature", "BIOTYPE",
                                          "gnomADe_AF", "CLIN_SIG", "PUBMED"))
  })
  
  observeEvent(input$select_all, {
    updateCheckboxGroupInput(session, "columns", selected = colnames(vcf_data()))
  })
  
  observeEvent(input$clear_all, {
    updateCheckboxGroupInput(session, "columns", selected = character(0))
  })
  
  filtered_data <- reactive({
    req(vcf_data())
    vcf_data()[, input$columns, drop = FALSE]
  })
  
  output$vcf_table <- renderDT({
    req(filtered_data())
    datatable(filtered_data(), 
              options = list(pageLength = 10, autoWidth = TRUE), 
              filter = "top")
  }, server = FALSE)  # ВАЖНО: server = FALSE, чтобы фильтрация работала на клиенте!
  
  output$download_csv <- downloadHandler(
    filename = function() {
      paste0("filtered_data_", Sys.Date(), ".csv")
    },
    content = function(file) {
      req(input$vcf_table_rows_all)  # Проверяем, есть ли видимые строки после фильтрации
      
      filtered_rows <- input$vcf_table_rows_all  # Получаем индексы отфильтрованных строк
      export_data <- filtered_data()[filtered_rows, , drop = FALSE]  # Оставляем только видимые строки
      
      write.csv2(export_data, file, row.names = FALSE)  # Сохраняем в CSV с `;`
    }
  )
}

# === Запуск приложения ===
shinyApp(ui, server)
