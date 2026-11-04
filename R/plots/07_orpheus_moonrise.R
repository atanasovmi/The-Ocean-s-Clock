# One evening, reconstructed from the reef observer's point of view.
source("R/plots/style.R")
species <- read_csv("outputs/tables/07_orpheus_species.csv", show_col_types = FALSE)
track <- read_csv("outputs/tables/07_orpheus_moon_track.csv", show_col_types = FALSE)
marks <- count(species, start_minutes, moon_deg, name = "n_species")

# Interpolate the local minute at which the airless centre crosses 0 degrees.
crossing <- which(diff(track$moon_deg >= 0) == 1)
stopifnot(length(crossing) == 1)
rise <- approx(track$moon_deg[c(crossing, crossing + 1)],
               track$local_minute[c(crossing, crossing + 1)], xout = 0)$y
clock_label <- function(m) sprintf("%02d:%02d", as.integer(round(m)) %/% 60, as.integer(round(m)) %% 60)
first_start <- slice_min(marks, start_minutes, n = 1)
last_start <- slice_max(marks, start_minutes, n = 1)

p <- ggplot(track, aes(local_minute, moon_deg)) +
  geom_hline(yintercept = 0, linewidth = 0.6, colour = ink) +
  geom_line(linewidth = 1.1, colour = muted) +
  geom_point(data = marks, aes(start_minutes, moon_deg, size = n_species),
             shape = 21, fill = blue, colour = "white", stroke = 0.8) +
  scale_size_area(max_size = 6.8, guide = "none") +
  annotate("text", x = 1110, y = 1.8, label = "HORIZON  0°", hjust = 0,
           colour = muted, fontface = "bold", size = 4) +
  annotate("segment", x = first_start$start_minutes, xend = first_start$start_minutes,
           y = first_start$moon_deg + 1.6, yend = -30, colour = blue) +
  annotate("text", x = first_start$start_minutes - 4, y = -28.5, hjust = 0, vjust = 0,
           label = paste0(clock_label(first_start$start_minutes), "   First release\nGoniastrea favulus"),
           colour = blue, size = 4.8, lineheight = 1.05) +
  annotate("segment", x = last_start$start_minutes, xend = last_start$start_minutes,
           y = last_start$moon_deg - 1.7, yend = -18, colour = blue) +
  annotate("text", x = last_start$start_minutes + 2, y = -20, hjust = 1, vjust = 1,
           label = paste0(clock_label(last_start$start_minutes), "   Last releases\nAcropora cerealis and A. nasuta"),
           colour = blue, size = 4.8, lineheight = 1.05) +
  annotate("point", x = rise, y = 0, shape = 23, fill = orange, colour = "white", stroke = 0.6, size = 4.6) +
  annotate("text", x = rise - 3, y = 4.2, hjust = 1, colour = orange, fontface = "bold",
           label = paste0(clock_label(rise), "   Moon’s centre crosses the horizon"), size = 4.8) +
  scale_x_continuous(breaks = seq(1140, 1380, 60), labels = clock_label, expand = c(0, 0)) +
  scale_y_continuous(breaks = c(-45, -30, -15, 0), labels = function(x) paste0(x, "°")) +
  coord_cartesian(xlim = c(1106, 1380), ylim = c(-51, 9), expand = FALSE) +
  labs(title = "Seventeen species spawned before moonrise",
       subtitle = "Orpheus Island, Great Barrier Reef  ·  24 November 1983  ·  Sunset at 18:33",
       x = "Local time at the reef", y = "Moon’s height above or below the horizon",
       caption = "The curve follows the Moon. Each teal dot marks the first recorded start for one species or two starting together.\nField observations from Baird et al. (2021). NASA/JPL Horizons gives the Moon’s centre above an ideal sea horizon, without refraction.") +
  theme_presentation() + theme(panel.grid.major.x = element_blank())
save_plot(p, "07_orpheus_moonrise")
