library(tidyverse)
library(ggplot2)
library(dplyr)
library(tm)
library(wordcloud2) 
library(ggwordcloud)
library(patchwork)
library(tidytext)
library(sf)
library(tigris)
options(tigris_use_cache = TRUE)
library(tidycensus)
library(cowplot)
library(viridis)
library(ggpubr)
library(tidytext)
library(png)
library(htmlwidgets)
library(webshot)
webshot::install_phantomjs()




folder = dirname(rstudioapi::getSourceEditorContext()$path)
data_directory = file.path(folder, '..', 'data')
setwd(data_directory)

tweets <- read.csv("gpt_4_locations_sentiments.csv")
govtrack_house <- read.csv("govtrack-stats-2020-house-ideology.csv")
govtrack_senate <- read.csv("govtrack-stats-2020-senate-ideology.csv")
govtrack_df <- bind_rows(govtrack_house, govtrack_senate)

data <- merge(tweets, govtrack_df, by.x = "govtrack_id", by.y = "id")

# Replace the stance columns
data <- data %>% 
  mutate(stance = gsub("Together", "Neutral", stance),
         stance = gsub(".*TStance.*", "Favor", stance))
# Create the new column based on ideology cluster
data <- data %>%
  mutate(ideology_cluster = case_when(
    ideology >= 0 & ideology <= 0.2 ~ "Far Left",
    ideology > 0.2 & ideology <= 0.4 ~ "Left Centrist",
    ideology > 0.4 & ideology <= 0.6 ~ "Centrist",
    ideology > 0.6 & ideology <= 0.8 ~ "Right Centrist",
    ideology > 0.8 & ideology <= 1 ~ "Far Right",
    TRUE ~ "Unknown"
  ))

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
  )


generate_wordcloud <- function(tweets, title, max_words = 100) {
  # Convert data to a vector
  # tweets <- as.vector(data[[column_name]])
  tweets$tweet <- gsub("\\b\\w*’\\w*\\b", "", tweets$tweet)
  tweets <- tweets %>%
    mutate(tweet = str_replace_all(tweet, "[^a-zA-Z\\s]", ""))
  
  tweet_corpus <- Corpus(VectorSource(tweets$tweet))
  # Preprocessing
  tweet_corpus <- tm_map(tweet_corpus, content_transformer(tolower))
  tweet_corpus <- tm_map(tweet_corpus, removeNumbers)
  tweet_corpus <- tm_map(tweet_corpus, removeWords, stopwords("en"))
  tweet_corpus <- tm_map(tweet_corpus, removePunctuation)
  tweet_corpus <- tm_map(tweet_corpus, stripWhitespace)
  
  # Create a document-term matrix
  dtm <- DocumentTermMatrix(tweet_corpus)
  
  # Generate the data frame for word frequency
  word_frequency <- sort(colSums(as.matrix(dtm)), decreasing = TRUE)
  df_frequency <- data.frame(word = names(word_frequency), freq = word_frequency)

  # Exclude specific words from the word cloud
  exclude_words <- c("broadband")
  df_frequency <- df_frequency[!(df_frequency$word %in% exclude_words),]
  
  df_f <- head(df_frequency, max_words)  # This will keep only the top 10
  df_f <- df_f %>%
    mutate(angle = 90 * sample(c(0, 1), n(), replace = TRUE, prob = c(60, 40)))
  
  
  png(filename = "temp_wc.png")
  wc1 <- wordcloud2(df_f, 
                    backgroundColor = "#f5f5f2", 
                    size = 1.25)
  
  path = file.path(folder, '..', 'data', 'temp.html')
  saveWidget(wc1, path, selfcontained = FALSE)
  
  webshot(path,"wc.png", delay = 5)

  wc_img <- readPNG("wc.png")
  wc_raster <- grid::rasterGrob(wc_img, interpolate = TRUE)

  # Add the raster to a ggplot object
  wc <- ggplot() +
    annotation_custom(grob = wc_raster, xmin = 0, xmax = 1, ymin = 0, ymax = 1) +
    theme_void() +
    theme(plot.margin = margin(0, 0, 0, 0),
          plot.background = element_rect(fill = '#f5f5f2', color = NA)) +
    labs(title = title)

  
  return(wc)
}

