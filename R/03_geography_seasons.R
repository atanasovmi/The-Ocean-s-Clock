# Geographic coverage and seasonal timing, with the observation effort visible.
source("R/style.R")
library(sf)
nights <- read_csv("data/derived/reef_nights.csv", show_col_types = FALSE)

# Map the evidence, not an estimated distribution of coral reefs ----
locations <- nights |>
  group_by(subsite_id, site, country, latitude, longitude) |>
  summarise(n_nights = n(), .groups = "drop")
location_sf <- st_as_sf(locations, coords = c("longitude", "latitude"), crs = 4326,
                        remove = FALSE)
world <- st_as_sf(maps::map("world", fill = TRUE, plot = FALSE)) |>
  filter(!grepl("Antarctica", ID)) |>
  st_break_antimeridian(lon_0 = 150)
pacific_projection <- "+proj=robin +lon_0=150 +datum=WGS84 +units=m +no_defs"

map_plot <- ggplot() +
  geom_sf(data = world, fill = "#E8ECEE", colour = "white", linewidth = 0.15) +
  geom_sf(data = location_sf, aes(size = n_nights), shape = 21,
          fill = ocean, colour = "white", stroke = 0.4, alpha = 0.82) +
  scale_size_area(max_size = 13, breaks = c(1, 25, 100, 200),
                   name = "Recorded reef-nights") +
  coord_sf(crs = pacific_projection, datum = NA, expand = FALSE) +
  labs(x = NULL, y = NULL) +
  theme_clock() +
  theme(panel.grid = element_blank(), panel.grid.major = element_blank(),
        axis.text = element_blank(), axis.ticks = element_blank(),
        plot.margin = margin(0, 0, 0, 0), legend.position = "bottom")

# Geographic signposts; point size remains the only quantitative map encoding.
region_labels <- tibble(
  label = c("RED SEA", "JAPAN & TAIWAN", "SOUTHEAST ASIA", "GREAT BARRIER REEF", "SOUTH PACIFIC", "EASTERN PACIFIC"),
  longitude = c(28, 140, 103, 145, -160, -95),
  latitude = c(34, 38, -3, -29, -27, 14)) |>
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)
map_plot <- map_plot + geom_sf_text(data = region_labels, aes(label = label),
                                   size = 3, fontface = "bold", colour = muted)

annual <- nights |> count(year, name = "n_nights") |>
  complete(year = min(nights$year):max(nights$year), fill = list(n_nights = 0))
