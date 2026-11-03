# External environmental context. Existing public responses are cached verbatim.
library(dplyr)
library(readr)
library(jsonlite)
library(httr2)
.libPaths(c(".Rlibrary", .libPaths()))
library(ncdf4)

dir.create("data/raw/noaa", recursive = TRUE, showWarnings = FALSE)
dir.create("data/raw/usno", recursive = TRUE, showWarnings = FALSE)
reef_nights <- read_csv("data/derived/reef_nights.csv", show_col_types = FALSE)
requests_log <- list()

fetch_cached <- function(url, path) {
  if (!file.exists(path)) {
    response <- request(url) |> req_timeout(60) |> req_retry(max_tries = 2) |> req_perform()
    writeBin(resp_body_raw(response), path)
  }
  requests_log[[length(requests_log) + 1]] <<- tibble(
    path = path, url = url, bytes = file.info(path)$size,
    md5 = unname(tools::md5sum(path)))
  path
}

# Select ONE actual subsite per location; the plotted events use exactly that subsite.
# The bounded 2016 case study combines monthly reference samples and exact
# recorded event dates. It is not a daily annual series or a climate normal.
thermal_sites <- reef_nights |>
  filter(site %in% c("Raffles Lighthouse", "Orpheus Island", "Sesoko"), year == 2016) |>
  count(site, subsite_id, latitude, longitude, name = "n_nights") |>
  group_by(site) |> arrange(desc(n_nights), subsite_id) |> slice_head(n = 1) |> ungroup()
write_csv(thermal_sites, "data/derived/thermal_sites.csv")
thermal_events <- reef_nights |>
  semi_join(thermal_sites, by = "subsite_id") |> filter(year == 2016)
reference_dates <- seq(as.Date("2016-01-01"), as.Date("2016-12-01"), by = "month")
sample_dates <- sort(unique(c(reference_dates, thermal_events$date)))
# Grid indices are chosen once from the first file and held fixed for all dates.
grid_cells <- NULL
sst_parts <- list()
for (i in seq_along(sample_dates)) {
  sample_date <- sample_dates[i]
  filename <- sprintf("oisst-avhrr-v02r01.%s.nc", format(sample_date, "%Y%m%d"))
  path <- file.path("data/raw/noaa", filename)
  url <- sprintf(paste0("https://www.ncei.noaa.gov/data/sea-surface-temperature-",
                        "optimum-interpolation/v2.1/access/avhrr/%s/%s"),
                 format(sample_date, "%Y%m"), filename)
  message("NOAA daily grid: ", sample_date)
  fetch_cached(url, path)
  grid <- nc_open(path)
  # Check the file's time coordinate, not just the requested filename.
  stopifnot(ncatt_get(grid, "time", "units")$value == "days since 1978-01-01 12:00:00",
            ncatt_get(grid, "sst", "units")$value == "Celsius")
  returned_date <- as.Date("1978-01-01") + ncvar_get(grid, "time")
  stopifnot(returned_date == sample_date)
  temperatures <- ncvar_get(grid, "sst") # ncdf4 applies the source scale and missing-value mask.
  latitudes <- ncvar_get(grid, "lat")
  longitudes <- ncvar_get(grid, "lon")
  nc_close(grid)
  if (is.null(grid_cells)) {
    chosen <- lapply(seq_len(nrow(thermal_sites)), function(j) {
      row <- thermal_sites[j, ]
      candidates <- expand.grid(lon_index = which(abs(longitudes - row$longitude %% 360) < 0.75),
                                lat_index = which(abs(latitudes - row$latitude) < 0.75))
      candidates$sst_c <- temperatures[as.matrix(candidates[c("lon_index", "lat_index")])]
      candidates$grid_latitude <- latitudes[candidates$lat_index]
      candidates$grid_longitude <- longitudes[candidates$lon_index]
      # Great-circle distance, earth radius 6371 km; nearest finite ocean cell.
      a <- sin((candidates$grid_latitude - row$latitude) * pi / 360)^2 +
        cos(row$latitude * pi / 180) * cos(candidates$grid_latitude * pi / 180) *
        sin((candidates$grid_longitude - row$longitude) * pi / 360)^2
      candidates$grid_distance_km <- 2 * 6371 * atan2(sqrt(a), sqrt(1 - a))
      candidates <- candidates |> filter(is.finite(sst_c)) |> arrange(grid_distance_km)
      stopifnot(nrow(candidates) > 0, candidates$grid_distance_km[1] < 60)
      bind_cols(row, select(candidates[1, ], -sst_c))
    })
    grid_cells <- bind_rows(chosen)
    write_csv(grid_cells, "data/derived/thermal_grid_cells.csv")
  }
  sst_parts[[i]] <- grid_cells |>
    mutate(date = sample_date,
           sst_c = temperatures[cbind(lon_index, lat_index)],
           monthly_reference = sample_date %in% reference_dates) |>
    select(subsite_id, site, date, sst_c, monthly_reference,
           grid_latitude, grid_longitude, grid_distance_km,
           requested_latitude = latitude, requested_longitude = longitude)
}
sst_daily <- bind_rows(sst_parts)
stopifnot(!anyNA(sst_daily$sst_c), all(sst_daily$sst_c > -3 & sst_daily$sst_c < 45))
sst_events <- thermal_events |>
  left_join(select(sst_daily, subsite_id, date, sst_c, grid_latitude, grid_longitude),
            by = c("subsite_id", "date"), relationship = "many-to-one")
