#' Make demographic plots
#'
#' Helper function to make stratified plots by each demographic field.
#'
#' @param data Dataframe with demographics
#' @param demo Demographic fields to plot
#'
#' @import ggplot2
#' @import ggthemes

make_demo_plot <- function(data, demo){
  ggplot(data = filter(data, demo_group == demo), aes(x = demo_value, y = METRIC)) +
    geom_bar(stat = "summary", fun.y = "mean", fill = "#50a0f0") +
    theme_few() +
    labs(x = demo, y = "AVERAGE", title = paste(METRIC, "stratified by", demo))
}
