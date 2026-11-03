# Connect historical spawning calendars to four decades of regional heat stress.
source("R/style.R")
daily <- readRDS("data/derived/regional_daily.rds") |> filter(between(year, 1986, 2024))
annual <- read_csv("data/derived/regional_annual.csv", show_col_types = FALSE) |>
  filter(between(year, 1986, 2024), complete_year)
regions <- read_csv("data/derived/region_catalogue.csv", show_col_types = FALSE)
lookup <- read_csv("data/derived/reef_region_lookup.csv", show_col_types = FALSE)
nights <- read_csv("data/derived/reef_nights.csv", show_col_types = FALSE)

# A worldwide view: every region has the same influence, not the same reef area.
source_groups <- read_csv("data/derived/region_display_groups.csv", show_col_types = FALSE)
annual <- annual |> left_join(select(source_groups, station_id, display_group), by = "station_id", relationship = "many-to-one") |>
  mutate(basin = display_group)
ordering <- annual |> distinct(station_id, station_name, basin, marker_latitude) |>
  arrange(basin, desc(marker_latitude))
annual <- annual |> mutate(station_id = factor(station_id, levels = rev(ordering$station_id)))
global <- annual |> group_by(year) |>
  summarise(regions = n(), share4 = mean(max_dhw_c_weeks >= 4), share8 = mean(max_dhw_c_weeks >= 8), .groups = "drop") |>
  pivot_longer(c(share4, share8), names_to = "threshold", values_to = "share") |>
  mutate(threshold = recode(threshold, share4 = "Reached 4 °C-weeks", share8 = "Reached 8 °C-weeks"))
trend <- ggplot(global, aes(year, share, colour = threshold)) +
  geom_line(linewidth = 1) + geom_point(data = filter(global, year == 2024), size = 2) +
  scale_colour_manual(values = c("#E69F00", "#9E2447"), name = NULL) +
  scale_y_continuous(labels = scales::label_percent(), limits = c(0, 1)) +
  scale_x_continuous(breaks = seq(1990, 2020, 10)) +
  labs(x = NULL, y = "Share of regions") + theme_clock(12) +
  theme(plot.margin = margin(0, 10, 0, 10), legend.position = "top")
labels_sparse <- ordering |> mutate(label = if_else(row_number() %% 8 == 0, station_name, ""))
carpet <- ggplot(annual, aes(year, station_id, fill = max_dhw_c_weeks)) +
  geom_tile(width = .96, height = 1) +
  facet_grid(basin ~ ., scales = "free_y", space = "free_y") +
  scale_y_discrete(labels = setNames(labels_sparse$label, labels_sparse$station_id), expand = c(0, 0)) +
  scale_fill_gradientn(colours = c("#FAFAFA", "#FFE0A3", "#F2994A", "#D54C36", "#7F174B", "#28133D"),
                       values = scales::rescale(c(0, 4, 8, 12, 20, 40)), limits = c(0, 40),
                       oob = scales::squish, breaks = c(0, 4, 8, 16, 32, 40), labels = c("0", "4", "8", "16", "32", "40+"), name = "Annual maximum DHW (°C-weeks)") +
  scale_x_continuous(breaks = c(1986, 1990, 1995, 2000, 2005, 2010, 2015, 2020, 2024), expand = c(0, 0)) +
  labs(x = NULL, y = "214 NOAA reef regions, ordered by latitude within each source group") + theme_clock(11) +
  theme(panel.grid.major = element_blank(), panel.spacing.y = grid::unit(.25, "lines"),
        strip.text.y = element_text(angle = 0, size = 10), axis.text.y = element_text(size = 7),
        legend.position = "bottom", plot.margin = margin(0, 10, 0, 10))
p <- (trend / carpet) + plot_layout(heights = c(1, 4)) +
  plot_annotation(title = "Severe heat stress now reaches most monitored reef regions",
    subtitle = "Annual maxima across 214 NOAA regions, 1986–2024. Each row is a region; each column is a year.",
    caption = "Source: NOAA Coral Reef Watch v3.1 regional virtual stations. DHW accumulates sustained heat stress over 12 weeks.\nThresholds describe heat-stress conditions, not observed bleaching or spawning failure. Regions receive equal weight; facets follow NOAA's geographic groups, with duplicate listings assigned once.", theme = theme_clock())
