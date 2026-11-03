# Regional ocean context: 1985-2025, every published NOAA region.
# NOAA's regional values are NOT thermometers placed at each coral observation.
library(dplyr)
library(tidyr)
library(readr)
library(sf)

manifest <- read_csv("data/raw/crw/manifest.csv", show_col_types = FALSE)
stopifnot(!anyDuplicated(manifest$station_id))
dir.create("data/derived", recursive = TRUE, showWarnings = FALSE)

# Each file has a short metadata header followed by a daily whitespace table.
read_region <- function(path, station_id) {
  connection <- gzfile(path, "rt")
  header <- readLines(connection, n = 40, warn = FALSE)
  close(connection)
  header_row <- which(grepl("^YYYY", header))[1]
  stopifnot(!is.na(header_row))
  daily <- read_table(path, skip = header_row,
    col_names = c("year", "month", "day", "sst_min_c", "sst_max_c", "sst_c",
                  "ssta_c", "hotspot_c", "dhw_c_weeks", "alert_level"),
    col_types = cols(.default = col_double()), progress = FALSE)
  stopifnot(nrow(problems(daily)) == 0)
  daily <- daily |>
    mutate(station_id = station_id,
           date = as.Date(sprintf("%04d-%02d-%02d", year, month, day)),
           across(c(year, month, day, alert_level), as.integer)) |>
    filter(date <= as.Date("2025-12-31"))
  stopifnot(!anyNA(daily$date), !anyDuplicated(daily$date),
            min(daily$date) == as.Date("1985-01-01"),
            max(daily$date) == as.Date("2025-12-31"))
  metadata_value <- function(label) header[grep(label, header, fixed = TRUE)[1] + 1]
  metadata <- tibble(station_id = station_id,
    station_name = metadata_value("Name:"),
    marker_longitude = as.numeric(metadata_value("Polygon Middle Longitude:")),
    marker_latitude = as.numeric(metadata_value("Polygon Middle Latitude:")),
    maximum_monthly_mean_c = as.numeric(metadata_value("Averaged Maximum Monthly Mean:")))
  missing_dates <- setdiff(seq(as.Date("1985-01-01"), as.Date("2025-12-31"), by = "day"), daily$date)
  gaps <- tibble(station_id = station_id, date = as.Date(missing_dates, origin = "1970-01-01"))
  list(daily = daily, metadata = metadata, gaps = gaps)
}

regions <- lapply(seq_len(nrow(manifest)), function(i) {
  if (i %% 25 == 0) message("Read NOAA region ", i, "/", nrow(manifest))
  read_region(manifest$path[i], manifest$station_id[i])
})
regional_daily <- bind_rows(lapply(regions, `[[`, "daily"))
region_catalogue <- bind_rows(lapply(regions, `[[`, "metadata"))
calendar_gaps <- bind_rows(lapply(regions, `[[`, "gaps"))
stopifnot(!anyNA(regional_daily$sst_c), all(regional_daily$sst_c > -3),
          all(regional_daily$sst_c < 45), !anyNA(region_catalogue$maximum_monthly_mean_c))
saveRDS(regional_daily, "data/derived/regional_daily.rds", compress = "gzip")
write_csv(region_catalogue, "data/derived/region_catalogue.csv")
write_csv(calendar_gaps, "data/derived/regional_calendar_gaps.csv")
display_groups <- read_csv("data/raw/crw/station_groups.csv", show_col_types = FALSE)
stopifnot(!anyDuplicated(display_groups$station_id),
          setequal(display_groups$station_id, region_catalogue$station_id))
write_csv(display_groups, "data/derived/region_display_groups.csv")

# Keep the full daily series, but exclude 1985 from heat-stress comparisons:
# the initial 84-day accumulation window was not valid at the start of that year.
regional_annual <- regional_daily |>
  filter(year >= 1986) |>
  group_by(station_id, year) |>
  summarise(n_days = n(), mean_sst_c = mean(sst_c), mean_ssta_c = mean(ssta_c),
            max_dhw_c_weeks = max(dhw_c_weeks),
            days_dhw4 = sum(dhw_c_weeks >= 4), days_dhw8 = sum(dhw_c_weeks >= 8),
            days_hotspot1 = sum(hotspot_c >= 1), .groups = "drop") |>
  mutate(expected_days = as.integer(as.Date(paste0(year + 1, "-01-01")) - as.Date(paste0(year, "-01-01"))),
         coverage = n_days / expected_days, complete_year = n_days == expected_days) |>
  left_join(region_catalogue, by = "station_id", relationship = "many-to-one")
stopifnot(all(regional_annual$n_days <= regional_annual$expected_days))
write_csv(regional_annual, "data/derived/regional_annual.csv")

# A real spatial join against NOAA's published region boundaries.
# Marker distances alone do not define which regional data a reef belongs to.
features <- st_read("data/raw/crw/station_polygons.geojson", quiet = TRUE)
polygons <- features |>
  filter(st_geometry_type(geometry) %in% c("POLYGON", "MULTIPOLYGON")) |>
  mutate(station_id = sub("\\.php.*$", "", gauge_page)) |>
  select(station_id)
stopifnot(!anyDuplicated(polygons$station_id), all(st_is_valid(polygons)),
          setequal(polygons$station_id, region_catalogue$station_id))
reef_nights <- read_csv("data/derived/reef_nights.csv", show_col_types = FALSE)
subsites <- reef_nights |> distinct(subsite_id, site, country, latitude, longitude)
points <- st_as_sf(subsites, coords = c("longitude", "latitude"), crs = 4326, remove = FALSE)
reef_region_lookup <- st_join(points, polygons, join = st_intersects, left = TRUE) |>
  st_drop_geometry() |>
  left_join(region_catalogue, by = "station_id", relationship = "many-to-one") |>
  mutate(match_method = if_else(is.na(station_id), "outside_published_regions", "inside_NOAA_polygon"))
stopifnot(!anyDuplicated(reef_region_lookup$subsite_id))
write_csv(reef_region_lookup, "data/derived/reef_region_lookup.csv")

# Unknown environmental context stays missing. No nearest-region imputation.
regional_events <- reef_nights |>
  left_join(select(reef_region_lookup, subsite_id, station_id, station_name, match_method),
            by = "subsite_id", relationship = "many-to-one") |>
  left_join(select(regional_daily, station_id, date, sst_c, ssta_c, hotspot_c,
                   dhw_c_weeks, alert_level),
            by = c("station_id", "date"), relationship = "many-to-one")
stopifnot(nrow(regional_events) == nrow(reef_nights))
write_csv(regional_events, "data/derived/regional_events.csv")
message(format(nrow(regional_daily), big.mark = ","), " regional daily records; ",
        nrow(region_catalogue), " regions; ", sum(!is.na(regional_events$sst_c)),
        "/", nrow(regional_events), " recorded reef-nights matched to regional ocean context.")
