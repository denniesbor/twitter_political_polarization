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
  
  levels = c(
    "no",
    "canada_border",
    "mexico_border"
  ),
  labels = c(
    "No",
    "Ca",
    "Mx"
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
data$`avgmaxaddown..cd.`[data$`avgmaxaddown..cd.` > outlier_threshold] <-
  median_value

# Ideology vs other features plot

# Plot 1: Ideology Score vs. Education (%)
plot1 <- ggplot(
  data,
  aes(
    x = ideology,
    y = X2014_2018_acs_educational_attainment_among_adults_25._and_median_household_income_high_school_or_greater,
    color = ideology_cluster,
    shape = border
  )
) +
  geom_point(aes(size = percentage_adv_tech..cd. )) +
  labs(title = "(A) Ideology score vs. population (25+) with \nhighschool education (%)",
       x = "Ideology score", y = "Education (%)") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_size_continuous(name = "Broadband tech", guide = "none") +
  scale_shape_manual(values = c(15,16, 17), name = "Border country") +
  theme(axis.title.x = element_blank())  # Remove x-axis label

print(plot1)

# Plot 2: Ideology Score vs. Median Income
plot2 <- ggplot(data,
                aes(
                  x = ideology,
                  y = median_income,
                  color = ideology_cluster,
                  shape = border
                )) +
  geom_point(aes(size = percentage_adv_tech..cd. )) +
  labs(title = "(B) Ideology score vs. median income",
       x = "Ideology score", y = "Median Income") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_size_continuous(name = "Broadband tech", guide = "none") +
  scale_shape_manual(values = c(15,16, 17), name = "Border country") +
  theme(axis.title.x = element_blank())  # Remove x-axis label

# Plot 3: Ideology Score vs. White Population Percentage
plot3 <- ggplot(
  data,
  aes(
    x = ideology,
    y = population_white_percentage,
    color = ideology_cluster,
    shape = border
  )
) +
  geom_point(aes(size = percentage_adv_tech..cd. )) +
  labs(title = "(C) Ideology score vs. white population \n (%)",
       x = "Ideology score", y = "White Population (%)") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_size_continuous(name = "Broadband tech", guide = "none") +
  scale_shape_manual(values = c(15,16, 17), name = "Border country") +
  theme(axis.title.x = element_blank())  # Remove x-axis label


# Plot 4: Ideology Score vs. Urban-Rural Population Ratio
plot4 <- ggplot(data,
                aes(
                  x = ideology,
                  y = cd_urban_pop_ratio,
                  color = ideology_cluster,
                  shape = border
                )) +
  geom_point(aes(size = percentage_adv_tech..cd. )) +
  labs(title = "(D) Ideology score vs. urban-rural \n population ratio",
       x = "Ideology score", y = "Urban-Rural Population Ratio") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_size_continuous(name = "Broadband tech", guide = "none") +
  scale_shape_manual(values = c(15,16, 17), name = "Border country")

# Plot 5: Ideology Score vs. Households without Internet
plot5 <- ggplot(
  data,
  aes(
    x = ideology,
    y = X.cd..perc_estimate_households_without_internet,
    color = ideology_cluster,
    shape = border
  )
) +
  geom_point(aes(size = percentage_adv_tech..cd. )) +
  labs(title = "(E) Ideology score vs. households \n without internet",
       x = "Ideology score", y = "Households without Internet (%)") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_size_continuous(name = "Broadband tech", guide = "none") +
  scale_shape_manual(values = c(15,16, 17), name = "Border country")


# Plot 6: Ideology Score vs. Avg Internet Download Speed
plot6 <- ggplot(data,
                aes(
                  x = ideology,
                  y = avgmaxaddown..cd.,
                  color = ideology_cluster,
                  shape = border
                )) +
  geom_point(aes(size = 2)) +
  labs(title = "(F) Ideology score vs. internet \n download speed (avg)",
       x = "Ideology score", y = "Avg Internet Download Speed") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_shape_manual(values = c(15,16, 17), name = "Border country")


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

print(arranged_plots)

folder_out = file.path(folder, 'figures')
dir.create(folder_out, showWarnings = FALSE)

path_out = file.path(folder, 'figures', 'ideology_features.png')

ggsave(path_out,
       arranged_plots,
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
    shape = border,
    size = percentage_adv_tech..cd.
  )
) +
  geom_point() +
  labs(title = "(A) Download speed vs. adult pop\n with high school education (%)",
       x = "Download Speed", y = "Education (%)") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_size_continuous(name = "Broadband tech", guide = "none") +
  scale_shape_manual(values = c(15,16, 17), name = "Border country") +
  theme(axis.title.x = element_blank())  # Remove y-axis label

# Plot 2: Download Speed vs. Median Income
plot2 <- ggplot(
  data,
  aes(
    x = avgmaxaddown..cd.,
    y = median_income,
    color = ideology_cluster,
    shape = border,
    size = percentage_adv_tech..cd.
  )
) +
  geom_point() +
  labs(title = "(B) Download speed vs. median income",
       x = "Download Speed", y = "Median Income") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_size_continuous(name = "Broadband tech", guide = "none") +
  scale_shape_manual(values = c(15,16, 17), name = "Border country") +
  theme(axis.title.x = element_blank())  # Remove y-axis label

