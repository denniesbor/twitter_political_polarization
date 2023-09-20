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
#   "percentage_adv_tech..cd...cd.",
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

# Reorder ideology_cluster from left -> right
data$border <- factor(
  data$border,
  
  levels = c("no",
             "canada_border",
             "mexico_border"),
  labels = c("No",
             "Ca",
             "Mx")
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
data$`avgmaxaddown..cd.`[data$`avgmaxaddown..cd.` > outlier_threshold] <-
  median_value


data$cd_urban_pop_ratio <- (data$cd_urban_pop_ratio * 100)
data$percentage_adv_tech..cd. <- data$percentage_adv_tech..cd. * 100

# Define viridis ccolor palette
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
  shape = c(16, 17, 18, 19, 20)
)

# Ideology vs Other Features Plot
# Plot 1: Ideology Score vs. Education
plot1 <- ggplot(
  data,
  aes(
    x = ideology,
    y = X2014_2018_acs_educational_attainment_among_adults_25._and_median_household_income_high_school_or_greater,
    color = ideology_cluster,
    shape = ideology_cluster
  )
) +
  geom_point(size = 2) +
  labs(title = "(A) High School Education for\nAdults (25+) Against\nPolitical Ideology",
       x = "Ideology Score", y = "Education (%)") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology Group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology Group")
print(plot1)

# Plot 2: Ideology Score vs. Median Income
plot2 <- ggplot(
  data,
  aes(
    x = ideology,
    y = median_income,
    color = ideology_cluster,
    shape = ideology_cluster
  )
) +
  geom_point(size = 2) +
  labs(title = "(B) Median Income \nvs. Political Ideology",
       x = "Ideology Score", y = "Median Income ($)") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology Group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology Group")

# Plot 3: Ideology Score vs. White Population Percentage
plot3 <- ggplot(
  data,
  aes(
    x = ideology,
    y = population_white_percentage,
    color = ideology_cluster,
    shape = ideology_cluster
  )
) +
  geom_point(size = 2) +
  labs(title = "(C) White Population \nvs. Political Ideology",
       x = "Ideology Score", y = "White Population (%)") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology Group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology Group")

# Plot 4: Ideology Score vs. Urban Population Ratio
plot4 <- ggplot(
  data,
  aes(
    x = ideology,
    y = cd_urban_pop_ratio,
    color = ideology_cluster,
    shape = ideology_cluster
  )
) +
  geom_point(size = 2) +
  labs(title = "(D) Urban-Rural Population Ratio \nvs. Ideology",
       x = "Ideology Score", y = "Urban Population Ratio (%)") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology Group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology Group")

# Plot 5: Ideology Score vs. Households without Internet
plot5 <- ggplot(
  data,
  aes(
    x = ideology,
    y = X.cd..perc_estimate_households_without_internet,
    color = ideology_cluster,
    shape = ideology_cluster
  )
) +
  geom_point(size = 2) +
  labs(title = "(E) Households Without Internet \nvs. Ideology",
       x = "Ideology Score", y = "Households Without Internet (%)") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology Group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology Group")

# Plot 6: Ideology Score vs. Avg Internet Download Speed
plot6 <- ggplot(
  data,
  aes(
    x = ideology,
    y = avgmaxaddown..cd.,
    color = ideology_cluster,
    shape = ideology_cluster
  )
) +
  geom_point(size = 2) +
  labs(title = "(F) Internet Download Speed \nvs. Ideology",
       x = "Ideology Score", y = "Avg Internet Download Speed (Mbps)") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology Group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology Group")

arranged_plots_ideology <-
  ggarrange(
    plot1,
    plot2,
    plot3,
    plot4,
    plot5,
    plot6,
    ncol = 3,
    nrow = 2,
    common.legend = TRUE,
    legend = "bottom"
  )

print(arranged_plots_ideology)

folder_out = file.path(folder, 'figures')
dir.create(folder_out, showWarnings = FALSE)

path_out = file.path(folder, 'figures', 'ideology_features.png')

ggsave(path_out,
       arranged_plots_ideology,
       width = 12,
       height = 8)

# Second panel plot of download speed vs other features
# Plot 1: Download Speed vs. Education (%)
plot1 <- ggplot(
  data,
  aes(
    x = avgmaxaddown..cd.,
    y = X2014_2018_acs_educational_attainment_among_adults_25._and_median_household_income_high_school_or_greater,
    color = ideology_cluster,
    shape = ideology_cluster,
    size = ideology
  )
) +
  geom_point(size = 2) +
  labs(title = "(A) Education for Adults 25+ \nvs. Broadband Download Speed",
       x = "Download Speed (Mbps)", y = "Education (%)") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology Group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology Group")

