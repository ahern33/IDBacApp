convertDataTabUI <- function(id) {
  ns <- shiny::NS(id)
  
  
  navlistPanel(widths = c(3, 8), id = ns("ConversionsNav"),
               "Create an IDBac experiment",
               tabPanel(tags$ul(tags$li("Click here to convert Bruker files")),
                        value = ns("convert_bruker_nav"),
                        mainPanel(offset = 3,
                                  radioButtons(ns("typeOfRawData"),
                                               label = h3("Begin by selecting an option below:"),
                                               choices = list("Select here to convert and analyze raw-data from a single MALDI-plate" = 1),
                                               #"Select here to convert and analyze raw-data from multiple MALDI-plates at once" = 2),
                                               selected = 0,
                                               inline = FALSE,
                                               width = "100%"),
                                  uiOutput(ns("conversionMainUI1"))
                        )
               ),
               tabPanel(tags$ul(tags$li("Click here to convert mzML/mzXML files")),
                        value = ns("convert_mzml_nav"),
                        fluidRow(
                          uiOutput(ns("conversionMainUI2"))
                        )
               ),
               tabPanel(tags$ul(tags$li("Click here to convert txt files")),
                        value = ns("convert_txt_nav"),
                        mainPanel(
                          uiOutput(ns("conversionMainUI3"))
                        )
               )
  )
}