# Plot 3: Download Speed vs. White Population Percentage
plot3 <- ggplot(
  data,
  aes(
    x = avgmaxaddown..cd.,
    y = population_white_percentage,
    color = ideology_cluster,
    shape = border,
    size = percentage_adv_tech..cd.
  )
) +
  geom_point() +
  labs(title = "(C) Download speed vs. white \npopulation (%)",
       x = "Download Speed", y = "White Population (%)") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_size_continuous(name = "Broadband tech", guide = "none") +
  scale_shape_manual(values = c(15,16, 17), name = "Border country") +
  theme(axis.title.x = element_blank())  # Remove y-axis label

# Plot 4: Download Speed vs. Urban-Rural Population Ratio
plot4 <- ggplot(
  data,
  aes(
    x = avgmaxaddown..cd.,
    y = cd_urban_pop_ratio,
    color = ideology_cluster,
    shape = border,
    size = percentage_adv_tech..cd.
  )
) +
  geom_point() +
  labs(title = "(D) Download speed vs.\n urban-rural population ratio",
       x = "Download Speed", y = "Urban-Rural Population Ratio") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_shape_manual(values = c(15,16, 17), name = "Border country") +
  scale_size_continuous(name = "Broadband tech", guide = "none")

# Plot 5: Download Speed vs. Households without Internet
plot5 <- ggplot(
  data,
  aes(
    x = avgmaxaddown..cd.,
    y = X.cd..perc_estimate_households_without_internet,
    color = ideology_cluster,
    shape = border,
    size = percentage_adv_tech..cd. 
  )
) +
  geom_point() +
  labs(title = "(E) Download speed vs. \nhouseholds without internet",
       x = "Households without Internet (%)", y = "Ideology Score") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_shape_manual(values = c(15,16, 17), name = "Border country") +
  scale_size_continuous(name = "Download Speed")

# Plot 6: Download Speed vs. Ideology Score
plot6 <- ggplot(
  data,
  aes(
    x = avgmaxaddown..cd.,
    y = ideology,
    color = ideology_cluster,
    shape = border,
    size = percentage_adv_tech..cd.
  )
) +
  geom_point() +
  labs(title = "(F) Download speed vs. ideology score",
       x = "Download Speed", y = "Ideology Score") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_shape_manual(values = c(15,16, 17), name = "Border country") +
  scale_size_continuous(name = "Broadband tech", guide = "none")

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

# Third plot of income vs other plots
# Plot 1: Median Income vs. Download Speed
plot1 <- ggplot(
  data,
  aes(
    x = median_income,
    y = avgmaxaddown..cd.,
    color = ideology_cluster,
    shape = border,
    size = percentage_adv_tech..cd.
  )
) +
  geom_point() +
  labs(title = "(A) Median income vs. download speed",
       x = "Median Income", y = "Download Speed") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_size_continuous(name = "Broadband tech", guide = "none") +
  scale_shape_manual(values = c(15,16, 17), name = "Border country") +
  theme(axis.title.x = element_blank())  # Remove y-axis label

# Plot 2: Median Income vs. Education (%)
plot2 <- ggplot(
  data,
  aes(
    x = median_income,
    y = X2014_2018_acs_educational_attainment_among_adults_25._and_median_household_income_high_school_or_greater,
    color = ideology_cluster,
    shape = border,
    size = percentage_adv_tech..cd.
  )
) +
  geom_point() +
  labs(title = "(B) Median income vs. population (25+) with \nhigh school education (%)",
       x = "Median Income", y = "Education (%)") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_size_continuous(name = "Broadband tech", guide = "none") +
  scale_shape_manual(values = c(15,16, 17), name = "Border country") +
  theme(axis.title.x = element_blank())  # Remove y-axis label

# Plot 3: Median Income vs. White Population Percentage
plot3 <- ggplot(
  data,
  aes(
    x = median_income,
    y = population_white_percentage,
    color = ideology_cluster,
    shape = border,
    size = percentage_adv_tech..cd.
  )
) +
  geom_point() +
  labs(title = "(C) Median income vs. white population \n (%)",
       x = "Median Income", y = "White Population (%)") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_size_continuous(name = "Broadband tech", guide = "none") +
  scale_shape_manual(values = c(15,16, 17), name = "Border country") +
  theme(axis.title.x = element_blank())  # Remove y-axis label

# Plot 4: Median Income vs. Urban-Rural Population Ratio
plot4 <- ggplot(
  data,
  aes(
    x = median_income,
    y = cd_urban_pop_ratio,
    color = ideology_cluster,
    shape = border,
    size = percentage_adv_tech..cd.
  )
) +
  geom_point() +
  labs(title = "(D) Median income vs. urban-rural \n population ratio",
       x = "Median Income", y = "Urban-Rural Population Ratio") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_shape_manual(values = c(15,16, 17), name = "Border country") +
  scale_size_continuous(name = "Broadband tech", guide = "none")

