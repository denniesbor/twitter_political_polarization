library(tidyverse)
library(ggplot2)
library(dplyr)
library(viridis)


folder = dirname(rstudioapi::getSourceEditorContext()$path)
data_directory = file.path(folder, '..', 'data')
setwd(data_directory)

tweets_df <- read.csv("gpt_4_locations_sentiments.csv")

# Broadband csv
bb_df <- read.csv("broadband_demand_supply_v2.csv")
bb_df <- bb_df %>% rename(district = cd116)

# Congressional district member biographies
cd_bios <- read.csv("cd116_bio.csv")


# Merge the bios and the broadband df
bb_bios_df <- merge(bb_df, cd_bios, by = c("state", "district"))

govtrack_house <- read.csv("govtrack-stats-2020-house-ideology.csv")
govtrack_senate <-
  read.csv("govtrack-stats-2020-senate-ideology.csv")
govtrack_df <- bind_rows(govtrack_house, govtrack_senate)

data <-
  merge(tweets_df, govtrack_df, by.x = "govtrack_id", by.y = "id")

# Replace the stance columns
data <- data %>%
  mutate(
    stance = gsub("Together", "Neutral", stance),
    stance = gsub(".*TStance.*", "Favor", stance)
  )
# Create the new column based on ideology cluster
data <- data %>%
  mutate(
    ideology_cluster = case_when(
      ideology >= 0 & ideology <= 0.2 ~ "Far Left",
      ideology > 0.2 & ideology <= 0.4 ~ "Left Centrist",
      ideology > 0.4 & ideology <= 0.6 ~ "Centrist",
      ideology > 0.6 & ideology <= 0.8 ~ "Right Centrist",
      ideology > 0.8 & ideology <= 1 ~ "Far Right",
      TRUE ~ "Unknown"
    )
  )

# Perform the replacements on the 'sentiment' column based on values from 'sent_3_5'
data <- data %>%
  mutate(
    stance = as.factor(stance),
    sentiment = case_when(
      sentiment == "Infrastructure" ~ sent_3_5,
      sentiment == "Positve" ~ "Positive",
      sentiment == "Broadband" ~ sent_3_5,
      grepl("-> Sentiment", sentiment) ~ sent_3_5,
      TRUE ~ sentiment
    ),
    sentiment = as.factor(sentiment)
  ) %>%
  mutate(ideology_cluster = factor(
    ideology_cluster,
    levels = c(
      "Far Left",
      "Left Centrist",
      "Centrist",
      "Right Centrist",
      "Far Right"
    ),
    ordered = TRUE
  ))

# Compute Positive/Total for sentiment
sentiment_ratio <- data %>%
  group_by(username) %>%
  summarise(
    total_sentiment = n(),
    positive_count = sum(sentiment == 'Positive'),
    positive_ratio = positive_count / total_sentiment
  )

# Compute Favor/Total for stance
stance_ratio <- data %>%
  group_by(username) %>%
  summarise(
    total_stance = n(),
    favor_count = sum(stance == 'Favor'),
    favor_ratio = favor_count / total_stance
  )

# Merge the two dataframes to have both ratios for each username
final_result <-
  left_join(sentiment_ratio, stance_ratio, by = "username") %>%
  select(username, positive_ratio, favor_ratio)

# Merge final_result with the original data to include the ideology_score
ss_df <-
  left_join(
    final_result,
    data %>% select(username, ideology, ideology_cluster) %>% distinct(),
    by = "username"
  )

# View the result
print(ss_df)

# Visualizations

# Viridis colorscale
viridis_color_scale <- scale_color_viridis(option = "D")

# Create the color and shape map with actual color codes
scale_map <- list(
  color = c(
    "Far Left" = "#2166ac",
    "Left Centrist" = "#4393c3",
    "Centrist" = "#fddbc7",
    "Right Centrist" = "#d6604d",
    "Far Right" = "#b2182b"
  ),
  name = c(
    "Far Left",
    "Left Centrist",
    "Centrist",
    "Right Centrist",
    "Far Right"
  ),
  shape = c(15, 16, 17, 18, 19)
)

# Ideology
plot1 <- ggplot(
  ss_df,
  aes(x = positive_ratio, y = favor_ratio, color = ideology_cluster, shape=ideology_cluster)) +
  geom_point(size = 3) +
  labs(title = "Sentiments against Stances Per Subject",
       x = "Sentiments (Positive/Total)", y = "Stance (Favor/Against)") +
  scale_x_continuous(expand = c(0, 0), limits = c(-0.01, 1.03), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
  scale_y_continuous(expand = c(0, 0), limits = c(-0.01, 1.03), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
  scale_color_manual(
    values = scale_map$color,
    labels = scale_map$name,
    name = "Ideology Group"
  ) +
  scale_shape_manual(
    values = scale_map$shape,
    labels = scale_map$name,
    name = "Ideology Group"
  )

print(plot1)

# Ideology
plot1 <- ggplot(
  ss_df,
  aes(x = ideology, y = positive_ratio, color = ideology_cluster, shape=ideology_cluster)) +
  geom_point(size = 3) +
  labs(title = "Sentiments against Ideology",
       x = "Ideology Score", y = "Sentiments (Positive/Total)") +
  scale_x_continuous(expand = c(0, 0), limits = c(-0.01, 1.03), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
  scale_y_continuous(expand = c(0, 0), limits = c(-0.01, 1.03), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
  scale_color_manual(
    values = scale_map$color,
    labels = scale_map$name,
    name = "Ideology Group"
  ) +
  scale_shape_manual(
    values = scale_map$shape,
    labels = scale_map$name,
    name = "Ideology Group"
  )

print(plot1)


# Merge the sentiments/stance df with broadband_bios_df
final_df = merge(bb_bios_df, ss_df, by = "govtrack_id")
print(final_df)



  

  
