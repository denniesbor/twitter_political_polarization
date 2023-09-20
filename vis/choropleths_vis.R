library(tidyverse)
library(readr)
library(tidyr)
library(broom)
library(jsonlite)
library(usmap)
library(dplyr)
library(tigris)
library(tidycensus)
library(patchwork)
library(sf)
library(sp)
library(viridis)
library(ggpubr)
library(geojsonio)

# install.packages("sf")
# install.packages("sp")
# install.packages("patchwork")


# install.packages("ggpubr")
# install.packages("viridis")


options(tigris_use_cache = TRUE)

folder = dirname(rstudioapi::getSourceEditorContext()$path)
data_directory = file.path(folder, '..', 'data')
setwd(data_directory)

# JSON mapper
json_file <- fromJSON("json_mapper.json")

# Get the congressional districts
congressional_districts <- tigris::congressional_districts(cb = TRUE, year=2019, resolution = "20m")

shape_data <- tigris::shift_geometry(congressional_districts)

# Congress data
cd116_congress_bios <- read.csv("cd116_bio.csv")

# Copngressional demographic data
cd_demogr_df <-
  read.csv("congressional_district_demographic_data.csv")

# Broadband demand and supply data
broadband = read.csv("broadband_demand_supply_v2.csv")
broadband <- broadband %>%
  rename(district = cd116)

data <- cd_demogr_df %>%
  inner_join(broadband, by = c("state", "district")) %>%
  mutate(new_index = row_number()) %>%
  select(new_index, everything()) %>%
  rename(index = new_index)

# Use mutate to create a new column 'state_code' by applying a function to each value in the 'state' column
cd116_congress_bios <- cd116_congress_bios %>%
  mutate(state_code = sapply(state, function(state)
    json_file$state_code[[state]]))

data <- data %>%
  mutate(state_code = sapply(state, function(state)
    json_file$state_code[[state]]))

# Exclude states not within the US. highland
excluded_states <- c("AS", "PR", "VI") # AK, Hi
data <- data[!data$state %in% excluded_states, ]
cd116_congress_bios <- cd116_congress_bios[!cd116_congress_bios$state %in% excluded_states, ]

# median value
median_value <- median(data$`avgmaxaddown..cd.`)

#remove outliers from the avg broadband speed (Minnessota data)
outlier_threshold <- 600

# Replace outliers with the median
data$`avgmaxaddown..cd.`[data$`avgmaxaddown..cd.` > outlier_threshold] <-
  median_value

# Make ratios as percentages
data$cd_urban_pop_ratio <- data$cd_urban_pop_ratio * 100
data$percentage_adv_tech..cd. <- data$percentage_adv_tech..cd. * 100

# Round to 0 decimal places
data$cd_urban_pop_ratio <- as.integer(data$cd_urban_pop_ratio, 0)

# Create the geoid column
data$geoid <-
  paste0(sprintf("%02d", as.numeric(data$state_code)), sprintf("%02d", as.numeric(data$district)))

# Create the geoid column for the congress bios
cd116_congress_bios$geoid <-
  paste0(sprintf("%02d", as.numeric(cd116_congress_bios$state_code)), sprintf("%02d", as.numeric(cd116_congress_bios$district)))


# Mutate party labels
cd116_congress_bios <- cd116_congress_bios %>%
  mutate(party_factor = factor(
    party,
    levels = c("R", "D", "I"),
    labels = c(1, 0, 3)
  ))

# Reorder and mutate ideology_cluster from left -> right
cd116_congress_bios$ideology_cluster <- factor(
  cd116_congress_bios$ideology_cluster,
  
  levels = c(
    "Far Left",
    "Left Centrist",
    "Centrist",
    "Right Centrist",
    "Far Right"
  )
)

# Step 3: Merging the broadband and demographic data with shp files
merged_data <- shape_data %>%
  inner_join(data, by = c("GEOID" = "geoid"))

merged_congress_bios <- shape_data %>%
  inner_join(cd116_congress_bios, by = c("GEOID" = "geoid"))

# Add centroids to the data
merged_data$geometry_centroid <- st_centroid(merged_data$geometry)

# Add centroids to the data
merged_congress_bios$geometry_centroid <-
  st_centroid(merged_congress_bios$geometry)


# Calculate the minimum and maximum for each variable to be plotted
summary_stats <- merged_data %>%
  summarise(
    min_urban_pop = min(cd_urban_pop_ratio, na.rm = TRUE),
    max_urban_pop = max(cd_urban_pop_ratio, na.rm = TRUE),
    min_download_speed = min(avgmaxaddown..cd., na.rm = TRUE),
    max_download_speed = max(avgmaxaddown..cd., na.rm = TRUE),
    min_adv_broadband = min(percentage_adv_tech..cd., na.rm = TRUE),
    max_adv_broadband = max(percentage_adv_tech..cd., na.rm = TRUE),
    min_education = min(
      X2014_2018_acs_educational_attainment_among_adults_25._and_median_household_income_high_school_or_greater,
      na.rm = TRUE
    ),
    max_education = max(
      X2014_2018_acs_educational_attainment_among_adults_25._and_median_household_income_high_school_or_greater,
      na.rm = TRUE
    ),
    min_median_income = min(median_income, na.rm = TRUE),
    max_median_income = max(median_income, na.rm = TRUE)
  )

