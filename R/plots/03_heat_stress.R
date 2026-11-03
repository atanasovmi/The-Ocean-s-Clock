# Question: has severe heat stress become more widespread in the same NOAA regions?
source("R/plots/style.R")
annual <- read_csv("data/derived/regional_annual.csv", show_col_types = FALSE) |>
  filter(between(year, 1986, 2024), complete_year)
heat_trend <- annual |> group_by(year) |>
  summarise(n_regions = n(), n_severe = sum(max_dhw_c_weeks >= 8),
            share = n_severe / n_regions, .groups = "drop")
stopifnot(all(heat_trend$n_regions == 214))
endpoints <- heat_trend |> filter(year %in% c(1986, 2024)) |>
  mutate(label = paste(n_severe, "of", n_regions),
         label_year = if_else(year == 1986, year + 1, year - 1),
         label_share = if_else(year == 1986, share + 0.075, share + 0.06),
         hjust = if_else(year == 1986, 0, 1))

heat_plot <- ggplot(heat_trend, aes(year, share)) +
  geom_line(colour = blue, linewidth = 0.95) +
  geom_point(data = endpoints, size = 2.7, colour = blue) +
  geom_text(data = endpoints, aes(label_year, label_share, label = label, hjust = hjust), size = 4.7) +
  scale_x_continuous(breaks = c(1986, 1995, 2005, 2015, 2024)) +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2), labels = scales::label_percent()) +
  labs(title = "Severe heat stress reached more reef regions over time",
       subtitle = "The same 214 NOAA reef regions are compared each year.",
       x = "Year", y = "Regions reaching the severe heat-stress level",
       caption = "Severe level: annual maximum DHW ≥8 °C-weeks. Source: NOAA Coral Reef Watch.\nThis counts regions, not reef area or observed coral deaths.") +
  theme_presentation()
save_plot(heat_plot, "03_heat_stress")
write_csv(heat_trend, "outputs/tables/03_heat_stress.csv")
