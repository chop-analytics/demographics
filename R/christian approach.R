# How Christian might approach this
make_demo_plot <- function(data, metric, demo){
  # Draft of data transformation
  data2 <- data %>%
    group_by(demo, demo_group, metric) %>%
    summarize(n = n(),
              mean = sum(metric)/ count(metric) )

  ggplot(filter(data2, demo_group == demo), aes(x = reorder(demo_value, -METRIC), y = metric)) +
    geom_col(fill = "#50a0f0", na.rm = TRUE) +
    geom_text(y = mean, aes(label = mean), hjust = -.25 ) +
    geom_text(y = -.5,  aes(label =  n)) +
    theme_few() +
    labs(x = demo, y = paste("Avg of", metric), title = paste(metric, "stratified by", demo)) +
    coord_flip()
}

library(scales)

make_demo_plot <- function(data, metric, demo){
  ggplot(data, aes(x = demo, y = metric,  label = 1)) +
    geom_bar(aes(y = ..count..), fill = "#50a0f0", na.rm = TRUE) +
    geom_text() +
    theme_few() +
    labs(x = demo, y = paste("Avg of", metric), title = paste(metric, "stratified by", demo)) +
    coord_flip()
}
