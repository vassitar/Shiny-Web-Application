
library(shiny)
library(leaflet)
library(dplyr)
library(rgdal)
library(ggplot2)


europe <- read.csv("european_countries.csv", stringsAsFactors = FALSE)
euro.map <- readOGR(dsn =  "./European_Union_Map",
                    layer = "EuroMap")
countries <- sort(europe$Country)


capitals <- data.frame(Country = countries,
                       Capital = c("Vienna", "Brussels", "Sofia", "Zagreb",
                                   "Nicosia", "Prague", "Copenhagen", "Tallinn", 
                                   "Helsinki", "Paris", "Berlin", "Athens", "Budapest",
                                   "Reykjavik", "Dublin", "Rome", "Riga", "Vaduz",
                                   "Vilnius", "Luxembourg", "Valletta", "Amsterdam",
                                   "Oslo", "Warsaw", "Lisbon", "Bucharest", "Bratislava",
                                   "Ljubljana", "Madrid", "Stockholm", "Berne", "London"),
                       lat = c(48.21, 50.85, 42.70, 45.81, 35.17, 50.09, 55.68, 59.44,
                               60.17, 48.85, 52.52, 37.98, 47.50, 64.14, 53.33, 
                               41.89, 56.95, 47.14, 54.69, 49.61, 
                               35.90, 52.37, 59.91, 52.23, 38.72, 44.43, 48.15, 
                               46.05, 40.42, 59.33, 46.95, 51.51),
                       lng = c(16.37, 4.35, 23.32, 15.98, 33.37, 14.42, 12.57, 24.75,
                               24.94, 2.35, 13.41, 23.72, 19.04, -21.90, -6.25, 
                               12.48, 24.11, 9.52, 25.28, 6.13, 
                               14.51, 4.89, 10.75, 21.01, -9.13, 26.11, 17.11, 
                               14.51, -3.70, 18.06, 7.45, -0.13),
                       stringsAsFactors = FALSE)


bins <- data.frame(Population.Value = c(0, 500000, 4000000, 8000000, 25000000, 35000000, 45000000, 
                                        55000000, 85000000),
                   Income.Value = c(0, 2500, 5000, 7500, 15000, 20000, 25000, 35000, 45000),
                   Intentional.Homicide.Value = c(0, 0.5, 1, 1.5, 2, 3, 4, 5, 6),
                   Healthcare.Expenditure.Value = c(0, 1000, 3000, 10500, 25000, 40000, 100000, 200000, 300000),
                   Unemployment.Value = c(0, 3, 4.5, 5.5, 6.5, 7.5, 10, 15, 20),
                   GDP.Value = c(0, 10000, 50000, 100000, 200000, 500000, 1500000, 2000000, 3500000))


color.schemes <- data.frame(Population.Value = "YlOrRd", 
                            Income.Value = "OrRd",
                            Intentional.Homicide.Value = "PuRd",
                            Healthcare.Expenditure.Value = "RdPu",
                            Unemployment.Value = "YlOrBr",
                            GDP.Value = "YlGn",
                            stringsAsFactors = FALSE)



europe.map <- leaflet(data = euro.map) %>%
    addTiles() %>%
    addMarkers(popup = capitals$Capital,
               lng = capitals$lng,
               lat = capitals$lat,
               options = markerOptions(opacity = 0.7)) 







