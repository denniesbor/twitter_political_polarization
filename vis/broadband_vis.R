library(tidyverse)
library(readr)
library(tidyr)
# install.packages("ggpubr")
library(ggpubr)
#install.packages("GGally")
#install.packages("haven")
library(GGally)
library(haven)
library(stats)


folder = dirname(rstudioapi::getSourceEditorContext()$path)
data_directory = file.path(folder, '..', 'data')
setwd(data_directory)

# read the files
data <- read.csv("congressional_district_broadband_data.csv")


data <- data[, c(
  "party",
  "ideology",
  "ideology_cluster",
  "X2014_2018_acs_educational_attainment_among_adults_25._and_median_household_income_high_school_or_greater",
  "median_income",
  "population_white_percentage",
  "percentage_adv_tech..cd.",
  "cd_urban_pop_ratio",
  "X.cd..perc_estimate_households_without_internet",
  "avgmaxaddown..cd."
)]

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


# Calculate the median of the data in the specified column
median_value <- median(data[, outlier_column])

# Replace the outliers with the median value
data[data[outlier_column] > 600, outlier_column] <- median_value

standardized_cols <- c(
  "ideology",
  "X2014_2018_acs_educational_attainment_among_adults_25._and_median_household_income_high_school_or_greater",
  "median_income",
  "population_white_percentage",
  "percentage_adv_tech..cd.",
  "cd_urban_pop_ratio",
  "X.cd..perc_estimate_households_without_internet",
  "avgmaxaddown..cd."
)

# Initial Plots

plot1 <- ggpairs(
  data,
  columns = standardized_cols,
  upper = list(continuous = wrap('cor', size = 3)),
  columnLabels = c(
    "Ideology Score",
    "Education \n(Perc + High School)",
    "Median Income",
    "White Population\n (Percentage)",
    "Broadband Tech \n(Advanced/Legacy)",
    "Urban-Rural Pop Ratio",
    "Households\nw/o Internet",
    "Avg Internet\nDownload Speed"
  ),
  mapping = ggplot2::aes(color = ideology_cluster),
  
)

plot1 <- plot1 + theme(axis.text.x = element_text(
  angle = 90,
  hjust = 1,
  size = 8
))

print(plot1)
path_out = file.path(folder, 'figures', 'corr_broadband_var_0.png')

# Display the arranged plots
ggsave(path_out,
       plot1,
       width = 12,
       height = 8)



standardized_cols <- c(
  "ideology",
  "median_income",
  "population_white_percentage",
  "cd_urban_pop_ratio",
  "X.cd..perc_estimate_households_without_internet",
  "avgmaxaddown..cd."
)

# Standardize the selected columns
#data[standardized_cols] <- scale(data[standardized_cols])


plot2 <- ggpairs(
  data,
  columns = standardized_cols,
  upper = list(continuous = wrap('cor', size = 3)),
  columnLabels = c(
    "Ideology Score",
    "Median Income",
    "White Population\n (Percentage)",
    "Urban-Rural Pop Ratio",
    "Households\nw/o Internet",
    "Avg Internet\nDownload Speed"
  ),
  mapping = aes(corSize = 8, color = ideology_cluster)
) 

plot2 <- plot2 + theme(axis.text.x = element_text(
    angle = 90,
    hjust = 1,
    size = 8
  ))

print(plot2)

path_out = file.path(folder, 'figures', 'corr_broadband_var_1.png')





# Scatter plots of individual plots






# Display the arranged plots
ggsave(path_out,
       plot2,
       width = 12,
       height = 8)
