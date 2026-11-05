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

season_plot <- ggplot(field, aes(day_step, latitude_band)) +
  geom_raster(aes(fill = warming_c_per_month), interpolate = TRUE) +
  geom_hline(yintercept = 0, colour = moon, linewidth = 0.3, alpha = 0.5) +
  geom_point(data = nights, aes(day_of_year, latitude),
             position = position_jitter(width = 0, height = 0.45, seed = 2),
             shape = 21, size = 1.75, stroke = 0.2, fill = spawn, colour = night) +
  annotate("text", x = 4, y = 1.2, hjust = 0, vjust = 0, family = font_note, size = pts(13),
           colour = moon, label = "Equator") +
  geom_text(data = place_labels, aes(day, latitude, label = label, hjust = hjust),
            family = font_label, size = pts(14.5), colour = moon) +
  scale_fill_gradient2(low = water, mid = "#12283B", high = warm_gold, midpoint = 0,
                       limits = c(-2.2, 2.2), oob = scales::squish, breaks = c(-2, 0, 2),
                       labels = c("−2 °C", "0", "+2 °C"), name = "Sea temperature change per month",
                       guide = guide_colourbar(barwidth = unit(170, "pt"), barheight = unit(9, "pt"),
                                               title.position = "top", ticks = FALSE)) +
  scale_x_continuous(breaks = month_middles, labels = month.abb, expand = c(0, 0)) +
  scale_y_continuous(breaks = c(-30, -15, 0, 15, 30),
                     labels = c("30° S", "15° S", "0°", "15° N", "30° N"), expand = c(0, 0)) +
  coord_cartesian(xlim = c(1, 365), ylim = c(-33, 35)) +
  labs(title = "Both hemispheres spawn while the water warms",
       subtitle = sprintf("Their calendar months are about half a year apart, but their place on the temperature\ncurve is the same: %.0f%% of reef-nights fall while the local sea warms, just %.0f%% of the year.",
                          100 * share_warming, 100 * share_of_year),
       x = NULL, y = NULL,
       caption = sprintf("Each dot: one recorded reef-night (%s, 1978–2019). Backdrop: 39-year mean warming rate by latitude band, 214 NOAA regions. Warming share from the %s nights inside NOAA regions.\nPeople look for spawning when they expect it, so quiet months are under-recorded. Sources: Baird et al. (2021), NOAA Coral Reef Watch.",
                         format(nrow(nights), big.mark = ","), format(nrow(seasons), big.mark = ","))) +
  theme_plot() +
  theme(axis.ticks.x = element_blank(), legend.position = "top", legend.justification = "right",
        legend.margin = margin(t = -44, b = 8), legend.title = element_text(hjust = 0),
        plot.subtitle = element_text(margin = margin(b = 8)))

save_plot(season_plot, "02_season")
write_csv(select(seasons, subsite_id, date, station_id, days_from_peak, warming_c_per_month, warming),
          "outputs/tables/02_season.csv")
