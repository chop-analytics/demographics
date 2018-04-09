library(ggplot2)
library(ggthemes)

make_demo_plot <- function(demo){
  ggplot(data = filter(demo_pivot, demo_group == demo), aes(x = demo_value, y = METRIC)) +
    geom_bar(stat = "summary", fun.y = "mean", fill = "#50a0f0") +
    theme_few() +
    labs(x = demo, y = "AVERAGE", title = paste(METRIC, "stratified by", demo))
}
