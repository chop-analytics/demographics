#' Stratify dataset by demographic variables
#'
#' Function to stratify a metric from an input dataset by race/ethnicity, primary language, and payer type.
#'
#' @param table Either datamart name or R dataframe
#' @param metric Metric to be stratified
#' @param qmr_con QMR_DEV connection name
#' @param datamart Logical indicating if table argument is a datamart in \code{OCQI_UAT} Defaults to TRUE.
#'
#' @import tidyr
#' @import dplyr
#' @import purrr
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Make sure you have a connection to \code{QMR_DEV} established
#' screen_demos(table = "FACT_KARABOTS_BREASTFEEDING",
#' metric = "BREASTFED_ONLY_IND",
#' qmr_con = qmr_dev)
#' }
#'
#' \dontrun{
#' # Make sure you have a connection to \code{QMR_DEV} established
#' screen_demos(table = "your_data_frame",
#' metric = "column_in_dataframe",
#' qmr_con = qmr_dev,
#' datamart = FALSE)
#' }

screen_demos <- function(table, metric, qmr_con, datamart = TRUE) {
# get data

demo_data <- get_demo_data(table, metric, qmr_con, datamart)

#Define the demos here by their SQL columns names
demo_vars <- c("RACE", "PAYER_TYPE", "PRIMARY_LANG")

#Gather
demo_pivot <-
  demo_data %>%
  gather(demo_group, demo_value, -VISIT_KEY, -PAT_KEY, -METRIC)

demo_plots <- map(demo_vars, ~make_demo_plot(data = demo_pivot, metric = metric, demo = .))

names(demo_plots) <- demo_vars

demo_plots
}