annual_plot <- ggplot(annual, aes(year, n_nights)) +
  geom_col(fill = ocean, width = 0.74) +
  scale_x_continuous(breaks = seq(1980, 2020, 5), expand = expansion(add = 0.5)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  labs(x = NULL, y = "Recorded reef-nights", subtitle = "Coverage varies sharply across years") +
  theme_clock() + theme(plot.margin = margin(6, 8, 6, 8),
                         panel.grid.major.x = element_blank(),
                         plot.subtitle = element_text(size = 13, face = "bold", colour = ink))
atlas <- (map_plot / annual_plot) + plot_layout(heights = c(3.6, 1)) +
  plot_annotation(
    title = "Where the spawning records come from",
    subtitle = paste0(format(nrow(nights), big.mark = ","), " recorded reef-nights at ",
                      n_distinct(nights$subsite_id), " subsites, 1978–2019"),
    caption = paste(source_coral,
      "Basemap: maps, projected with sf (Pacific-centred Robinson).",
      "\nNatural-reef records only. One reef-night = one subsite and local date.",
      "Point area shows recorded coverage; it does not estimate reef abundance or survey effort."),
    theme = theme_clock())
save_figure(atlas, "01_observation_atlas", width = 16, height = 10)
write_csv(locations, "outputs/tables/01_observation_atlas.csv")
write_csv(annual, "outputs/tables/01_observation_years.csv")

# Calendar, with a second panel showing which years support each row ----
# Eligibility keeps the geographic range visible; coverage stays explicit.
selected_sites <- nights |>
  group_by(site, country) |>
  summarise(n_nights = n(), n_years = n_distinct(year), latitude = mean(latitude),
            .groups = "drop") |>
  filter(n_nights >= 5) |>
  arrange(desc(latitude)) |>
  mutate(label = paste0(site, ", ", country), row = rev(seq_len(n())))
calendar <- nights |>
  inner_join(select(selected_sites, site, country, label, row, n_nights),
             by = c("site", "country"), relationship = "many-to-one") |>
  count(label, row, n_nights, month) |>
  complete(nesting(label, row, n_nights), month = 1:12, fill = list(n = 0)) |>
  mutate(share = n / n_nights)
coverage <- nights |>
  inner_join(select(selected_sites, site, country, row),
             by = c("site", "country"), relationship = "many-to-one") |>
  distinct(row, year) |>
  left_join(select(selected_sites, row, label, latitude, n_nights, n_years), by = "row")

calendar_plot <- ggplot(calendar, aes(month, row, fill = share)) +
  geom_tile(width = 0.94, height = 0.82) +
  geom_text(data = filter(calendar, share >= 0.4),
            aes(label = scales::percent(share, accuracy = 1),
                colour = if_else(share >= 0.6, "white", ink)),
            size = 2.6, fontface = "bold") +
  scale_colour_identity() +
  scale_fill_gradient(low = "#F1F4F5", high = "#005F73",
                      labels = scales::label_percent(), limits = c(0, 1),
                      name = "Share of recorded reef-nights within site") +
  scale_x_continuous(breaks = 1:12, labels = month.abb, expand = expansion(add = 0.55)) +
  scale_y_continuous(breaks = selected_sites$row, labels = selected_sites$label,
                     expand = expansion(add = 0.6)) +
  labs(x = NULL, y = NULL, subtitle = "Recorded spawning months") +
  theme_clock() + theme(panel.grid.major = element_blank(),
                         axis.text.y = element_text(size = 9.5),
                         plot.margin = margin(0, 6, 0, 0),
                         plot.subtitle = element_text(size = 13, face = "bold", colour = ink))

years_plot <- ggplot(coverage, aes(year, row)) +
  geom_point(size = 1.45, colour = ink) +
  scale_x_continuous(limits = c(1977, 2021), breaks = c(1980, 2000, 2020)) +
  scale_y_continuous(limits = c(0.4, nrow(selected_sites) + 0.6), expand = expansion(mult = 0)) +
  labs(x = NULL, y = NULL, subtitle = "Years with records") +
  theme_clock() + theme(panel.grid.major.y = element_blank(),
                         axis.text.y = element_blank(), axis.ticks.y = element_blank(),
                         plot.margin = margin(0, 4, 0, 0),
                         plot.subtitle = element_text(size = 13, face = "bold", colour = ink))
sample_plot <- ggplot(selected_sites, aes(1, row, label = paste0(n_nights, " / ", n_years))) +
  geom_text(hjust = 0, colour = ink, size = 3) +
  scale_y_continuous(limits = c(0.4, nrow(selected_sites) + 0.6), expand = expansion(mult = 0)) +
  scale_x_continuous(limits = c(1, 1.45)) +
  labs(x = NULL, y = NULL, subtitle = "Nights / years") +
  theme_clock() + theme(panel.grid.major = element_blank(),
                         axis.text = element_blank(), axis.ticks = element_blank(),
                         plot.margin = margin(0, 0, 0, 0),
                         plot.subtitle = element_text(size = 13, face = "bold", colour = ink))
season_plot <- (calendar_plot + years_plot + sample_plot) +
  plot_layout(widths = c(5, 1.8, 0.85), guides = "collect") +
  plot_annotation(
    title = "Spawning seasons shift between reefs",
    subtitle = paste0(nrow(selected_sites), " sites with at least five recorded reef-nights, ordered north to south"),
    caption = paste(source_coral,
      "\nOne count per subsite-date; named sites may contain several subsites. Years panel shows actual years with recorded events.",
      "\nA pale cell means few or no recorded events. Unknown survey effort prevents interpreting it as biological absence."),
    theme = theme_clock())
save_figure(season_plot, "02_seasonal_calendars", width = 17, height = 13)
write_csv(calendar, "outputs/tables/02_seasonal_calendars.csv")
write_csv(coverage, "outputs/tables/02_seasonal_coverage.csv")
