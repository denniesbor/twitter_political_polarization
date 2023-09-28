library(tidyverse)
library(ggplot2)
library(dplyr)
library(viridis)
library(ggpubr)
library(patchwork)
library(sf)
library(jsonlite)
library(tigris)
options(tigris_use_cache = TRUE)


folder = dirname(rstudioapi::getSourceEditorContext()$path)
data_directory = file.path(folder, '..', 'data')
setwd(data_directory)

# Tweets
tweets_df <- read.csv("gpt_4_locations_sentiments.csv")

# Congressional data
cd_data <- read.csv("congressional_district_demographic_data.csv")

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

# Compute Positive / Tweets Count for sentiment
sentiment_ratio <- data %>%
  group_by(username) %>%
  summarise(
    tweet_frequency = n(),
    positive_count = sum(sentiment == 'Positive'),
    positive_ratio = positive_count / tweet_frequency
  )

# Compute Favor / Tweets Count for stance
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
  select(username, positive_ratio, favor_ratio,tweet_frequency)

# Merge final_result with the original data to include the ideology_score
ss_df <-
  left_join(
    final_result,
    data %>% select(username, ideology, ideology_cluster,govtrack_id) %>% distinct(),
    by = "username"
  )

# View the result
print(ss_df)

# Visualizations

color_palette <- viridis_pal()(5)

# Color scale map
scale_map <- data.frame(
  name = c(
    "Far Left",
    "Left Centrist",
    "Centrist",
    "Right Centrist",
    "Far Right"
  )
  ,
  color = color_palette,
  shape = c(15, 16, 17, 18, 19)
)

