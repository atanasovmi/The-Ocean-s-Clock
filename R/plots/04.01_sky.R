# Plot 4.01, a second version of R/plots/04_sky.R.
# Same data as plot 4, drawn as real evenings: one row per night after full moon, time
# running left to right from sunset. The Moon sits where it rises that night.
source("R/plots/style.R")

first_night <- -2
last_night <- 11
last_hour <- 9
fine_hours <- seq(0, last_hour, by = 0.02)

sky <- read_csv("data/derived/sky_grid.csv", show_col_types = FALSE) |>
  filter(between(lunar_day, first_night, last_night), hours_after_sunset <= last_hour) |>
  # Square root, because the eye judges brightness on a compressed scale.
  mutate(sky_brightness = sqrt(moonlight)) |>
  # The grid has a value every 6 minutes; finer steps stop the sky showing as bands.
  reframe(sky_brightness = approx(hours_after_sunset, sky_brightness, xout = fine_hours, rule = 2)$y,
          hours_after_sunset = fine_hours, .by = lunar_day)
moonrise <- read_csv("data/derived/moonrise_curve.csv", show_col_types = FALSE) |>
  # Before full moon the Moon rises before sunset, so those rows have no moonrise to mark.
  filter(between(lunar_day, 0, last_night))
all_starts <- read_csv("data/derived/genus_starts.csv", show_col_types = FALSE)
stats <- read_statistics("outputs/tables/sky_statistics.csv")
# The control for the caption: same reefs and clock times, on the recorded date and around it.
moon_calendar <- read_csv("outputs/tables/moon_calendar.csv", show_col_types = FALSE)
moon_down_on_date <- moon_calendar$share_below[moon_calendar$shift_days == 0]
moon_down_elsewhere <- mean(moon_calendar$share_below[moon_calendar$shift_days != 0])

# Dots spread up and down inside their own row only. Their time is never moved.
set.seed(4)
starts <- all_starts |>
  filter(between(lunar_day, first_night, last_night)) |>
  mutate(row = lunar_day + runif(n(), -0.3, 0.3))

# One bar per night: the middle 50% of that night's starts. Single dots mix many genera
# and reefs and look like noise; the bars show what stays the same from night to night.
night_spread <- starts |>
  summarise(n = n(), q25 = quantile(hours_after_sunset, 0.25), q75 = quantile(hours_after_sunset, 0.75),
            .by = lunar_day) |>
  # A middle 50% of fewer than 8 starts says little, so those nights keep only their dots.
  filter(n >= 8)

usual_hour <- stats[["median_start_hours"]]
clock_text <- function(hours) sprintf("%d h %02d", floor(hours), round(60 * (hours %% 1)))

# The subtitle says the usual hour turns dark at night +3 and that nights +3 to +6 are
# the busiest, so check both against the data.
moon_up_at_usual_hour <- read_csv("data/derived/sky_grid.csv", show_col_types = FALSE) |>
  filter(abs(hours_after_sunset - usual_hour) <= 0.15) |>
  summarise(moon_up = mean(moon_up_share), .by = lunar_day)
moon_up_on <- function(night) moon_up_at_usual_hour$moon_up[moon_up_at_usual_hour$lunar_day == night]
busiest_nights <- count(all_starts, lunar_day, sort = TRUE) |> slice_head(n = 4) |> pull(lunar_day)
stopifnot(moon_up_on(1) > 0.9, moon_up_on(3) < 0.1, setequal(busiest_nights, 3:6))
peak_share <- mean(between(all_starts$lunar_day, 3, 6))

# The Moon at each moonrise, with the phase of that night ----
icon_width <- 0.2      # hours
icon_height <- 0.86    # rows
circle <- seq(0, 2 * pi, length.out = 50)
moon_discs <- bind_rows(lapply(seq_len(nrow(moonrise)), function(i) {
  tibble(id = i, x = moonrise$moonrise_hours[i] + icon_width / 2 * cos(circle),
         y = moonrise$lunar_day[i] + icon_height / 2 * sin(circle))
}))
moon_lit <- bind_rows(lapply(seq_len(nrow(moonrise)), function(i) {
  moon_icon(moonrise$moonrise_hours[i], moonrise$lunar_day[i], moonrise$lunar_day[i],
            icon_width, icon_height, id = i)
}))

# The key sits below the hour labels, outside the sky. Its marks match the plot.
key_y <- 13.2
key_moon_disc <- tibble(x = 4.3 + icon_width / 2 * cos(circle), y = key_y + icon_height / 2 * sin(circle))
key_moon_lit <- moon_icon(4.3, key_y, 5, icon_width, icon_height, id = 1)

# One real dot stands in as the key.
key_dot <- starts |> filter(lunar_day == last_night) |> slice_max(hours_after_sunset, n = 1, with_ties = FALSE)

sky_colours <- c(night, "#16324A", "#3C6684", "#93B2BF", "#E9E3CF")
sky_range <- range(sky$sky_brightness)
night_labels <- c("−2", "−1", "Full moon", paste0("+", 1:last_night))