# Plot 2: Download Speed vs. Median Income
plot2 <- ggplot(
  data,
  aes(
    x = avgmaxaddown..cd.,
    y = median_income,
    color = ideology_cluster,
    shape = ideology_cluster,
    size = ideology
  )
) +
  geom_point(size = 2) +
  labs(title = "(B) Median Income \nvs. Broadband Download Speed",
       x = "Download Speed (Mbps)", y = "Median Income ($)") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology Group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology Group")

# Plot 3: Download Speed vs. White Population Percentage
plot3 <- ggplot(
  data,
  aes(
    x = avgmaxaddown..cd.,
    y = population_white_percentage,
    color = ideology_cluster,
    shape = ideology_cluster,
    size = ideology
  )
) +
  geom_point(size = 2) +
  labs(title = "(C) White Population \nvs. Broadband Download Speed",
       x = "Download Speed (Mbps)", y = "White Population (%)") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology Group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology Group")

# Plot 4: Download Speed vs. Urban Population (%)
plot4 <- ggplot(
  data,
  aes(
    x = avgmaxaddown..cd.,
    y = cd_urban_pop_ratio,
    color = ideology_cluster,
    shape = ideology_cluster,
    size = ideology
  )
) +
  geom_point(size = 2) +
  labs(title = "(D) Urban-Rural Pop Ratio \nvs. Broadband Download Speed",
       x = "Download Speed (Mbps)", y = "Urban Population (%)") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology Group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology Group")

# Plot 5: Download Speed vs. Households without Internet
plot5 <- ggplot(
  data,
  aes(
    x = avgmaxaddown..cd.,
    y = X.cd..perc_estimate_households_without_internet,
    color = ideology_cluster,
    shape = ideology_cluster,
    size = avgmaxaddown..cd.
  )
) +
  geom_point(size = 2) +
  labs(title = "(E) Households without Internet \nvs. Download Speed",
       x = "Download Speed (Mbps)", y = "Households Without Internet (%)") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology Group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology Group")

# Plot 6: Download Speed vs. Average Internet Download Speed
plot6 <- ggplot(
  data,
  aes(
    x = avgmaxaddown..cd.,
    y = percentage_adv_tech..cd.,
    color = ideology_cluster,
    shape = ideology_cluster,
    size = ideology
  )
) +
  geom_point(size = 2) +
  labs(title = "(F) Broadband Tech Supply \nvs. Download Speed",
       x = "Download Speed (Mbps)", y = "Modern Broadband Tech (%)") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology Group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology Group")

# Arrange the plots into a 3x2 grid
arranged_plots <- ggarrange(
  plot1,
  plot2,
  plot3,
  plot4,
  plot5,
  plot6,
  ncol = 3,
  nrow = 2,
  common.legend = TRUE,
  legend = "bottom"
)

# Print the arranged plots
print(arranged_plots)

path_out = file.path(folder, 'figures', 'download_speed_features.png')

ggsave(path_out,
       arranged_plots,
       width = 12,
       height = 8)

# Median Income vs other features plot
# Plot 1: Median Income vs. Education (%)
plot1 <- ggplot(
  data,
  aes(
    x = median_income,
    y = X2014_2018_acs_educational_attainment_among_adults_25._and_median_household_income_high_school_or_greater,
    color = ideology_cluster,
    shape = ideology_cluster
  )
) +
  geom_point(size = 2) +
  labs(title = "(A) Education vs. Median Income",
       x = "Median Income ($)", y = "Education (%)") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology Group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology Group")

print(plot1)

# Plot 2: Advanced tech vs. Median Income
plot2 <- ggplot(
  data,
  aes(
    x = median_income,
    y = percentage_adv_tech..cd.,
    color = ideology_cluster,
    shape = ideology_cluster
  )
) +
  geom_point(size = 2) +
  labs(title = "(B) Deployed Broadband Tech vs. Median Income",
       x = "Median Income ($)", y = "Modern Broadband Tech (%)") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology Group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology Group")

print(plot2)

# Plot 3: Median Income vs. White Population Percentage
plot3 <- ggplot(
  data,
  aes(
    x = median_income,
    y = population_white_percentage,
    color = ideology_cluster,
    shape = ideology_cluster
  )
) +
  geom_point(size = 2) +
  labs(title = "(C) White Population vs. Median Income",
       x = "Median Income ($)", y = "White Population (%)") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology Group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology Group")

print(plot3)

# Plot 4: Median Income vs. Urban Population (%)
plot4 <- ggplot(
  data,
  aes(
    x = median_income,
    y = cd_urban_pop_ratio,
    color = ideology_cluster,
    shape = ideology_cluster
  )
) +
  geom_point(size = 2) +
  labs(title = "(D) Urban Population vs. Median Income",
       x = "Median Income ($)", y = "Urban Population (%)") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology Group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology Group")

