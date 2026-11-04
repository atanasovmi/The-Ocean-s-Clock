# Rebuild the night sky above the timed spawning records.
#
# The Horizons archive gives the Moon's height at the recorded start times only.
# Two questions need more than that: when did the Moon rise that night, and how
# much moonlight was there at every hour of every lunar night? So we calculate
# Moon and Sun positions directly, then check the result against the NASA archive.
library(dplyr)
library(tidyr)
library(readr)

degrees <- pi / 180
synodic_month <- 29.53

# Low-precision formulas of the Astronomical Almanac. Accurate to a few tenths of
# a degree, which is about one minute of moonrise time. Longitude is east-positive.
# Returns the height of Moon and Sun above an ideal sea horizon, in degrees, and
# the lit fraction of the Moon's disc (0 new, 1 full).
sky_position <- function(utc_minute, latitude, longitude) {
  days <- utc_minute / 1440 + 2440587.5 - 2451545     # days since 1 January 2000, 12:00
  century <- days / 36525
  wave <- function(start, speed) sin((start + speed * century) * degrees)
  cowave <- function(start, speed) cos((start + speed * century) * degrees)

  moon_longitude <- 218.32 + 481267.881 * century +
    6.29 * wave(135.0, 477198.87) - 1.27 * wave(259.3, -413335.36) +
    0.66 * wave(235.7, 890534.22) + 0.21 * wave(269.9, 954397.74) -
    0.19 * wave(357.5, 35999.05) - 0.11 * wave(186.5, 966404.03)
  moon_latitude <- 5.13 * wave(93.3, 483202.02) + 0.28 * wave(228.2, 960400.89) -
    0.28 * wave(318.3, 6003.15) - 0.17 * wave(217.6, -407332.21)
  moon_parallax <- 0.9508 + 0.0518 * cowave(135.0, 477198.87) +
    0.0095 * cowave(259.3, -413335.36) + 0.0078 * cowave(235.7, 890534.22) +
    0.0028 * cowave(269.9, 954397.74)

  sun_anomaly <- (357.528 + 0.9856003 * days) * degrees
  sun_longitude <- 280.460 + 0.9856474 * days +
    1.915 * sin(sun_anomaly) + 0.020 * sin(2 * sun_anomaly)

  obliquity <- (23.439 - 0.0000004 * days) * degrees
  star_time <- (280.46061837 + 360.98564736629 * days + longitude) * degrees

  # Turn a position on the ecliptic into a height above the local horizon.
  height <- function(ecliptic_longitude, ecliptic_latitude) {
    lambda <- ecliptic_longitude * degrees
    beta <- ecliptic_latitude * degrees
    x <- cos(beta) * cos(lambda)
    y <- cos(obliquity) * cos(beta) * sin(lambda) - sin(obliquity) * sin(beta)
    z <- sin(obliquity) * cos(beta) * sin(lambda) + cos(obliquity) * sin(beta)
    hour_angle <- star_time - atan2(y, x)
    asin(sin(latitude * degrees) * z +
           cos(latitude * degrees) * sqrt(1 - z^2) * cos(hour_angle)) / degrees
  }

  moon_geocentric <- height(moon_longitude, moon_latitude)
  elongation <- cos(moon_latitude * degrees) * cos((moon_longitude - sun_longitude) * degrees)
  tibble(moon_deg = moon_geocentric - moon_parallax * cos(moon_geocentric * degrees),
         sun_deg = height(sun_longitude, 0),
         moon_lit = (1 - elongation) / 2)
}

# Inputs ----
field <- read_csv("data/derived/field_observations.csv", show_col_types = FALSE)

# Same evening sample as the Horizons request: exact starts after sunset, without
# the ambiguous after-midnight record. Daylight spawners are a separate behaviour.
evening <- field |>
  filter(exact_start, !midnight_ambiguous, start_minutes >= sunset_minutes)

# One dot per genus on one reef-night. A night with many timed species of one
# genus does not get many votes, and the median keeps a single late colony from
# moving the whole group.
genus_starts <- evening |>
  summarise(hours_after_sunset = median(sunset_offset_hours),
            lunar_day = first(lunar_day), sunset_minutes = first(sunset_minutes),
            utc_offset = first(utc_offset), latitude = first(latitude),
            longitude = first(longitude), site = first(site),
            .by = c(subsite_id, date, genus))

# Every timed reef-night, for drawing the sky those dots sit in.
timed_nights <- evening |>
  distinct(subsite_id, date, site, latitude, longitude, utc_offset, sunset_minutes,
           lunar_day, supplied_full_moon)

# Check 1: the formulas against NASA ----
archive <- "data/raw/horizons/reef_moon_positions.zip"
read_horizons <- function(member) {
  stream <- unz(archive, member, open = "rb")
  on.exit(close(stream))
  reply <- jsonlite::fromJSON(paste(readLines(stream, warn = FALSE), collapse = "\n"))
  lines <- strsplit(reply$result, "\n", fixed = TRUE)[[1]]
  rows <- lines[(match("$$SOE", lines) + 1):(match("$$EOE", lines) - 1)]
  columns <- strsplit(rows, ",", fixed = TRUE)
  tibble(subsite_id = as.integer(sub("site_([0-9]+).json", "\\1", member)),
         utc_minute = round((as.numeric(vapply(columns, `[`, "", 1)) - 2440587.5) * 1440),
         horizons_deg = as.numeric(vapply(columns, `[`, "", 5)))
}
horizons <- bind_rows(lapply(unzip(archive, list = TRUE)$Name, read_horizons))
site_coordinates <- distinct(timed_nights, subsite_id, latitude, longitude)
stopifnot(!anyDuplicated(site_coordinates$subsite_id))
moon_check <- horizons |>
  inner_join(site_coordinates, by = "subsite_id", relationship = "many-to-one") |>
  mutate(formula_deg = sky_position(utc_minute, latitude, longitude)$moon_deg,
         difference = formula_deg - horizons_deg)