evenings_plot <- ggplot(sky, aes(hours_after_sunset, lunar_day)) +
  geom_tile(aes(fill = sky_brightness), width = 0.024, height = 0.86, linewidth = 0) +
  annotate("segment", x = usual_hour, xend = usual_hour, y = first_night - 0.5, yend = last_night + 0.5,
           colour = moon, linewidth = 0.4) +
  geom_polygon(data = moon_discs, aes(x, y, group = id), inherit.aes = FALSE, fill = "#1F3549",
               colour = night, linewidth = 0.3) +
  geom_polygon(data = moon_lit, aes(x, y, group = id), inherit.aes = FALSE, fill = moon) +
  # Dots go last, so no moon hides a record.
  geom_point(data = starts, aes(hours_after_sunset, row), inherit.aes = FALSE, shape = 21, size = 1.7,
             stroke = 0.2, fill = spawn, colour = night, alpha = 0.6) +
  geom_segment(data = night_spread, aes(q25, lunar_day, xend = q75, yend = lunar_day), inherit.aes = FALSE,
               colour = night, linewidth = 3.4, lineend = "round") +
  geom_segment(data = night_spread, aes(q25, lunar_day, xend = q75, yend = lunar_day), inherit.aes = FALSE,
               colour = moon, linewidth = 1.8, lineend = "round") +
  # The two things to compare, named at the top of the column and beside the moons.
  plot_note(usual_hour, first_night - 0.95, sprintf("Spawning: about %s after sunset, every night", clock_text(usual_hour)),
            hjust = 0, colour = moon, size = 14) +
  plot_note(4.05, 9, sprintf("Moonrise: %.0f min later every night", stats[["moonrise_delay_minutes_per_night"]]),
            colour = moon, size = 14) +
  note_line(6.4, 9, 6.98, 9) +
  plot_note(key_dot$hours_after_sunset + 0.32, key_dot$row, "Each dot: one coral genus starting to spawn on one night") +
  note_line(key_dot$hours_after_sunset + 0.07, key_dot$row, key_dot$hours_after_sunset + 0.27, key_dot$row) +
  plot_note(-0.62, first_night - 0.95, "Nights from full moon") +
  # What is not obvious in the sky itself, written on the rows it belongs to.
  plot_note(3.6, -1, "Before full moon, the Moon is already up at sunset", colour = night, size = 13) +
  plot_note(3.6, 2, "The Moon reaches the spawning hour. From the next night, that hour is dark.",
            colour = night, size = 13) +
  # The busiest nights, marked in the margin beside the night labels.
  note_line(-0.28, 2.6, -0.28, 6.4) +
  plot_note(-0.31, 4.5, sprintf("%.0f%%
of
starts", 100 * peak_share), hjust = 1, size = 12) +
  # Key
  annotate("segment", x = -0.6, xend = -0.34, y = key_y, yend = key_y, colour = moon, linewidth = 1.8,
           lineend = "round") +
  plot_note(-0.27, key_y, "Middle 50% of that night’s starts (nights with 8+ starts)", size = 13) +
  annotate("segment", x = 3.05, xend = 3.05, y = key_y - 0.34, yend = key_y + 0.34, colour = moon, linewidth = 0.4) +
  plot_note(3.12, key_y, "Median start", size = 13) +
  geom_polygon(data = key_moon_disc, aes(x, y), inherit.aes = FALSE, fill = "#1F3549") +
  geom_polygon(data = key_moon_lit, aes(x, y), inherit.aes = FALSE, fill = moon) +
  plot_note(4.45, key_y, "Moon at moonrise, in that night’s phase", size = 13) +
  scale_fill_gradientn(colours = sky_colours, limits = sky_range, name = "Moonlight at the reef",
                       breaks = sky_range[1] + diff(sky_range) * c(0.07, 0.86),
                       labels = c("None", "Strongest"),
                       guide = guide_colourbar(direction = "horizontal", barwidth = unit(170, "pt"),
                                               barheight = unit(9, "pt"), title.position = "top",
                                               ticks = FALSE)) +
  scale_x_continuous(breaks = 0:last_hour, labels = c("Sunset", paste0("+", 1:last_hour, " h")),
                     expand = c(0, 0)) +
  scale_y_reverse(breaks = first_night:last_night, labels = night_labels, expand = c(0, 0)) +
  coord_cartesian(xlim = c(-0.06, last_hour), ylim = c(last_night + 0.5, first_night - 0.5), clip = "off") +
  labs(title = "The Sun fixes the hour, the Moon decides when it goes dark",
       subtitle = sprintf("Each row is one evening. The Moon rises later every night, but corals keep their hour.\nThey peak on nights +3 to +6 (%.0f%% of starts), the first evenings when that hour is dark.",
                          100 * peak_share),
       x = NULL, y = NULL,
       caption = sprintf("A pattern, not proof of a trigger: people also chose which nights to watch. At the same reefs and clock times the Moon is down for %.0f%% of starts, against %.0f%% on the 28 surrounding dates.
%d of %d timed starts shown, %d reef sites. Sky and moonrise: typical values across those reefs. Start time against night, genus controlled: +%.1f min per night (95%% CI %.1f to %.1f). Data: Baird et al. (2021).",
                         100 * moon_down_on_date, 100 * moon_down_elsewhere,
                         nrow(starts), nrow(all_starts), n_distinct(all_starts$subsite_id),
                         stats[["start_drift_minutes_per_night"]], stats[["start_drift_low"]], stats[["start_drift_high"]])) +
  theme_plot() +
  theme(axis.ticks.y = element_blank(),
        plot.subtitle = element_text(margin = margin(b = 34)),
        plot.caption = element_text(margin = margin(t = 40)),
        legend.position = "inside", legend.position.inside = c(1, 1.045),
        legend.justification.inside = c(1, 0), legend.title = element_text(hjust = 0),
        legend.ticks = element_blank(),
        legend.frame = element_rect(colour = rule, linewidth = 0.3, fill = NA))

save_plot(evenings_plot, "04.01_sky")
write_csv(select(night_spread, lunar_day, n, q25, q75), "outputs/tables/04.01_sky.csv")
