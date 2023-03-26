#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(tidyverse)
library(terra)
library(tmap)
library(sf)

id_r   <- rast(here('shiny_data/watershed_id.tif'))
cost_r <- rast(here('shiny_data/cost_by_watershed.tif'))
rip_r  <- rast(here('shiny_data/riparian_by_watershed.tif'))
vs_r   <- rast(here('shiny_data/viewshed_by_watershed.tif'))
roi_sf <- read_sf(dsn = here('raw_data/input.gpkg'),
                  layer = 'watersheds')


reclass_rast <- function(r_val, n_cats = 4, reverse = FALSE) {
  ### reclassify raster watersheds based on ntile; return as raster with ntile
  ### value in place of original raster value
  ### NOTE: 1 = best, n_cats = worst!
  r_df <- data.frame(values(id_r),
                     values(r_val)) %>%
    setNames(c('id', 'val'))
  qtile_df <- r_df %>%
    drop_na() %>%
    distinct() %>%
    ### quantiles by highest value = first priority; go by reverse value
    mutate(qtile = ntile(-val, n_cats)) %>%
    select(id, qtile)
  if(reverse) qtile_df <- qtile_df %>% mutate(qtile = n_cats - qtile + 1)
  qtile_r_df <- r_df %>%
    left_join(qtile_df, by = 'id')
  qtile_r <- r_val %>%
    setValues(qtile_r_df$qtile)
  return(qtile_r)
}

# Define server logic required to draw a histogram
function(input, output, session) {

  ### For tab 1: weighted average of criterion weights
  ### Determine relative criterion weights based on input scores
  crit_wts <- reactive({
    tot_wt <- sum(input$rip_wt, input$vs_wt, input$cost_wt)
    rel_wt <- c(rip  = input$rip_wt / tot_wt,
                vs   = input$vs_wt / tot_wt,
                cost = input$cost_wt / tot_wt)
    return(rel_wt)
  })
  output$crit_wt_text <- renderText({
    txt_stem <- 'Relative weights: %.1f%% (riparian), %.1f%% (viewshed), %.1f%% (cost)'
    rel_pct <- round(crit_wts() * 100, 1)
    message(paste0(rel_pct, collapse = ', '))
    return(sprintf(txt_stem, rel_pct[1], rel_pct[2], rel_pct[3]))
  })
  
  ### get quantiled criteria maps, stack, and calc weighted mean by
  ### summing relative-weighted rasters
  get_mca_map <- reactive({
    rip_q_r  <- reclass_rast(rip_r,  input$ntile, reverse = FALSE)
    vs_q_r   <- reclass_rast(vs_r,   input$ntile, reverse = FALSE)
    cost_q_r <- reclass_rast(cost_r, input$ntile, reverse = TRUE)
    
    mca_mean_r <- 
      rip_q_r * crit_wts()['rip'] +
      vs_q_r * crit_wts()['vs'] +
      cost_q_r * crit_wts()['cost']

    return(mca_mean_r)
  })
  ### plot MCA result map as tmap
  output$mca_map_plot <- renderTmap({
    mca_results_by_watershed <- get_mca_map()
    watersheds <- roi_sf
    tm_shape(mca_results_by_watershed) +
      tm_raster(alpha = input$alpha1, 
                title = 'MCA priority',
                palette = '-viridis') +
      tm_shape(watersheds) +
      tm_borders(col = 'yellow1')
  })
  
    
  ### For tab 2:
  ### identify the proper criterion map, and if user wants, reclass to quantiles
  get_crit_map <- reactive({
    r <- switch(input$crit_map_select,
                rip = rip_r,
                vs = vs_r,
                cost = cost_r)
    if(input$q_or_val == 'q') {
      reverse <- input$crit_map_select == 'cost'
      message(input$crit_map_select)
      message('reverse = ', reverse)
      r <- reclass_rast(r, n_cats = input$ntile, reverse = reverse)
    }
    return(r)
  })
  
  output$q_vs_val_text <- renderText({
    return('Ranking by quantile: 1 = highest priority')
  })
  
  
  ### plot criterion map as tmap
  output$crit_map_plot <- renderTmap({
    criterion_by_watershed <- get_crit_map()
    watersheds <- roi_sf
    ### set up legend title
    crit_text <- switch(input$crit_map_select,
                        rip =  'Riparian area',
                        vs =   'Viewshed area',
                        cost = 'Development cost')
    if(input$q_or_val == 'q') {
      crit_text <- paste(crit_text, '\n(priority quantile)')
    }
    ### set up palette direction: 
    ### * if quantile, -viridis (low values = yellow); 
    ### * if value, viridis (high values, good or bad = yellow)
    crit_pal <- ifelse(input$q_or_val == 'q', '-viridis', 'viridis')
    tm_shape(criterion_by_watershed) +
      tm_raster(alpha = input$alpha2,
                title = crit_text,
                palette = crit_pal) +
      tm_shape(watersheds) +
      tm_borders(col = 'yellow1')
  })

}