print(plot4)

# Plot 5: Median Income vs. Households Without Internet
plot5 <- ggplot(
  data,
  aes(
    x = median_income,
    y = X.cd..perc_estimate_households_without_internet,
    color = ideology_cluster,
    shape = ideology_cluster
  )
) +
  geom_point(size = 2) +
  labs(title = "(E) Households Without Internet\n vs. Median Income",
       x = "Median Income ($)", y = "Households Without Internet (%)") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology Group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology Group")

print(plot5)

# Plot 6: Median Income vs. Average Internet Download Speed
plot6 <- ggplot(
  data,
  aes(
    x = median_income,
    y = avgmaxaddown..cd.,
    color = ideology_cluster,
    shape = ideology_cluster
  )
) +
  geom_point(size = 2) +
  labs(title = "(F) Avg Internet Download Speed\n vs. Median Income",
       x = "Median Income ($)", y = "Avg Internet Download Speed (Mbps)") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology Group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology Group")

print(plot6)

# Arrange the plots into a 3x2 grid
arranged_plots <-
  ggarrange(
    plot1,
    plot2,
    plot3,
    plot4,
    plot5,
    plot6,
    ncol = 3,
    nrow = 2,
    common.legend = TRUE,
    legend = "bottom"
  )

# Print the arranged plots
print(arranged_plots)

# Save the arranged plots to a file
path_out = file.path(folder, 'figures', 'median_income_features.png')
ggsave(path_out,
       arranged_plots,
       width = 12,
       height = 8)


# 4th population white percentage
# Plot 1: White population (%) vs. Education (%)

plot1 <- ggplot(
  data,
  aes(
    x = population_white_percentage,
    y = X2014_2018_acs_educational_attainment_among_adults_25._and_median_household_income_high_school_or_greater,
    color = ideology_cluster,
    shape = ideology_cluster
  )
) +
  geom_point(size = 2) +
  labs(title = "(A) Education vs. White Population",
       x = "White Population (%)", y = "Education (%)") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology group")

print(plot1)

# Plot 2: Advanced tech vs. White Population

plot2 <- ggplot(
  data,
  aes(
    x = population_white_percentage,
    y = percentage_adv_tech..cd.,
    color = ideology_cluster,
    shape = ideology_cluster
  )
) +
  geom_point(size = 2) +
  labs(title = "(B) Advanced Tech vs. White Population",
       x = "White Population (%)", y = "Advanced Tech (%)") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology group")

print(plot2)

# Plot 3: Median Income vs. White Population Percentage
plot3 <- ggplot(
  data,
  aes(
    x = population_white_percentage,
    y = median_income,
    color = ideology_cluster,
    shape = ideology_cluster
  )
) +
  geom_point(size = 2) +
  labs(title = "(C) Median Income vs. White Population",
       x = "White Population (%)", y = "Median Income ($)") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology group")

# Plot 4: Urban Population vs. White Population
plot4 <- ggplot(
  data,
  aes(
    x = population_white_percentage,
    y = cd_urban_pop_ratio,
    color = ideology_cluster,
    shape = ideology_cluster
  )
) +
  geom_point(size = 2) +
  labs(title = "(D) Urban Population\n vs. White Population",
       x = "White Population (%)", y = "Urban Population (%)") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology group")

# Plot 5: Households without Internet vs. White Population
plot5 <- ggplot(
  data,
  aes(
    x = population_white_percentage,
    y = X.cd..perc_estimate_households_without_internet,
    color = ideology_cluster,
    shape = ideology_cluster
  )
) +
  geom_point(size = 2) +
  labs(title = "(E) Households without Internet\n vs. White Population",
       x = "White Population (%)", y = "Households without Internet (%)") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology group")

# Plot 6: Avg Internet Download Speed vs. White Population
plot6 <- ggplot(
  data,
  aes(
    x = population_white_percentage,
    y = avgmaxaddown..cd.,
    color = ideology_cluster,
    shape = ideology_cluster
  )
) +
  geom_point(size = 2) +
  labs(title = "(F) Avg Internet Download Speed\n vs. White Population",
       x = "White Population (%)", y = "Avg Internet Download Speed (Mbps)") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology group")

# Arrange the plots into a 3x2 grid
arranged_plots_white_population <-
  ggarrange(
    plot1,
    plot2,
    plot3,
    plot4,
    plot5,
    plot6,
    ncol = 3,
    nrow = 2,
    common.legend = TRUE,
    legend = "bottom"
  )

# Print the arranged plots
print(arranged_plots_white_population)

path_out = file.path(folder, 'figures', 'white_population_features.png')
ggsave(path_out,
       arranged_plots_white_population,
       width = 12,
       height = 8)
