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
# The notes under the dials name the shortest and longest hand, so check they still are.
hand_lengths <- clocks$tightness[match(c("year", "moon", "sun"), clocks$clock)]
stopifnot(which.min(hand_lengths) == 2, which.max(hand_lengths) == 3)
dial_text <- tibble(
  x = dial_centres - 1.08,
  heading = c("Year", "Moon", "Sun"),
  # Each heading has its own width, so its follow-on text starts at its own offset.
  job_x = x + c(0.5, 0.58, 0.42),
  job = c("opens the season", "narrows the night", "sets the hour"),
  detail = c(sprintf("%.0f%% of spawning nights fall while the local sea\nis warming, which is %.0f%% of the year",
                     100 * share_warming, 100 * expected_warming),
             sprintf("%.0f%% fall in the eight days from full moon,\nwhich is 27%% of the month",
                     100 * share_week),
             sprintf("Half of all starts fall between %s\nand %s after sunset",
                     clock_text(hours[["q25_start_hours"]]), clock_text(hours[["q75_start_hours"]]))),
  hand = sprintf("Hand length %.2f%s", hand_lengths, c("", ", the shortest", ", the longest"))
)

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
  geom_text(data = dial_text, aes(x, -2.06, label = hand), hjust = 0, vjust = 1, family = font_note,
            size = pts(14), colour = moon) +
  # How to read a dial: notes sit in the empty gaps and lead to one example each.
  plot_note(1.425, -1.16, "Time runs clockwise", hjust = 0.5) +
  plot_note(1.65, 1.14, "Long bar: a lot of spawning\nat this time", hjust = 0.5) +
  note_line(1.2, 0.93, 0.74, 0.66) +
  plot_note(-1.45, -1.16, "Thin circle: how far bars\nwould reach if spawning\nwere spread evenly", hjust = 0.5) +
  note_line(-0.95, -0.87, -0.39, -0.39) +
  plot_note(-1.425, 1.12, "Hand: the typical time.\nA longer hand means\nspawning is more in step", hjust = 0.5) +
  note_line(-2, 0.82, -2.93, 0.09) +
  # What each part of the circle stands for
  plot_note(0.17, 1.22, "Full moon", size = 14) +
  plot_note(0.17, -1.22, "New moon", size = 14) +
  plot_note(dial_centres[["year"]] - 0.49, -0.62, "Sea warming", hjust = 0.5) +
  plot_note(dial_centres[["year"]] + 0.49, -0.62, "Sea cooling", hjust = 0.5) +
  plot_note(dial_centres[["sun"]] - 0.68, 0, "Day", hjust = 0.5) +
  plot_note(dial_centres[["sun"]] + 0.68, -0.25, "Night", hjust = 0.5) +
  scale_linewidth_manual(values = c("FALSE" = 0.25, "TRUE" = 0.5), guide = "none") +
  coord_fixed(xlim = c(-4.25, 4.25), ylim = c(-2.2, 1.56), clip = "off", expand = FALSE) +
  labs(title = "The reef reads three clocks, and the Moon is the loosest",
       subtitle = "Coral spawning on three natural clocks. The more the bars bunch up, the stronger that clock’s grip.",
       x = NULL, y = NULL,
       caption = sprintf("Hand: the typical moment. Its length is the tightness, from 0 (an even spread) to 1 (all records at one moment): %.2f year, %.2f Moon, %.2f Sun. Year dial aligned to each region’s warmest week.\n%s spawning nights (one reef, one night) on the year dial, %s on the Moon dial, %d genus starts on the Sun dial. Survey effort is uneven. Sources: Baird et al. (2021), NOAA Coral Reef Watch.",
                         clocks$tightness[clocks$clock == "year"], clocks$tightness[clocks$clock == "moon"],
                         clocks$tightness[clocks$clock == "sun"], format(nrow(seasons), big.mark = ","),
                         format(nrow(nights), big.mark = ","), nrow(starts))) +
  theme_plot() +
  theme(axis.text.x = element_blank(), axis.text.y = element_blank(), axis.ticks = element_blank(),
        plot.subtitle = element_text(margin = margin(b = 6)))

save_plot(clock_plot, "01_three_clocks")
write_csv(clocks, "outputs/tables/01_three_clocks.csv")
