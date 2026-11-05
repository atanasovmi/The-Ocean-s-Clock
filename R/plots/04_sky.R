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

# A small moonlight key, built from the same colours as the sky.
sky_colours <- c(night, "#16324A", "#3C6684", "#93B2BF", "#E9E3CF")
sky_key <- tibble(left = -13.55 + 0.55 * 0:4, colour = sky_colours)

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
  annotate("text", x = 11.5, y = 8.1, hjust = 0, family = font_label, size = pts(16),
           colour = moon, label = "Moonrise") +
  annotate("text", x = 11.5, y = 7.35, hjust = 0, family = font_note, size = pts(14),
           colour = soft, lineheight = 1.05,
           label = sprintf("Median of reefs:\n+%.0f min per night", stats[["moonrise_delay_minutes_per_night"]])) +
  annotate("segment", x = 11.2, xend = 10.15, y = 4.6, yend = 2.25, colour = soft, linewidth = 0.35) +
  annotate("text", x = 11.5, y = 5.25, hjust = 0, family = font_label, size = pts(16),
           colour = moon, label = "Spawning start") +
  annotate("text", x = 11.5, y = 4.2, hjust = 0, family = font_note, size = pts(14),
           colour = soft, lineheight = 1.05,
           label = sprintf("Linear fit to dots:\n+%.0f min per night,\nalmost constant", stats[["start_drift_minutes_per_night"]])) +
  # Moonlight key in the dark corner, where nothing else is drawn.
  plot_note(-14.6, 7.95, "Moonlight at the reef") +
  plot_note(-14.6, 7.3, "None") +
  annotate("rect", xmin = sky_key$left, xmax = sky_key$left + 0.5, ymin = 7.14, ymax = 7.46,
           fill = sky_key$colour, colour = rule, linewidth = 0.25) +
  plot_note(-10.65, 7.3, "Strongest") +
  plot_note(-1.6, 7.2, "Around full moon,\nmoonlight fills the night", hjust = 0.5, colour = night, size = 14) +
  plot_note(8.6, 4.8, "Dark interval:\nsunset to moonrise", hjust = 0.5, size = 14) +
  plot_note(-16.5, 8.72, "Time after sunset") +
  # One real dot stands in as the key.
  plot_note(-14.6, 3.95, "Each dot: one coral genus\nstarting to spawn on one night") +
  note_line(-12, 3.42, -12, 3.05) +
  moon_phase_row(c(-14.77, -7.38, 0, 7.38, 14.77), y = top_hour + 0.5, width = 0.78, height = 0.66) +
  plot_note(-14.1, top_hour + 0.5, "New moon", size = 14) +
  plot_note(14.1, top_hour + 0.5, "New moon", hjust = 1, size = 14) +
  scale_fill_gradientn(colours = sky_colours, guide = "none") +
  scale_x_continuous(breaks = c(-14, -7, 0, 7, 14),
                     labels = c("−14", "−7", "Full moon", "+7", "+14"), expand = c(0, 0)) +
  scale_y_continuous(breaks = seq(0, 8, 2), labels = c("Sunset", paste0("+", seq(2, 8, 2), " h")),
                     expand = c(0, 0)) +
  coord_cartesian(xlim = c(-15, 14.9), ylim = c(0, top_hour), clip = "off") +
  labs(title = "Spawning keeps to the Sun, whatever the Moon is doing",
       subtitle = sprintf("Moonrise shifts %.0f minutes later every night, yet spawning stays about %s after sunset.\nAfter full moon, %.0f%% of starts fall in the dark interval between sunset and moonrise.",
                          stats[["moonrise_delay_minutes_per_night"]], clock_text(stats[["median_start_hours"]]),
                          100 * stats[["share_moon_down_after_full"]]),
       x = "Days from full moon", y = NULL,
       caption = sprintf("Moonlight: lit share of the Moon × its height. %d starts on %d spawning nights at %d reef sites, spread sideways so the dots stay visible.\nTrend with genus controlled: +%.1f min per night (95%% CI %.1f to %.1f). Starts vary %.1f times less around sunset than around moonrise. Moon formula checked against NASA. Data: Baird et al. (2021).",
                         nrow(starts), n_distinct(paste(starts$subsite_id, starts$date)), n_distinct(starts$subsite_id),
                         stats[["start_drift_minutes_per_night"]], stats[["start_drift_low"]], stats[["start_drift_high"]],
                         stats[["sd_from_moonrise_hours"]] / stats[["sd_from_sunset_hours"]])) +
  theme_plot() +
  theme(plot.subtitle = element_text(margin = margin(b = 42)))

save_plot(sky_plot, "04_sky")
write_csv(select(starts, subsite_id, date, genus, lunar_day, hours_after_sunset, moonrise_hours, moon_deg),
          "outputs/tables/04_sky.csv")
