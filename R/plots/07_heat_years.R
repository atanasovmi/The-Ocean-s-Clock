# Plot 7. How has heat stress changed across the world's reef regions?
# Every one of the 214 NOAA regions in every year, instead of one summary line.
source("R/plots/style.R")
library(patchwork)

annual <- read_csv("data/derived/regional_annual.csv", show_col_types = FALSE) |>
  filter(between(year, 1986, 2024), complete_year)
groups <- read_csv("data/derived/region_display_groups.csv", show_col_types = FALSE) |>
  # Three regions are listed under two groups; the first one decides their row.
  mutate(ocean = sub(" \\|.*", "", display_group))
stopifnot(nrow(annual) == 214 * 39, !anyDuplicated(groups$station_id))

# Row order: ocean regions, then north to south inside each one.
ocean_order <- c("Atlantic", "Indian Ocean", "Southeast Asia", "Australia", "Pacific")
region_rows <- annual |>
  distinct(station_id, marker_latitude) |>
  left_join(select(groups, station_id, ocean), by = "station_id", relationship = "one-to-one") |>
  mutate(ocean = factor(ocean, levels = ocean_order)) |>
  arrange(ocean, desc(marker_latitude)) |>
  # A six-row gap between oceans keeps them readable as blocks.
  mutate(row = -(row_number() + 6 * (as.integer(ocean) - 1)))
stopifnot(!anyNA(region_rows$ocean))

# Degree heating weeks in classes, named in words and numbers for the legend.
# 4 and 8 are NOAA's bleaching-risk thresholds.
dhw_classes <- c("None <1", "Low 1–4", "High 4–8", "Severe 8–12", "Very severe 12–16", "Extreme 16+")
plot_data <- annual |>
  left_join(region_rows, by = c("station_id", "marker_latitude"), relationship = "many-to-one") |>
  mutate(dhw_class = cut(max_dhw_c_weeks, c(-Inf, 1, 4, 8, 12, 16, Inf),
                         labels = dhw_classes, right = FALSE))

severe_by_year <- annual |>
  summarise(n_regions = n(), n_severe = sum(max_dhw_c_weeks >= 8), .by = year) |>
  arrange(year)
stopifnot(all(severe_by_year$n_regions == 214))
peaks <- filter(severe_by_year, year %in% c(1998, 2010, 2016, 2024))

ocean_labels <- region_rows |>
  summarise(row = mean(row), n = n(), .by = ocean) |>
  mutate(label = paste0(ocean, "\n", n, " regions"))

year_breaks <- c(1986, seq(1990, 2020, 5), 2024)
# The window reaches left of 1986 to leave room for the ocean names.
year_window <- c(1978.4, 2024.5)
share_2024 <- severe_by_year$n_severe[severe_by_year$year == 2024] / 214
first_count <- severe_by_year$n_severe[severe_by_year$year == 1986]
# A row below the panel for the note level with the year labels.
axis_row <- min(region_rows$row) - 16

# Top strip: the count of regions over the severe threshold.
count_strip <- ggplot(severe_by_year, aes(year, n_severe)) +
  geom_col(width = 0.74, fill = heat_steps[5]) +
  geom_text(data = peaks, aes(label = n_severe, y = n_severe + 7), family = font_label,
            size = pts(15), colour = moon, vjust = 0) +
  annotate("text", x = 1986, y = 150, hjust = 0, vjust = 1, family = font_note, size = pts(14),
           colour = soft, label = "Number of reef regions with severe heat each year") +
  plot_note(year_window[1], 90, "Severe heat: 8 degree\nheating weeks, such as\n2 °C above the usual\nsummer high for 4 weeks", size = 13) +
  scale_x_continuous(breaks = year_breaks, expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  coord_cartesian(xlim = year_window, ylim = c(0, 171), clip = "off") +
  labs(x = NULL, y = NULL) +
  theme_plot() +
  theme(axis.text.x = element_blank(), axis.text.y = element_blank(), axis.ticks = element_blank(),
        plot.margin = margin(6, 0, 4, 0))

stripes <- ggplot(plot_data, aes(year, row, fill = dhw_class)) +
  geom_tile(width = 1, height = 1, linewidth = 0) +
  geom_text(data = ocean_labels, aes(x = 1985.1, y = row, label = label), inherit.aes = FALSE,
            hjust = 1, family = font_note, size = pts(14), lineheight = 1.05, colour = soft) +
  scale_x_continuous(breaks = year_breaks, expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_fill_manual(values = heat_steps, drop = FALSE,
                    name = "Peak degree heating weeks of the year") +
  # Fixed limits: the notes below sit outside the rows and must not stretch the panel.
  coord_cartesian(xlim = year_window, ylim = c(min(region_rows$row) - 0.5, max(region_rows$row) + 0.5),
                  clip = "off") +
  plot_note(year_window[1], axis_row, "Each line: one region") +
  guides(fill = guide_legend(nrow = 1, keywidth = unit(34, "pt"), keyheight = unit(10, "pt"),
                             label.position = "bottom")) +
  labs(x = NULL, y = NULL) +
  theme_plot() +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(),
        legend.position = "bottom", legend.justification = "right",
        legend.margin = margin(t = 2), legend.title = element_text(margin = margin(r = 12), vjust = 0.9),
        legend.key = element_rect(colour = rule, linewidth = 0.3),
        legend.key.spacing.x = unit(8, "pt"),
        plot.margin = margin(0, 0, 0, 0))

heat_plot <- count_strip / stripes +
  plot_layout(heights = c(1, 4.6)) +
  plot_annotation(
    title = "In 2024, four in five reef regions crossed the severe heat line",
    subtitle = sprintf("In 1986 it was just %d of 214 regions. Each line is one region, each column one year. The brighter, the hotter.\nThe peaks of 1998, 2010, 2016 and 2024 each followed an El Niño, when the Pacific heats up.",
                       first_count),
    caption = "214 NOAA Coral Reef Watch regions, 1986–2024, each counted once whatever its reef area. Degree heating weeks add up heat above the usual summer high over 12 weeks. Heat stress is not coral death.",
    theme = theme_plot() + theme(plot.subtitle = element_text(margin = margin(b = 10)))
  )
stopifnot(round(share_2024, 1) == 0.8)

save_plot(heat_plot, "07_heat_years")
write_csv(severe_by_year, "outputs/tables/07_heat_years.csv")
