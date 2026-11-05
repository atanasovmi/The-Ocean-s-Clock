# Plot 1. Which natural cycles hold the spawning records, and how tightly?
# Three dials, because year, lunar month and day are all circles. Each bar is a
# stretch of the cycle, and the thin circle is what an even spread would reach.
# The hand points at the typical moment; its length is the tightness.
source("R/plots/style.R")

seasons <- read_csv("data/derived/reef_night_seasons.csv", show_col_types = FALSE)
nights <- read_csv("data/derived/reef_nights.csv", show_col_types = FALSE)
starts <- read_csv("data/derived/all_exact_starts.csv", show_col_types = FALSE)
clocks <- read_csv("outputs/tables/clock_summary.csv", show_col_types = FALSE)
hours <- read_statistics("outputs/tables/sky_statistics.csv")

# Dial geometry ----
# Drawn in plain x-y coordinates, because coord_polar() allows one circle per
# panel and these dials need their own bars, ticks and labels. A "turn" is a share
# of the circle, clockwise from twelve o'clock.
dial_centres <- c(year = -2.85, moon = 0, sun = 2.85)
inner_radius <- 0.34
outer_radius <- 1

on_dial <- function(turn, radius, centre) {
  tibble(x = centre + radius * sin(2 * pi * turn), y = radius * cos(2 * pi * turn))
}

# One bar is a small ring segment: out along one edge and back along the other.
ring_bar <- function(from, to, inner, outer, centre, id) {
  edge <- seq(from, to, length.out = 6)
  bind_rows(on_dial(edge, outer, centre), on_dial(rev(edge), inner, centre)) |>
    mutate(id = id)
}

# Count records per stretch of the cycle and scale the longest bar to the dial.
dial_bars <- function(value, period, n_bars, centre, name) {
  bar <- floor((value %% period) / period * n_bars)
  shares <- tibble(bar = 0:(n_bars - 1)) |>
    left_join(count(tibble(bar = bar), bar), by = "bar") |>
    mutate(share = coalesce(n, 0L) / length(value))
  longest <- max(shares$share)
  bars <- shares |>
    filter(share > 0) |>
    mutate(reach = inner_radius + (outer_radius - inner_radius) * share / longest,
           # A sliver of the page stays between bars.
           from = (bar + 0.08) / n_bars, to = (bar + 0.92) / n_bars)
  list(polygons = bind_rows(Map(ring_bar, bars$from, bars$to, inner_radius, bars$reach, centre,
                                paste(name, bars$bar))),
       even_radius = inner_radius + (outer_radius - inner_radius) / n_bars / longest)
}

year_bars <- dial_bars(seasons$days_from_peak, 365, 36, dial_centres[["year"]], "year")
moon_bars <- dial_bars(nights$lunar_day, 29.53, 30, dial_centres[["moon"]], "moon")
sun_bars <- dial_bars(starts$hours_on_dial, 24, 72, dial_centres[["sun"]], "sun")
all_bars <- bind_rows(year_bars$polygons, moon_bars$polygons, sun_bars$polygons)

circle <- function(radius, centre, id) mutate(on_dial(seq(0, 1, length.out = 181), radius, centre), id = id)
even_rings <- bind_rows(circle(year_bars$even_radius, dial_centres[["year"]], "year"),
                        circle(moon_bars$even_radius, dial_centres[["moon"]], "moon"),
                        circle(sun_bars$even_radius, dial_centres[["sun"]], "sun"))
rims <- bind_rows(lapply(names(dial_centres), function(name) circle(1.03, dial_centres[[name]], name)))

# Ticks on the rim: months, days and hours.
dial_ticks <- function(n, centre, major_every) {
  turn <- (0:(n - 1)) / n
  long <- (0:(n - 1)) %% major_every == 0
  tibble(x = on_dial(turn, 1.03, centre)$x, y = on_dial(turn, 1.03, centre)$y,
         xend = on_dial(turn, if_else(long, 1.09, 1.06), centre)$x,
         yend = on_dial(turn, if_else(long, 1.09, 1.06), centre)$y, long = long)
}
ticks <- bind_rows(dial_ticks(12, dial_centres[["year"]], 3),
                   dial_ticks(28, dial_centres[["moon"]], 7),
                   dial_ticks(24, dial_centres[["sun"]], 6))

