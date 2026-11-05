# Plot 4. Which clock sets the hour: the Sun or the Moon?
# Each lunar night is a column; hours after sunset run upward. The shading is the
# moonlight those same reefs had, so the dots sit in the sky they actually had.
source("R/plots/style.R")

sky <- read_csv("data/derived/sky_grid.csv", show_col_types = FALSE)
moonrise <- read_csv("data/derived/moonrise_curve.csv", show_col_types = FALSE) |>
  filter(between(lunar_day, 0, 11))
starts <- read_csv("data/derived/genus_starts.csv", show_col_types = FALSE)
stats <- read_statistics("outputs/tables/sky_statistics.csv")

top_hour <- 9

# Square root, because the eye judges brightness on a compressed scale.
sky <- sky |>
  filter(hours_after_sunset <= top_hour + 0.2) |>
  mutate(sky_brightness = sqrt(moonlight))

# One straight line through the starts, across the nights holding nearly all of them.
start_trend <- lm(hours_after_sunset ~ lunar_day, data = filter(starts, between(lunar_day, -2, 10)))
trend_line <- tibble(lunar_day = c(-2, 10)) |>
  mutate(hours = predict(start_trend, newdata = pick(lunar_day)))

# The sky colours, from no moonlight to the strongest.
sky_colours <- c(night, "#16324A", "#3C6684", "#93B2BF", "#E9E3CF")
sky_range <- range(sky$sky_brightness)

clock_text <- function(hours) sprintf("%d h %02d", floor(hours), round(60 * (hours %% 1)))

sky_plot <- ggplot(sky, aes(lunar_day, hours_after_sunset)) +
  geom_raster(aes(fill = sky_brightness), interpolate = TRUE) +
  # The Moon's rising edge
  geom_line(data = moonrise, aes(lunar_day, moonrise_hours), colour = moon, linewidth = 0.9) +
  # The dots: position_jitter only spreads whole lunar days sideways, never the time.
  geom_point(data = starts, aes(lunar_day, hours_after_sunset),
             position = position_jitter(width = 0.3, height = 0, seed = 4),
             shape = 21, size = 2.5, stroke = 0.3, fill = spawn, colour = night) +
  geom_line(data = trend_line, aes(lunar_day, hours), colour = night, linewidth = 2.6) +
  geom_line(data = trend_line, aes(lunar_day, hours), colour = moon, linewidth = 1.1) +
  # The plot is a test, so the two lines are named as prediction and observation.
  # The rising line carries its own label, written along it in the dark sky below.
  annotate("text", x = 9.24, y = 6.17, angle = 43, family = font_note, size = pts(13.5), colour = moon,
           lineheight = 1.05,
           label = sprintf("If moonrise were the signal:
+%.0f min per night", stats[["moonrise_delay_minutes_per_night"]])) +
  annotate("segment", x = 11.2, xend = 10.15, y = 4.6, yend = 2.25, colour = soft, linewidth = 0.35) +
  annotate("text", x = 11.5, y = 5.25, hjust = 0, family = font_label, size = pts(16),
           colour = moon, label = "What we observe") +
  annotate("text", x = 11.5, y = 4.45, hjust = 0, family = font_note, size = pts(14),
           colour = soft, lineheight = 1.05,
           label = sprintf("Dots stay flat:
+%.0f min per night", stats[["start_drift_minutes_per_night"]])) +
  plot_note(-16.5, 8.72, "Time after sunset") +
  # One real dot stands in as the key.
  plot_note(-14.6, 3.95, "Each dot: one coral genus
starting to spawn on one night") +
  note_line(-12, 3.42, -12, 3.05) +
  moon_phase_row(c(-14.77, -7.38, 0, 7.38, 14.77), y = top_hour + 0.5, width = 0.78, height = 0.66) +
  plot_note(-14.1, top_hour + 0.5, "New moon", size = 14) +
  plot_note(14.1, top_hour + 0.5, "New moon", hjust = 1, size = 14) +
  scale_fill_gradientn(colours = sky_colours, limits = sky_range, name = "Moonlight at the reef",
                       breaks = sky_range[1] + diff(sky_range) * c(0.07, 0.86),
                       labels = c("None", "Strongest"),
                       guide = guide_colourbar(direction = "horizontal", barwidth = unit(170, "pt"), barheight = unit(9, "pt"),
                                               title.position = "top", ticks = FALSE)) +
  scale_x_continuous(breaks = c(-14, -7, 0, 7, 14),
                     labels = c("−14", "−7", "Full moon", "+7", "+14"), expand = c(0, 0)) +
  scale_y_continuous(breaks = seq(0, 8, 2), labels = c("Sunset", paste0("+", seq(2, 8, 2), " h")),
                     expand = c(0, 0)) +
  coord_cartesian(xlim = c(-15, 14.9), ylim = c(0, top_hour), clip = "off") +
  labs(title = "Spawning keeps to the Sun, whatever the Moon is doing",
       subtitle = sprintf("Does moonrise tell corals when to spawn? If it did, the dots would climb with the line.\nInstead they stay flat, about %s after sunset, on almost every night.",
                          clock_text(stats[["median_start_hours"]])),
       x = "Days from full moon", y = NULL,
       caption = sprintf("Dots are nudged sideways so they stay visible. Rising line: median moonrise across reefs. Flat line: linear fit to the dots. Moonlight: lit share of the Moon × its height.\n%d starts, %d spawning nights, %d reef sites. Trend with genus controlled: +%.1f min per night (95%% CI %.1f to %.1f). Starts vary %.1f times less around sunset than around moonrise. Data: Baird et al. (2021).",
                         nrow(starts), n_distinct(paste(starts$subsite_id, starts$date)), n_distinct(starts$subsite_id),
                         stats[["start_drift_minutes_per_night"]], stats[["start_drift_low"]], stats[["start_drift_high"]],
                         stats[["sd_from_moonrise_hours"]] / stats[["sd_from_sunset_hours"]])) +
  theme_plot() +
  # The legend sits above the panel, beside the subtitle, so nothing covers the sky.
  # An inside position with a value above 1 keeps it out of the layout, so the panel stays put.
  theme(plot.subtitle = element_text(margin = margin(b = 42)),
        legend.position = "inside", legend.position.inside = c(1, 1.105),
        legend.justification.inside = c(1, 0), legend.title = element_text(hjust = 0), legend.ticks = element_blank(),
        legend.frame = element_rect(colour = rule, linewidth = 0.3, fill = NA))

save_plot(sky_plot, "04_sky")
write_csv(select(starts, subsite_id, date, genus, lunar_day, hours_after_sunset, moonrise_hours, moon_deg),
          "outputs/tables/04_sky.csv")
