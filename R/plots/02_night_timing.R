source("R/plots/style.R")
field <- read_csv("data/derived/field_observations.csv", show_col_types = FALSE)
night_starts <- field |> filter(exact_start, !midnight_ambiguous) |>
  summarise(hours_after_sunset = median(sunset_offset_hours),
            .by = c(subsite_id, date, genus)) |> filter(hours_after_sunset >= 0)
selected <- night_starts |> count(genus, sort = TRUE) |> slice_head(n = 6)
plot_data <- night_starts |> semi_join(selected, by = "genus") |>
  left_join(selected |> rename(n_nights = n), by = "genus", relationship = "many-to-one") |>
  mutate(label = paste0(genus, "  ·  ", n_nights, " nights"),
         label = reorder(label, -hours_after_sunset, median))
centres <- plot_data |>
  summarise(median = median(hours_after_sunset), q25 = quantile(hours_after_sunset, 0.25),
            q75 = quantile(hours_after_sunset, 0.75), .by = label)
p <- ggplot(plot_data, aes(hours_after_sunset, label)) +
  geom_point(position = position_jitter(width = 0, height = 0.18, seed = 41),
             size = 2.1, colour = "#719298", alpha = 0.65) +
  geom_segment(data = centres, aes(x = q25, xend = q75, yend = label),
               linewidth = 2.6, colour = blue, lineend = "round") +
  geom_point(data = centres, aes(x = median), shape = 21, fill = "white",
             colour = blue, stroke = 1.2, size = 3.5) +
  scale_x_continuous(limits = c(0, NA), breaks = 0:6, labels = c("Sunset", 1:6),
                     expand = expansion(mult = c(0.02, 0.08))) +
  labs(title = "Coral groups keep different evening schedules",
       subtitle = "Each dot is one genus, reef location and date. Lines span the middle half of the recorded starts.",
       x = "Hours after local sunset", y = NULL,
       caption = "Six genera with the most exact evening records. White circles mark medians. Source: Baird et al. (2021).\nSpecies and locations differ between groups. Daylight and ambiguous midnight records are outside this comparison.") +
  theme_presentation() + theme(panel.grid.major.y = element_blank())
save_plot(p, "02_night_timing")
write_csv(plot_data, "outputs/tables/02_night_timing.csv")