convertDataTabServer <- function(input,
                                 output,
                                 session,
                                 tempMZDir){
  
  
  # Single MALDI plate ------------------------------------------------------
  
  #This "observe" event creates the UI element for analyzing a single MALDI plate, based on user-input.
  #----
  observeEvent(c(input$ConversionsNav,
                 input$typeOfRawData), 
               ignoreInit = TRUE, 
               {
                 ns <- session$ns
                 print(input$typeOfRawData)
                 
                 if (input$ConversionsNav == ns("convert_bruker_nav")) {
                   
                   if (is.null(input$typeOfRawData)) {
                     
                   } else if (input$typeOfRawData == "1") {
                     output$conversionMainUI1 <- renderUI({
                       IDBacApp::oneMaldiPlate(ns)
                     }) 
                   } else if (input$typeOfRawData == 2) {
                     output$conversionMainUI1 <- renderUI({
                       IDBacApp::multipleMaldiPlates(ns("multipleMaldiPlates"))
                     })
                   }
                 }
                 
                 
                 if (input$ConversionsNav == ns("convert_mzml_nav")) {
                   output$conversionMainUI2 <- renderUI({
                     IDBacApp::beginWithMZ(ns("beginWithMZ"))
                   })
                 } 
                 
                 if (input$ConversionsNav == ns("convert_txt_nav")) {
                   output$conversionMainUI3 <- renderUI({
                     IDBacApp::beginWithTXT(ns("beginWithTXT"))
                   })
                 } 
                 
               })
  
  
  
  
  
  
  
  
  # Reactive variable returning the user-chosen location of the raw MALDI files as string
  #----
  rawFilesLocation <- reactive({
    if (input$rawFileDirectory > 0) {
      IDBacApp::choose_dir()
    }
  })
  
  
  # Creates text showing the user which directory they chose for raw files
  #----
  output$rawFileDirectoryText <- renderText({
    if (is.null(rawFilesLocation())) {
      return("No Folder Selected")
    } else {
      folders <- NULL
      # Get the folders contained within the chosen folder.
      foldersInFolder <- list.dirs(rawFilesLocation(),
                                   recursive = FALSE,
                                   full.names = FALSE) 
      for (i in 1:length(foldersInFolder)) {
        # Creates user feedback about which raw data folders were chosen.  Individual folders displayed on a new line "\n"
        folders <- paste0(folders, 
                          "\n",
                          foldersInFolder[[i]])
      }
      return(folders)
    }
  })
  
  
  # Reactive variable returning the user-chosen location of the raw MALDI files as string
  #----
  multipleMaldiRawFileLocation <- reactive({
    if (input$multipleMaldiRawFileDirectory > 0) {
      IDBacApp::choose_dir()
    }
  })
  
  
  # Creates text showing the user which directory they chose for raw files
  #----
  output$multipleMaldiRawFileDirectory <- renderText({
    if (is.null(multipleMaldiRawFileLocation())) {
      return("No Folder Selected")
    } else {
      folders <- NULL
      # Get the folders contained within the chosen folder.
      foldersInFolder <- list.dirs(multipleMaldiRawFileLocation(),
                                   recursive = FALSE, 
                                   full.names = FALSE) 
      for (i in 1:length(foldersInFolder)) {
        # Creates user feedback about which raw data folders were chosen. 
        # Individual folders displayed on a new line "\n"
        folders <- paste0(folders, "\n", foldersInFolder[[i]]) 
      }
      
      return(folders)
    }
  })
  
  
  # Sample Map --------------------------------------------------------------
  
  
  output$missingSampleNames <- shiny::renderText({
    req(rawFilesLocation())
    req(sampleMapReactive$rt)
    
    aa <- sapply(1:24, function(x) paste0(LETTERS[1:16], x))
    aa <- matrix(aa, nrow = 16, ncol = 24)
    
    
    spots <- IDBacApp::brukerDataSpotsandPaths(brukerDataPath = rawFilesLocation())
    s1 <- base::as.matrix(sampleMapReactive$rt)
    b <- sapply(spots, function(x) s1[which(aa %in% x)])
    b <- as.character(spots[which(is.na(b))])
    
    if (length(b) == 0) {
      paste0("No missing IDs")
    } else {
      paste0(paste0(b, collapse = " \n ", sep = ","))
    }
  })
  
  sampleMapReactive <- reactiveValues(rt = as.data.frame(base::matrix(NA,
                                                                      nrow = 16,
                                                                      ncol = 24,
                                                                      dimnames = list(LETTERS[1:16],1:24))))
  
  observeEvent(input$showSampleMap, 
               ignoreInit = TRUE, {  
                 ns <- session$ns
                 showModal(modalDialog(footer = actionButton(ns("saveSampleMap"), "Save"),{
                   tagList(
                     rhandsontable::rHandsontableOutput(ns("plateDefault"))
                     
                   )
                 }))
                 
                 
                 
               })
  observeEvent(input$saveSampleMap, 
               ignoreInit = TRUE, {  
                 
                 shiny::removeModal()
                 
               })
  
  
  
  output$plateDefault <- rhandsontable::renderRHandsontable({
    
    rhandsontable::rhandsontable(sampleMapReactive$rt,
                                 useTypes = FALSE,
                                 contextMenu = TRUE,
                                 maxRows = 16,
                                 maxRows = 24) %>%
      rhandsontable::hot_context_menu(allowRowEdit = FALSE,
                                      allowColEdit = FALSE) %>%
      rhandsontable::hot_cols(colWidths = 100) %>%
      rhandsontable::hot_rows(rowHeights = 25)
  })
  
  
  
  
  
  
  observeEvent(input$saveSampleMap, 
               ignoreInit = TRUE, {
                 z <- unlist(input$plateDefault$data, recursive = FALSE) 
                 zz <- as.character(z)
                 zz[zz == "NULL"] <- NA 
                 
                 # for some reason rhandsontable hot_to_r not working, implementing own:
                 changed <- base::matrix(zz,
                                         nrow = nrow(sampleMapReactive$rt),
                                         ncol = ncol(sampleMapReactive$rt),
                                         dimnames = list(LETTERS[1:16],1:24),
                                         byrow = T)
                 
                 sampleMapReactive$rt <- as.data.frame(changed, stringsAsFactors = FALSE)
                 
                 
               })
  
  
  
  
  
  
  
  
  
  
  
  
  
  # Spectra Conversion ------------------------------------------------------
  
  
  
  # Spectra conversion
  #This observe event waits for the user to select the "run" action button and then creates the folders for storing data and converts the raw data to mzML
  #----
  spectraConversion <- reactive({
    
    IDBacApp::excelMaptoPlateLocation(typeOfRawData = input$typeOfRawData,
                                      excelFileLocation = input$excelFile$datapath,
                                      rawFilesLocation = rawFilesLocation(),
                                      multipleMaldiRawFileLocation = multipleMaldiRawFileLocation())
    
  })
  
  
  
  
  
  # Run raw data processing on delimited-type input files
  #----
  observeEvent(input$runDelim, 
               ignoreInit = TRUE, {
                 
                 popup1()
                 
                 IDBacApp::parseDelimitedMS(proteinDirectory = delimitedLocationP(),
                                            smallMolDirectory = delimitedLocationSM(),
                                            exportDirectory =  tempdir())
                 popup2()
               })
  
  # Popup summarizing the final status of the conversion
  #----
  popup2 <- reactive({
    showModal(modalDialog(
      size = "m",
      title = "Conversion Complete",
      paste0(" files were converted into open data format files."),
      br(),
      "To check what has been converted you can navigate to:",
      easyClose = TRUE,
      footer = tagList(actionButton("beginPeakProcessingModal", 
                                    "Click to continue with Peak Processing"),
                       modalButton("Close"))
    ))
  })
  # Modal to display while converting to mzML
  #----
  popup1 <- reactive({
    showModal(modalDialog(
      size = "m",
      title = "Important message",
      "To track the",
      "To check what has been converted, you can navigate to:",
      easyClose = FALSE, size = "l",
      footer = ""))
  })
  
  
  
  
  
  
  
  # Call the Spectra processing function when the spectra processing button is pressed
  #----
  observeEvent(input$run, 
               ignoreInit = TRUE,  {
                 
                 ns <- session$ns
                 popup3()
                 
                 if (input$ConversionsNav == ns("convert_bruker_nav")) {
                   if (input$typeOfRawData == 1) {
                     validate(need(any(!is.na(sampleMapReactive$rt)), 
                                   "No samples entered into sample map, please try entering them again"))
                     aa <- sapply(1:24, function(x) paste0(LETTERS[1:16], x))
                     aa <- matrix(aa, nrow = 16, ncol = 24)
                     
                     spots <-  brukerDataSpotsandPaths(brukerDataPath = rawFilesLocation())
                     s1 <- base::as.matrix(sampleMapReactive$rt)
                     sampleMap <- sapply(spots, function(x) s1[which(aa %in% x)])
                     
                     forProcessing <- startingFromBrukerFlex(chosenDir = rawFilesLocation(), 
                                                             msconvertPath = "",
                                                             sampleMap = sampleMap,
                                                             tempDir = tempMZDir)
                     
                     
                     
                   }
                 }
                 
                 validate(need(length(forProcessing$mzFile) == length(forProcessing$sampleID), 
                               "Temp mzML files and sample ID lengths don't match."
                 ))
                 
                 lengthProgress <- length(forProcessing$mzFile)
                 
                 # Create DB
                 
                 userDB <- createNewSQLITEdb(input$newExperimentName)
                 
                 
                 progLength <- base::length(forProcessing$mzFile)
                 withProgress(message = 'Processing in progress',
                              value = 0,
                              max = progLength, {
                                
                                for (i in base::seq_along(forProcessing$mzFile)) {
                                  setProgress(value = i,
                                              message = 'Processing in progress',
                                              detail = glue::glue(" \n Sample: {forProcessing$sampleID[[i]]},
                                                            {i} of {progLength}"),
                                              session = getDefaultReactiveDomain())
                                  
                                  IDBacApp::spectraProcessingFunction(rawDataFilePath = forProcessing$mzFile[[i]],
                                                                      sampleID = forProcessing$sampleID[[i]],
                                                                      userDBCon = userDB) # pool connection
                                }
                                
                              })
                 
                 
                 pool::poolReturn(userDB)
                 
                 
                 
                 
                 # aa2z <-newExperimentSqlite()
                 # 
                 # numCores <- parallel::detectCores()
                 # cl <- parallel::makeCluster(numCores)
                 # parallel::parLapply(cl,fileList, function(x)
                 #                     IDBacApp::spectraProcessingFunction(rawDataFilePath = x,
                 #                                     userDBCon = aa2z))
                 # 
                 # 
                 
                 #  parallel::stopCluster(cl)
                 
                 
                 
                 
                 popup4()
               })
  
  
  
  # Modal displayed while speactra -> peak processing is ocurring
  #----
  popup3 <- reactive({
    showModal(modalDialog(
      size = "m",
      title = "Important message",
      "When spectra processing is complete you will be able to begin with the data analysis",
      br(),
      "To check the progress, observe the progress bar at bottom right.",
      easyClose = FALSE, 
      footer = ""))
  })
  
  
  # Popup notifying user when spectra processing is complete
  #----
  popup4 <- reactive({
    showModal(modalDialog(
      size = "m",
      title = "Spectra Processing is Now Complete",
      br(),
      easyClose = FALSE,
      tagList(actionButton("processToAnalysis", 
                           "Click to continue"))
    ))
    
  })
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
}











#' oneMaldiPlate
#'
#' @param id NA
#'
#' @return NA
#' @export
#'
#' @examples NA
oneMaldiPlate <- function(ns){
  tagList( 
    column(width = 12,
           style = "background-color:#7777770d",
           fluidRow(
             h3("Starting with a Single MALDI Plate of Raw Data", align = "center"),
             
             br(),
             column(12, align = "center",
                    p(strong("1: Enter a Name for this New Experiment")),
                    p("Only numbers, \"_\", and A-Z. Shouldn't start with a number."),
                    textInput(ns("newExperimentName"),
                              label = ""),
                    tags$hr(size = 20)),
             br(),
             p(strong("2: Click to select the location of your RAW data"), align = "center"),
             column(12, align = "center",
                    actionButton(ns("rawFileDirectory"),
                                 label = "Raw Data Folder"),
                    verbatimTextOutput(ns("rawFileDirectoryText"),
                                       placeholder = TRUE),
                    tags$hr(size = 20)),
             br(),
             column(12, align = "center",
                    p(strong("3:", "Fill in the Sample-ID spreadsheet.")),
                    
                    actionButton(ns("showSampleMap"), "Click to name samples"),
                    br(),
                    p(strong("Missing sample IDs for the following spots:")),
                    shiny::verbatimTextOutput(ns("missingSampleNames"), placeholder = TRUE)
             ),
             column(12, align = "center",
                    p(strong("4:","Click \"Process Data\" to begin spectra conversion.")),
                    actionButton(ns("run"),
                                 label = "Process Data"),
                    tags$hr(size = 20))
           )
    ))
  
}


#' oneMaldiPlateHelpUI
#'
#' @param id NA
#'
#' @return NA
#' @export
#'
#' @examples NA
oneMaldiPlateHelpUI <- function(id){
  ns <- shiny::NS(id)
  tagList(
    h3("Instructions", align = "center"),
    
    br(),
    p(strong("1: Working Directory"), " This directs where on your computer you would like to create an IDBac working directory."),
    p("In the folder you select, IDBac will create sub-folders within a main directory named \"IDBac\":"),
    img(src = "WorkingDirectory.png",
        style = "width:60%;height:60%"),
    br(),
    p(strong("2: Raw Data"), "Your RAW data is a single folder that contains: one subfolder containing protein
      data and one subfolder containing small-molecule data"),
    img(src = "Single-MALDI-Plate.png",
        style = "width:60%;height:60%"),
    br(),
    p("*Note: Sometimes the browser window won't pop up, but will still appear in the application bar. See below:"),
    img(src = "window.png",
        width = "100%")
  )
  
}



#' multipleMaldiPlates
#'
#' @param id NA
#'
#' @return NA
#' @export
#'
#' @examples NA
multipleMaldiPlates <- function(id){
  ns <- shiny::NS(id)
  fluidRow(
    column(12,
           br(),
           br(),
           fluidRow(
             column(12,offset = 3,
                    h3("Starting with Multiple MALDI Plates of Raw Data"))), br(), br(),
           column(5,
                  fluidRow(column(5,
                                  offset = 3,
                                  h3("Instructions"))),
                  br(),
                  p(strong("1:")," This directs where on your computer you would like to create an IDBac working directory."),
                  p("In the folder you select- IDBac will create folders within a main directory named \"IDBac\":"),
                  img(src = "WorkingDirectory.png",
                      style = "width:322px;height:164px"),
                  p("If there is already an \"IDBac\" folder present in the working directory,
                    files will be added into the already-present IDBac folder ", strong("and any samples with the same name will be overwritten.")),
                  br(),
                  p(strong("2:"),"The RAW data file will be one folder that contains individual folders for each
                    MALDI plate. Each MALDI plate folder will contain an Excel map and two folders: one
                    containing protein data and the other containing small molecule data:"),
                  img(src = "Multi-MALDI-Plate.png", 
                      style = "width:410px;height:319px"),
                  p("Note: Sometimes the browser window won't pop up, but will still appear in the application bar. See below:"),
                  img(src = "window.png",
                      width = "100%")
           ),
           column(1),
           column(5,
                  style = "background-color:#7777770d",
                  fluidRow(
                    h3("Workflow Pane", align = "center")),
                  br(),
                  column(12, align = "center",
                         p(strong("1: Enter a Name for this New Experiment")),
                         p("Only numbers, \"_\", and A-Z. Shouldn't start with a number."),
                         textInput(ns("newExperimentName"),
                                   label = ""),
                         tags$hr(size = 20)),
                  fluidRow(
                    column(12,
                           verbatimTextOutput(ns("newExperimentNameText"),
                                              placeholder = TRUE))),
                  br(),
                  p(strong("2:"), "Your RAW data will be one folder that contains folders for each MALDI plate."),
                  br(),
                  p(strong("2: Click to select the location of your RAW data"), align = "center"),
                  actionButton(ns("multipleMaldiRawFileDirectory"),
                               label = "Click to select the location of your RAW data"),
                  fluidRow(column(12,
                                  verbatimTextOutput(ns("multipleMaldiRawFileDirectory"),
                                                     placeholder = TRUE))),
                  br(),
                  column(12, align = "center",
                         p(strong("4:","Click \"Process Data\" to begin spectra conversion.")),
                         actionButton(("run"),
                                      label = "Process Data"),
                         tags$hr(size = 20))
           )
    )
  )
}


#' beginWithMZ
#'
#' @param id NA
#'
#' @return NA
#' @export
#'
#' @examples NA
beginWithMZ <- function(id){
  fluidRow(
    column(width = 10, offset = 2, wellPanel(class = "intro_WellPanel", align= "center",
                                             h3("Starting with mzML or mzXML Data:"),
                                             
                                             
                                             p(strong("1: Enter a filename for this new experiment")),
                                             p("Only numbers, \"_\", and A-Z. Shouldn't start with a number."),
                                             textInput(ns("newExperimentName"),
                                                       label = ""),
                                             tags$hr(size = 20),
                                             
                                             br(),
                                             p(strong("2: Click to select the location of your mzML files"), align= "center"),
                                             actionButton(ns("mzmlRawFileDirectory"),
                                                          label = "Raw Data Folder"),
                                             verbatimTextOutput(ns("mzmlRawFileDirectory"),
                                                                placeholder = TRUE),
                                             tags$hr(size = 20),
                                             br(),
                                             p("Samples will be named according to the file name of the provided files"),
                                             br(),
                                             p(strong("4:","Click \"Process Data\" to begin spectra conversion.")),
                                             actionButton(ns("run"),
                                                          label = "Process Data"),
                                             tags$hr(size = 20)
                                             
    )
    ))
  
}

#' beginWithTXT
#'
#' @param id NA
#'
#' @return NA
#' @export
#'
#' @examples NA
beginWithTXT <- function(id){
  ns <- NS(id)
  fluidRow(
    p(".txt and .csv support coming soon!"),
    actionButton(ns("delimitedDirectoryP"),
                 label = "Raw Data P Folder"),
    actionButton(ns("delimitedDirectorySM"),
                 label = "Raw Data SM Folder"),
    actionButton(ns("runDelim"),
                 label = "Process Data"),
    verbatimTextOutput(ns("delimitedLocationPo"),
                       placeholder = TRUE),
    verbatimTextOutput(ns("delimitedLocationSMo"),
                       placeholder = TRUE)
  )
}