# Create legend breaks based on the minimum and maximum values
create_breaks <- function(min_val, max_val) {
  breaks = exp(seq(log(min_val), log(max_val), length.out = 6))
  return(round(breaks, 0))
}

# Political ideologies in the US. Congress
plot0 <- ggplot(merged_congress_bios) +
  geom_sf(aes(fill = ideology_cluster)) +
  theme_void() +
  scale_fill_manual(
    values = c(
      "Far Left" = "#2166ac",
      "Left Centrist" = "#4393c3",
      "Centrist" = "#fddbc7",
      "Right Centrist" = "#d6604d",
      "Far Right" = "#b2182b"
    ),
    name = "Ideology",
    labels = c(
      "Far Left",
      "Left Centrist",
      "Centrist",
      "Right Centrist",
      "Far Right"
    ),
    guide = guide_legend(
      keyheight = unit(3, units = "mm"),
      keywidth = unit(16, units = "mm"),
      label.position = "bottom",
      title.position = 'top',
      nrow = 1
    )
  ) +
  labs(title = "(A) 116th Congressional \nDistricts Ideologies") +
  theme(
    text = element_text(color = "#22211d"),
    plot.margin = margin(0, 0, 0, 0, "cm"),
    plot.background = element_rect(fill = "#f5f5f2", color = NA),
    panel.background = element_rect(fill = "#f5f5f2", color = NA),
    legend.background = element_rect(fill = "#f5f5f2", color = NA),
    plot.title = element_text(
      size = 12,
      hjust = 0.01,
      color = "#4e4d47",
      margin = margin(
        b = -0.1,
        t = 0.2,
        l = 2,
        unit = "cm"
      )
    ),
    legend.position = "bottom",
    legend.text = element_text(size = 10, color = "blue"),
    # Adjust size and color here
    legend.title = element_text(size = 10)  # Adjusting legend title size
  ) +
  coord_sf()

print(plot0)

# Plot 1: Choropleth Urban Population
plot1 <- ggplot(merged_data) +
  geom_sf(aes(fill = cd_urban_pop_ratio)) +
  theme_void() +
  scale_fill_viridis(
    trans = "log",
    direction = -1,
    breaks = create_breaks(summary_stats$min_urban_pop, summary_stats$max_urban_pop),
    name = "Urban Population (%)",
    guide = guide_legend(
      keyheight = unit(3, units = "mm"),
      keywidth = unit(12, units = "mm"),
      label.position = "bottom",
      title.position = 'top',
      nrow = 1
    )
  ) +
  labs(title = "(B) Urban Population per \nCongressional District") +
  theme(
    text = element_text(color = "#22211d"),
    plot.margin = margin(0, 0, 0, 0, "cm"),
    plot.background = element_rect(fill = "#f5f5f2", color = NA),
    panel.background = element_rect(fill = "#f5f5f2", color = NA),
    legend.background = element_rect(fill = "#f5f5f2", color = NA),
    plot.title = element_text(
      size = 12,
      hjust = 0.01,
      color = "#4e4d47",
      margin = margin(
        b = -0.1,
        t = 0.4,
        l = 2,
        unit = "cm"
      )
    ),
    legend.position = "bottom"
  ) +
  coord_sf()

print(plot1)

# Plot 2: Median Broadband \nDownload Speed
plot2 <- ggplot(merged_data) +
  geom_sf(aes(fill = avgmaxaddown..cd.)) +
  theme_void() +
  scale_fill_viridis(
    trans = "log",
    direction = -1,
    breaks = create_breaks(
      summary_stats$min_download_speed,
      summary_stats$max_download_speed
    ),
    name = "Download Speed (Mbps)",
    guide = guide_legend(
      keyheight = unit(3, units = "mm"),
      keywidth = unit(12, units = "mm"),
      label.position = "bottom",
      title.position = 'top',
      nrow = 1
    )
  ) +
  labs(title = "(C) Median Broadband \nDownload Speed") +
  theme(
    text = element_text(color = "#22211d"),
    plot.margin = margin(0, 0, 0, 0, "cm"),
    plot.background = element_rect(fill = "#f5f5f2", color = NA),
    panel.background = element_rect(fill = "#f5f5f2", color = NA),
    legend.background = element_rect(fill = "#f5f5f2", color = NA),
    plot.title = element_text(
      size = 12,
      hjust = 0.01,
      color = "#4e4d47",
      margin = margin(
        b = -0.1,
        t = 0.4,
        l = 2,
        unit = "cm"
      )
    ),
    legend.position = "bottom"
  ) +
  coord_sf()

print(plot2)