shinyServer(function(input, output, session) {
    
    
    # Plot button (box plot or a histogram):    
    
    button <- reactiveValues(click = NULL) 
    
    # Reset the click button when input$parameter is changed:
    observeEvent(eventExpr = input$parameter, handlerExpr = {
        
        button$click <- NULL
    })
    
    
    observeEvent(eventExpr = input$BoxplotButton, handlerExpr = {     
        
        button$click <- "boxplot"
    })   
    
    observeEvent(eventExpr = input$HistogramButton, handlerExpr = {     
        
        button$click <- "histogram"
    })  
    
   
    
    # Bins for the reactive slider:
    histbins <- reactive({
        
        round(diff(range(europe[ ,input$parameter], na.rm = TRUE))/(2*IQR(europe[ ,input$parameter], na.rm = TRUE)/32^(1/3)))
    })   
    
    
    output$slider <- renderUI(expr = {
        
        if(is.null(button$click)){
            
            return()
            
        }
        
        if(button$click == "histogram"){
            sliderInput(inputId = "sliderin", label = "Number of bins:",
                        min = 1,
                        max = 2*histbins(),
                        value = histbins())
        }
        
    })
    

        
# Reactive plot (box plot or histogram):
    observeEvent(eventExpr = button$click, ignoreNULL = FALSE, handlerExpr = {
        
        if(is.null(button$click)) {
            
            output$plot <- renderPlot({
                
            }) 
        }else  if(button$click == "boxplot"){
            
            isolate({
                output$plot <- renderPlot(expr = {
                    
                    g <- ggplot(data = europe, aes(x = factor(0), y = europe[ ,input$parameter])) +  
                        geom_boxplot(na.rm = TRUE) +
                        stat_summary(fun.y = mean, geom = 'point', shape = 4, colour = "red", na.rm = TRUE) +
                        labs(x = gsub("\\.|Value", " ", input$parameter),
                             y = "") +
                        scale_x_discrete(breaks = NULL) +
                        ggtitle(paste("Box Plot of", gsub("\\.|Value", " ", input$parameter)))
                    
                    print(g) 
                }) 
            })
        }else if(button$click == "histogram"){
            
            isolate({    
                output$plot <- renderPlot(expr = {
                    
                    g <- ggplot(data = europe, aes(x = europe[ ,input$parameter])) +
                        geom_histogram(bins = input$sliderin, na.rm = TRUE) +
                        labs(x = gsub("\\.|Value", " ", input$parameter),
                             y = "Count") +
                        ggtitle(paste("Histogram of", gsub("\\.|Value", " ", input$parameter)))
                    
                    print(g)
                })
            })
        }
    })
    
    
    
    
    # Character vector with the information about each country:        
    
    info.polygons <- reactiveValues(info = vector(mode = "character"))
    
    observeEvent(eventExpr = input$parameter, handlerExpr = {
        
        info.polygons$info <- sapply(countries, function(name){
            
            paste(name, ",", gsub("\\.|Value", " ", input$parameter), ":",
                  europe[europe$Country == name, input$parameter])
        })
        info.polygons$info <- as.vector(info.polygons$info, mode = "character")
    })
    
    
    # Palettes for the maps:
    
    pal <- reactiveValues()    
    
    observeEvent(eventExpr = input$parameter, handlerExpr = {
        
        pal <<- colorBin(palette = color.schemes[ ,input$parameter], 
                         domain = europe[ ,input$parameter], 
                         bins = bins[ ,input$parameter])
    })  
    
   
    
    # Rendering the leaflet map:
    
    output$map <- renderLeaflet({
        
        europe.map %>%
            addPolygons(smoothFactor = 0.2,
                        fillOpacity = 0.6, 
                        fillColor = ~pal(europe[ ,input$parameter]),
                        stroke = TRUE, 
                        dashArray = "3", 
                        weight = 2, 
                        color = "white", 
                        opacity = 1,
                        highlight = highlightOptions(weight = 5,
                                                     color = "#666",
                                                     dashArray = "",
                                                     fillOpacity = 0.7,
                                                     bringToFront = TRUE),
                        label = info.polygons$info,
                        labelOptions = labelOptions(style = list("font-weight" = "normal", padding = "3px 8px"),
                                                    textsize = "15px",
                                                    direction = "auto"))%>%
            addLegend(pal = pal, position = "topright", values = ~europe[ , input$parameter],    
                      title = paste(gsub("\\.|Value", " ", input$parameter))) %>%
            setView(lng = 9.52, lat = 47.14, zoom = 4)
        
    })
    
})


