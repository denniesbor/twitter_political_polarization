library(tidyverse)
library(readr)
library(tidyr)
# install.packages("ggpubr")
library(ggpubr)

folder = dirname(rstudioapi::getSourceEditorContext()$path)
data_directory = file.path(folder, '..', 'data')
setwd(data_directory)

# read the files
data <- read.csv("climate.csv")


# Reorder ideology_cluster from left -> right
data$ideology_cluster <- factor(
  data$ideology_cluster,
  
  levels = c(
    "Far Left",
    "Left Centrist",
    "Centrist",
    "Right Centrist",
    "Far Right"
  )
)

data$stance <- factor(
  data$stance,
  levels = c("pro",
             "anti",
             "neutral"),
  labels = c(
    "Favor)",
    "Against",
    "Neutral"
  )
)

# Box plot of sentiment by ideology_cluster
plot1 <-
  ggplot(data, aes(x = ideology_cluster, y = sentiment_label, fill = stance)) +
  geom_boxplot() +
  labs(title = "Sentiment scores per ideological group and stance", x = "Ideology group", y = "Sentiment") +
  scale_fill_discrete(name = "stance") +
  guides(fill=guide_legend(title="Stance"))

folder_out = file.path(folder, 'figures')
dir.create(folder_out, showWarnings = FALSE)

path_out = file.path(folder, 'figures', 'climate_change_sentiment.png')

# Display the arranged plots
ggsave(path_out,
       plot1,
       width = 8,
       height = 6)
print(plot1)