#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)


# Define UI for application that draws a histogram
navbarPage('Multicriteria analysis for conservation priorities',

    tabPanel('Calculate MCA',
      # Sidebar with a slider input for number of bins
      sidebarLayout(
          sidebarPanel(
            h3('Quantiles'),
            p('To what quantile level should watersheds be scored?'),
            sliderInput('ntile',
                        'How many quantiles?',
                        min = 3,
                        max = 10,
                        value = 4),
            h3('Criteria weighting'),
            p('Weights are relative and need not sum to 1.'),
            numericInput('rip_wt',
                         'Riparian habitat weight',
                         value = 0.50,
                         min = 0, max = NA),
            numericInput('vs_wt',
                         'Viewshed area weight',
                         value = 0.33,
                         min = 0, max = NA),
            numericInput('cost_wt',
                         'Developable cost weight',
                         value = 0.17,
                         min = 0, max = NA),
            textOutput('crit_wt_text')
          ),
  
          # Show a plot of the generated distribution
          mainPanel(
            h3('Map of conservation priorities (1 = highest priority), according 
               to multiple criteria analysis results'),
              tmapOutput('mca_map_plot'),
              sliderInput('alpha1',
                          'Opacity?',
                          min = 0.1, max = 1, step = .1, value = .7)
          )
          )
      ),
    tabPanel('View criteria maps',
             # Sidebar with a slider input for number of bins
             sidebarLayout(
               sidebarPanel(
                 h3('View criterion maps'),
                 radioButtons('crit_map_select',
                              label = 'Choose a criterion:',
                              choices = c('Riparian area' = 'rip',
                                          'Viewshed area' = 'vs',
                                          'Developable cost' = 'cost'),
                              selected = 'rip'),
                 radioButtons('q_or_val',
                              label = 'Display value or quantile?',
                              choices = c('Value' = 'v',
                                          'Quantile' = 'q'),
                              selected = 'v'),
                 
                 textOutput('q_vs_val_text')
               ),
               
               # Show a plot of the generated distribution
               mainPanel(
                 tmapOutput('crit_map_plot'),
                 sliderInput('alpha2',
                             'Opacity?',
                             min = 0.1, max = 1, step = .1, value = .7)
                 )
               )
             )
)
