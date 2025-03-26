library(shiny)
library(shinythemes)
library(shinyjs)
library(dplyr)
library(tidyr)
library(DT)
library(vcfR)

# === Function to Load VCF ===
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
  useShinyjs(),
  titlePanel("VEPViewer"),
  
  fluidRow(
    column(
      width = 3, id = "sidebar",
      wellPanel(
        fileInput("vcf_file", "Upload VCF/VEP file", accept = c(".vcf", ".vep")),
        actionButton("select_all", "Select All"),
        actionButton("clear_all", "Clear"),
        div(style = "overflow-y: auto; max-height: 300px;",  # Добавляем прокрутку
            checkboxGroupInput("columns", "Select columns", choices = NULL)
        )
      )
    ),
    
    column(
      width = 9,
      actionButton("toggle_sidebar", "Show/Hide Panel"),
      DTOutput("vcf_table"),
      br(),  # Добавляет отступ перед кнопкой
      downloadButton("download_csv", "Download CSV")
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
  }, server = FALSE)
  
  output$download_csv <- downloadHandler(
    filename = function() {
      paste0("filtered_data_", Sys.Date(), ".csv")
    },
    content = function(file) {
      req(input$vcf_table_rows_all)  
      filtered_rows <- input$vcf_table_rows_all  
      export_data <- filtered_data()[filtered_rows, , drop = FALSE]  
      write.csv2(export_data, file, row.names = FALSE)  
    }
  )
  
  observeEvent(input$toggle_sidebar, {
    toggle("sidebar")
  })
}

# === Launch app ===
shinyApp(ui, server)