stopifnot(!anyNA(sst_events$sst_c))
write_csv(sst_daily, "data/derived/sst_daily.csv")
write_csv(sst_events, "data/derived/sst_events.csv")

# Independently validate moon dates wherever cached USNO phases cover the event.
# A bounded offline run uses the complete cached responses and needs no service.
fetch_cached("https://aa.usno.navy.mil/api/moon/phases/date?date=1995-11-01&nump=5",
             "data/raw/usno/moon_phases_199511.json")
moon_files <- list.files("data/raw/usno", pattern = "\\.json$", full.names = TRUE)
moon_parts <- lapply(moon_files, function(path) {
  response <- fromJSON(path)
  phases <- response$phasedata
  if (is.null(phases)) return(NULL)
  phases |>
    filter(phase == "Full Moon") |>
    transmute(full_moon_utc = as.POSIXct(sprintf("%04d-%02d-%02d %s", year, month, day, time),
                                        format = "%Y-%m-%d %H:%M", tz = "UTC"))
})
moons <- bind_rows(moon_parts) |> distinct() |> arrange(full_moon_utc)
if (nrow(moons)) {
  audit_parts <- lapply(seq_len(nrow(reef_nights)), function(i) {
    event <- reef_nights[i, ]
    local_dates <- as.Date(moons$full_moon_utc + event$utc_offset * 3600, tz = "UTC")
    delta <- as.numeric(event$date - local_dates)
    tied <- which(abs(delta) == min(abs(delta)))
    # Prefer the future moon on an exact calendar-distance tie, as [-15,+14].
    nearest <- tail(tied, 1)
    if (!length(nearest) || abs(delta[nearest]) > 15) return(NULL)
    mutate(event, usno_full_moon_utc = moons$full_moon_utc[nearest],
           usno_full_moon_local = local_dates[nearest], usno_lunar_day = delta[nearest],
           calendar_distance_tie = length(tied) > 1,
           difference_days = usno_lunar_day - lunar_day)
  })
  lunar_audit <- bind_rows(audit_parts)
  write_csv(lunar_audit, "data/derived/lunar_audit.csv")
  message("Independent moon matches: ", nrow(lunar_audit))
}
write_csv(bind_rows(requests_log), "data/derived/request_manifest.csv")
message("Temperature panel: ", nrow(sst_daily), " daily values; ", nrow(sst_events), " reef-nights")
