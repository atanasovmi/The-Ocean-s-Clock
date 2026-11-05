# Plot 3. Do all reefs follow the Moon equally?
# A lunar actogram: every place gets one row across the lunar month, ordered from
# the equator outwards, and a brighter cell means more of that place's records.
source("R/plots/style.R")
library(patchwork)

tropic <- 23.44
even_share <- 8 / 29.53     # the eight days from full moon, as a share of the month

places <- read_csv("outputs/tables/lunar_tightness_by_place.csv", show_col_types = FALSE) |>
  arrange(abs_latitude) |>
  # A one-row gap marks the edge of the tropics.
  mutate(row = -(row_number() + if_else(abs_latitude > tropic, 1, 0)),
         independent = record != "field database",
         label = case_when(place == "Churaumi Aquarium" ~ "Churaumi Aquarium, every day watched",
                           place == "Maldives atolls" ~ "Maldives atolls, separate study",
                           TRUE ~ paste0(place, ", ", country)))
counts <- read_csv("outputs/tables/lunar_counts_by_place.csv", show_col_types = FALSE) |>
  left_join(select(places, place, row), by = "place", relationship = "many-to-one")
stats <- read_statistics("outputs/tables/lunar_statistics.csv")
stopifnot(!anyNA(counts$row))

tropic_row <- max(places$row[places$abs_latitude > tropic]) + 1
# Share of reef-nights inside the frame, for the notes on each side of the tropic line.
share_label <- function(where, share) sprintf("%s\n%.0f%% fall in the frame", where, 100 * share)
row_limits <- c(min(places$row) - 0.6, -0.4)

# A small brightness key, built from the same colours as the cells.
cell_colours <- c("#1C2B41", "#57304F", "#A64562", spawn, "#FFE0DC")
key_y <- row_limits[1] - 1.55
key_cells <- tibble(left = -23.6 + 0.95 * 0:4, colour = cell_colours)

actogram <- ggplot(counts, aes(lunar_day, row)) +
  geom_tile(aes(fill = share), width = 0.92, height = 0.82, linewidth = 0) +
  # A hairline frame around the eight-day window the percentages refer to
  annotate("rect", xmin = -0.5, xmax = 7.5, ymin = row_limits[1], ymax = row_limits[2],
           fill = NA, colour = soft, linewidth = 0.4) +
  annotate("text", x = -15.7, y = tropic_row, hjust = 1, family = font_label, size = pts(13),
           colour = soft, label = "Edge of the tropics, 23.4°") +
  annotate("segment", x = -15.5, xend = 14.5, y = tropic_row, yend = tropic_row,
           colour = rule, linewidth = 0.4) +
  geom_text(data = places, aes(x = -15.7, y = row, label = label, colour = independent),
            hjust = 1, family = font_note, size = pts(13.5)) +
  moon_phase_row(c(-14.77, -7.38, 0, 7.38, 14.77), y = 0.65, width = 1.24, height = 1.5) +
  plot_note(-15.7, 0.65, "One row per place, nearest the equator at the top", hjust = 1) +
  plot_note(3.5, 1.05, "8 days from\nfull moon", hjust = 0.5, size = 12.5) +
  plot_note(-14.6, -8.5, share_label("Inside the tropics", stats[["share_inside_tropics"]]),
            colour = moon, size = 14.5) +
  plot_note(-14.6, -18, share_label("Beyond the tropics", stats[["share_outside_tropics"]]),
            colour = moon, size = 14.5) +
  plot_note(-34, key_y, "Spawning on that day:  little") +
  annotate("rect", xmin = key_cells$left, xmax = key_cells$left + 0.87, ymin = key_y - 0.42,
           ymax = key_y + 0.42, fill = key_cells$colour) +
  plot_note(-18.6, key_y, "a lot") +
  scale_colour_manual(values = c("FALSE" = soft, "TRUE" = moon), guide = "none") +
  scale_fill_gradientn(colours = cell_colours,
                       transform = "sqrt", limits = c(0, 0.5), guide = "none") +
  scale_x_continuous(breaks = c(-14, -7, 0, 7, 14),
                     labels = c("−14", "7 days before", "Full moon", "7 days after", "+14"),
                     expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  # The window reaches left of the data to leave room for the place names.
  coord_cartesian(xlim = c(-34, 15.3), ylim = row_limits, clip = "off") +
  labs(x = NULL, y = NULL) +
  theme_plot() +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(),
        plot.margin = margin(38, 0, 0, 0))

tightness_strip <- ggplot(places, aes(tightness, row)) +
  geom_segment(aes(x = 0, xend = tightness, yend = row), colour = rule, linewidth = 0.6) +
  geom_point(aes(fill = independent), shape = 21, size = 3.3, stroke = 0.3, colour = night) +
  scale_fill_manual(values = c("FALSE" = spawn, "TRUE" = moon), guide = "none") +
  scale_x_continuous(limits = c(0, 1), breaks = c(0, 0.5, 1), labels = c("0", "0.5", "1"),
                     expand = expansion(mult = c(0.02, 0.06))) +
  scale_y_continuous(expand = c(0, 0)) +
  coord_cartesian(ylim = row_limits, clip = "off") +
  labs(x = NULL, y = NULL) +
  annotate("text", x = 0, y = 0.65, hjust = 0, family = font_label, size = pts(14), colour = soft,
           label = "Tightness") +
  plot_note(1, 1.05, "0: spread out\n1: one night", hjust = 1, size = 12.5) +
  theme_plot() +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(), plot.margin = margin(38, 0, 0, 16))

moon_plot <- actogram + tightness_strip +
  plot_layout(widths = c(5.2, 1)) +
  plot_annotation(
    title = "The Moon’s hold loosens away from the equator",
    subtitle = sprintf("Inside the tropics %.0f%% of reef-nights fall in the eight framed days after full moon. Beyond them it is %.0f%%, and an even\nspread would give %.0f%%. The two records with the most nights, Eilat and the aquarium, look loosest of all.",
                       100 * stats[["share_inside_tropics"]], 100 * stats[["share_outside_tropics"]], 100 * even_share),
    caption = sprintf("Brighter cell: a larger share of that place’s records. Cream names and dots: records from outside the main database. Tightness: 1 means a single lunar night, 0 an even spread. Latitude trend:\nSpearman ρ = %.2f, also found within genera, though places with more recorded nights look looser too. Places with at least 12 reef-nights. Sources: Baird et al. (2021), Sheridan et al. (2025), Sakai et al. (2024).",
                      stats[["spearman_rho"]]),
    theme = theme_plot() + theme(plot.subtitle = element_text(margin = margin(b = 0)))
  )

save_plot(moon_plot, "03_moon")
write_csv(select(places, place, country, latitude, n, years, tightness, typical, record),
          "outputs/tables/03_moon.csv")
