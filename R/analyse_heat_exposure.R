# Connect historical spawning calendars to four decades of regional heat stress.
library(dplyr)
library(tidyr)
library(readr)
daily <- readRDS("data/derived/regional_daily.rds") |> filter(between(year, 1986, 2024))
annual <- read_csv("data/derived/regional_annual.csv", show_col_types = FALSE) |>
  filter(between(year, 1986, 2024), complete_year)
regions <- read_csv("data/derived/region_catalogue.csv", show_col_types = FALSE)
lookup <- read_csv("data/derived/reef_region_lookup.csv", show_col_types = FALSE)
nights <- read_csv("data/derived/reef_nights.csv", show_col_types = FALSE)

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

write_csv(eligible, "data/derived/calendar_eligible_sites.csv")
write_csv(weights, "data/derived/spawning_calendar_weights.csv")
write_csv(exposure, "data/derived/calendar_exposure.csv")
write_csv(comparison, "data/derived/decadal_exposure.csv")
message(nrow(eligible), " eligible sites in ", nrow(comparison), " regions.")
