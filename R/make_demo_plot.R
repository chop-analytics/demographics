#' Make demographic plots
#'
#' Helper function to make stratified plots by each demographic field.
#'
#' @param data Dataframe with demographics
#' @param metric Field from dataframe to stratify
#' @param demo Demographic fields to plot
#'
#' @import ggplot2
#' @import ggthemes

make_demo_plot <- function(data, metric, demo){
  ggplot(data = filter(data, demo_group == demo), aes(x = reorder(demo_value, -METRIC), y = METRIC)) +
    geom_bar(stat = "summary", fun.y = "mean", fill = "#50a0f0", na.rm = TRUE) +
    theme_few() +
    labs(x = demo, y = paste("Avg of", metric), title = paste(metric, "stratified by", demo)) +
    coord_flip()
}




