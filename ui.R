
library(shiny)
library(leaflet)



shinyUI(fluidPage(
    
    # Application title
    titlePanel("Statistical Data on the European Union Countries"),
    sidebarLayout(
        sidebarPanel(
            selectInput(inputId = "parameter",
                        label = "Select parameter:",
                        choices = c("Population" = "Population.Value",
                                    "Income" = "Income.Value",
                                    "Intentional Homicide Rate" = "Intentional.Homicide.Value",
                                    "Healthcare Expenditure" = "Healthcare.Expenditure.Value",
                                    "Unemployment Rate" = "Unemployment.Value",
                                    "GDP" = "GDP.Value")),
            actionButton(inputId = "BoxplotButton", label = "Box plot"),
            actionButton(inputId = "HistogramButton", label = "Histogram"),
            uiOutput("slider"),
            plotOutput(outputId = "plot")
        ),
        mainPanel(
            leafletOutput("map"),
            helpText(p(strong("Documentation:")),
                     p("- The interactive web application shows statistical data about the
                       countries in the European Union together with Norway, Switzerland,
                        Iceland and Liechtenstein, which are either members of the European Free Trade Association (EFTA) or the Schengen Area"),
                     p("- The data is for 2014 and is taken from", a("Eurostat", href = "http://ec.europa.eu/eurostat/data/database")),
                     p("- Select a parameter from the drop-down menu"),
                     p("The interactive map is redrawn to show the values of the chosen parameter"),
                     p("- Push one of the two buttons:", strong("Box plot"), "or", strong("Histogram")),
                     p("- If" , strong("Box plot"), "is chosen, the red cross represents the mean"),
                     p("- If", strong("Histogram"), "is chosen, move the slider to set the number of bins (the 
                       optimal number of bins for each parameter is calculated according 
                       to the Freedman-Diaconis rule and is set by default as the initial value of the slider)"),
                     p("- Hover with the mouse over the map to see the name of the corresponding country together
                       with the value of the chosen parameter for this country"),
                     p("- The markers are placed at the geographical location of each capital"),
                     p("- Click with the mouse on a marker to see the name of the respective capital")
            )  
        )
    )
))

