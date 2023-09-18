library(tidyverse)
library(readr)
library(tidyr)
library(broom)

# install.packages("sf")
# install.packages("sp")

library(sf)
library(sp)


# install.packages("ggpubr")
# install.packages("viridis")
library(viridis)
library(ggpubr)
library(geojsonio)

folder = dirname(rstudioapi::getSourceEditorContext()$path)
data_directory = file.path(folder, '..', 'data')
setwd(data_directory)

# read the files
data <- read.csv("congressional_district_broadband_data.csv")
shape_data <- st_read("tl_2019_us_cd116")

# Exclude states not within the US. highland
excluded_states <- c("AK", "HI", "AS", "PR", "VI")
data <- data[!data$state %in% excluded_states,]

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

# Function to format numbers with leading zeros
format_with_leading_zeros <- function(number, width) {
  formatC(number,
          width = width,
          format = "d",
          flag = "0")
}

# Create the geoid column
data$geoid <- ifelse(
  data$district >= 10,
  paste0(data$state_code, data$district),
  paste0(data$state_code, "0", data$district)
)

# Mutate party labels
data <- data %>%
  mutate(party_factor = factor(
    party,
    levels = c("R", "D", "I"),
    labels = c(1, 0, 3)
  ))

# Reorder and mutate ideology_cluster from left -> right
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

# Step 3: Merging the Datasets
merged_data <- shape_data %>%
  inner_join(data, by = c("GEOID" = "geoid")) # Adjust the column names as per your data

# Add centroids to the data
merged_data$geometry_centroid <- st_centroid(merged_data$geometry)

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
    max_median_income = max(median_income, na.rm = TRUE),
    min_median_ideology = min(ideology, na.rm = TRUE),
    max_median_ideology = max(ideology, na.rm = TRUE)
  )

# Create legend breaks based on the minimum and maximum values
create_breaks <- function(min_val, max_val) {
  breaks = exp(seq(log(min_val), log(max_val), length.out = 6))
  return(round(breaks, 0))
}
# Political ideologies in the US. Congress
plot0 <- ggplot(merged_data) +
  geom_sf(aes(fill = ideology_cluster)) +
  geom_text(
    aes(
      label = paste0(state, sprintf("%02d", district)),
      x = st_coordinates(geometry_centroid)[, 1],
      y = st_coordinates(geometry_centroid)[, 2]
    ),
    size = 1.5,
    check_overlap = TRUE
  ) +
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
    guides(fill = guide_legend(keyheight = unit(1.5, "lines"), label.position = "bottom", label.size = 6))
  ) +
  labs(title = "(A) 116th Congressional \nDistricts Ideologies") +
  theme(
    text = element_text(color = "#22211d"),
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
    legend.text = element_text(size = 10, color = "blue"),  # Adjust size and color here
    legend.title = element_text(size = 10)  # Adjusting legend title size
  ) +
  coord_sf()

`# Plot 1: Choropleth Urban Population
plot1 <- ggplot(merged_data) +
  geom_sf(aes(fill = cd_urban_pop_ratio)) +
  geom_text(
    aes(
      label = paste0(state, sprintf("%02d", district)),
      x = st_coordinates(geometry_centroid)[, 1],
      y = st_coordinates(geometry_centroid)[, 2]
    ),
    size = 1,
    check_overlap = TRUE
  ) +
  theme_void() +
  scale_fill_viridis(
    trans = "log",
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

# Plot 2: Median Broadband Download Speed
plot2 <- ggplot(merged_data) +
  geom_sf(aes(fill = avgmaxaddown..cd.)) +
  geom_text(
    aes(
      label = paste0(state, sprintf("%02d", district)),
      x = st_coordinates(geometry_centroid)[, 1],
      y = st_coordinates(geometry_centroid)[, 2]
    ),
    size = 2,
    check_overlap = TRUE
  ) +
  theme_void() +
  scale_fill_viridis(
    trans = "log",
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

# Plot 3: Advanced Broadband Technology
plot3 <- ggplot(merged_data) +
  geom_sf(aes(fill = percentage_adv_tech..cd.)) +
  geom_text(
    aes(
      label = paste0(state, sprintf("%02d", district)),
      x = st_coordinates(geometry_centroid)[, 1],
      y = st_coordinates(geometry_centroid)[, 2]
    ),
    size = 2,
    check_overlap = TRUE
  ) +
  theme_void() +
  scale_fill_viridis(
    trans = "log",
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
  labs(title = "(D) Advanced Broadband Technology\n (DOCSIS 3.0, 3.1, and Fiber)") +
  theme(
    text = element_text(color = "#22211d"),
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

# Plot 4: Adult Age 25+ High School Education
plot4 <- ggplot(merged_data) +
  geom_sf(
    aes(fill = X2014_2018_acs_educational_attainment_among_adults_25._and_median_household_income_high_school_or_greater)
  ) +
  geom_text(
    aes(
      label = paste0(state, sprintf("%02d", district)),
      x = st_coordinates(geometry_centroid)[, 1],
      y = st_coordinates(geometry_centroid)[, 2]
    ),
    size = 2,
    check_overlap = TRUE
  ) +
  theme_void() +
  scale_fill_viridis(
    trans = "log",
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
  labs(title = "(E) Adult Age 25+ High School Education") +
  theme(
    text = element_text(color = "#22211d"),
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

# Plot 5: Median Income
plot5 <- ggplot(merged_data) +
  geom_sf(aes(fill = median_income)) +
  geom_text(
    aes(
      label = paste0(state, sprintf("%02d", district)),
      x = st_coordinates(geometry_centroid)[, 1],
      y = st_coordinates(geometry_centroid)[, 2]
    ),
    size = 2,
    check_overlap = TRUE
  ) +
  theme_void() +
  scale_fill_viridis(
    trans = "log",
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

# Panel all the plots
arranged_plots <- ggarrange(plot0,
                            plot1,
                            plot2,
                            plot3,
                            plot4,
                            plot5,
                            nrow = 3,
                            ncol = 2,
                            widths = c(1, 1, 1), 
                            heights = c(1, 1))

print(arranged_plots)

path_out = file.path(folder, 'figures', 'choropleth.png')

ggsave(path_out,
       arranged_plots,
       width = 12,
       height = 8)

# Panel all the plots
arranged_plots <- ggarrange(plot0,
                            plot1,
                            nrow = 1,
                            ncol = 2,
                            widths = c(1, 1, 1), 
                            heights = c(1, 1))
print(arranged_plots)
