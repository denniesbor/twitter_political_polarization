library(tidyverse)
library(readr)
library(tidyr)
# install.packages("ggpubr")
library(ggpubr)
#install.packages("GGally")
#install.packages("haven")
library(GGally)
library(haven)


folder = dirname(rstudioapi::getSourceEditorContext()$path)
data_directory = file.path(folder, '..', 'data')
setwd(data_directory)

# read the files
data <- read.csv("congressional_district_broadband_data.csv")


data <- data[, c("party",
                 "ideology",
                     "ideology_cluster",
                     "2014_2018_acs_educational_attainment_among_adults_25+_and_median_household_income_high_school_or_greater",
                     "median_income",
                     "population_white_percentage",
                     "percentage_adv_tech (cd)",
                     "cd_urban_pop_ratio",
                     "(cd) perc_estimate_households_without_internet")]

data$party <- factor(
  data$party)

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


correlation_data <- data[, c(
  "ideology",
  "2014_2018_acs_educational_attainment_among_adults_25+_and_median_household_income_high_school_or_greater",
  "median_income",
  "population_white_percentage",
  "percentage_adv_tech (cd)",
  "cd_urban_pop_ratio",
  "(cd) perc_estimate_households_without_internet"
)]

plot1 <- ggpairs(correlation_data, aes(color = ideology_cluster))


path_out = file.path(folder, 'figures', 'corr_broadband.png')

#arranged_plots <-
#  ggarrange(plot1, plot2, ncol = 2, nrow = 1)

# Display the arranged plots
ggsave(path_out,
       plot1,
       width = 12,
       height = 6)