stopifnot(nrow(moon_check) > 10000, abs(mean(moon_check$difference)) < 0.1,
          max(abs(moon_check$difference)) < 0.75)
message("Moon formula vs NASA Horizons: ", nrow(moon_check), " positions, largest gap ",
        round(max(abs(moon_check$difference)), 2), " degrees.")

# Check 2: the Sun should sit on the horizon at the sunset the source reports.
# This also tests our conversion from local clock time to UTC.
sunset_check <- timed_nights |>
  mutate(utc_minute = as.numeric(date) * 1440 + sunset_minutes - 60 * utc_offset,
         sun_deg = sky_position(utc_minute, latitude, longitude)$sun_deg)
stopifnot(abs(median(sunset_check$sun_deg)) < 2)
message("Sun height at the source's sunset: median ", round(median(sunset_check$sun_deg), 2),
        " degrees (", round(mean(abs(sunset_check$sun_deg) < 3) * 100), "% within 3).")

# The sky on every lunar night ----
# For each timed reef-night, step through a whole lunar cycle around its full moon
# and the hours after sunset. Keeping that night's reef and sunset clock time means
# the sky behind the dots belongs to the same places and seasons as the dots.
sky_samples <- timed_nights |>
  crossing(sky_lunar_day = -15:14, hours_after_sunset = seq(0, 12, by = 0.1)) |>
  mutate(utc_minute = (as.numeric(supplied_full_moon) + sky_lunar_day) * 1440 +
           sunset_minutes - 60 * utc_offset + 60 * hours_after_sunset)
sky_samples <- bind_cols(sky_samples,
                         sky_position(sky_samples$utc_minute, sky_samples$latitude,
                                      sky_samples$longitude))

# Moonlight here means how full times how high: the lit fraction of the disc times
# the sine of its height, which is how light from an angle falls on flat water.
# It runs from 0 (no Moon) to 1 (a full Moon overhead). Clouds are ignored.
sky_grid <- sky_samples |>
  mutate(moonlight = moon_lit * sin(pmax(moon_deg, 0) * degrees)) |>
  summarise(moonlight = mean(moonlight), moon_up_share = mean(moon_deg > 0),
            sun_deg = mean(sun_deg),
            .by = c(sky_lunar_day, hours_after_sunset)) |>
  rename(lunar_day = sky_lunar_day)

# Moonrise ----
# The first hour after sunset at which the Moon climbs through the horizon. For
# each night and lunar day, step through the evening every six minutes.
moonrise_samples <- timed_nights |>
  crossing(sky_lunar_day = -2:14, hours_after_sunset = seq(-3, 13, by = 0.1)) |>
  mutate(utc_minute = (as.numeric(supplied_full_moon) + sky_lunar_day) * 1440 +
           sunset_minutes - 60 * utc_offset + 60 * hours_after_sunset)
moonrise_samples$moon_deg <- sky_position(moonrise_samples$utc_minute, moonrise_samples$latitude,
                                          moonrise_samples$longitude)$moon_deg
moonrise_by_night <- moonrise_samples |>
  arrange(subsite_id, date, sky_lunar_day, hours_after_sunset) |>
  mutate(previous_deg = lag(moon_deg), previous_hour = lag(hours_after_sunset),
         .by = c(subsite_id, date, sky_lunar_day)) |>
  filter(previous_deg < 0, moon_deg >= 0) |>
  mutate(moonrise_hours = previous_hour + 0.1 * -previous_deg / (moon_deg - previous_deg)) |>
  # Within 16 hours the Moon can rise twice; the first climb belongs to this night.
  slice_min(hours_after_sunset, n = 1, by = c(subsite_id, date, sky_lunar_day))
moonrise_curve <- moonrise_by_night |>
  summarise(low = quantile(moonrise_hours, 0.1), high = quantile(moonrise_hours, 0.9),
            moonrise_hours = median(moonrise_hours), nights = n(), .by = sky_lunar_day) |>
  rename(lunar_day = sky_lunar_day) |>
  arrange(lunar_day)

# Each genus start, next to the moonrise of its own night ----
own_moonrise <- moonrise_by_night |>
  filter(sky_lunar_day == lunar_day) |>
  select(subsite_id, date, moonrise_hours)
genus_starts <- genus_starts |>
  left_join(own_moonrise, by = c("subsite_id", "date"), relationship = "many-to-one") |>
  mutate(utc_minute = as.numeric(date) * 1440 + sunset_minutes - 60 * utc_offset +
           60 * hours_after_sunset) |>
  mutate(moon_deg = sky_position(utc_minute, latitude, longitude)$moon_deg) |>
  select(-utc_minute)

write_csv(sky_grid, "data/derived/sky_grid.csv")
write_csv(moonrise_curve, "data/derived/moonrise_curve.csv")
write_csv(genus_starts, "data/derived/genus_starts.csv")
