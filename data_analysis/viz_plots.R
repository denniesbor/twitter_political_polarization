library(tidyverse)
library(vcd)
library(readr)


sample_immigration <- read_csv("NLP/sample_immigration.csv")


# ggplot(sample_immigration, aes(x = ideology_cluster, fill = sentiment)) +
#   geom_bar(position = "stack") +
#   labs(title = "Sentiment distribution by ideology cluster", x = "Ideology Cluster", y = "Count") +
#   scale_fill_manual(values = c("negative" = "red", "positive" = "green", "neutral" = "blue")) +  # Adjust colors
#   facet_grid(~ vote)  # Add facets for "yes" and "no" votes


# Create a grouped bar plot
ggplot(sample_immigration, aes(x = sentiment, y = vader, fill = sentiment)) +
  geom_bar(stat = "identity") +
  labs(title = "VADER score against annotated sentiment and Vote", x = "Sentiment", y = "VADER scores") +
  facet_grid(vote ~ .) +
  scale_fill_manual(values = c("negative" = "red", "positive" = "green", "neutral" = "blue")) +
  theme(legend.position = "none") +
  ylim(-1, 1)


