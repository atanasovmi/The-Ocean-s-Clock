# Where on the local temperature curve does each reef-night sit?
#
# Calendar months cannot be compared across the equator: June is the warm season
# in Okinawa and the cool season on the Great Barrier Reef. So each region gets its
# own typical year of sea temperature, and every reef-night is placed on that curve.
library(dplyr)
library(tidyr)
library(readr)

daily <- readRDS("data/derived/regional_daily.rds") |> filter(between(year, 1986, 2024))
regions <- read_csv("data/derived/region_catalogue.csv", show_col_types = FALSE)
lookup <- read_csv("data/derived/reef_region_lookup.csv", show_col_types = FALSE)
nights <- read_csv("data/derived/reef_nights.csv", show_col_types = FALSE)

# A 31-day moving average that wraps from December back into January.
smooth_year <- function(values, width = 31) {
  half <- width %/% 2
  padded <- c(tail(values, half), values, head(values, half))
  as.numeric(stats::filter(padded, rep(1 / width, width)))[(half + 1):(half + length(values))]
}

# Change over a centred 30-day span, in degrees per 30 days. It wraps the same way.
warming_rate <- function(temperature) {
  wrapped <- c(tail(temperature, 15), temperature, head(temperature, 15))
  wrapped[31:395] - wrapped[1:365]
}

# Typical year ----
# Mean temperature for each day of the year over the 39 complete years. Day 366
# of a leap year is dropped; the one-day shift after 29 February does not matter
# at this scale. This is NOAA's regional statistic, not a thermometer at the coral.
typical_year <- daily |>
  mutate(day_of_year = as.integer(format(date, "%j"))) |>
  filter(day_of_year <= 365) |>
  summarise(sst_c = mean(sst_c, na.rm = TRUE), .by = c(station_id, day_of_year)) |>
  arrange(station_id, day_of_year) |>
  mutate(smooth_sst_c = smooth_year(sst_c),
         warming_c_per_month = warming_rate(smooth_sst_c), .by = station_id)
stopifnot(nrow(typical_year) == 214 * 365, !anyNA(typical_year$warming_c_per_month))

region_seasons <- typical_year |>
  summarise(peak_day = day_of_year[which.max(smooth_sst_c)],
            cold_day = day_of_year[which.min(smooth_sst_c)],
            coldest_c = min(smooth_sst_c), warmest_c = max(smooth_sst_c),
            warming_share_of_year = mean(warming_c_per_month > 0),
            .by = station_id)

# Reef-nights on the curve ----
# Five subsites lie outside every NOAA region and drop out here. The typical year
# needs no same-date match, so nights before satellite coverage can stay in.
night_positions <- nights |>
  left_join(select(lookup, subsite_id, station_id, station_name), by = "subsite_id",
            relationship = "many-to-one") |>
  filter(!is.na(station_id)) |>
  mutate(day_of_year = pmin(as.integer(format(date, "%j")), 365L)) |>
  left_join(region_seasons, by = "station_id", relationship = "many-to-one") |>
  left_join(select(typical_year, station_id, day_of_year, smooth_sst_c, warming_c_per_month),
            by = c("station_id", "day_of_year"), relationship = "many-to-one") |>
  mutate(days_from_peak = ((day_of_year - peak_day + 182) %% 365) - 182,
         warming = warming_c_per_month > 0)
stopifnot(!anyNA(night_positions$smooth_sst_c), all(abs(night_positions$days_from_peak) <= 182))

# Warming field ----
# Average warming rate by latitude band and 5-day step across all 214 regions,
# whether or not they have spawning records. This is the backdrop for plate 2.
warming_field <- typical_year |>
  left_join(select(regions, station_id, marker_latitude), by = "station_id",
            relationship = "many-to-one") |>
  mutate(latitude_band = floor(marker_latitude / 2.5) * 2.5 + 1.25,
         day_step = ((day_of_year - 1) %/% 5) * 5 + 3) |>
  summarise(warming_c_per_month = mean(warming_c_per_month),
            regions = n_distinct(station_id), .by = c(latitude_band, day_step))

write_csv(region_seasons, "data/derived/region_seasons.csv")
write_csv(night_positions, "data/derived/reef_night_seasons.csv")
write_csv(warming_field, "data/derived/warming_field.csv")
