library(shiny)
library(ggplot2)
library(purrr)
library(dplyr)
library(stringr)
library(tidyr)
library(readr)
library(stats)
library(tools)

# written and owned by Albert Vill, albertcvill@gmail.com
# Last Updated 28 July 2023

# Define function to create stacked barplot

plot_bracken <- function(file, top = NA, pal, otherColor){
  
  # file is the bracken data
  # top is an integer, trims the data to the number of top taxa (by median) in a given level for better plotting
  ## top = NA is the default and will plot all taxa in a given level
  # pal is a palette of hex colors
  # otherColor is the color used to represent taxa below median abundance threshold
  
  levdat <-
    dplyr::select(file,
                  -contains(c("_num","taxonomy_"))) |>
    tidyr::pivot_longer(cols = !name,
                        names_to = "sample",
                        values_to = "fraction") |>
    dplyr::mutate(sample = str_remove_all(sample, "_frac"))
  
  level <-
    dplyr::select(file,
                  contains("taxonomy_lvl")) |>
    unique()
  
  newpal <-
    paste0("#",
           stringr::str_split(pal, ",") |> unlist()
    )
  
  if (level == "K") {
    label <- "Kingdom"
  } else if (level == "P") {
    label <- "Phylum"
  } else if (level == "C") {
    label <- "Class"
  } else if (level == "O") {
    label <- "Order"
  } else if (level == "F") {
    label <- "Family"
  } else if (level == "G") {
    label <- "Genus"
  } else if (level == "S") {
    label <- "Species"
  } else if (level == "S1") {
    label <- "Strain"
  } else {
    message("Bracken taxonomy_lvl needs to be K, P, C, O, F, G, S, or S1")
  }
  
  if (!is.na(top) && top < length(unique(levdat$name))) {
    
    top_select <-
      stats::aggregate(x = levdat$fraction,
                       by = list(levdat$name),
                       FUN = median) |>
      purrr::set_names(c("group","value")) |>
      dplyr::arrange(dplyr::desc(value)) |>
      dplyr::slice(1:top) |>
      dplyr::pull(var = group)
    
    levdat <- dplyr::filter(levdat, levdat$name %in% top_select)
    
    fill_unk <-
      stats::aggregate(x = levdat$fraction,
                       by = list(levdat$sample),
                       FUN = sum) |> 
      purrr::set_names(c("sample","sum")) |> 
      dplyr::mutate_if(is.numeric, round, 3)
    
    fill_unk$residual <- 1 - fill_unk$sum
    
    for (i in 1:nrow(fill_unk)) {
      
      levdat <- rbind(levdat, c("other", fill_unk[i,1], fill_unk[i,3]))
      
    }
    
    levdat <- transform(levdat, fraction = as.numeric(fraction))
    levdat$name <- factor(levdat$name, levels = unique(levdat$name))
    
    fill_vals <- c(rep_len(newpal, nrow(unique(levdat[1]))-1), otherColor)
    
  } else {
    
    fill_vals <- c(rep_len(newpal, nrow(unique(levdat[1]))))
    
  }
  
  print(nrow(levdat))
  
  ggplot2::ggplot(data = levdat) +
    ggplot2::geom_bar(mapping = ggplot2::aes(x = sample,
                                             y = fraction,
                                             fill = name),
                      position = "fill",
                      stat = "identity",
                      width = 0.75) + 
    ggplot2::scale_fill_manual(paste(label),
                               values = fill_vals) +
    ggplot2::theme_classic() +
    ggplot2::scale_x_discrete("") +
    ggplot2::scale_y_continuous("Relative Abundance") +
    ggplot2::theme(axis.text.x = element_text(angle = -90, vjust = 0.5, hjust = 1, size = 12),
                   axis.text.y = element_text(size = 10),
                   axis.title.x = element_text(),
                   axis.title.y = element_text(size = 13),
                   legend.position = "right")
  
}

# Define UI 
ui <- fluidPage(

    # Application title
    titlePanel("Bracken bar plot generator"),

    HTML("<p>For help, example files, and source code, please visit the <a href='https://github.com/acvill/bracken_plot'>GitHub page</a>.</p>"),
    
    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            fileInput("userFile", "Upload Bracken results file",
                      multiple = F,
                      accept = c(".txt",".tsv",".tab")),
            numericInput("topTaxa", "Maximum number of taxa to plot (leave blank to plot all)",
                         value = NULL,
                         min = 1, max = 50, step = 1),
            conditionalPanel(
                condition = "output.check >= 1",
                selectInput("otherColor", "Color for \"other\" taxa",
                            choices = c("gray","black","white"))
            ),
            textInput("userPal", "Custom color palette (optional)",
                      value = "5c2751,ef798a,f7a9a8,00798c,6457a6,9dacff,76e5fc,a30000,ff7700,f5b841"),
            submitButton(text = "Create Plot"),
            downloadButton(outputId = 'downloadPlot', label = 'Download Plot')
        ),
        
        mainPanel(
           plotOutput("barPlot")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    
    output$check <- reactive({ 
        input$topTaxa
    })   
    
    outputOptions(output, 'check', suspendWhenHidden = F)
    
    # Read in data
    
    reactive_data <- reactive({
        if(is.null(input$userFile)) {
            return(NULL)
        }
        print(input$userFile$datapath)
        notLogical <- cols(taxonomy_lvl = col_character())
        df <- readr::read_tsv(file = input$userFile$datapath,
                              col_names = TRUE,
                              col_types = notLogical)
        return(df)
    })
    
    # Create barplot
    
    output$barPlot <- renderPlot({
        
        data <- reactive_data()
 
        if (is.null(data)) {
            
            return(NULL)
            
        } else {
        
        plotout <- plot_bracken(file = data,
                                top = input$topTaxa,
                                pal = input$userPal,
                                otherColor = input$otherColor)
        
        ggsave("barplot.pdf", plotout)
        plotout
        
        }  
    })
    
    output$downloadPlot <- downloadHandler(
      filename = function() {
        "barplot.pdf"
      },
      content = function(file) {
        file.copy("barplot.pdf", file, overwrite = TRUE)
      }
    )
    
}

# Run the application 
shinyApp(ui = ui, server = server)