save_figure(p, "06_regional_heat_stress", width = 16, height = 13)
write_csv(annual, "outputs/tables/06_regional_heat_stress.csv")
write_csv(global, "outputs/tables/06_global_threshold_shares.csv")

# Define the biological calendar before inspecting the heat series.
# Eligible sites: at least 10 recorded subsite-dates over at least 3 years.
bio <- nights |> left_join(select(lookup, subsite_id, station_id, station_name), by = "subsite_id", relationship = "many-to-one") |>
  filter(!is.na(station_id))
eligible <- bio |> group_by(site, country, station_id, station_name) |>
  summarise(n_nights = n(), years = n_distinct(year), .groups = "drop") |> filter(n_nights >= 10, years >= 3)
site_months <- bio |> semi_join(eligible, by = c("site", "country", "station_id")) |>
  count(site, country, station_id, station_name, month) |>
  complete(nesting(site, country, station_id, station_name), month = 1:12, fill = list(n = 0)) |>
  group_by(site, country, station_id) |> mutate(calendar_weight = n / sum(n)) |> ungroup()
weights <- site_months |> group_by(station_id, station_name, month) |>
  summarise(calendar_weight = mean(calendar_weight), n_sites = n(), .groups = "drop")
stopifnot(all(abs((weights |> summarise(s = sum(calendar_weight), .by = station_id))$s - 1) < 1e-10))
monthly <- daily |> semi_join(weights, by = "station_id") |>
  group_by(station_id, year, month) |>
  summarise(stress_fraction = mean(dhw_c_weeks >= 4), mean_ssta = mean(ssta_c), max_dhw = max(dhw_c_weeks), .groups = "drop") |>
  inner_join(weights, by = c("station_id", "month"), relationship = "many-to-one")
exposure <- monthly |> group_by(station_id, station_name, year) |>
  summarise(calendar_exposure = sum(calendar_weight * stress_fraction),
            calendar_anomaly = sum(calendar_weight * mean_ssta), n_sites = first(n_sites), .groups = "drop")
comparison <- exposure |> mutate(period = case_when(between(year, 1986, 1995) ~ "1986–1995",
                                                    between(year, 2015, 2024) ~ "2015–2024", TRUE ~ NA_character_)) |>
  filter(!is.na(period)) |> group_by(station_id, station_name, period) |>
  summarise(mean_exposure = mean(calendar_exposure), .groups = "drop") |>
  pivot_wider(names_from = period, values_from = mean_exposure) |>
  mutate(change = `2015–2024` - `1986–1995`) |> arrange(change)
exposure <- exposure |> mutate(station_name = factor(station_name, levels = comparison$station_name))

# The key integration: a fixed historical calendar against changing conditions.
tiles <- ggplot(exposure, aes(year, station_name, fill = calendar_exposure)) +
  geom_tile(width = .95, height = .9) +
  scale_fill_gradientn(colours = c("#F4F7F8", "#F8C976", "#DF733D", "#9E2447"), limits = c(0, 1),
                       labels = scales::label_percent(), name = "Calendar-weighted fraction of days at DHW ≥4") +
  scale_x_continuous(breaks = c(1986, 1995, 2005, 2015, 2024), expand = c(0, 0)) +
  labs(x = NULL, y = NULL, subtitle = "Historical spawning-calendar weights held fixed across all 39 years") +
  theme_clock(12) + theme(panel.grid.major = element_blank(), plot.margin = margin(0, 12, 0, 4))
changes <- comparison |> mutate(station_name = factor(station_name, levels = comparison$station_name)) |>
  pivot_longer(c(`1986–1995`, `2015–2024`), names_to = "period", values_to = "exposure")
