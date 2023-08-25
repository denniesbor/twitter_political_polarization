library(tidyverse)
library(readr)
library(tidyr)


# read the files
data <- read_csv("./sample_immigration.csv")

# Lower the text in ideology_cluster
data$ideology_cluster <- tolower(data$ideology_cluster)

# Reorder ideology_cluster from left -> right
data$ideology_cluster <- factor(data$ideology_cluster, levels = c("far left", "left centrist", "centrist", "right centrist", "far right"))

plot1 <- ggplot(data, aes(x = ideology_cluster, fill = sentiment)) +
  geom_bar(position = "dodge") +
  labs(title = "Sentiment distribution by ideology cluster", x = "Ideology Cluster", y = "Count") +
  scale_fill_manual(values = c("negative" = "red", "positive" = "green", "neutral" = "blue"))+
  facet_grid(cols=vars(vote))

plot2 <- ggplot(data, aes(x = ideology, y = vader, color = ideology_cluster, shape = vote)) +
  geom_point(size = 3) +
  labs(title = "VADER sentiment vs. ideology scores with hue and shape by vote",
  x = "Ideology Scores", y = "VADER Sentiment") +
  scale_color_discrete(name = "Ideology Cluster") +
  scale_shape_manual(name = "Vote", values = c("No" = 16, "Yes" = 17))

# Box plot of sentiment by ideology_cluster
plot3 <- ggplot(data, aes(x = ideology_cluster, y = vader, fill = vote)) +
  geom_boxplot() +
  labs(title = "VADER sentiment scores per ideological group and vote", x = "Ideology Cluster", y = "VADER Sentiment")

# Plot a table matrix of the bert sentiment against manually annotated sentiment
# Create a cross-tabulation table
cross_tab <- table(data$bert_sentiment, data$sentiment)

# Convert the table to a data frame for plotting
cross_tab_df <- as.data.frame.matrix(cross_tab)
cross_tab_df$bert_sentiment <- rownames(cross_tab_df)

# Convert the data frame to long format for plotting
cross_tab_long <- gather(cross_tab_df, key = "sentiment", value = "count", -bert_sentiment)

# Create the bar plot
plot4 = ggplot(cross_tab_long, aes(x = bert_sentiment, y = count, fill = sentiment)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Cross-Tabulation of Bert Sentiment vs. Manually Annotated Sentiment",
       x = "Bert Sentiment", y = "Count") +
  scale_fill_discrete(name = "Manual Sentiment")