# Plot 3: Advanced Broadband Technology
plot3 <- ggplot(merged_data) +
  geom_sf(aes(fill = percentage_adv_tech..cd.)) +
  theme_void() +
  scale_fill_viridis(
    trans = "log",
    direction = -1,
    breaks = create_breaks(
      summary_stats$min_adv_broadband,
      summary_stats$max_adv_broadband
    ),
    name = "Advanced Broadband (%)",
    guide = guide_legend(
      keyheight = unit(3, units = "mm"),
      keywidth = unit(12, units = "mm"),
      label.position = "bottom",
      title.position = 'top',
      nrow = 1,
      direction = "horizontal"
    )
  ) +
  labs(title = "(D) Advanced Broadband Technology \n (DOCSIS 3.0, 3.1, and Fiber)") +
  theme(
    text = element_text(color = "#22211d"),
    plot.margin = margin(0, 0, 0, 0, "cm"),
    plot.background = element_rect(fill = "#f5f5f2", color = NA),
    panel.background = element_rect(fill = "#f5f5f2", color = NA),
    legend.background = element_rect(fill = "#f5f5f2", color = NA),
    plot.title = element_text(
      size = 12,
      hjust = 0.01,
      color = "#4e4d47",
      margin = margin(
        b = -0.1,
        t = 0.4,
        l = 2,
        unit = "cm"
      )
    ),
    legend.position = "bottom"
  ) +
  coord_sf()

print(plot3)

# Plot 4: Adult Age 25+ High School Education
plot4 <- ggplot(merged_data) +
  geom_sf(
    aes(fill = X2014_2018_acs_educational_attainment_among_adults_25._and_median_household_income_high_school_or_greater)
  ) +
  theme_void() +
  scale_fill_viridis(
    trans = "log",
    direction = -1,
    breaks = create_breaks(summary_stats$min_education, summary_stats$max_education),
    name = "Education (%)",
    guide = guide_legend(
      keyheight = unit(3, units = "mm"),
      keywidth = unit(12, units = "mm"),
      label.position = "bottom",
      title.position = 'top',
      nrow = 1
    )
  ) +
  labs(title = "(E) Adult Age 25+ \nHigh School Education") +
  theme(
    text = element_text(color = "#22211d"),
    plot.margin = margin(0, 0, 0, 0, "cm"),
    plot.background = element_rect(fill = "#f5f5f2", color = NA),
    panel.background = element_rect(fill = "#f5f5f2", color = NA),
    legend.background = element_rect(fill = "#f5f5f2", color = NA),
    plot.title = element_text(
      size = 12,
      hjust = 0.01,
      color = "#4e4d47",
      margin = margin(
        b = -0.1,
        t = 0.4,
        l = 2,
        unit = "cm"
      )
    ),
    legend.position = "bottom"
  ) +
  coord_sf()

print(plot4)

# Plot 5: Median Income
plot5 <- ggplot(merged_data) +
  geom_sf(aes(fill = median_income)) +
  theme_void() +
  scale_fill_viridis(
    trans = "log",
    direction = -1,
    breaks = create_breaks(
      summary_stats$min_median_income,
      summary_stats$max_median_income
    ),
    name = "Median Income($)",
    guide = guide_legend(
      keyheight = unit(3, units = "mm"),
      keywidth = unit(12, units = "mm"),
      label.position = "bottom",
      title.position = 'top',
      nrow = 1
    )
  ) +
  labs(title = "(F) Median Income") +
  theme(
    text = element_text(color = "#22211d"),
    plot.margin = margin(0, 0, 0, 0, "cm"),
    plot.background = element_rect(fill = "#f5f5f2", color = NA),
    panel.background = element_rect(fill = "#f5f5f2", color = NA),
    legend.background = element_rect(fill = "#f5f5f2", color = NA),
    plot.title = element_text(
      size = 12,
      hjust = 0.01,
      color = "#4e4d47",
      margin = margin(
        b = -0.1,
        t = 0.4,
        l = 2,
        unit = "cm"
      )
    ),
    legend.position = "bottom"
  ) +
  coord_sf()

print(plot5)

# Combine the plots using patchwork
combined_plot_0_1 <-  plot0 / plot1
combined_plot_2_5 <-  plot2 / plot3 / plot4 / plot5

# Adjust the layout
combined_plot_2_5 <- combined_plot + plot_layout(ncol = 2, nrow = 2) & 
  theme(
    plot.margin = unit(c(0, 0, 0, 0), "null")
  )

combined_plot_0_1 <- combined_plot_0_1 + plot_layout(ncol = 2, nrow = 1) & 
  theme(
    plot.margin = unit(c(0, 0, 0, 0), "null")
  )

print(combined_plot_2_5)

path_out_1 = file.path(folder, 'figures', 'choropleth_0_1.png')
path_out = file.path(folder, 'figures', 'choropleth_2_5.png')

ggsave(path_out_1,
       combined_plot_0_1,
       width = 12,
       height = 8)

ggsave(path_out,
       combined_plot_2_5,
       width = 12,
       height = 8)