# Word clouds
wc_all <- generate_wordcloud(data, "(A) All Ideologies")

print(wc_all)

# Filter data by ideology cluster and then generate word clouds
data_far_left <- subset(data, ideology_cluster == "Far Left")
data_left_centrist <- subset(data, ideology_cluster == "Left Centrist")
data_centrist <- subset(data, ideology_cluster == "Centrist")
data_right_centrist <- subset(data, ideology_cluster == "Right Centrist")
data_far_right <- subset(data, ideology_cluster == "Far Right")

# Word clouds
wc_all <- generate_wordcloud(data, "(A) All Ideologies")
wc_far_left <- generate_wordcloud(data_far_left, "(B) Far Left")
wc_left_centrist <- generate_wordcloud(data_left_centrist, "(C) Left Centrist")
wc_centrist <- generate_wordcloud(data_centrist, "(D) Centrist")
wc_right_centrist <- generate_wordcloud(data_right_centrist, "(E) Right Centrist")
wc_far_right <- generate_wordcloud(data_far_right, "(F) Far Right")


# Combine the plots
# Use ggarrange() to arrange your plots
ggarrange_plot <- ggarrange(wc_all, wc_far_left, 
                           wc_left_centrist, wc_centrist, 
                           wc_right_centrist, wc_far_right, 
                           ncol = 2, nrow = 3)


print(wc_all)


path_out = file.path(folder, 'figures', 'wclouds_ideology.png')
ggsave(path_out,
       ggarrange_plot,

              height = 10,
       width = 8, dpi = 300)

dev.off ()

# Filter data by stance
data_favor <- subset(data, stance == "Favor")
data_neutral <- subset(data, stance == "Neutral")
data_against <- subset(data, stance == "Against")

# Word clouds for all ideologies by stance
wc_all_favor <- generate_wordcloud(data_favor, "(A) All Ideologies - Favor")
wc_all_neutral <- generate_wordcloud(data_neutral, "(A) All Ideologies - Neutral")
wc_all_against <- generate_wordcloud(data_against, "(A) All Ideologies - Against")

# Filter data by ideology cluster and generate word clouds for each cluster
wc_far_left_favor <- generate_wordcloud(subset(data_favor, ideology_cluster == "Far Left"), "(B) Far Left - Favor")
wc_left_centrist_favor <- generate_wordcloud(subset(data_favor, ideology_cluster == "Left Centrist"), "(C) Left Centrist - Favor")
wc_centrist_favor <- generate_wordcloud(subset(data_favor, ideology_cluster == "Centrist"), "(D) Centrist - Favor")
wc_right_centrist_favor <- generate_wordcloud(subset(data_favor, ideology_cluster == "Right Centrist"), "(E) Right Centrist - Favor")
wc_far_right_favor <- generate_wordcloud(subset(data_favor, ideology_cluster == "Far Right"), "(F) Far Right - Favor")

wc_far_left_neutral <- generate_wordcloud(subset(data_neutral, ideology_cluster == "Far Left"), "(B) Far Left - Neutral")
wc_left_centrist_neutral <- generate_wordcloud(subset(data_neutral, ideology_cluster == "Left Centrist"), "(C) Left Centrist - Neutral")
wc_centrist_neutral <- generate_wordcloud(subset(data_neutral, ideology_cluster == "Centrist"), "(D) Centrist - Neutral")
wc_right_centrist_neutral <- generate_wordcloud(subset(data_neutral, ideology_cluster == "Right Centrist"), "(E) Right Centrist - Neutral")
wc_far_right_neutral <- generate_wordcloud(subset(data_neutral, ideology_cluster == "Far Right"), "(F) Far Right - Neutral")