# Create the color and shape map with actual color codes
scale_map_man <- list(
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

# Sentiments vs stances
plot1 <- ggplot(
  ss_df,
  aes(x = positive_ratio, y = favor_ratio, color = ideology_cluster, shape=ideology_cluster)) +
  geom_point(size = 2) +
  labs(title = "(A) Sentiments vs. Stances",
       x = "Sentiments (Positive / Tweets Count)", y = "Stance (Favor / Tweets Count)") +
  scale_y_continuous(expand = c(0, 0), breaks = c(0.25, 0.5, 0.75, 1)) +
  scale_x_continuous(expand = c(0, 0)) +
  scale_color_manual(
    values = scale_map$color,
    labels = scale_map$name,
    name = "Ideology Group"
  ) +
  scale_shape_manual(
    values = scale_map$shape,
    labels = scale_map$name,
    name = "Ideology Group"
  ) +
  theme(plot.title = element_text(size = 8),
        axis.text.x = element_text(size=6),
        axis.title = element_text(size = 7),
        legend.text = element_text(size = 7),
        legend.title = element_text(size=7))

print(plot1)

# Sentiments vs ideology
plot2 <- ggplot(
  ss_df,
  aes(x = ideology, y = positive_ratio, color = ideology_cluster, shape=ideology_cluster)) +
  geom_point(size = 2) +
  labs(title = "(B) Sentiments vs. Ideology",
       x = "Ideology Score", y = "Sentiments (Positive / Tweets Count)") +
  scale_y_continuous(expand = c(0, 0), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
  scale_x_continuous(expand = c(0, 0)) +
  scale_color_manual(
    values = scale_map$color,
    labels = scale_map$name,
    name = "Ideology Group"
  ) +
  scale_shape_manual(
    values = scale_map$shape,
    labels = scale_map$name,
    name = "Ideology Group"
  )+
  theme(plot.title = element_text(size = 8),
        axis.text.x = element_text(size=6),
        axis.title = element_text(size = 7),
        legend.text = element_text(size = 7),
        legend.title = element_text(size=7))

print(plot2)

# Sentimenrts vs Tweeting frequency
plot3 <- ggplot(
  ss_df,
  aes(x = tweet_frequency, y = positive_ratio, color = ideology_cluster, shape=ideology_cluster)) +
  geom_point(size = 2) +
  labs(title = "(C) Sentiments vs. Tweeting \n Frequency",
       x = "Frequency", y = "Sentiments (Positive / Tweets Count)") +
  scale_y_continuous(expand = c(0, 0), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
  scale_x_continuous(expand = c(0, 0)) +
  scale_color_manual(
    values = scale_map$color,
    labels = scale_map$name,
    name = "Ideology Group"
  ) +
  scale_shape_manual(
    values = scale_map$shape,
    labels = scale_map$name,
    name = "Ideology Group"
  )+
  theme(plot.title = element_text(size = 8),
        axis.text.x = element_text(size=6),
        axis.title = element_text(size = 7),
        legend.text = element_text(size = 7),
        legend.title = element_text(size=7))

print(plot3)

# Stances vs Tweeting frequency
plot4 <- ggplot(
  ss_df,
  aes(x = tweet_frequency, y = favor_ratio, color = ideology_cluster, shape=ideology_cluster)) +
  geom_point(size = 2) +
  labs(title = "(D) Stances vs. Tweeting \n Frequency",
       x = "Frequency", y = "Stances (Favor / Tweets Count)") +
  scale_y_continuous(expand = c(0, 0), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
  scale_x_continuous(expand = c(0, 0)) +
  scale_color_manual(
    values = scale_map$color,
    labels = scale_map$name,
    name = "Ideology Group"
  ) +
  scale_shape_manual(
    values = scale_map$shape,
    labels = scale_map$name,
    name = "Ideology Group"
  )+
  theme(plot.title = element_text(size = 8),
        axis.text.x = element_text(size=6),
        axis.title = element_text(size = 7),
        legend.text = element_text(size = 7),
        legend.title = element_text(size=7))

print(plot4)

# Merge the sentiments/stance df with broadband_bios_df
bb_bios_ss_df <- merge(bb_bios_df, ss_df, by = "govtrack_id")
final_df <- merge(bb_bios_ss_df, cd_data, by.x = c("state", "district"), by.y = c("state", "district"))

# Convert floating data into percentages
final_df$cd_urban_pop_ratio <- (final_df$cd_urban_pop_ratio * 100)
final_df$percentage_adv_tech..cd. <- final_df$percentage_adv_tech..cd. * 100

# Sentiments vs median download speeds
plot5 <- ggplot(
  final_df,
  aes(x = avgmaxaddown..cd., y = positive_ratio, color = ideology_cluster.x, shape=ideology_cluster.x)) +
  geom_point(size = 2) +
  labs(title = "(E) Sentiments vs. Congressional\n Districts Median Download Speeds",
       x = "Median Download Speed\n (Mbps)", y = "Sentiments (Positive / Tweets Count)") +
  scale_y_continuous(expand = c(0, 0), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
  scale_x_continuous(expand = c(0, 0)) +
  scale_color_manual(
    values = scale_map$color,
    labels = scale_map$name,
    name = "Ideology Group"
  ) +
  scale_shape_manual(
    values = scale_map$shape,
    labels = scale_map$name,
    name = "Ideology Group"
  )+
  theme(plot.title = element_text(size = 8),
        axis.text.x = element_text(size=6),
        axis.title = element_text(size = 7),
        legend.text = element_text(size = 7),
        legend.title = element_text(size=7))

print(plot5)

# Stances vs median donwload speeds
plot6 <- ggplot(
  final_df,
  aes(x = avgmaxaddown..cd., y = favor_ratio, color = ideology_cluster.x, shape=ideology_cluster.x)) +
  geom_point(size = 2) +
  labs(title = "(F) Stances vs. Congressional Districts \n Median Download Speeds",
       x = "Median Download Speed\n (Mbps)", y = "Stances (Favor / Tweets Count)") +
  scale_y_continuous(expand = c(0, 0), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
  scale_x_continuous(expand = c(0, 0)) +
  scale_color_manual(
    values = scale_map$color,
    labels = scale_map$name,
    name = "Ideology Group"
  ) +
  scale_shape_manual(
    values = scale_map$shape,
    labels = scale_map$name,
    name = "Ideology Group"
  )+
  theme(plot.title = element_text(size = 8),
        axis.text.x = element_text(size=6),
        axis.title = element_text(size = 7),
        legend.text = element_text(size = 7),
        legend.title = element_text(size=7))

print(plot6)

# Sentiments vs advanced broadband adoption
plot7 <- ggplot(
  final_df,
  aes(x = percentage_adv_tech..cd., y = positive_ratio, color = ideology_cluster.x, shape=ideology_cluster.x)) +
  geom_point(size = 2) +
  labs(title = "(G) Sentiments vs. Advanced \nBroadband Technology Adoption",
       x = "Broadband Technology (%)", y = "Sentiment (Positive / Tweets Count)") +
  scale_y_continuous(expand = c(0, 0), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
  scale_x_continuous(expand = c(0, 0)) +
  scale_color_manual(
    values = scale_map$color,
    labels = scale_map$name,
    name = "Ideology Group"
  ) +
  scale_shape_manual(
    values = scale_map$shape,
    labels = scale_map$name,
    name = "Ideology Group"
  )+
  theme(plot.title = element_text(size = 8),
        axis.text.x = element_text(size=6),
        axis.title = element_text(size = 7),
        legend.text = element_text(size = 7),
        legend.title = element_text(size=7))

print(plot7)

# Stances vs advanced broadband adoption
plot8 <- ggplot(
  final_df,
  aes(x = percentage_adv_tech..cd., y = favor_ratio, color = ideology_cluster.x, shape=ideology_cluster.x)) +
  geom_point(size = 2) +
  labs(title = "(H) Stances vs. Advanced Broadband \n Technology Adoption",
       x = "Broadband Technology (%)", y = "Stances (Favor / Tweets Count)") +
  scale_y_continuous(expand = c(0, 0), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
  scale_x_continuous(expand = c(0, 0), limits = c(0, 100), breaks = c(20,40,60,80,100)) +
  scale_color_manual(
    values = scale_map$color,
    labels = scale_map$name,
    name = "Ideology Group"
  ) +
  scale_shape_manual(
    values = scale_map$shape,
    labels = scale_map$name,
    name = "Ideology Group"
  )+
  theme(plot.title = element_text(size = 8),
        axis.text.x = element_text(size=6),
        axis.title = element_text(size = 7),
        legend.text = element_text(size = 7),
        legend.title = element_text(size=7))

print(plot8)

# Sentiments vs urban rural population
plot9 <- ggplot(
  final_df,
  aes(x = cd_urban_pop_ratio, y = positive_ratio, color = ideology_cluster.x, shape=ideology_cluster.x)) +
  geom_point(size = 2) +
  labs(title = "(I) Sentiments vs. Urban Population",
       x = "Urban Population (%)", y = "Sentiment (Positive / Tweets Count)") +
  scale_y_continuous(expand = c(0, 0), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
  scale_x_continuous(expand = c(0, 0), limits = c(0, 100), breaks = c(20,40,60,80,100)) +
  scale_color_manual(
    values = scale_map$color,
    labels = scale_map$name,
    name = "Ideology Group"
  ) +
  scale_shape_manual(
    values = scale_map$shape,
    labels = scale_map$name,
    name = "Ideology Group"
  )+
  theme(plot.title = element_text(size = 8),
        axis.text.x = element_text(size=6),
        axis.title = element_text(size = 7),
        legend.text = element_text(size = 7),
        legend.title = element_text(size=7))

print(plot9)

# Stances vs urban pop
plot10 <- ggplot(
  final_df,
  aes(x = cd_urban_pop_ratio, y = favor_ratio, color = ideology_cluster.x, shape=ideology_cluster.x)) +
  geom_point(size = 2) +
  labs(title = "(J) Stances vs. Urban Population",
       x = "Urban Population (%)", y = "Stances (Favor / Tweets Count)") +
  scale_y_continuous(expand = c(0, 0), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
  scale_x_continuous(expand = c(0, 0), limits = c(0, 100), breaks = c(20,40,60,80,100)) +
  scale_color_manual(
    values = scale_map$color,
    labels = scale_map$name,
    name = "Ideology Group"
  ) +
  scale_shape_manual(
    values = scale_map$shape,
    labels = scale_map$name,
    name = "Ideology Group"
  )+
  theme(plot.title = element_text(size = 8),
        axis.text.x = element_text(size=6),
        axis.title = element_text(size = 7),
        legend.text = element_text(size = 7),
        legend.title = element_text(size=7))

print(plot10)

# Sentiments vs households with internet
plot11 <- ggplot(
  final_df,
  aes(x = X.cd..perc_estimate_households_without_internet, y = positive_ratio, color = ideology_cluster.x, shape=ideology_cluster.x)) +
  geom_point(size = 2) +
  labs(title = "(K) Sentiments vs. Households \nwithout Internet",
       x = " HS Internet Adoption (%)", y = "Sentiment (Positive / Tweets Count)") +
  scale_y_continuous(expand = c(0, 0), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
  scale_x_continuous(expand = c(0, 0), limits = c(0, NA), breaks = c(20,40,60,80,100)) +
  scale_color_manual(
    values = scale_map$color,
    labels = scale_map$name,
    name = "Ideology Group"
  ) +
  scale_shape_manual(
    values = scale_map$shape,
    labels = scale_map$name,
    name = "Ideology Group"
  )+
  theme(plot.title = element_text(size = 8),
        axis.text.x = element_text(size=6),
        axis.title = element_text(size = 7),
        legend.text = element_text(size = 7),
        legend.title = element_text(size=7))

print(plot11)

# Stances vs households with internet
plot12 <- ggplot(
  final_df,
  aes(x = X.cd..perc_estimate_households_without_internet, y = favor_ratio, color = ideology_cluster.x, shape=ideology_cluster.x)) +
  geom_point(size = 2) +
  labs(title = "(L) Stances vs. Households \nwithout Internet",
       x = "HS Internet Adoption (%)", y = "Stances (Favor / Tweets Count)") +
  scale_y_continuous(expand = c(0, 0), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
  scale_x_continuous(expand = c(0, 0), limits = c(0, NA), breaks = c(20,40,60,80,100)) +
  scale_color_manual(
    values = scale_map$color,
    labels = scale_map$name,
    name = "Ideology Group"
  ) +
  scale_shape_manual(
    values = scale_map$shape,
    labels = scale_map$name,
    name = "Ideology Group"
  )+
  theme(plot.title = element_text(size = 8),
        axis.text.x = element_text(size=6),
        axis.title = element_text(size = 7),
        legend.text = element_text(size = 7),
        legend.title = element_text(size=7))

print(plot12)

# Sentiments vs Education
plot13 <- ggplot(
  final_df,
  aes(x = X2014_2018_acs_educational_attainment_among_adults_25._and_median_household_income_high_school_or_greater, y = positive_ratio, color = ideology_cluster.x, shape=ideology_cluster.x)) +
  geom_point(size = 2) +
  labs(title = "(M) Sentiments vs. High School Education",
       x = " Education (%)", y = "Sentiment (Positive / Tweets Count)") +
  scale_y_continuous(expand = c(0, 0), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
  scale_x_continuous(expand = c(0, 0), limits = c(NA, 100), breaks = c(20,40,60,80,100)) +
  scale_color_manual(
    values = scale_map$color,
    labels = scale_map$name,
    name = "Ideology Group"
  ) +
  scale_shape_manual(
    values = scale_map$shape,
    labels = scale_map$name,
    name = "Ideology Group"
  )+
  theme(plot.title = element_text(size = 8),
        axis.text.x = element_text(size=6),
        axis.title = element_text(size = 7),
        legend.text = element_text(size = 7),
        legend.title = element_text(size=7))

print(plot13)

# Stances vs Education
plot14 <- ggplot(
  final_df,
  aes(x = X2014_2018_acs_educational_attainment_among_adults_25._and_median_household_income_high_school_or_greater, y = favor_ratio, color = ideology_cluster.x, shape=ideology_cluster.x)) +
  geom_point(size = 2) +
  labs(title = "(N) Stances vs. High School Education",
       x = "Education (%)", y = "Stances (Favor / Tweets Count)") +
  scale_y_continuous(expand = c(0, 0), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
  scale_x_continuous(expand = c(0, 0), limits = c(NA, 100), breaks = c(20,40,60,80,100)) +
  scale_color_manual(
    values = scale_map$color,
    labels = scale_map$name,
    name = "Ideology Group"
  ) +
  scale_shape_manual(
    values = scale_map$shape,
    labels = scale_map$name,
    name = "Ideology Group"
  )+
  theme(plot.title = element_text(size = 8),
        axis.text.x = element_text(size=6),
        axis.title = element_text(size = 7),
        legend.text = element_text(size = 7),
        legend.title = element_text(size=7))

print(plot14)

# Sentiments vs Median Income
plot15 <- ggplot(
  final_df,
  aes(x = median_income, y = positive_ratio, color = ideology_cluster.x, shape=ideology_cluster.x)) +
  geom_point(size = 2) +
  labs(title = "(O) Sentiments vs. HS Median Income",
       x = "Income ($)", y = "Sentiment (Positive / Tweets Count)") +
  scale_y_continuous(expand = c(0, 0), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
  scale_x_continuous(expand = c(0, 0), limits = c(0, NA)) +
  scale_color_manual(
    values = scale_map$color,
    labels = scale_map$name,
    name = "Ideology Group"
  ) +
  scale_shape_manual(
    values = scale_map$shape,
    labels = scale_map$name,
    name = "Ideology Group"
  )+
  theme(plot.title = element_text(size = 8),
        axis.text.x = element_text(size=6),
        axis.title = element_text(size = 7),
        legend.text = element_text(size = 7),
        legend.title = element_text(size=7))

print(plot15)

# Stances vs median income
plot16 <- ggplot(
  final_df,
  aes(x = median_income, y = favor_ratio, color = ideology_cluster.x, shape=ideology_cluster.x)) +
  geom_point(size = 2) +
  labs(title = "(P) Stances vs. Median Income",
       x = "Income ($)", y = "Stances (Favor / Tweets Count)") +
  scale_y_continuous(expand = c(0, 0), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
  scale_x_continuous(expand = c(0, 0), limits = c(0, NA)) +
  scale_color_manual(
    values = scale_map$color,
    labels = scale_map$name,
    name = "Ideology Group"
  ) +
  scale_shape_manual(
    values = scale_map$shape,
    labels = scale_map$name,
    name = "Ideology Group"
  )+
  theme(plot.title = element_text(size = 8),
        axis.text.x = element_text(size=6),
        axis.title = element_text(size = 7),
        legend.text = element_text(size = 7),
        legend.title = element_text(size=7))

print(plot16)

# Sentiments vs White Population
plot17 <- ggplot(
  final_df,
  aes(x = population_white_percentage, y = positive_ratio, color = ideology_cluster.x, shape=ideology_cluster.x)) +
  geom_point(size = 2) +
  labs(title = "(Q) Sentiments vs. White Population",
       x = "White Population (%)", y = "Sentiment (Positive / Tweets Count)") +
  scale_y_continuous(expand = c(0, 0), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
  scale_x_continuous(expand = c(0, 0), limits = c(0, NA)) +
  scale_color_manual(
    values = scale_map$color,
    labels = scale_map$name,
    name = "Ideology Group"
  ) +
  scale_shape_manual(
    values = scale_map$shape,
    labels = scale_map$name,
    name = "Ideology Group"
  )+
  theme(plot.title = element_text(size = 8),
        axis.text.x = element_text(size=6),
        axis.title = element_text(size = 7),
        legend.text = element_text(size = 7),
        legend.title = element_text(size=7))

print(plot17)

# Stances vs White population
plot18 <- ggplot(
  final_df,
  aes(x = population_white_percentage, y = favor_ratio, color = ideology_cluster.x, shape=ideology_cluster.x)) +
  geom_point(size = 2) +
  labs(title = "(R) Stances vs. White Population",
       x = "White Population (%)", y = "Stances (Favor / Tweets Count)") +
  scale_y_continuous(expand = c(0, 0), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
  scale_x_continuous(expand = c(0, 0), limits = c(0, NA)) +
  scale_color_manual(
    values = scale_map$color,
    labels = scale_map$name,
    name = "Ideology Group"
  ) +
  scale_shape_manual(
    values = scale_map$shape,
    labels = scale_map$name,
    name = "Ideology Group"
  )+
  theme(plot.title = element_text(size = 8),
        axis.text.x = element_text(size=6),
        axis.title = element_text(size = 7),
        legend.text = element_text(size = 7),
        legend.title = element_text(size=7))

print(plot18)

# congressional member plots against sentiments
#sentiments vs ideology cluster
box_1 <-
  ggplot(final_df, aes(x = ideology_cluster.y, y = positive_ratio)) +
  geom_boxplot(aes(fill = ideology_cluster.y)) +
  labs(title = "Sentiments vs Ideology Cluster",
       x = "Ideology Cluster",
       y = "Sentiments") +
  scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
  scale_fill_manual(values = scale_map_man$color) +
  theme(
    panel.background = element_rect(fill = "grey90"),
    # Background color
    panel.grid.major = element_line(
      size = 0.5,
      linetype = 'solid',
      colour = "white"
    ),
    # Major grid lines
    panel.grid.minor = element_line(
      size = 0.25,
      linetype = 'solid',
      colour = "white"
    ),
    # Minor grid lines
    axis.line = element_line(colour = "black")  # Axis lines
  ) +
  theme(
    plot.title = element_text(size = 8),
    axis.text.x = element_text(
      size = 6,
      angle = 45,
      hjust = 1
    ),
    axis.title = element_text(size = 7),
    legend.text = element_text(size = 7),
    legend.position = "none"
  )

# Print the plot
print(box_1)

box_2 <-
  ggplot(final_df, aes(x = ideology_cluster.y, y = favor_ratio)) +
  geom_boxplot(aes(fill = ideology_cluster.y)) +
  labs(title = "Stance vs Ideology Cluster",
       x = "Ideology Cluster",
       y = "Stance (Favor/Total Count)") +
  scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
  scale_fill_manual(values = scale_map_man$color) +
  theme(
    panel.background = element_rect(fill = "grey90"),
    # Background color
    panel.grid.major = element_line(
      size = 0.5,
      linetype = 'solid',
      colour = "white"
    ),
    # Major grid lines
    panel.grid.minor = element_line(
      size = 0.25,
      linetype = 'solid',
      colour = "white"
    ),
    # Minor grid lines
    axis.line = element_line(colour = "black")  # Axis lines
  ) +
  theme(
    plot.title = element_text(size = 8),
    axis.text.x = element_text(
      size = 6,
      angle = 45,
      hjust = 1
    ),
    axis.title = element_text(size = 7),
    legend.text = element_text(size = 7),
    legend.position = "none"
  )

# Print the plot
print(box_2)

#sentiments vs is veteran
box_3 <-
  ggplot(final_df, aes(x = is_vet, y = positive_ratio)) +
  geom_boxplot(aes(fill = is_vet)) +
  labs(title = "Sentiment Distribution vs. Military Status",
       x = "Veteran Status",
       y = "Sentiments") +
  scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
  theme(
    panel.background = element_rect(fill = "grey90"),
    # Background color
    panel.grid.major = element_line(
      size = 0.5,
      linetype = 'solid',
      colour = "white"
    ),
    # Major grid lines
    panel.grid.minor = element_line(
      size = 0.25,
      linetype = 'solid',
      colour = "white"
    ),
    # Minor grid lines
    axis.line = element_line(colour = "black")  # Axis lines
  ) +
  theme(
    plot.title = element_text(size = 8),
    axis.text.x = element_text(
      size = 6,
      angle = 45,
      hjust = 1
    ),
    axis.title = element_text(size = 7),
    legend.text = element_text(size = 7),
    legend.position = "none"
  )

# Print the plot
print(box_3)

# Stance vs. Military Status
box_4 <-
  ggplot(final_df, aes(x = is_vet, y = favor_ratio)) +
  geom_boxplot(aes(fill = is_vet)) +
  labs(title = "Stance Distribution vs Military Status",
       x = "Veteran Status",
       y = "Stance (Favor/Total Count)") +
  scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
  theme(
    panel.background = element_rect(fill = "grey90"),
    # Background color
    panel.grid.major = element_line(
      size = 0.5,
      linetype = 'solid',
      colour = "white"
    ),
    # Major grid lines
    panel.grid.minor = element_line(
      size = 0.25,
      linetype = 'solid',
      colour = "white"
    ),
    # Minor grid lines
    axis.line = element_line(colour = "black")  # Axis lines
  ) +
  theme(
    plot.title = element_text(size = 8),
    axis.text.x = element_text(
      size = 6,
      angle = 45,
      hjust = 1
    ),
    axis.title = element_text(size = 7),
    legend.text = element_text(size = 7),
    legend.position = "none"
  )

# Print the plot
print(box_4)

#sentiments vs ethnicity
box_5 <-
  ggplot(final_df, aes(x = race_ethnicity, y = positive_ratio)) +
  geom_boxplot(aes(fill = race_ethnicity)) +
  labs(title = "Sentiment Distribution vs. Ethnicity",
       x = "Ethnicity",
       y = "Sentiments") +
  scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
  theme(
    panel.background = element_rect(fill = "grey90"),
    # Background color
    panel.grid.major = element_line(
      size = 0.5,
      linetype = 'solid',
      colour = "white"
    ),
    # Major grid lines
    panel.grid.minor = element_line(
      size = 0.25,
      linetype = 'solid',
      colour = "white"
    ),
    # Minor grid lines
    axis.line = element_line(colour = "black")  # Axis lines
  ) +
  theme(
    plot.title = element_text(size = 8),
    axis.text.x = element_text(
      size = 6,
      angle = 45,
      hjust = 1
    ),
    axis.title = element_text(size = 7),
    legend.text = element_text(size = 7),
    legend.position = "none"
  )

# Print the plot
print(box_5)

# Stance vs. Ethnicity
box_6 <-
  ggplot(final_df, aes(x = race_ethnicity, y = favor_ratio)) +
  geom_boxplot(aes(fill = race_ethnicity)) +
  labs(title = "Stance Distribution vs Ethnicity",
       x = "Ethnicity",
       y = "Stance (Favor/Total Count)") +
  scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
  theme(
    panel.background = element_rect(fill = "grey90"),
    # Background color
    panel.grid.major = element_line(
      size = 0.5,
      linetype = 'solid',
      colour = "white"
    ),
    # Major grid lines
    panel.grid.minor = element_line(
      size = 0.25,
      linetype = 'solid',
      colour = "white"
    ),
    # Minor grid lines
    axis.line = element_line(colour = "black")  # Axis lines
  ) +
  theme(
    plot.title = element_text(size = 8),
    axis.text.x = element_text(
      size = 6,
      angle = 45,
      hjust = 1
    ),
    axis.title = element_text(size = 7),
    legend.text = element_text(size = 7),
    legend.position = "none"
  )

# Print the plot
print(box_6)

#sentiments vs religion
box_7 <-
  ggplot(final_df, aes(x = christian, y = positive_ratio)) +
  geom_boxplot(aes(fill = christian)) +
  labs(title = "Sentiment Distribution vs. Christianity Status",
       x = "Christian",
       y = "Sentiments") +
  scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
  theme(
    panel.background = element_rect(fill = "grey90"),
    # Background color
    panel.grid.major = element_line(
      size = 0.5,
      linetype = 'solid',
      colour = "white"
    ),
    # Major grid lines
    panel.grid.minor = element_line(
      size = 0.25,
      linetype = 'solid',
      colour = "white"
    ),
    # Minor grid lines
    axis.line = element_line(colour = "black")  # Axis lines
  ) +
  theme(
    plot.title = element_text(size = 8),
    axis.text.x = element_text(
      size = 6,
      angle = 45,
      hjust = 1
    ),
    axis.title = element_text(size = 7),
    legend.text = element_text(size = 7),
    legend.position = "none"
  )

# Print the plot
print(box_7)

# Stance vs. Christianity
box_8 <-
  ggplot(final_df, aes(x = christian, y = favor_ratio)) +
  geom_boxplot(aes(fill = christian)) +
  labs(title = "Stance Distribution vs Christianity Status",
       x = "Christian",
       y = "Stance (Favor/Total Count)") +
  scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
  theme(
    panel.background = element_rect(fill = "grey90"),
    # Background color
    panel.grid.major = element_line(
      size = 0.5,
      linetype = 'solid',
      colour = "white"
    ),
    # Major grid lines
    panel.grid.minor = element_line(
      size = 0.25,
      linetype = 'solid',
      colour = "white"
    ),
    # Minor grid lines
    axis.line = element_line(colour = "black")  # Axis lines
  ) +
  theme(
    plot.title = element_text(size = 8),
    axis.text.x = element_text(
      size = 6,
      angle = 45,
      hjust = 1
    ),
    axis.title = element_text(size = 7),
    legend.text = element_text(size = 7),
    legend.position = "none"
  )

# Print the plot
print(box_8)

# Sentiments vs age of a congress member
plot19 <- ggplot(
  final_df,
  aes(x = age, y = positive_ratio, color = ideology_cluster.y, shape=ideology_cluster.y)) +
  geom_point(size = 2) +
  labs(title = "(B) Sentiments vs. Age",
       x = "Age of a Member", y = "Sentiments (Positive / Tweets Count)") +
  scale_y_continuous(expand = c(0, 0), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
  scale_x_continuous(expand = c(0, 0)) +
  scale_color_manual(
    values = scale_map$color,
    labels = scale_map$name,
    name = "Ideology Group"
  ) +
  scale_shape_manual(
    values = scale_map$shape,
    labels = scale_map$name,
    name = "Ideology Group"
  )+
  theme(plot.title = element_text(size = 8),
        axis.text.x = element_text(size=6),
        axis.title = element_text(size = 7),
        legend.text = element_text(size = 7),
        legend.title = element_text(size=7))

print(plot19)

# Sentiments vs age of a congress member
plot20 <- ggplot(
  final_df,
  aes(x = age, y = favor_ratio, color = ideology_cluster.y, shape=ideology_cluster.y)) +
  geom_point(size = 2) +
  labs(title = "(B) Stance vs. Age",
       x = "Age of a Member", y = "Stance (Favor / Tweets Count)") +
  scale_y_continuous(expand = c(0, 0), breaks = c(0, 0.25, 0.5, 0.75, 1)) +
  scale_x_continuous(expand = c(0, 0)) +
  scale_color_manual(
    values = scale_map$color,
    labels = scale_map$name,
    name = "Ideology Group"
  ) +
  scale_shape_manual(
    values = scale_map$shape,
    labels = scale_map$name,
    name = "Ideology Group"
  )+
  theme(plot.title = element_text(size = 8),
        axis.text.x = element_text(size=6),
        axis.title = element_text(size = 7),
        legend.text = element_text(size = 7),
        legend.title = element_text(size=7))

print(plot20)

# Save the plots
arranged_plots_1 <-
  ggarrange(
    plot1,
    plot2,
    plot3,
    plot4,
    plot5,
    plot6,
    plot7,
    plot8,
    ncol = 2,
    nrow = 4,
    common.legend = TRUE,
    legend = "bottom"
  )

print(arranged_plots_1)

# Save the plots
arranged_plots_2 <-
  ggarrange(
    plot9,
    plot10,
    plot11,
    plot12,
    plot13,
    plot14,
    plot15,
    plot16,
    plot17,
    plot18,
    ncol = 2,
    nrow = 5,
    common.legend = TRUE,
    legend = "bottom"
  )

print(arranged_plots_2)

# Member related plots
arranged_plots_3 <-
  ggarrange(
    plot19,
    plot20,
    box_1,
    box_2,
    box_3,
    box_4,
    box_5,
    box_6,
    box_7,
    box_8,
    ncol = 2,
    nrow = 5,
    common.legend = TRUE,
    legend = "bottom"
  )


print(arranged_plots_3)

path_out_1 = file.path(folder, 'figures', 'sentiment_stances_demo.png')
path_out_2 = file.path(folder, 'figures', 'sentiment_stances_demo.png')
path_out_3 = file.path(folder, 'figures', 'sentiment_stances_background.png')

ggsave(path_out_1,
       arranged_plots_1,
       width = 8.27,
       height = 11.69)

ggsave(path_out_2,
       arranged_plots_2,
       width = 8.27,
       height = 11.69)

ggsave(path_out_3,
       arranged_plots_3,
       width = 8.27,
       height = 11.69)

while (dev.cur() > 1) {
  dev.off()
}

# Choropleth the sentiments vs. stances
# Get the congressional districts
congressional_districts <-
  tigris::congressional_districts(cb = TRUE,
                                  year = 2019,
                                  resolution = "20m")
shape_data <- tigris::shift_geometry(congressional_districts)

# JSON mapper
json_file <- fromJSON("json_mapper.json")

# Use mutate to create a new column 'state_code' by applying a function to each value in the 'state' column
final_df <- final_df %>%
  mutate(state_code = sapply(state, function(state)
    json_file$state_code[[state]]))

# Create the geoid column
final_df$geoid <-
  paste0(sprintf("%02d", as.numeric(final_df$state_code)), sprintf("%02d", as.numeric(final_df$district)))

merged_data <- shape_data %>%
  left_join(final_df, by = c("GEOID" = "geoid"))


# Plot 1: Choropleth Urban Population
plot8 <- ggplot(merged_data) +
  geom_sf(aes(fill = positive_ratio),
          linewidth = 0.0001,
          color = "white") +
  theme_void() +
  scale_fill_viridis_c(trans = "sqrt",
                       direction = -1,
                       name = "Sentiments (Positive/Frequency)") +
  labs(title = "(A) Congressional District Members Sentiment Distribution") +
  theme(
    text = element_text(color = "#22211d"),
    plot.margin = margin(0, 0, 0, 0, "cm"),
    plot.background = element_rect(fill = "#f5f5f2", color = NA),
    panel.background = element_rect(fill = "#f5f5f2", color = NA),
    legend.background = element_rect(fill = "#f5f5f2", color = NA),
    plot.title = element_text(
      size = 10,
      hjust = 0.01,
      margin = margin(
        b = -0.1,
        t = 0.4,
        l = 2,
        unit = "cm"
      )
    ),
    legend.position = "bottom",
    legend.text = element_text(size = 9),
    legend.key.height = unit(3, "mm"),
    legend.key.width = unit(0.05, "npc"),
    # Adjust size and color here
    legend.title = element_text(size = 10)  # Adjusting legend title size
  ) +
  guides(fill = guide_colourbar(title.position = 'top')) +
  coord_sf()

print(plot8)

# Plot 1: Choropleth Urban Population
plot9 <- ggplot(merged_data) +
  geom_sf(aes(fill = tweet_frequency),
          linewidth = 0.0001,
          color = "white") +
  theme_void() +
  scale_fill_viridis_c(trans = "sqrt",
                       direction = -1,
                       name = "Count of Tweets") +
  labs(title = "(B) Congressional District Members Tweeting Frequency") +
  theme(
    text = element_text(color = "#22211d"),
    plot.margin = margin(0, 0, 0, 0, "cm"),
    plot.background = element_rect(fill = "#f5f5f2", color = NA),
    panel.background = element_rect(fill = "#f5f5f2", color = NA),
    legend.background = element_rect(fill = "#f5f5f2", color = NA),
    plot.title = element_text(
      size = 10,
      hjust = 0.01,
      margin = margin(
        b = -0.1,
        t = 0.4,
        l = 2,
        unit = "cm"
      )
    ),
    legend.position = "bottom",
    legend.text = element_text(size = 9),
    legend.key.height = unit(3, "mm"),
    legend.key.width = unit(0.05, "npc"),
    # Adjust size and color here
    legend.title = element_text(size = 10)  # Adjusting legend title size
  ) +
  guides(fill = guide_colourbar(title.position = 'top')) +
  coord_sf()

print(plot9)

# Combine the plots using patchwork
combined_plot_frequency <- plot8 + plot9

combined_plot_frequency <-
  combined_plot_frequency + plot_layout(ncol = 2, nrow = 1) &
  theme(plot.margin = unit(c(0, 0, 0, 0), "cm"))

print(combined_plot_frequency)

path_out = file.path(folder, 'figures', 'sentiment_frequency_chor.png')
ggsave(path_out,
       combined_plot_frequency,
       width = 8.27,
       height = 6)
  

  
