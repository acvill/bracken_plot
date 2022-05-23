library(shiny)
library(ggplot2)
library(purrr)
library(dplyr)
library(stringr)
library(tidyr)

# written and owned by Albert Vill, albertcvill@gmail.com
# Last Updated 27 August 2021

# Define function to create stacked barplot

plot_bracken <- function(file, top = NA, pal, otherColor){
    
    # file is the bracken data
    # top is an integer, trims the data to the number of top taxa (by median) in a given level for better plotting
    ## top = NA is the default and will plot all taxa in a given level
    # pal is a palette of hex colors
    # otherColor is the color used to represent taxa below median abundance threshold
    
    levdat <- file %>%
        select(-contains(c("_num","taxonomy_"))) %>%
        pivot_longer(!name, names_to = "sample", values_to = "fraction") %>%
        mutate(sample = str_remove_all(sample, "_frac"))
    
    level <- file %>%
        select(contains("taxonomy_lvl")) %>% unique()
    
    newpal <- str_split(pal, ",") %>% unlist() %>% paste0("#",.)
    
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
        
        top_select <- aggregate(levdat$fraction, by = list(levdat$name), FUN = median) %>%
            purrr::set_names(c("group","value")) %>%
            arrange(desc(value)) %>%
            dplyr::slice(1:top) %>% pull(var = group)
        
        levdat <- filter(levdat, levdat$name %in% top_select)
        
        fill_unk <- aggregate(levdat$fraction, by = list(levdat$sample), FUN = sum) %>% 
            purrr::set_names(c("sample","sum")) %>% 
            mutate_if(is.numeric, round, 3)
        
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
    
    ggplot(data = levdat) +
        geom_bar(mapping = aes(x = sample, y = fraction, fill = name),
                 position = "fill", stat = "identity", width = 0.75) + 
        scale_fill_manual(paste(label),
                          values = fill_vals) +
        theme_classic() +
        scale_x_discrete("") +
        scale_y_continuous("Relative Abundance") +
        theme(axis.text.x = element_text(angle = -90, vjust = 0.5, hjust = 1, size = 12),
              axis.text.y = element_text(size = 10),
              axis.title.x = element_text(),
              axis.title.y = element_text(size = 13),
              legend.position = "right")
    
    
    
}

# Define UI 
ui <- fluidPage(

    # Application title
    titlePanel("Bracken bar plot generator"),

    HTML("<p>For help, example files, and source code, please refer to the <a href='https://github.com/acvill/bracken_plot'>github page</a>.</p>"),
    
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
            submitButton("Create Plot", icon = NULL, width = NULL)
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
    
    reactive_data <- reactive({
        if(is.null(input$userFile)) {
            return(NULL)
        }
        print(input$userFile$datapath)
        df <- read.table(file = input$userFile$datapath,
                         header = T,
                         sep = "\t")
        return(df)
    })
    
    ###
    
    output$barPlot <- renderPlot({
        
        data <- reactive_data()
 
        if (is.null(data)) {
            
            return(NULL)
            
        } else {
        
            plot_bracken(file = data,
                         top = input$topTaxa,
                         pal = input$userPal,
                         otherColor = input$otherColor)
        
        }  
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
