# install.packages("officer")
# install.packages("flextable")
library(officer)
library(flextable)
library(dplyr)

folder = dirname(rstudioapi::getSourceEditorContext()$path)
data_directory = file.path(folder, '..', 'data')
setwd(data_directory)

tweets_df <- read.csv("gpt_4_locations_sentiments.csv")

# select random tweets to be exported to table1


# Select one tweet from each category
# Filter and sample tweets
selected_tweets <- tweets_df %>%
  filter(sentiment %in% c("Positive", "Negative") & stance %in% c("Favor", "Against")) %>%
  group_by(sentiment, stance) %>%
  sample_n(10, replace = TRUE)

selected_columns <- select(selected_tweets,tweet, sentiment, stance)
selected_columns <- as.data.frame(selected_columns)

# Remove white spaces, hyperlinks, @handles, and hashtags while retaining common punctuations
selected_columns_clean <- as.data.frame(lapply(selected_columns, function(x) {
  x <- gsub("\\s+", " ", x)  # Remove extra white spaces
  x <- gsub("http[^[:space:]]*", "", x)  # Remove hyperlinks
  return(x)
}))


ft <- flextable(selected_columns_clean)

ft <- theme_vanilla(ft)
ft <- color(ft, part = "footer", color = "#666666")
ft <- set_caption(ft, caption = "Sample Tweets of Congress members with their sentiments and stances")
ft <- width(ft, j = "tweet", width = 4)
ft


path_out_tb_html = file.path(folder, 'figures', 'sample_tweets.html')
path_out_tb_docx = file.path(folder, 'figures', 'sample_tweets.docx')

save_as_html(ft, path = path_out_tb_html)
save_as_docx(ft, path = path_out_tb_docx)
