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


options(tigris_use_cache = FALSE)

folder = dirname(rstudioapi::getSourceEditorContext()$path)
data_directory = file.path(folder, '..', 'data')
setwd(data_directory)

# JSON mapper
json_file <- fromJSON("json_mapper.json")

# Get the congressional districts
congressional_districts <-
  tigris::congressional_districts(cb = TRUE,
                                  year = 2019,
                                  resolution = "20m")

shape_data <- tigris::shift_geometry(congressional_districts)

# Congress data
cd116_congress_bios <- read.csv("cd116_bio_bb.csv")

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
data <- data[!data$state %in% excluded_states,]
cd116_congress_bios <-
  cd116_congress_bios[!cd116_congress_bios$state %in% excluded_states,]

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
  left_join(cd116_congress_bios, by = c("GEOID" = "geoid"))

# # Add centroids to the data
# merged_data$geometry_centroid <- st_centroid(merged_data$geometry)
#
# # Add centroids to the data
# merged_congress_bios$geometry_centroid <-
#   st_centroid(merged_congress_bios$geometry)


# Create legend breaks based on the minimum and maximum values
create_breaks <- function(data) {
  breaks = quantile(data, probs = c(0, 0.25, 0.5, 0.75, 1))
  labels = round(breaks, 2)  # Rounding to 2 decimal places, adjust as necessary
  return(list(breaks = breaks, labels = labels))
}

# Political ideologies in the US. Congress
plot0 <- ggplot(merged_congress_bios) +
  geom_sf(aes(fill = ideology_cluster),
          linewidth = 0.0001,
          color = "white") +
  theme_void() +
  scale_fill_manual(
    values = c(
      "Na" = "grey50",
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
      "Far Right",
      "NA"
    ),
    guide = guide_legend(
      keyheight = unit(3, units = "mm"),
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
    # Adjust size and color here
    legend.title = element_text(size = 10)  # Adjusting legend title size
  ) +
  coord_sf()

print(plot0)

# Plot 1: Choropleth Urban Population
plot1 <- ggplot(merged_data) +
  geom_sf(aes(fill = cd_urban_pop_ratio),
          linewidth = 0.0001,
          color = "white") +
  theme_void() +
  scale_fill_viridis_c(trans = "sqrt",
                       direction = -1,
                       name = "Urban Population (%)") +
  labs(title = "(B) Urban Population per \nCongressional District") +
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

print(plot1)

# Plot 2: Median Broadband \nDownload Speed
plot2 <- ggplot(merged_data) +
  geom_sf(aes(fill = avgmaxaddown..cd.),
          linewidth = 0.0001,
          color = "white") +
  theme_void() +
  scale_fill_viridis_c(trans = "sqrt",
                       direction = -1,
                       name = "Download Speed (Mbps)") +
  labs(title = "(C) Median Broadband \nDownload Speed") +
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

print(plot2)

# Plot 3: Advanced Broadband Technology
plot3 <- ggplot(merged_data) +
  geom_sf(aes(fill = percentage_adv_tech..cd.),
          linewidth = 0.0001,
          color = "white") +
  theme_void() +
  scale_fill_viridis_c(
    trans = "sqrt",
    direction = -1,
    name = "Advanced Broadband (%)"
  ) +
  labs(title = "(D) Advanced Broadband Technology \n (DOCSIS 3.0, 3.1, and Fiber)") +
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

print(plot3)

# Plot 4: Adult Age 25+ High School Education
plot4 <- ggplot(merged_data) +
  geom_sf(
    aes(fill = X2014_2018_acs_educational_attainment_among_adults_25._and_median_household_income_high_school_or_greater),
    linewidth = 0.0001,
    color = "white"
  ) +
  theme_void() +
  scale_fill_viridis_c(
    trans = "sqrt",
    direction = -1,
    name = "Education (%)"
  ) +
  labs(title = "(E) Adult Age 25+ \nHigh School Education") +
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

print(plot4)

# Plot 5: Median Income
plot5 <- ggplot(merged_data) +
  geom_sf(aes(fill = median_income),
          linewidth = 0.0001,
          color = "white") +
  theme_void() +
  scale_fill_viridis_c(trans = "sqrt",
                       direction = -1,
                       # breaks = c(29000, 40000, 60000, 80000, 100000, 120000, 140000),
                       name = "Median Income($)") +
  labs(title = "(F) Median Income") +
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

print(plot5)

# Frequency of tweets
plot6 <- ggplot(merged_congress_bios) +
  geom_sf(aes(fill = bb_tweet_frequency),
          linewidth = 0.0001,
          color = "white") +
  theme_void() +
  scale_fill_viridis_c(
    trans = "sqrt",
    direction = -1,
    name = "Frequency"
  ) +
  labs(title = "(B) Frequency of Broadband-Related Tweets \nby Congressional District Member") +
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

print(plot6)

# Combined plots
combined_plot <- plot0 + plot1 + plot2 + plot3 + plot4 + plot5

# Adjust the layout
combined_plot <- combined_plot + plot_layout(ncol = 2, nrow = 3) &
  theme(plot.margin = unit(c(0, 0, 0, 0), "cm"))

path_out = file.path(folder, 'figures', 'choropleth.png')
ggsave(path_out,
       combined_plot,
       width = 8.27,
       height = 11.69)

# Combine the plots using patchwork
combined_plot_frequency <- plot0 + plot6
combined_plot_frequency <-
  combined_plot_frequency + plot_layout(ncol = 2, nrow = 1) &
  theme(plot.margin = unit(c(0, 0, 0, 0), "cm"))
print(combined_plot_frequency)
path_out = file.path(folder, 'figures', 'frequency_ideology.png')
ggsave(path_out,
       combined_plot_frequency,
       width = 8.27,
       height = 6)


histplot <-
  ggplot(data = merged_congress_bios %>% filter(bb_tweet_frequency > 0),
         aes(x = bb_tweet_frequency, fill = party)) +
  geom_histogram(binwidth = 10) +
  theme_minimal() +
  labs(title = "Tweet Frequency on Broadband\n by Congress Member", x = "Frequency", y = "Count") +
  scale_fill_manual(values = c(
    "R" = "red",
    "D" = "blue",
    "O" = 'green'
  ),
  name = "Party")

print(histplot)

eda_hist <-
  ggplot(data = merged_data, aes(x = cd_urban_pop_ratio)) +
  geom_histogram(bins = 10,
                 fill = "blue",
                 alpha = 0.7) +
  theme_minimal()

print(eda_hist)
