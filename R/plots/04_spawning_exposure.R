source("R/plots/style.R")
comparison <- read_csv("data/derived/decadal_exposure.csv", show_col_types = FALSE) |>
  arrange(desc(change), station_name) |>
  mutate(region = recode(station_id,
    northern_taiwan = "Northern Taiwan", gulf_of_aqaba = "Gulf of Aqaba",
    panama_pacific_west = "Pacific Panama (west)", northern_philippines = "Northern Philippines",
    tromelin_reunion = "Tromelin / Réunion", sabah = "Sabah",
    gbr_central = "Central Great Barrier Reef", northern_ryukyu_islands = "Northern Ryukyu Islands",
    madinah_makkah = "Al Madinah / Makkah", southern_taiwan = "Southern Taiwan",
    fiji = "Fiji", hawaii = "Hawaii", singapore = "Singapore",
    southern_ryukyu_islands = "Southern Ryukyu Islands"),
    region = factor(region, levels = rev(region)),
    change_label = if_else(change == 0, "0.0", sprintf("+%.1f", 100 * change)))
plot_data <- comparison |>
  pivot_longer(c(`1986–1995`, `2015–2024`), names_to = "period", values_to = "exposure") |>
  mutate(period = factor(period, levels = c("1986–1995", "2015–2024")))
p <- ggplot(plot_data, aes(exposure, region)) +
  geom_segment(data = comparison, aes(x = `1986–1995`, xend = `2015–2024`, yend = region),
               colour = "#A2B7BA", linewidth = 1.2) +
  geom_point(aes(shape = period, colour = period), size = 3.4, fill = "white", stroke = 1.1) +
  geom_text(data = comparison, aes(x = 0.31, label = change_label),
            hjust = 1, size = 4.1, colour = muted) +
  annotate("text", x = 0.31, y = 14.6, label = "Change (pp)", hjust = 1, size = 4.1, colour = muted) +
  scale_colour_manual(values = c(muted, blue)) +
  scale_shape_manual(values = c(21, 16)) +
  scale_x_continuous(limits = c(0, 0.315), breaks = seq(0, 0.3, 0.1),
                     labels = scales::label_percent(), expand = c(0.01, 0)) +
  scale_y_discrete(expand = expansion(add = c(0.5, 1.1))) +
  labs(title = "Spawning seasons face very different heat exposure",
       subtitle = "All 14 eligible regions  ·  A fixed spawning calendar compared across two decades",
       x = "Calendar-weighted exposure to heat stress", y = NULL,
       caption = "Monthly fractions of days at DHW ≥4 are weighted by recorded spawning months. Hollow circles show 1986–1995.\nFilled dots show 2015–2024. pp = percentage points. Sources: Coral Spawning Database + NOAA CRW. Reproductive outcomes are unmeasured.") +
  theme_presentation() + theme(panel.grid.major.y = element_blank(),
                               axis.text.y = element_text(size = 12.5))
save_plot(p, "04_spawning_exposure")
write_csv(plot_data, "outputs/tables/04_spawning_exposure.csv")
