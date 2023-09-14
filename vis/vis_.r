library(tidyverse)
library(readr)
library(tidyr)
# install.packages("ggpubr")
# install.packages("viridis")
library(viridis)
library(ggpubr)

folder = dirname(rstudioapi::getSourceEditorContext()$path)
data_directory = file.path(folder, '..', 'data')
setwd(data_directory)

# read the congressional level data

data <- read.csv("congressional_district_broadband_data.csv")

# Viridis colorscale
viridis_color_scale <- scale_color_viridis(option = "D")

# data_vars <- data[, c(
#   "party",
#   "ideology",
#   "ideology_cluster",
#   "X2014_2018_acs_educational_attainment_among_adults_25._and_median_household_income_high_school_or_greater",
#   "median_income",
#   "population_white_percentage",
#   "percentage_adv_tech..cd.",
#   "cd_urban_pop_ratio",
#   "X.cd..perc_estimate_households_without_internet",
#   "avgmaxaddown..cd."
# )]

data$party <- factor(data$party,
                     levels = c("R", "D", "O"))

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

# data$sentiment <- factor(
#   data$cohere,
#   levels = c("negative",
#              "neutral",
#              "positive"),
#   labels = c("Negative",
#              "Neutral",
#              "Positive")
# )


median_value <- median(data$`avgmaxaddown..cd.`)

#remove outliers from the avg broadband speed (Minnessota data)
outlier_threshold <- 600

# Replace outliers with the median
data$`avgmaxaddown..cd.`[data$`avgmaxaddown..cd.` > outlier_threshold] <- median_value

# Ideology vs other features plot

# Plot 1: Ideology Score vs. Education (%)
plot1 <- ggplot(data,
                aes(
                  x = ideology,
                  y = X2014_2018_acs_educational_attainment_among_adults_25._and_median_household_income_high_school_or_greater,
                  color = ideology_cluster,
                )) +
  geom_point(aes(size = avgmaxaddown..cd.)) +
  labs(title = "(A) Ideology score vs. population (25+) with \nhighschool education (%)",
       x = "Ideology score", y = "Education (%)") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_size(name = "Download Speed", guide = "none") +
  theme(axis.title.x = element_blank())  # Remove x-axis label


# Plot 2: Ideology Score vs. Median Income
plot2 <- ggplot(data,
                aes(
                  x = ideology,
                  y = median_income,
                  color = ideology_cluster,
                )) +
  geom_point(aes(size = avgmaxaddown..cd.)) +
  labs(title = "(B) Ideology score vs. median income",
       x = "Ideology score", y = "Median Income") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_size(name = "Download Speed", guide = "none") +
  theme(axis.title.x = element_blank())  # Remove x-axis label

# Plot 3: Ideology Score vs. White Population Percentage
plot3 <- ggplot(data,
                aes(
                  x = ideology,
                  y = population_white_percentage,
                  color = ideology_cluster,
                )) +
  geom_point(aes(size = avgmaxaddown..cd.)) +
  labs(title = "(C) Ideology score vs. white population \n (%)",
       x = "Ideology score", y = "White Population (%)") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_size(name = "Download Speed", guide = "none") +
  theme(axis.title.x = element_blank())  # Remove x-axis label


# Plot 4: Ideology Score vs. Urban-Rural Population Ratio
plot4 <- ggplot(data,
                aes(
                  x = ideology,
                  y = cd_urban_pop_ratio,
                  color = ideology_cluster,
                )) +
  geom_point(aes(size = avgmaxaddown..cd.)) +
  labs(title = "(D) Ideology score vs. urban-rural \n population ratio",
       x = "Ideology score", y = "Urban-Rural Population Ratio") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_size(name = "Download Speed", guide = "none") 

# Plot 5: Ideology Score vs. Households without Internet
plot5 <- ggplot(data,
                aes(
                  x = ideology,
                  y = X.cd..perc_estimate_households_without_internet,
                  color = ideology_cluster,
                )) +
  geom_point(aes(size = avgmaxaddown..cd.)) +
  labs(title = "(E) Ideology score vs. households \n without internet",
       x = "Ideology score", y = "Households without Internet (%)") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_size(name = "Download Speed", guide = "none")


# Plot 6: Ideology Score vs. Avg Internet Download Speed
plot6 <- ggplot(data,
                aes(
                  x = ideology,
                  y = avgmaxaddown..cd.,
                  color = ideology_cluster,
                )) +
  geom_point(aes(size=2)) +
  labs(title = "(F) Ideology score vs. internet \n download speed (avg)",
       x = "Ideology score", y = "Avg Internet Download Speed") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_size(guide = "none")


arranged_plots <-
  ggarrange(plot1, plot2, plot3, plot4, plot5, plot6, ncol = 3, nrow = 2, common.legend = TRUE, legend="bottom") +
  guides(color = guide_legend(override.aes = list(size = 10)))

print(arranged_plots)

folder_out = file.path(folder, 'figures')
dir.create(folder_out, showWarnings = FALSE)

path_out = file.path(folder, 'figures', 'ideology_features.png')

ggsave(path_out,
       arranged_plots,
       width = 12,
       height = 8)