source("R/plots/style.R")
calendar <- read_csv("outputs/tables/08_moon_calendar.csv", show_col_types = FALSE)
event <- filter(calendar, shift_days == 0)
reference <- mean(calendar$share_below[calendar$shift_days != 0])
later <- filter(calendar, shift_days == 5)
p <- ggplot(calendar, aes(shift_days, share_below)) +
  geom_hline(yintercept = reference, colour = muted, linetype = "32", linewidth = 0.6) +
  geom_vline(xintercept = 0, colour = grid, linewidth = 0.6) +
  geom_line(colour = "#71989E", linewidth = 1.2) +
  geom_point(colour = "#517A81", size = 2.25) +
  geom_point(data = event, shape = 21, fill = orange, colour = "white", stroke = 1, size = 6.3) +
  annotate("text", x = -0.55, y = event$share_below + 0.055, hjust = 1,
           label = sprintf("%.0f%% on the recorded date", 100 * event$share_below),
           fontface = "bold", colour = orange, size = 5.5) +
  annotate("text", x = -13.8, y = reference + 0.045, hjust = 0,
           label = sprintf("%.0f%% average on comparison dates", 100 * reference), colour = muted, size = 4.7) +
  annotate("text", x = 5.4, y = later$share_below - 0.105, hjust = 0.5, size = 4.5,
           label = sprintf("%.0f%% five days later", 100 * later$share_below), colour = ink) +
  scale_x_continuous(breaks = c(-14, -7, 0, 7, 14),
                     labels = c("14 days earlier", "7 earlier", "Recorded date", "7 later", "14 days later"),
                     expand = expansion(mult = 0.02)) +
  scale_y_continuous(limits = c(0, 1.01), breaks = seq(0, 1, 0.25),
                     labels = scales::label_percent(), expand = c(0, 0)) +
  labs(title = "The Moon was usually below the horizon",
       subtitle = "Keep the same reef and clock time. Move the date, and the sky changes.",
       x = NULL, y = "Share of starts with the Moon below the horizon",
       caption = sprintf("%d distinct evening start times across %d reef-nights at %d subsites. Each night carries equal weight.\nDay zero uses recorded spawning dates. The other dates are calculated comparisons. Sources: Baird et al. + NASA/JPL Horizons.",
                         event$start_times, event$reef_nights, event$subsites)) +
  theme_presentation() + theme(panel.grid.major.x = element_blank())
save_plot(p, "08_moon_calendar")
