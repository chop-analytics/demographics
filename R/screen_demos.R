library(tidyr)
library(dplyr)
library(ggplot2)
library(purrr)

screen_demos <- function(table, metric, qmr_con, datamart = TRUE) {
# get data

demo_data <- get_demo_data(table, metric, qmr_con, datamart)

#Define the demos here by their SQL columns names
demo_vars <- c("RACE", "PAYER_TYPE", "PRIMARY_LANG")

#Gather
demo_pivot <-
  demo_data %>%
  gather(demo_group, demo_value, -VISIT_KEY, -PAT_KEY, -METRIC)

demo_plots <- map(demo_vars, make_demo_plot)

demo_plots
}
