# A spatial and temporal join: exact event dates against a sampled 2016 temperature cycle.
source("R/style.R")
sst <- read_csv("data/derived/sst_daily.csv", show_col_types = FALSE)
events <- read_csv("data/derived/sst_events.csv", show_col_types = FALSE)

# Map month/day onto a common non-leap reference year. Leap day is omitted only
# from this visual alignment; it remains in the raw daily data and event joins.
annual_position <- function(date) {
  as.numeric(as.Date(paste0("2001-", format(date, "%m-%d"))) - as.Date("2001-01-01")) + 1
}
sst <- sst |> filter(format(date, "%m-%d") != "02-29") |>
  mutate(year = as.integer(format(date, "%Y")), day = annual_position(date))
events <- events |> filter(format(date, "%m-%d") != "02-29") |>
  mutate(day = annual_position(date))
coverage <- sst |> group_by(site) |>
  summarise(n_years = n_distinct(year), first_year = min(year), last_year = max(year), .groups = "drop") |>
  left_join(events |> count(site, name = "n_events"), by = "site") |>
  mutate(label = paste0(site, "  |  ", n_events, " recorded reef-nights · 2016"))
sst <- sst |> left_join(select(coverage, site, label), by = "site")
events <- events |> left_join(select(coverage, site, label), by = "site")
reference_cycle <- sst |> filter(monthly_reference)
month_days <- as.numeric(as.Date(paste0("2001-", sprintf("%02d", 1:12), "-01")) - as.Date("2001-01-01")) + 1

thermal_plot <- ggplot(reference_cycle, aes(day, sst_c)) +
  geom_line(colour = ocean, linewidth = 1) +
  geom_point(colour = ocean, size = 1.5) +
  geom_point(data = events, shape = 21, fill = coral, colour = paper, stroke = 0.6, size = 2.8) +
  facet_wrap(~label, ncol = 1) +
  scale_x_continuous(breaks = month_days, labels = month.abb, expand = expansion(mult = c(0.01, 0.01))) +
  labs(title = "Different reefs, different thermal seasons",
       subtitle = "A 2016 case study: exact spawning dates alongside first-of-month temperature samples",
       x = NULL, y = "Sea-surface temperature (°C)",
       caption = paste(source_coral, "Temperature: NOAA OISST v2.1 via NOAA NCEI.\nOrange dots: recorded reef-nights at their exact date-matched SST. Teal points: the first of each month;\nconnecting lines guide the eye and do not reconstruct daily temperatures. One selected subsite per site, year 2016 only.\nGridded surface temperature is environmental context, not coral-depth measurement or evidence of a causal trigger.")) +
  theme_clock() + theme(panel.spacing = grid::unit(1.2, "lines"), panel.grid.minor = element_blank())
save_figure(thermal_plot, "06_thermal_seasons", height = 11)
write_csv(reference_cycle, "outputs/tables/06_temperature_cycles.csv")
write_csv(events, "outputs/tables/06_temperature_events.csv")

# One visual integrates calendar season, lunar timing and temperature.
fingerprint <- ggplot(events, aes(day, lunar_day, colour = sst_c)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = coral, linewidth = 0.5) +
  geom_point(shape = 21, aes(fill = sst_c), size = 3, colour = ink, stroke = 0.3, alpha = 0.85) +
  facet_wrap(~label, ncol = 1) +
  scale_fill_viridis_c(option = "C", begin = 0.05, end = 0.9, name = "SST (°C)") +
  scale_colour_viridis_c(option = "C", begin = 0.05, end = 0.9, guide = "none") +
  scale_x_continuous(limits = c(1, 365), breaks = month_days, labels = month.abb) +
  scale_y_continuous(limits = c(-15.5, 14.5), breaks = c(-15, -7, 0, 7, 14)) +
  labs(title = "The ocean's clock has more than one hand",
       subtitle = "Every dot connects a reef location, an observed date, a lunar offset and a temperature grid cell",
       x = NULL, y = "Days before / after nearest local full moon",
       caption = paste(source_coral, "Temperature: NOAA OISST v2.1 via NOAA NCEI.\nOne dot per recorded subsite-date in 2016. Lunar offsets are supplied by the coral database;\nindependent USNO checks are documented separately. Coincident dots can overlap. This is a descriptive integration, not a spawning forecast.")) +
  theme_clock()
save_figure(fingerprint, "08_integrated_clock", height = 10)
write_csv(events, "outputs/tables/08_integrated_clock.csv")
