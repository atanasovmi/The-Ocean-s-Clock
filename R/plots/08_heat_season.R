# Plot 8. Does the heat now reach the months when corals spawn?
# Same grammar as plot 7, but counted only inside each region's spawning months.
# The spawning calendar is held fixed, so this measures overlap with the heat
# record. It cannot show that spawning moved or that reproduction failed.
source("R/plots/style.R")

yearly <- read_csv("data/derived/calendar_exposure.csv", show_col_types = FALSE)
comparison <- read_csv("data/derived/decadal_exposure.csv", show_col_types = FALSE) |>
  rename(early = `1986–1995`, recent = `2015–2024`)

region_names <- c(
  northern_taiwan = "Northern Taiwan", gulf_of_aqaba = "Gulf of Aqaba",
  panama_pacific_west = "Pacific Panama", northern_philippines = "Northern Philippines",
  tromelin_reunion = "Tromelin and Réunion", sabah = "Sabah",
  gbr_central = "Central Great Barrier Reef", northern_ryukyu_islands = "Northern Ryukyu Islands",
  madinah_makkah = "Saudi Red Sea", southern_taiwan = "Southern Taiwan", fiji = "Fiji",
  hawaii = "Hawaii", singapore = "Singapore", southern_ryukyu_islands = "Southern Ryukyu Islands")

rows <- comparison |>
  arrange(desc(change), station_id) |>
  mutate(row = -row_number(), region = region_names[station_id],
         change_label = if_else(change == 0, "0", sprintf("+%.1f", 100 * change)))
stopifnot(!anyNA(rows$region), nrow(rows) == 14)

# The note on the empty rows says these regions never saw heat stress in their
# spawning months, so check that against every year.
clear_regions <- yearly |>
  summarise(peak = max(calendar_exposure), .by = station_id) |>
  filter(peak == 0)
clear_rows <- filter(rows, station_id %in% clear_regions$station_id)
stopifnot(nrow(clear_rows) == 4, all(clear_rows$change == 0))

exposure_classes <- c("none", "under 10%", "10–25%", "25–50%", "50–75%", "over 75%")
plot_data <- yearly |>
  left_join(select(rows, station_id, row), by = "station_id", relationship = "many-to-one") |>
  mutate(exposure_class = cut(calendar_exposure, c(-Inf, 0, 0.1, 0.25, 0.5, 0.75, Inf),
                              labels = exposure_classes))

# The window reaches left of 1986 and right of 2024 for the two text columns.
year_window <- c(1974.2, 2029.6)

heat_season_plot <- ggplot(plot_data, aes(year, row, fill = exposure_class)) +
  # Empty rows still need to read as rows, so each gets a faint track.
  annotate("rect", xmin = 1985.5, xmax = 2024.5, ymin = rows$row - 0.43, ymax = rows$row + 0.43,
           fill = "#10263A") +
  geom_tile(data = filter(plot_data, exposure_class != "none"),
            width = 0.94, height = 0.86, linewidth = 0) +
  geom_text(data = rows, aes(x = 1985.1, y = row, label = region), inherit.aes = FALSE,
            hjust = 1, family = font_note, size = pts(14.5), colour = soft) +
  geom_text(data = rows, aes(x = 2029.5, y = row, label = change_label), inherit.aes = FALSE,
            hjust = 1, family = font_note, size = pts(14.5), colour = moon) +
  annotate("text", x = 2029.5, y = 0.25, hjust = 1, vjust = 0, family = font_label, size = pts(13.5),
           colour = soft, lineheight = 1, label = "More of the season hit\nthan in 1986–95 (% points)") +
  plot_note(1985.1, 0.25, "Biggest rise at the top", hjust = 1, vjust = 0) +
  plot_note(2005, clear_rows$row[2], "Never hit by heat during spawning", hjust = 0.5) +
  plot_note(year_window[1], -16.6, "Each box: one year when heat hit the spawning season") +
  scale_fill_manual(values = setNames(heat_steps, exposure_classes), limits = exposure_classes[-1],
                    name = "Part of the spawning season hit by heat") +
  scale_x_continuous(breaks = c(1986, seq(1990, 2020, 5), 2024), expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  coord_cartesian(xlim = year_window, ylim = c(-14.55, 0.5), clip = "off") +
  guides(fill = guide_legend(nrow = 1, keywidth = unit(44, "pt"), keyheight = unit(10, "pt"),
                             label.position = "bottom")) +
  labs(title = "Heat now reaches the spawning months, unevenly",
       subtitle = sprintf("We kept each region’s usual spawning months and asked: does heat reach them more often now? In %d of %d regions, yes.\nIn Northern Taiwan and the Gulf of Aqaba it hits about a quarter of a typical recent season. Four regions stay clear.",
                          sum(comparison$change > 0), nrow(comparison)),
       x = NULL, y = NULL,
       caption = "Heat here means 4 or more NOAA degree heating weeks, the level where corals are likely to bleach. The right column compares 2015–24 with 1986–95.\nThis shows overlap only: it cannot show that spawning moved or failed. Sources: Baird et al. (2021), NOAA Coral Reef Watch.") +
  theme_plot() +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(),
        legend.position = "bottom", legend.justification = "right", legend.margin = margin(t = 2),
        legend.title = element_text(margin = margin(r = 12), vjust = 0.9),
        legend.key.spacing.x = unit(2, "pt"),
        plot.subtitle = element_text(margin = margin(b = 34)))

save_plot(heat_season_plot, "08_heat_season")
write_csv(select(rows, station_id, region, early, recent, change), "outputs/tables/08_heat_season.csv")
