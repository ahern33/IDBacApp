
#' updateMeta_UI
#'
#' @param id id
#'
#' @return ui
#' @export
#'
updateMeta_UI <- function(id) {
  ns <- shiny::NS(id)
  tagList(
    column(width = 6, 
           p("Here is where you can add information about your sample. There are always standard
         columns like \"Genus\", but you can add your own columns as well."),
           p("After you are finished inputting your information, press \"save\" to write the information 
         to the database."),
           
           actionButton(ns("saven"),
                        label = "save")
    ), 
    column(width = 6,
           textInput(ns("addMetaColumnName"), 
                     label = "New Column Name"),
           actionButton(ns("insertNewMetaColumn"),
                        label = "Insert Column")),
    rhandsontable::rHandsontableOutput(ns("metaTable"))
  )
}



#' updateMeta_server
#'
#' @param input  .
#' @param output  .
#' @param session  .
#' @param pool  .
#' @param selectedDB  .
#'
#' @return .
#' @export
#'

updateMeta_server <- function(input,
                              output,
                              session,
                              pool,
                              selectedDB){
       
  #----
  rhand <- reactiveValues(rtab = data.frame("Strain_ID" = "Placeholder"))
  
  #----
  output$metaTable <- rhandsontable::renderRHandsontable({

    
    rhandsontable::rhandsontable(rhand$rtab,
                                 useTypes = FALSE,
                                 contextMenu = TRUE ) %>%
      rhandsontable::hot_col("Strain_ID",
                             readOnly = TRUE) %>%
      rhandsontable::hot_row(1,
                             readOnly = TRUE) %>%
      rhandsontable::hot_context_menu(allowRowEdit = FALSE,
                                      allowColEdit = TRUE) %>%
      rhandsontable::hot_cols(colWidths = 100) %>%
      rhandsontable::hot_rows(rowHeights = 25) %>%
      rhandsontable::hot_cols(fixedColumnsLeft = 1)
    
  })
  
  
  
  observeEvent(input$insertNewMetaColumn, 
               ignoreInit = TRUE, {
                 IDBacApp::insertMetadataColumns(pool = pool(),
                                                 columnNames = input$addMetaColumnName)
               })
  
  
  
  observeEvent(input$saven, 
               ignoreInit = TRUE, {
                 
                 
                 showModal(modalDialog(
                   size = "s",
                   title = "Saving...",
                   easyClose = FALSE, 
                   footer = ""))   
               })
  
  observeEvent(input$saven, 
               ignoreInit = TRUE, {
            
                 
                 
                 #make sure not to use the wrong metadata table
                 query <- glue::glue_sql("SELECT DISTINCT `Strain_ID`
                                          FROM `IndividualSpectra`",
                                         .con =  pool())
                 query <- DBI::dbGetQuery(pool(), query)[ ,1]
                 userTab <- as.character(rhandsontable::hot_to_r(input$metaTable)[-1, 1])
                 req(identical(userTab, query))
                 
                 DBI::dbWriteTable(conn = pool(),
                                   name = "metaData",
                                   value = rhandsontable::hot_to_r(input$metaTable)[-1, ], # remove example row 
                                   overwrite = TRUE)  
               
                 removeModal()
                 
               })
  
 
  
  
  #----
  observeEvent(c(selectedDB$selectExperiment, input$insertNewMetaColumn),{
                 
     if (identical(selectedDB$selectExperiment, "None")) {
       rhand$rtab <- data.frame("Strain_ID" = "Placeholder")
       } else {
         
    
                 if (!is.null(pool())) {
                   conn <- pool::poolCheckout(pool())
                   
                   if (!"metaData" %in% DBI::dbListTables(conn)) {
                     
                     warning("It appears the experiment file may be corrupt, please create again.")
                     rhand$rtab <- data.frame(Strain_ID = "It appears the experiment file may be corrupt, please create the experiment again.")
                     
                   } else{
                     
                     dbQuery <- glue::glue_sql("SELECT *
                                             FROM ({tab*})",
                                               tab = "metaData",
                                               .con = conn)
                     
                     dbQuery <- DBI::dbGetQuery(conn, dbQuery)
                     
                     exampleMetaData <- data.frame(      "Strain_ID"                    = "Example_Strain",
                                                         "Genbank_Accession"            = "KY858228",
                                                         "NCBI_TaxID"                   = "446370",
                                                         "Kingdom"                      = "Bacteria",
                                                         "Phylum"                       = "Firmicutes",
                                                         "Class"                        = "Bacilli",
                                                         "Order"                        = "Bacillales",
                                                         "Family"                       = "Paenibacillaceae",
                                                         "Genus"                        = "Paenibacillus",
                                                         "Species"                      = "telluris",
                                                         "MALDI_Matrix"                 = "CHCA",
                                                         "DSM_Agar_Media"               = "1054_Fresh",
                                                         "Cultivation_Temp_Celsius"     = "27",
                                                         "Cultivation_Time_Days"        = "10",
                                                         "Cultivation_Other"            = "",
                                                         "User"                         = "Chase Clark",
                                                         "User_ORCID"                   = "0000-0001-6439-9397",
                                                         "PI_FirstName_LastName"        = "Brian Murphy",
                                                         "PI_ORCID"                     = "0000-0002-1372-3887",
                                                         "dna_16S"                      = "TCCTGCCTCAGGACGAACGCTGGCGGCGTGCCTAATACATGCAAGTCGAGCGGAGTTGATGGAGTGCTTGCACTCCTGATGCTTAGCGGCGGACGGGTGAGTAACACGTAGGTAACCTGCCCGTAAGACTGGGATAACATTCGGAAACGAATGCTAATACCGGATACACAACTTGGTCGCATGATCGGAGTTGGGAAAGACGGAGTAATCTGTCACTTACGGATGGACCTGCGGCGCATTAGCTAGTTGGTGAGGTAACGGCTCACCAAGGCGACGATGCGTAGCCGACCTGAGAGGGTGATCGGCCACACTGGGACTGAGACACGGCCCAGACTCCTACGGGAGGCAGCAGTAGGGAATCTTCCGCAATGGACGAAAGTCTGACGGAGCAACGCCGCGTGAGTGATGAAGGTTTTCGGATCGTAAAGCTCTGTTGCCAGGGAAGAACGCTAAGGAGAGTAACTGCTCCTTAGGTGACGGTACCTGAGAAGAAAGCCCCGGCTAACTACGTGCCAGCAGCCGCGGTAATACGTAGGGGGCAAGCGTTGTCCGGAATTATTGGGCGTAAAGCGCGCGCAGGCGGCCTTGTAAGTCTGTTGTTTCAGGCACAAGCTCAACTTGTGTTCGCAATGGAAACTGCAAAGCTTGAGTGCAGAAGAGGAAAGTGGAATTCCACGTGTAGCGGTGAAATGCGTAGAGATGTGGAGGAACACCAGTGGCGAAGGCGACTTTCTGGGCTGTAACTGACGCTGAGGCGCGAAAGCGTGGGGAGCAAACAGGATTAGATACCCTGGTAGTCCACGCCGTAAACGATGAATGCTAGGTGTTAGGGGTTTCGATACCCTTGGTGCCGAAGTTAACACATTAAGCATTCCGCCTGGGGAGTACGGTCGCAAGACTGAAACTCAAAGGAATTGACGGGGACCCGCACAAGCAGTGGAGTATGTGGTTTAATTCGAAGCAACGCGAAGAACCTTACCAGGTCTTGACATCCCTCTGAATCTGCTAGAGATAGCGGCGGCCTTCGGGACAGAGGAGACAGGTGGTGCATGGTTGTCGTCAGCTCGTGTCGTGAGATGTTGGGTTAAGTCCCGCAACGAGCGCAACCCTTGATCTTAGTTGCCAGCAGGTKAAGCTGGGCACTCTAGGATGACTGCCGGTGACAAACCGGAGGAAGGTGGGGATGACGTCAAATCATCATGCCCCTTATGACCTGGGCTACACACGTACTACAATGGCCGATACAACGGGAAGCGAAACCGCGAGGTGGAGCCAATCCTATCAAAGTCGGTCTCAGTTCGGATTGCAGGCTGCAACTCGCCTGCATGAAGTCGGAATTGCTAGTAATCGCGGATCAGCATGCCGCGGTGAATACGTTCCCGGGTCTTGTACACACCGCCCGTCACACCACGAGAGTTTACAACACCCGAAGCCGGTGGGGTAACCGCAAGGAGCCAGCCGTCGAAGGTGGGGTAGATGATTGGGGTGAAGTCGTAAC"
                     )
                     
                     rhand$rtab <- merge(exampleMetaData,
                                          dbQuery,
                                          all = TRUE,
                                          sort = FALSE)
                     
                     pool::poolReturn(conn)
                   }
                 }
                 }
               })
  
}