slope <- ggplot(changes, aes(exposure, station_name, colour = period)) +
  geom_line(aes(group = station_name), colour = "#AAB6BE", linewidth = .8) + geom_point(size = 2.8) +
  scale_colour_manual(values = c(ocean, coral), name = NULL) +
  scale_x_continuous(labels = scales::label_percent(), limits = c(0, 1)) +
  labs(x = "Decade mean", y = NULL) + theme_clock(12) +
  theme(axis.text.y = element_blank(), panel.grid.major.y = element_blank(), legend.position = "top", plot.margin = margin(0, 8, 0, 4))
p <- (tiles | slope) + plot_layout(widths = c(3.5, 1)) +
  plot_annotation(title = "Historical spawning seasons show uneven heat-stress exposure",
    subtitle = paste(nrow(eligible), "well-recorded sites connect biological calendars to", nrow(comparison), "NOAA regions."),
    caption = "Sources: Coral Spawning Database v1; NOAA Coral Reef Watch. Monthly event shares are calculated per site, then sites receive equal weight within a region.\nThis is a fixed-calendar exposure index, not a measured change in spawning, a mortality estimate or a forecast. Observation effort can influence the historical calendar.", theme = theme_clock())
save_figure(p, "08_spawning_season_exposure", width = 16, height = max(8, nrow(comparison) * .35 + 3))

# Separate the calendar from the heat record at the best-covered matched sites.
show_regions <- eligible |> group_by(station_id, station_name) |>
  summarise(n_nights = sum(n_nights), .groups = "drop") |> slice_max(n_nights, n = 8, with_ties = FALSE)
monthly_decades <- monthly |> semi_join(show_regions, by = "station_id") |>
  filter(between(year, 1986, 1995) | between(year, 2015, 2024)) |>
  mutate(period = if_else(year <= 1995, "1986–1995", "2015–2024")) |>
  group_by(station_id, station_name, month, period) |>
  summarise(stress_fraction = mean(stress_fraction), calendar_weight = first(calendar_weight), .groups = "drop")
profile <- ggplot(monthly_decades, aes(month, stress_fraction, colour = period)) +
  geom_area(data = distinct(monthly_decades, station_id, station_name, month, calendar_weight),
            aes(month, calendar_weight, fill = "Recorded spawning share"), colour = NA, inherit.aes = FALSE, alpha = .22) +
  geom_line(linewidth = .85) + facet_wrap(~station_name, ncol = 2) +
  scale_colour_manual(values = c(ocean, coral), name = "Heat-stress days") +
  scale_fill_manual(values = c("Recorded spawning share" = "#5E6B76"), name = NULL) +
  guides(colour = guide_legend(order = 1), fill = guide_legend(order = 2)) +
  scale_x_continuous(breaks = c(1, 4, 7, 10), labels = c("Jan", "Apr", "Jul", "Oct")) +
  scale_y_continuous(labels = scales::label_percent(), limits = c(0, 1)) +
  labs(title = "Heat-stress seasons are changing around recorded spawning windows",
       subtitle = "Grey areas show the historical monthly spawning distribution; coloured lines show the fraction of days at DHW ≥4.",
       x = NULL, y = "Fraction within month / recorded spawning share",
       caption = "Sources: Coral Spawning Database v1; NOAA Coral Reef Watch. Eight best-covered eligible regions.\nThe two measures share a percentage scale but have different denominators. Curves connect monthly summaries; they do not imply daily interpolation or reproductive harm.") +
  theme_clock(12) + theme(panel.spacing = grid::unit(1.1, "lines"))
save_figure(profile, "09_seasonal_heat_overlap", width = 16, height = 11)
write_csv(eligible, "data/derived/calendar_eligible_sites.csv")
write_csv(weights, "data/derived/spawning_calendar_weights.csv")
write_csv(exposure, "data/derived/calendar_exposure.csv")
write_csv(comparison, "outputs/tables/08_decadal_exposure.csv")
write_csv(monthly_decades, "outputs/tables/09_seasonal_heat_overlap.csv")
write_csv(exposure, "outputs/tables/08_calendar_exposure.csv")
message(nrow(eligible), " eligible sites; ", nrow(comparison), " calendar-linked regions; ", nrow(annual), " complete regional years")
