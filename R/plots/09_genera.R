# Plot 9. Do all coral genera keep the same time?
# A stack of waves: each row is one genus across the lunar month, and a strip beside
# it shows the hour its spawning starts. The month runs from before full moon to past
# new moon, so a new-moon peak stays whole instead of being cut at the plot's edge.
source("R/plots/style.R")
library(patchwork)

synodic_month <- 29.53
month_start <- -synodic_month / 4     # the plot opens at the quarter moon before full
month_end <- month_start + synodic_month
new_moon <- synodic_month / 2

nights <- read_csv("data/derived/genus_group_nights.csv", show_col_types = FALSE)
starts <- read_csv("data/derived/genus_group_starts.csv", show_col_types = FALSE)
groups <- read_csv("outputs/tables/genus_group_summary.csv", show_col_types = FALSE)
stats <- read_statistics("outputs/tables/genus_statistics.csv")

# Rows ----
# The genus with most nights in the eight days after full moon goes on top, so the
# stack reads from tight to loose. A gap and a heading set the outlier apart.
pocillopora_rows <- c("Pocillopora, other seas", "Pocillopora, Red Sea")
crowd <- setdiff(groups$group, pocillopora_rows)
group_rows <- tibble(group = c(crowd, pocillopora_rows),
                     row = c(-seq_along(crowd), -length(crowd) - c(2.5, 3.9)),
                     outlier = group %in% pocillopora_rows) |>
  left_join(groups, by = "group", relationship = "one-to-one") |>
  mutate(label = sprintf("%s (%d)", sub("Pocillopora, ", "", group), nights),
         share_label = sprintf("%.0f%%", 100 * share_after_full))
headings <- tibble(row = -length(crowd) - 1.3, label = "Pocillopora")

# Waves ----
# Each night spreads over about a day either side (a Gaussian of sd 0.8 days), wrapped
# round the month. Height is the share of a row's nights per day, so rows compare.
wave_days <- seq(month_start, month_end, by = 0.1)
wave_height <- 8      # plot rows of height for a share of 100% per day
month_gap <- function(day, centre) {
  (day - centre + synodic_month / 2) %% synodic_month - synodic_month / 2
}
smooth_wave <- function(lunar_days) {
  tibble(day = wave_days,
         share = vapply(wave_days, function(d) mean(dnorm(month_gap(lunar_days, d), sd = 0.8)), numeric(1)))
}
waves <- nights |>
  reframe(smooth_wave(lunar_day), .by = group) |>
  left_join(select(group_rows, group, row, outlier), by = "group", relationship = "many-to-one") |>
  mutate(top = row + wave_height * share)
dots <- starts |>
  left_join(select(group_rows, group, row, outlier), by = "group", relationship = "many-to-one")
stopifnot(!anyNA(waves$row), !anyNA(dots$row))

row_limits <- c(min(group_rows$row) - 0.5, 1.2)
moon_y <- row_limits[2] + 2.05
window_y <- row_limits[2] + 0.75
crowd_fill <- "#A64562"     # plot 3's middle cell colour; the outlier wears full spawn pink
share_x <- month_end + 4.8
scale_bottom <- -0.35
even_share <- 8 / synodic_month     # the share an even spread would put in the frame

# The plot's right edge is a quarter moon too, which the shared row cannot draw:
# it shows days up to new moon, and this one comes after it.
edge_disc <- tibble(angle = seq(0, 2 * pi, length.out = 60),
                    x = month_end + 0.6 * cos(angle), y = moon_y + 0.6 * sin(angle))
edge_moon <- moon_icon(month_end, moon_y, -synodic_month / 4, 1.2, 1.2, id = "edge")

