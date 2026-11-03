# Question: how do exact night-time starts differ between well-recorded genera?
source("R/plots/style.R")
field <- read_csv("data/derived/field_observations.csv", show_col_types = FALSE)
exact_starts <- field |>
  filter(exact_start, !midnight_ambiguous, !is.na(sunset_offset_hours)) |>
  group_by(subsite_id, date, genus) |>
  summarise(hours_after_sunset = median(sunset_offset_hours), .groups = "drop")
# Keep this plot about night-time starts. Genuine daylight records stay in the source.
night_starts <- exact_starts |> filter(hours_after_sunset >= 0)
selected <- night_starts |> count(genus, sort = TRUE) |> slice_head(n = 6)
plot_data <- night_starts |> semi_join(selected, by = "genus") |>
  left_join(selected |> rename(n_nights = n), by = "genus", relationship = "many-to-one") |>
  mutate(label = paste0(genus, " (n = ", n_nights, ")"),
         label = reorder(label, hours_after_sunset, median))

night_plot <- ggplot(plot_data, aes(hours_after_sunset, label)) +
  geom_boxplot(width = 0.55, fill = "grey85", colour = "grey20", outlier.size = 1.8) +
  scale_x_continuous(limits = c(0, NA), breaks = 0:6,
                     expand = expansion(mult = c(0.02, 0.08))) +
  labs(title = "Night-spawning groups have different starting times",
       subtitle = "Six genera with the most exact night-time records.",
       x = "Hours after local sunset", y = NULL,
       caption = "One median exact start per genus, reef location and date. Source: Baird et al. (2021).\nDaylight and ambiguous midnight records are excluded. Locations and species differ between genera.") +
  theme_presentation() + theme(panel.grid.major.y = element_blank())
save_plot(night_plot, "02_night_timing")
write_csv(plot_data, "outputs/tables/02_night_timing.csv")
