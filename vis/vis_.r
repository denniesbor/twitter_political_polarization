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


# Ideology vs other features plot
# Plot 1: Ideology Score vs. Education (%)
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
  labs(title = "(A) High school education (%) for\n adults (25+) against political ideology",
       x = "Ideology score", y = "Education (%)") +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology group") +
  theme(axis.title.x = element_blank())  # Remove x-axis label

print(plot1)

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
  labs(title = "(B) Median income ($) \n vs. political ideology",
       x = "Ideology score", y = "Median income ($)") +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology group") +
  theme(axis.title.x = element_blank())  # Remove x-axis label


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
  labs(title = "(C) White population (%) \n vs. political ideology",
       x = "Ideology score", y = "White population (%)") +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology group") +
  theme(axis.title.x = element_blank())  # Remove x-axis label


# Plot 4: Ideology Score vs. Urban population (%)
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
  labs(title = "(D) Urban-rural pop ratio \n vs. ideology",
       x = "Ideology score", y = "Urban population (%)") +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology group")

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
  labs(title = "(E) Households without internet (%) \n vs. ideology",
       x = "Ideology score", y = "Households without internet (%)") +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology group")


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
  labs(title = "(F) Internet download speed (avg)\n vs. ideology",
       x = "Ideology score", y = "Avg internet download speed (Mbps)") +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology group")


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

# Second panel plot of download speed bs
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
  labs(title = "(A) Education (%) for adults (25+) \nvs. Broadband download speed",
       x = "Download Speed (Mbps)", y = "Education (%)") +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology group") +
  theme(axis.title.x = element_blank())  # Remove x-axis label

print(plot1)

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
  labs(title = "(B) Median income ($) vs.\n Broadband download speed",
       x = "Download Speed (Mbps)", y = "Median Income ($)") +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology group") +
  theme(axis.title.x = element_blank())  # Remove x-axis label

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
  labs(title = "(C) White population (%) vs.\n Broadband download speed",
       x = "Download Speed (Mbps)", y = "White Population (%)") +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology group") +
  theme(axis.title.x = element_blank())  # Remove x-axis label

# Plot 4: Download Speed vs. Urban population (%)
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
  labs(title = "(D) Urban-rural pop ratio \n vs. Broadband download speed",
       x = "Download Speed (Mbps)", y = "Urban population (%)") +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology group")

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
  labs(title = "(E) Households w/o internet \n vs. download speed",
       x = "Download Speed (Mbps)", y = "Households without Internet (%)") +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology group")
# Plot 6: Download Speed vs. Ideology Score
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
  labs(title = "(F) Broadband tech supply(%) \n vs. download speed",
       x = "Download Speed (Mbps)", y = "Modern Broadband Tech (%)") +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology group")


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

path_out = file.path(folder, 'figures', 'download_speed_features.png')

ggsave(path_out,
       arranged_plots,
       width = 12,
       height = 8)

# Median Income ($) vs other features plot
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
  labs(title = "(A) Education (%) vs. median income ($)",
       x = "Median income ($)", y = "Education (%)") +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology group") +
  theme(axis.title.x = element_blank())  # Remove x-axis label

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
  labs(title = "(B) Deployed broadband tech \n vs. median income ($)",
       x = "Median income ($)", y = "Modern Broadband Tech (%)") +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology group") +
  theme(axis.title.x = element_blank())  # Remove x-axis label

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
  labs(title = "(C) White population (%) \n vs. median income ($)",
       x = "Median income ($)", y = "White population (%)") +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology group") +
  theme(axis.title.x = element_blank())  # Remove x-axis label

# Plot 4: Median Income vs. Urban population (%)
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
  labs(title = "(D) Urban population (%) \n vs. median income ($)",
       x = "Median income ($)", y = "Urban population (%)") +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology group")

# Plot 5: Median Income vs. Households without Internet
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
  labs(title = "(E) Households without internet (%) \n vs. median income ($)",
       x = "Median income ($)", y = "Households without internet (%)") +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology group")

# Plot 6: Median Income vs. Avg Internet Download Speed
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
  labs(title = "(F) Avg internet download speed (Mbps)\n vs. median income ($)",
       x = "Median income ($)", y = "Avg internet download speed (Mbps)") +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology group")

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
  labs(title = "(A) Education (%) vs. white population (%)",
       x = "White Population (%)", y = "Education (%)") +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology group") +
  theme(axis.title.x = element_blank())  # Remove x-axis label

print(plot1)

# Plot 2: Advanced tech vs. White Population (%)
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
  labs(title = "(B) Deployed broadband tech \n vs. white population (%)",
       x = "White Population (%)", y = "Modern Broadband Tech (%)") +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology group") +
  theme(axis.title.x = element_blank())  # Remove x-axis label

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
  labs(title = "(C) Median income ($) \n vs. white population (%)",
       x = "White Population (%)", y = "Median income ($)") +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology group") +
  theme(axis.title.x = element_blank())  # Remove x-axis label

# Plot 4: Median Income vs. Urban population (%)
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
  labs(title = "(D) Urban population (%) \n vs. white population (%)",
       x = "White Population (%)", y = "Urban Population (%)") +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology group")

# Plot 5: Median Income vs. Households without Internet
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
  labs(title = "(E) Households without internet (%) \n vs. white population (%)",
       x = "White Population (%)", y = "Households without internet (%)") +
  scale_color_manual(values = scale_map$color,
                     labels = scale_map$name,
                     name = "Ideology group") +
  scale_shape_manual(values = scale_map$shape,
                     labels = scale_map$name,
                     name = "Ideology group")

# Plot 6: Median Income vs. Avg Internet Download Speed
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
  labs(title = "(F) Avg internet download speed (Mbps)\n vs. white population (%)",
       x = "White Population (%)", y = "Avg internet download speed (Mbps)") +
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
print(arranged_plots)

path_out = file.path(folder, 'figures', 'white_population_features.png')
ggsave(path_out,
       arranged_plots,
       width = 12,
       height = 8)
