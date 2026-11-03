# Where are the observations, and when were spawning events recorded?
source("R/style.R")
nights <- read_csv("data/derived/reef_nights.csv", show_col_types = FALSE)

# Geography ----
locations <- nights |>
  group_by(subsite_id, site, country, latitude, longitude) |>
  summarise(n_nights = n(), .groups = "drop") |>
  mutate(map_longitude = longitude %% 360)
world <- map_data("world2")
atlas <- ggplot() +
  geom_polygon(data = world, aes(long, lat, group = group),
               fill = "#D8DEDA", colour = paper, linewidth = 0.15) +
  geom_hline(yintercept = 0, colour = muted, linetype = "dotted", linewidth = 0.4) +
  geom_point(data = locations, aes(map_longitude, latitude, size = n_nights),
             shape = 21, fill = ocean, colour = paper, stroke = 0.5, alpha = 0.8) +
  scale_size_area(max_size = 15, breaks = c(1, 25, 100, 200), name = "Recorded reef-nights") +
  scale_x_continuous(breaks = c(60, 120, 180, 240, 300),
                     labels = c("60°E", "120°E", "180°", "120°W", "60°W")) +
  scale_y_continuous(breaks = c(-30, 0, 30), labels = c("30°S", "Equator", "30°N")) +
  coord_quickmap(xlim = c(25, 295), ylim = c(-33, 37), expand = FALSE) +
  labs(title = "A clock scattered across the ocean",
       subtitle = paste0(format(nrow(nights), big.mark = ","), " recorded reef-nights • ",
                         n_distinct(nights$subsite_id), " subsites • ", n_distinct(nights$country),
                         " country labels • 1978–2019"), x = NULL, y = NULL,
       caption = paste(source_coral, "Basemap: maps package, world2.\nPoint area shows coverage, not reef abundance. Natural-reef observations only; overlapping points are retained.")) +
  theme_clock() + theme(panel.grid = element_blank())
save_figure(atlas, "01_observation_atlas", height = 7.5)
write_csv(locations, "outputs/tables/01_observation_atlas.csv")

# Monthly calendar ----
# Named sites combine their subsites; count each subsite-date once.
selected_sites <- nights |>
  group_by(site, country) |>
  summarise(n_nights = n(), n_years = n_distinct(year), latitude = mean(latitude), .groups = "drop") |>
  filter(n_nights >= 15, n_years >= 2) |>
  slice_max(n_nights, n = 14, with_ties = FALSE) |>
  arrange(desc(latitude)) |>
  mutate(label = paste0(site, " · ", country, "  |  ", n_nights, " nights / ", n_years, " y"))
calendar <- nights |>
  inner_join(selected_sites |> select(site, country, label, n_nights),
             by = c("site", "country"), relationship = "many-to-one") |>
  count(label, n_nights, month) |>
  complete(nesting(label, n_nights), month = 1:12, fill = list(n = 0)) |>
  mutate(share = n / n_nights, label = factor(label, levels = rev(selected_sites$label)))
season_plot <- ggplot(calendar, aes(month, label, fill = share)) +
  geom_tile(width = 0.94, height = 0.88) +
  scale_fill_gradient(low = "#F0EFE7", high = ocean,
                      labels = scales::label_percent(), name = "Share within site") +
  scale_x_continuous(breaks = 1:12, labels = month.abb, expand = expansion(add = 0.55)) +
  labs(title = "The season changes with the reef",
       subtitle = "Observed spawning calendars at the 14 best-covered eligible sites, ordered north to south",
       x = NULL, y = NULL,
       caption = paste(source_coral, "\nUnit: one subsite-date. Sites require ≥15 recorded reef-nights across ≥2 years.\nBlank-event months are zero recorded events, not verified biological absence; survey effort is unknown.")) +
  theme_clock() + theme(panel.grid.major = element_blank(), axis.text.y = element_text(size = 11))
save_figure(season_plot, "02_seasonal_calendars", height = 9)
write_csv(calendar, "outputs/tables/02_seasonal_calendars.csv")
