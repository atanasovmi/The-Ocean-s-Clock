# Plot 2. What does the year clock follow?
# The backdrop shows when the sea warms and cools at each latitude, from all 214
# NOAA regions. Every dot is a recorded reef-night at its own date and latitude.
source("R/plots/style.R")

field <- read_csv("data/derived/warming_field.csv", show_col_types = FALSE)
nights <- read_csv("data/derived/reef_nights.csv", show_col_types = FALSE) |>
  mutate(day_of_year = as.integer(format(date, "%j")))
seasons <- read_csv("data/derived/reef_night_seasons.csv", show_col_types = FALSE)

warm_gold <- "#E3B54A"
share_warming <- mean(seasons$warming)
share_of_year <- mean(seasons$warming_share_of_year)

# How much of each hemisphere's spawning sits in its own season, for the two brackets.
spawn_month <- as.integer(format(nights$date, "%m"))
share_north <- mean(spawn_month[nights$latitude > 15] %in% 4:8)
share_south <- mean(spawn_month[nights$latitude < -10] %in% 10:12)

month_starts <- as.integer(format(as.Date(sprintf("2023-%02d-01", 1:12)), "%j"))
month_middles <- month_starts + c(diff(month_starts), 31) / 2

# Kochi and Shikoku lie just north of the last NOAA band. That band is repeated
# once so their dots still have a backdrop.
field <- bind_rows(field, filter(field, latitude_band == max(latitude_band)) |>
                     mutate(latitude_band = latitude_band + 2.5))

# Names make the two hemispheres concrete. Positions sit just beyond each cluster.
place_labels <- tribble(
  ~day, ~latitude, ~label, ~hjust,
  252, 33, "Kochi", 0,
  255, 29.6, "Eilat", 0,
  251, 26.2, "Okinawa", 0,
  92, 22.3, "Taiwan", 1,
  125, 1.3, "Singapore", 0,
  351, -18.3, "Fiji", 0,
  285, -14.6, "Great Barrier Reef", 0.5
)

# A faint bracket marking a stretch of the year at one latitude. Its label sits in a
# gap in the middle of the line, because dots lie just above and below it.
season_bracket <- function(from, to, latitude, label) {
  faint_moon <- scales::alpha(moon, 0.45)
  middle <- (from + to) / 2
  gap <- 35
  tick <- 0.9
  list(note_line(from, latitude, middle - gap, latitude, colour = faint_moon),
       note_line(middle + gap, latitude, to, latitude, colour = faint_moon),
       note_line(from, latitude, from, latitude + tick, colour = faint_moon),
       note_line(to, latitude, to, latitude + tick, colour = faint_moon),
       plot_note(middle, latitude, label, hjust = 0.5, size = 12))
}

season_plot <- ggplot(field, aes(day_step, latitude_band)) +
  geom_raster(aes(fill = warming_c_per_month), interpolate = TRUE) +
  geom_hline(yintercept = 0, colour = moon, linewidth = 0.3, alpha = 0.5) +
  geom_point(data = nights, aes(day_of_year, latitude),
             position = position_jitter(width = 0, height = 0.45, seed = 2),
             shape = 21, size = 1.75, stroke = 0.2, fill = spawn, colour = night) +
  # Text stays quiet so the dots lead: one size, one soft colour, nothing bold.
  annotate("text", x = 4, y = 1.2, hjust = 0, vjust = 0, family = font_note, size = pts(12),
           colour = soft, label = "Equator: little seasonal change") +
  geom_text(data = place_labels, aes(day, latitude, label = label, hjust = hjust),
            family = font_note, size = pts(12), colour = soft) +
  # The two seasons, about half a year apart, marked on the calendar itself.
  season_bracket(month_starts[4], month_starts[9] - 1, 18.7,
                 sprintf("North: %.0f%% spawn in Apr–Aug", 100 * share_north)) +
  season_bracket(month_starts[10], 364, -25.8,
                 sprintf("South: %.0f%% spawn in Oct–Dec", 100 * share_south)) +
  # One real dot stands in as the key.
  plot_note(6, 18.6, "Each dot: one night of
spawning on one reef", size = 12) +
  note_line(37, 15.8, 37, 13.4) +
  scale_fill_gradient2(low = water, mid = "#12283B", high = warm_gold, midpoint = 0,
                       limits = c(-2.2, 2.2), oob = scales::squish, breaks = c(-2, 0, 2),
                       labels = c("−2 °C", "No change", "+2 °C"), name = "Sea temperature change per month",
                       guide = guide_colourbar(barwidth = unit(170, "pt"), barheight = unit(9, "pt"),
                                               title.position = "top", ticks = FALSE)) +
  scale_x_continuous(breaks = month_middles, labels = month.abb, expand = c(0, 0)) +
  scale_y_continuous(breaks = c(-30, -15, 0, 15, 30),
                     labels = c("30° S", "15° S", "0°", "15° N", "30° N"), expand = c(0, 0)) +
  coord_cartesian(xlim = c(1, 365), ylim = c(-33, 35)) +
  labs(title = "Both hemispheres spawn while the water warms",
       subtitle = sprintf("A year calendar for every latitude. Gold: the sea is warming. Blue: it is cooling.\n%.0f%% of spawning nights fall while the local sea warms, just %.0f%% of the year.",
                          100 * share_warming, 100 * share_of_year),
       x = NULL, y = NULL, tag = "Latitude",
       caption = sprintf("%s spawning nights, 1978–2019, of which %s lie inside NOAA reef regions. Background colour: 39-year average from 214 regions. North: above 15° N. South: below 10° S.\nPeople look for spawning when they expect it, so quiet months are under-recorded. Sources: Baird et al. (2021), NOAA Coral Reef Watch.",
                         format(nrow(nights), big.mark = ","), format(nrow(seasons), big.mark = ","))) +
  theme_plot() +
  theme(axis.ticks.x = element_blank(), legend.position = "top", legend.justification = "right",
        legend.margin = margin(t = -44, b = 8), legend.title = element_text(hjust = 0),
        plot.subtitle = element_text(margin = margin(b = 8)),
        # A fixed tag position labels the axis without moving the panel.
        plot.tag = element_text(family = font_note, size = 12, colour = faint, angle = 90),
        plot.tag.position = c(-0.012, 0.46))

save_plot(season_plot, "02_season")
write_csv(select(seasons, subsite_id, date, station_id, days_from_peak, warming_c_per_month, warming),
          "outputs/tables/02_season.csv")