# Hands ----
hands <- clocks |>
  mutate(centre = dial_centres[clock],
         turn = (typical %% period) / period,
         tip_x = centre + tightness * sin(2 * pi * turn),
         tip_y = tightness * cos(2 * pi * turn))

# Labels ----
label_radius <- 1.2
compass <- function(centre, top, right, bottom, left) {
  tibble(turn = c(0, 0.25, 0.5, 0.75), label = c(top, right, bottom, left),
         hjust = c(0.5, 0, 0.5, 1), vjust = c(0, 0.5, 1, 0.5),
         x = on_dial(turn, label_radius - 0.07, centre)$x,
         y = on_dial(turn, label_radius - 0.07, centre)$y)
}
dial_labels <- bind_rows(
  compass(dial_centres[["year"]], "Warmest week", "+3 mo", "6 months away", "−3 mo"),
  compass(dial_centres[["sun"]], "Sunset", "+6 h", "About sunrise", "+18 h")
)

# Moons around the middle dial
moon_positions <- tibble(phase = c(0, 7.38, -14.77, -7.38), turn = c(0, 0.25, 0.5, 0.75)) |>
  mutate(x = on_dial(turn, 1.22, dial_centres[["moon"]])$x, y = on_dial(turn, 1.22, dial_centres[["moon"]])$y)
moon_discs <- bind_rows(lapply(seq_len(nrow(moon_positions)), function(i) {
  mutate(circle(0.11, moon_positions$x[i], i), y = y + moon_positions$y[i])
}))
moon_lit <- bind_rows(lapply(seq_len(nrow(moon_positions)), function(i) {
  moon_icon(moon_positions$x[i], moon_positions$y[i], moon_positions$phase[i], 0.22, 0.22, id = i)
}))

# What each dial says, in numbers from the data
share_warming <- mean(seasons$warming)
expected_warming <- mean(seasons$warming_share_of_year)
share_week <- mean(between(nights$lunar_day, 0, 7))
clock_text <- function(h) sprintf("%d h %02d", floor(h), round(60 * (h %% 1)))
# The text under the dials calls the Moon loosest and the Sun tightest, so check that.
hand_lengths <- clocks$tightness[match(c("year", "moon", "sun"), clocks$clock)]
stopifnot(which.min(hand_lengths) == 2, which.max(hand_lengths) == 3)
dial_text <- tibble(
  x = dial_centres - 1.08,
  heading = c("Year", "Moon", "Sun"),
  # Each heading has its own width, so its follow-on text starts at its own offset.
  job_x = x + c(0.5, 0.58, 0.42),
  job = c("picks the season", "picks the night", "picks the hour"),
  detail = c(sprintf("%.0f%% of spawning nights fall while the sea\nis warming, just %.0f%% of the year",
                     100 * share_warming, 100 * expected_warming),
             sprintf("%.0f%% fall in the 8 days after full moon,\njust 27%% of the month",
                     100 * share_week),
             sprintf("Half of all spawning starts between\n%s and %s after sunset",
                     clock_text(hours[["q25_start_hours"]]), clock_text(hours[["q75_start_hours"]]))),
  timing = sprintf("R = %.2f%s", hand_lengths, c("", ", the loosest clock", ", the tightest clock"))
)

key_y <- 1.47
key_ring <- mutate(circle(0.075, 2.15, "key"), y = y + key_y)