wc_far_left_against <- generate_wordcloud(subset(data_against, ideology_cluster == "Far Left"), "(B) Far Left - Against")
wc_left_centrist_against <- generate_wordcloud(subset(data_against, ideology_cluster == "Left Centrist"), "(C) Left Centrist - Against")
wc_centrist_against <- generate_wordcloud(subset(data_against, ideology_cluster == "Centrist"), "(D) Centrist - Against")
wc_right_centrist_against <- generate_wordcloud(subset(data_against, ideology_cluster == "Right Centrist"), "(E) Right Centrist - Against")
wc_far_right_against <- generate_wordcloud(subset(data_against, ideology_cluster == "Far Right"), "(F) Far Right - Against")

# For "Favor" stance
ggarrange_favor <- ggarrange(wc_all_favor, wc_far_left_favor, 
                             wc_left_centrist_favor, wc_centrist_favor, 
                             wc_right_centrist_favor, wc_far_right_favor, 
                             ncol = 2, nrow = 3)

# For "Neutral" stance
ggarrange_neutral <- ggarrange(wc_all_neutral, wc_far_left_neutral, 
                               wc_left_centrist_neutral, wc_centrist_neutral, 
                               wc_right_centrist_neutral, wc_far_right_neutral, 
                               ncol = 2, nrow = 3)

# For "Against" stance
ggarrange_against <- ggarrange(wc_all_against, wc_far_left_against, 
                               wc_left_centrist_against, wc_centrist_against, 
                               wc_right_centrist_against, wc_far_right_against, 
                               ncol = 2, nrow = 3)


# Save "Favor" plot
path_out_favor = file.path(folder, 'figures', 'wclouds_ideology_favor.png')
ggsave(path_out_favor, ggarrange_favor, height = 10, width = 8, dpi = 300)
while(dev.cur() > 1) dev.off()
# Save "Neutral" plot
path_out_neutral = file.path(folder, 'figures', 'wclouds_ideology_neutral.png')
ggsave(path_out_neutral, ggarrange_neutral, height = 10, width = 8, dpi = 300)
while(dev.cur() > 1) dev.off()
# Save "Against" plot
path_out_against = file.path(folder, 'figures', 'wclouds_ideology_against.png')
ggsave(path_out_against, ggarrange_against, height = 10, width = 8, dpi = 300)
while(dev.cur() > 1) dev.off()

# Sentiment all ideologies
data_positive <- subset(data, sentiment == "Positive")
data_negative <- subset(data, sentiment == "Negative")

# Word clouds for all ideologies by sentiment
wc_all_positive <- generate_wordcloud(data_positive, "(A) All Ideologies - Positive")
wc_all_negative <- generate_wordcloud(data_negative, "(A) All Ideologies - Negative")

# Filter data by ideology cluster and generate word clouds
wc_far_left_positive <- generate_wordcloud(subset(data_positive, ideology_cluster == "Far Left"), "(B) Far Left - Positive")
wc_left_centrist_positive <- generate_wordcloud(subset(data_positive, ideology_cluster == "Left Centrist"), "(C) Left Centrist - Positive")
wc_centrist_positive <- generate_wordcloud(subset(data_positive, ideology_cluster == "Centrist"), "(D) Centrist - Positive")
wc_right_centrist_positive <- generate_wordcloud(subset(data_positive, ideology_cluster == "Right Centrist"), "(E) Right Centrist - Positive")
wc_far_right_positive <- generate_wordcloud(subset(data_positive, ideology_cluster == "Far Right"), "(F) Far Right - Positive")

