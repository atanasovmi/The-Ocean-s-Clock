# Question: did the heat-stress overlap change equally in every spawning region?
source("R/plots/style.R")
comparison <- read_csv("data/derived/decadal_exposure.csv", show_col_types = FALSE)
# Show five largest increases and a zero-change comparison; the full table has 14 regions.
selected <- bind_rows(slice_max(comparison, change, n = 5, with_ties = FALSE),
                      filter(comparison, station_id == "singapore")) |>
  arrange(desc(change)) |>
  mutate(region = recode(station_id,
    northern_taiwan = "Northern Taiwan", gulf_of_aqaba = "Gulf of Aqaba",
    panama_pacific_west = "Pacific Panama (west)", northern_philippines = "Northern Philippines",
    tromelin_reunion = "Tromelin / Réunion", singapore = "Singapore"))
plot_data <- selected |>
  pivot_longer(c(`1986–1995`, `2015–2024`), names_to = "period", values_to = "exposure") |>
  mutate(region = factor(region, levels = rev(selected$region)),
         period = factor(period, levels = c("1986–1995", "2015–2024")),
         percent_label = scales::percent(exposure, accuracy = 0.1))

exposure_plot <- ggplot(plot_data, aes(exposure, region, fill = period)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65) +
  geom_text(aes(label = percent_label), position = position_dodge(width = 0.75),
            hjust = -0.15, size = 4) +
  scale_fill_manual(values = c("grey70", blue), drop = FALSE) +
  scale_x_continuous(limits = c(0, 0.32), breaks = seq(0, 0.3, 0.1),
                     labels = scales::label_percent(), expand = expansion(mult = c(0, 0))) +
  labs(title = "Spawning-season heat exposure rose in some regions",
       subtitle = "Five largest increases, with Singapore as a zero-change comparison.",
       x = "Spawning-season heat exposure index", y = NULL,
       caption = "Historical spawning calendars held fixed; monthly days at DHW ≥4 are weighted by those calendars.\nSources: Coral Spawning Database and NOAA CRW. This index does not measure reproductive failure.") +
  theme_presentation() + theme(panel.grid.major.y = element_blank())
save_plot(exposure_plot, "04_spawning_exposure", width = 11, height = 7)
write_csv(plot_data, "outputs/tables/04_spawning_exposure.csv")