# Plot 5: Median Income vs. Households without Internet
plot5 <- ggplot(
  data,
  aes(
    x = median_income,
    y = X.cd..perc_estimate_households_without_internet,
    color = ideology_cluster,
    shape = border,
    size = percentage_adv_tech..cd. 
  )
) +
  geom_point() +
  labs(title = "(E) Median income vs. households \n without internet",
       x = "Median Income", y = "Households without Internet (%)") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_shape_manual(values = c(15,16, 17), name = "Border country") +
  scale_size_continuous(name = "Download Speed")

# Plot 6: Median Income vs. Download Speed
plot6 <- ggplot(
  data,
  aes(
    x = median_income,
    y = avgmaxaddown..cd.,
    color = ideology_cluster,
    shape = border,
    size = percentage_adv_tech..cd.
  )
) +
  geom_point() +
  labs(title = "(F) Median income vs. download speed",
       x = "Median Income", y = "Download Speed") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_shape_manual(values = c(15,16, 17), name = "Border country") +
  scale_size_continuous(name = "Broadband tech", guide = "none")

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
# Plot 1: White Population Percentage vs. Download Speed
plot1 <- ggplot(
  data,
  aes(
    x = population_white_percentage,
    y = avgmaxaddown..cd.,
    color = ideology_cluster,
    shape = border,
    size = percentage_adv_tech..cd.
  )
) +
  geom_point() +
  labs(title = "(A) White population (%)\n vs. download speed",
       x = "White Population (%)", y = "Download Speed") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_shape_manual(values = c(15,16, 17), name = "Border country") +
  scale_size_continuous(name = "Broadband tech", guide = "none")

# Plot 2: White Population Percentage vs. Education (%)
plot2 <- ggplot(
  data,
  aes(
    x = population_white_percentage,
    y = X2014_2018_acs_educational_attainment_among_adults_25._and_median_household_income_high_school_or_greater,
    color = ideology_cluster,
    shape = border,
    size = percentage_adv_tech..cd.
  )
) +
  geom_point() +
  labs(title = "(B) White population (%) vs. adult pop \nwith high school education (%)",
       x = "White Population (%)", y = "Education (%)") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_shape_manual(values = c(15,16, 17), name = "Border country") +
  scale_size_continuous(name = "Broadband tech", guide = "none")

# Plot 3: White Population Percentage vs. Median Income
plot3 <- ggplot(
  data,
  aes(
    x = population_white_percentage,
    y = median_income,
    color = ideology_cluster,
    shape = border,
    size = percentage_adv_tech..cd.
  )
) +
  geom_point() +
  labs(title = "(C) White population (%) vs. median income",
       x = "White Population (%)", y = "Median Income") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_shape_manual(values = c(15,16, 17), name = "Border country") +
  scale_size_continuous(name = "Broadband tech", guide = "none")

# Plot 4: White Population Percentage vs. Urban-Rural Population Ratio
plot4 <- ggplot(
  data,
  aes(
    x = population_white_percentage,
    y = cd_urban_pop_ratio,
    color = ideology_cluster,
    shape = border,
    size = percentage_adv_tech..cd.
  )
) +
  geom_point() +
  labs(title = "(D) White population (%) vs. \nurban-rural population ratio",
       x = "White Population (%)", y = "Urban-Rural Population Ratio") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_shape_manual(values = c(15,16, 17), name = "Border country") +
  scale_size_continuous(name = "Broadband tech", guide = "none")

# Plot 5: White Population Percentage vs. Households without Internet
plot5 <- ggplot(
  data,
  aes(
    x = population_white_percentage,
    y = X.cd..perc_estimate_households_without_internet,
    color = ideology_cluster,
    shape = border,
    size = percentage_adv_tech..cd. 
  )
) +
  geom_point() +
  labs(title = "(E) White population (%) vs.\n households without internet",
       x = "White Population (%)", y = "Households without Internet (%)") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_shape_manual(values = c(15,16, 17), name = "Border country") +
  scale_size_continuous(name = "Download Speed")

# Plot 6: White Population Percentage vs. Download Speed
plot6 <- ggplot(
  data,
  aes(
    x = population_white_percentage,
    y = ideology,
    color = ideology_cluster,
    shape = border,
    size = percentage_adv_tech..cd.
  )
) +
  geom_point() +
  labs(title = "(F) White population (%) \n vs. ideology",
       x = "White Population (%)", y = "Download Speed") +
  scale_colour_viridis_d(name = "Ideology group") +
  scale_shape_manual(values = c(15,16, 17), name = "Border country") +
  scale_size_continuous(name = "Broadband tech", guide = "none")

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
  ) +
  guides(color = guide_legend(nrow = 2))

# Print the arranged plots
print(arranged_plots)

path_out = file.path(folder, 'figures', 'white_population_features.png')
ggsave(path_out,
       arranged_plots,
       width = 12,
       height = 8)