wc_far_left_negative <- generate_wordcloud(subset(data_negative, ideology_cluster == "Far Left"), "(B) Far Left - Negative")
wc_left_centrist_negative <- generate_wordcloud(subset(data_negative, ideology_cluster == "Left Centrist"), "(C) Left Centrist - Negative")
wc_centrist_negative <- generate_wordcloud(subset(data_negative, ideology_cluster == "Centrist"), "(D) Centrist - Negative")
wc_right_centrist_negative <- generate_wordcloud(subset(data_negative, ideology_cluster == "Right Centrist"), "(E) Right Centrist - Negative")
wc_far_right_negative <- generate_wordcloud(subset(data_negative, ideology_cluster == "Far Right"), "(F) Far Right - Negative")


ggarrange_positive <- ggarrange(wc_all_positive, wc_far_left_positive, 
                                wc_left_centrist_positive, wc_centrist_positive, 
                                wc_right_centrist_positive, wc_far_right_positive, 
                                ncol = 2, nrow = 3)

ggarrange_negative <- ggarrange(wc_all_negative, wc_far_left_negative, 
                                wc_left_centrist_negative, wc_centrist_negative, 
                                wc_right_centrist_negative, wc_far_right_negative, 
                                ncol = 2, nrow = 3)

# Save "Positive" plot
path_out_positive = file.path(folder, 'figures', 'wclouds_ideology_positive.png')
ggsave(path_out_positive, ggarrange_positive, height = 10, width = 8, dpi = 300)

# Save "Negative" plot
path_out_negative = file.path(folder, 'figures', 'wclouds_ideology_negative.png')
ggsave(path_out_negative, ggarrange_negative, height = 10, width = 8, dpi = 300)
while(dev.cur() > 1) dev.off()

# Named entities in the dataset

filtered_data <- subset(data, location_NER != "none")

filtered_data$location_NER <- gsub("\\b\\w*’\\w*\\b", "", filtered_data$location_NER)
named_entities <- filtered_data %>%
  mutate(location_NER = str_replace_all(location_NER, "[^a-zA-Z\\s]", ""))

ner_corpus <- Corpus(VectorSource(named_entities$location_NER))
# Preprocessing
ner_corpus <- tm_map(ner_corpus, content_transformer(tolower))
ner_corpus <- tm_map(ner_corpus, removeNumbers)
ner_corpus <- tm_map(ner_corpus, removeWords, stopwords("en"))
ner_corpus <- tm_map(ner_corpus, removePunctuation)
ner_corpus <- tm_map(ner_corpus, stripWhitespace)

# Create a document-term matrix
dtm <- DocumentTermMatrix(ner_corpus)

# Generate the data frame for word frequency
word_frequency <- sort(colSums(as.matrix(dtm)), decreasing = TRUE)
df_frequency <- data.frame(word = names(word_frequency), freq = word_frequency)

# Exclude specific words from the word cloud
exclude_words <- c("broadband")
df_frequency <- df_frequency[!(df_frequency$word %in% exclude_words),]

df_f <- head(df_frequency, 100)  # This will keep only the top 10
df_f <- df_f %>%
  mutate(angle = 90 * sample(c(0, 1), n(), replace = TRUE, prob = c(60, 40)))


png(filename = "temp_wc.png")
wc1 <- wordcloud2(df_f, 
                  backgroundColor = "#f5f5f2", 
                  size = 2)

path = file.path(folder, '..', 'data', 'temp.html')
saveWidget(wc1, path, selfcontained = FALSE)

webshot(path,"ner.png", delay = 5)

wc_img <- readPNG("ner.png")
wc_raster <- grid::rasterGrob(wc_img, interpolate = TRUE)

# Add the raster to a ggplot object
wc <- ggplot() +
  annotation_custom(grob = wc_raster, xmin = 0, xmax = 1, ymin = 0, ymax = 1) +
  theme_void() +
  theme(plot.margin = margin(0, 0, 0, 0),
        plot.background = element_rect(fill = '#f5f5f2', color = NA)) +
  labs(title = "Named Entities")

# Save ner plot
ner_plot = file.path(folder, 'figures', 'named_entities.png')
ggsave(ner_plot, wc, height = 4, width = 6, dpi = 300)

