source("R/plots/style.R")
annual <- read_csv("data/derived/regional_annual.csv", show_col_types = FALSE) |>
  filter(between(year, 1986, 2024), complete_year)
heat_trend <- annual |>
  summarise(n_regions = n(), n_severe = sum(max_dhw_c_weeks >= 8), .by = year) |>
  mutate(share = n_severe / n_regions) |> arrange(year)
stopifnot(all(heat_trend$n_regions == 214))
latest <- filter(heat_trend, year == 2024)
first <- filter(heat_trend, year == 1986)
p <- ggplot(heat_trend, aes(year, n_severe)) +
  geom_hline(yintercept = 214, linewidth = 0.45, colour = muted, linetype = "32") +
  geom_line(colour = blue, linewidth = 1.2) +
  geom_point(data = latest, shape = 21, fill = orange, colour = "white", stroke = 0.8, size = 5) +
  geom_point(data = first, colour = blue, size = 3) +
  annotate("text", x = 1986, y = 220, label = "All 214 monitored regions", hjust = 0,
           size = 4.6, colour = muted) +
  annotate("text", x = 2023.7, y = 190, label = paste(latest$n_severe, "of 214"), hjust = 1,
           fontface = "bold", size = 7.3, colour = orange) +
  annotate("text", x = 1987, y = 22, label = paste(first$n_severe, "of 214"), hjust = 0,
           size = 5, colour = blue) +
  scale_x_continuous(breaks = c(1986, 1995, 2005, 2015, 2024), expand = expansion(mult = c(0.01, 0.02))) +
  scale_y_continuous(limits = c(0, 230), breaks = seq(0, 200, 50), expand = c(0, 0)) +
  labs(title = "Severe heat stress reaches far more reef regions",
       subtitle = "The same 214 NOAA regions, followed through 39 complete years",
       x = NULL, y = "Regions reaching severe heat stress during the year",
       caption = "Severe heat stress means an annual maximum of at least 8 degree-heating weeks. Source: NOAA Coral Reef Watch.\nRegions count equally. This measures accumulated thermal stress. Coral deaths and affected reef area were not measured.") +
  theme_presentation() + theme(panel.grid.major.x = element_blank())
save_plot(p, "03_heat_stress")
write_csv(heat_trend, "outputs/tables/03_heat_stress.csv")