clock_plot <- ggplot() +
  geom_polygon(data = rims, aes(x, y, group = id), fill = "#10263A", colour = rule, linewidth = 0.4) +
  geom_polygon(data = all_bars, aes(x, y, group = id), fill = spawn) +
  geom_path(data = even_rings, aes(x, y, group = id), colour = moon, linewidth = 0.35) +
  geom_segment(data = ticks, aes(x, y, xend = xend, yend = yend, linewidth = long), colour = soft) +
  # The hand: a dark casing keeps it readable across the bars.
  geom_segment(data = hands, aes(centre, 0, xend = tip_x, yend = tip_y), colour = night,
               linewidth = 3.2, lineend = "round") +
  geom_segment(data = hands, aes(centre, 0, xend = tip_x, yend = tip_y), colour = moon,
               linewidth = 1.5, lineend = "round") +
  geom_point(data = hands, aes(centre, 0), shape = 21, size = 4.4, stroke = 0.9, fill = night,
             colour = moon) +
  geom_text(data = dial_labels, aes(x, y, label = label, hjust = hjust, vjust = vjust),
            family = font_note, size = pts(14), colour = soft, lineheight = 0.95) +
  geom_polygon(data = moon_discs, aes(x, y, group = id), fill = "#1F3549") +
  geom_polygon(data = moon_lit, aes(x, y, group = id), fill = moon) +
  geom_text(data = dial_text, aes(x, -1.56, label = heading), hjust = 0, family = font_title,
            size = pts(21), colour = moon) +
  geom_text(data = dial_text, aes(job_x, -1.565, label = job), hjust = 0, family = font_text,
            size = pts(17), colour = moon) +
  geom_text(data = dial_text, aes(x, -1.72, label = detail), hjust = 0, vjust = 1, family = font_note,
            size = pts(14), colour = soft, lineheight = 1.08) +
  geom_text(data = dial_text, aes(x, -2.06, label = timing), hjust = 0, vjust = 1, family = font_note,
            size = pts(14), colour = moon) +
  # One key row above the dials names each mark by what it looks like.
  annotate("rect", xmin = -4.22, xmax = -4.06, ymin = key_y - 0.04, ymax = key_y + 0.04, fill = spawn) +
  plot_note(-4, key_y, "Pink bar : share of records", size = 14) +
  annotate("segment", x = -2.3, xend = -2.07, y = key_y, yend = key_y, colour = moon, linewidth = 1.5,
           lineend = "round") +
  plot_note(-2.01, key_y, "White line: average time. Length R: 0 = evenly spread, 1 = all at one moment", size = 14) +
  geom_path(data = key_ring, aes(x, y), colour = moon, linewidth = 0.35) +
  plot_note(2.28, key_y, "Thin ring: an even spread", size = 14) +
  plot_note(0.17, 1.22, "Full moon", size = 14) +
  plot_note(0.17, -1.22, "New moon", size = 14) +
  scale_linewidth_manual(values = c("FALSE" = 0.25, "TRUE" = 0.5), guide = "none") +
  coord_fixed(xlim = c(-4.25, 4.25), ylim = c(-2.2, 1.56), clip = "off", expand = FALSE) +
  labs(title = "The reef reads three clocks, and the Moon is the loosest",
       subtitle = "Corals do not spawn at random. Each clock shows when they spawn: in the year, in the Moon’s cycle and in the day.",
       x = NULL, y = NULL,
       caption = sprintf("R (mean resultant length) shows how concentrated the records are. It is not a confidence interval. Spawning is not watched equally at all times, so quiet times are under-recorded.\n%s spawning nights on the year clock, %s on the Moon clock, %d timed starts on the Sun clock. Sources: Baird et al. (2021), NOAA Coral Reef Watch.",
                         format(nrow(seasons), big.mark = ","), format(nrow(nights), big.mark = ","),
                         nrow(starts))) +
  theme_plot() +
  theme(axis.text.x = element_blank(), axis.text.y = element_blank(), axis.ticks = element_blank(),
        plot.subtitle = element_text(margin = margin(b = 6)))

save_plot(clock_plot, "01_three_clocks")
write_csv(clocks, "outputs/tables/01_three_clocks.csv")