# Lunar panel ----
wave_plot <- ggplot(waves, aes(day)) +
  # The hairline frame is the eight-day window of plots 1 and 3.
  annotate("rect", xmin = -0.5, xmax = 7.5, ymin = row_limits[1], ymax = row_limits[2],
           fill = NA, colour = soft, linewidth = 0.4) +
  # Each wave carries its own top edge, so a wave in front covers the ones behind it.
  geom_ribbon(aes(ymin = row, ymax = top, group = reorder(group, -row), fill = outlier, colour = outlier),
              outline.type = "upper", linewidth = 0.45) +
  geom_text(data = group_rows, aes(x = month_start - 0.6, y = row + 0.12, label = label), hjust = 1,
            family = font_note, size = pts(14), colour = soft) +
  geom_text(data = headings, aes(x = month_start - 0.6, y = row + 0.12, label = label), hjust = 1,
            family = font_label, size = pts(14.5), colour = moon) +
  geom_text(data = group_rows, aes(x = share_x, y = row + 0.12, label = share_label, colour = outlier),
            hjust = 1, family = font_note, size = pts(14.5)) +
  annotate("text", x = share_x, y = window_y + 0.75, hjust = 1, vjust = 0.5, family = font_label,
           size = pts(14), colour = soft, lineheight = 1, label = "Nights in\nthose 8 days") +
  moon_phase_row(c(month_start, 0, -month_start, new_moon), y = moon_y, width = 1.2, height = 1.2) +
  geom_polygon(data = edge_disc, aes(x, y), inherit.aes = FALSE, fill = "#1F3549") +
  geom_polygon(data = edge_moon, aes(x, y), inherit.aes = FALSE, fill = moon) +
  plot_note(3.5, window_y, "8 days after full moon", hjust = 0.5) +
  plot_note(month_start - 1.3, moon_y - 0.35, "One wave per genus\n(n) = spawning nights", hjust = 1) +
  # The height key sits in the label column, drawn at the waves' own scale.
  annotate("segment", x = month_start - 0.6, xend = month_start - 0.6, y = scale_bottom,
           yend = scale_bottom + wave_height * 0.2, colour = soft, linewidth = 0.6) +
  plot_note(month_start - 1.1, scale_bottom + wave_height * 0.1,
            "This bar = 20% of a\ngenus’s nights in a day", hjust = 1, size = 12.5) +
  plot_note(share_x, headings$row, "Same genus, opposite moon", hjust = 1, colour = moon) +
  plot_note(share_x, 0.15, sprintf("Same peak, but not equally tight: %s down to %s",
                                   first(group_rows$share_label[!group_rows$outlier]),
                                   last(group_rows$share_label[!group_rows$outlier])), hjust = 1) +
  scale_fill_manual(values = c("FALSE" = crowd_fill, "TRUE" = spawn), guide = "none") +
  scale_colour_manual(values = c("FALSE" = "#E58A97", "TRUE" = moon), guide = "none") +
  scale_x_continuous(breaks = c(0, -month_start, new_moon, month_end),
                     labels = c("Full moon", "+7 days", "New moon", "+22 days"), expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  coord_cartesian(xlim = c(-16.3, share_x), ylim = row_limits, clip = "off") +
  labs(x = "Days after full moon", y = NULL) +
  theme_plot() +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(), plot.margin = margin(60, 0, 0, 0),
        axis.title.x = element_text(hjust = 0.57, margin = margin(t = 6)))

# Hour panel ----
# Sunrise comes about 12 h after sunset, earlier or later with place and season, so
# the daylight fades in over three hours instead of starting at one sharp line.
daylight <- colorRampPalette(c(night, "#2A4A63"))(30)
daylight <- matrix(c(daylight, rep("#2A4A63", 70)), nrow = 1)
hour_plot <- ggplot(dots, aes(hours, row)) +
  annotation_raster(daylight, xmin = 10, xmax = 20, ymin = row_limits[1], ymax = row_limits[2],
                    interpolate = TRUE) +
  geom_hline(data = group_rows, aes(yintercept = row), colour = "#1B3044", linewidth = 0.3) +
  geom_point(aes(fill = outlier), position = position_jitter(width = 0.1, height = 0.22, seed = 9),
             shape = 21, size = 1.9, stroke = 0.16, colour = night) +
  annotate("text", x = -4, y = window_y + 1.3, hjust = 0, family = font_label, size = pts(14),
           colour = soft, label = "Hour spawning starts") +
  plot_note(-4, window_y, "One dot: one genus starting on one night") +
  plot_note(16.5, 0.4, "Daylight", hjust = 0.5) +
  plot_note(9.6, mean(group_rows$row[group_rows$outlier]),
            sprintf("%d of %d start\nafter sunrise", stats[["pocillopora_timed"]] - stats[["pocillopora_evening"]],
                    stats[["pocillopora_timed"]]), hjust = 1, colour = moon) +
  scale_fill_manual(values = c("FALSE" = crowd_fill, "TRUE" = spawn), guide = "none") +
  scale_x_continuous(breaks = c(0, 6, 12, 18), labels = c("Sunset", "+6 h", "About sunrise", "+18 h"),
                     expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  coord_cartesian(xlim = c(-4, 20), ylim = row_limits, clip = "off") +
  labs(x = "Hours after sunset", y = NULL) +
  theme_plot() +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(), plot.margin = margin(60, 0, 0, 26),
        axis.title.x = element_text(margin = margin(t = 6)))

genera_plot <- wave_plot + hour_plot +
  plot_layout(widths = c(2.55, 1)) +
  plot_annotation(
    title = "Most coral genera share one timetable. Pocillopora does not",
    subtitle = "A genus is a group of related species. Each wave is one genus over the lunar month: higher means more nights that day.\nEleven genera peak after full moon and start in the evening. Pocillopora spawns by day, and in the Red Sea at new moon.",
    caption = sprintf("Spawning night: one genus on one reef on one date. Percentages: share of a genus’s nights inside the white frame; an even spread would give %.0f%%. Tight: packed into few days. Some times are approximate.\nBright pink: Pocillopora (cauliflower corals), split by sea. Shown: genera with 40+ nights, of %.0f recorded. Waves are smoothed by about a day. Sunrise comes about 12 h after sunset, varying by place and season.\np < 0.001: shuffling genus labels within reefs almost never gives gaps this large, so genera differ even on one reef. Platygyra has a small new-moon peak (%.0f%% of nights). Source: Baird et al. (2021).",
                      100 * even_share, stats[["genera_all"]], 100 * stats[["platygyra_share_near_new"]]),
    theme = theme_plot() + theme(plot.subtitle = element_text(margin = margin(b = 0)))
  )

save_plot(genera_plot, "09_genera")
write_csv(select(group_rows, group, nights, reefs, share_after_full, share_near_new),
          "outputs/tables/09_genera.csv")
