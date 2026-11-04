# What did the sky look like from the reef at the recorded start time?
library(dplyr)
library(tidyr)
library(readr)

field <- read_csv("data/derived/field_observations.csv", show_col_types = FALSE)
evening <- field |>
  filter(exact_start, !midnight_ambiguous, start_minutes >= sunset_minutes) |>
  mutate(utc_minute = as.numeric(date) * 1440 + start_minutes - 60 * utc_offset)
stopifnot(all(evening$utc_minute == round(evening$utc_minute)))

# The archive contains one original Horizons JSON response per subsite. Use its
# returned Julian dates. Rows can arrive in a different order from the requests.
archive <- "data/raw/horizons/reef_moon_positions.zip"
members <- unzip(archive, list = TRUE)$Name
read_positions <- function(member) {
  stream <- unz(archive, member, open = "rb")
  on.exit(close(stream))
  reply <- jsonlite::fromJSON(paste(readLines(stream, warn = FALSE), collapse = "\n"))
  lines <- strsplit(reply$result, "\n", fixed = TRUE)[[1]]
  first <- match("$$SOE", lines)
  last <- match("$$EOE", lines)
  stopifnot(!is.na(first), last > first + 1, any(grepl("Moon (301)", lines, fixed = TRUE)),
            any(grepl("NO (AIRLESS)", lines, fixed = TRUE)))
  rows <- read_csv(I(paste(lines[(first + 1):(last - 1)], collapse = "\n")),
                   col_names = c("jd", "solar", "flag", "azimuth", "elevation", "empty"),
                   col_types = "dccdd_", trim_ws = TRUE, show_col_types = FALSE)
  tibble(subsite_id = as.integer(sub("site_([0-9]+).json", "\\1", member)),
         utc_minute = round((rows$jd - 2440587.5) * 1440), moon_deg = rows$elevation)
}
sky <- bind_rows(lapply(members, read_positions))
stopifnot(!anyNA(sky), !anyDuplicated(sky[c("subsite_id", "utc_minute")]),
          all(abs(sky$moon_deg) <= 90))

# A richly described night gets the same weight as one with a single timed start.
# Within each reef-night, count each distinct recorded clock minute once.
starts <- evening |> distinct(subsite_id, date, utc_minute)
comparisons <- crossing(starts, shift_days = -14:14) |>
  mutate(target_minute = utc_minute + shift_days * 1440) |>
  left_join(sky, by = c("subsite_id", "target_minute" = "utc_minute"),
            relationship = "many-to-one")
stopifnot(!anyNA(comparisons$moon_deg), nrow(comparisons) == 29 * nrow(starts))
night_shares <- comparisons |>
  summarise(n_start_times = n(), below = mean(moon_deg < 0),
            below_minus_one = mean(moon_deg < -1), below_plus_one = mean(moon_deg < 1),
            .by = c(subsite_id, date, shift_days))
by_site <- night_shares |>
  summarise(site_share = mean(below), .by = c(subsite_id, shift_days)) |>
  summarise(equal_site_share = mean(site_share), .by = shift_days)
moon_calendar <- night_shares |>
  summarise(share_below = mean(below), low_threshold_share = mean(below_minus_one),
            high_threshold_share = mean(below_plus_one), reef_nights = n(),
            start_times = sum(n_start_times), subsites = n_distinct(subsite_id),
            .by = shift_days) |>
  left_join(by_site, by = "shift_days", relationship = "one-to-one") |>
  arrange(shift_days)
write_csv(moon_calendar, "outputs/tables/08_moon_calendar.csv")

# The first precise record per species on the historical Orpheus evening.
# One species was recorded at two times. It contributes only its first start.
orpheus <- evening |> filter(subsite_id == 40, date == as.Date("1983-11-24"))
stopifnot(n_distinct(orpheus$utc_offset) == 1, n_distinct(orpheus$sunset_minutes) == 1,
          !anyNA(orpheus$species))
orpheus_species <- orpheus |>
  arrange(start_minutes, Obs_ID) |> slice_head(n = 1, by = Coral_ID) |>
  select(Obs_ID, Coral_ID, subsite_id, date, genus, species, start_minutes, utc_minute) |>
  left_join(sky, by = c("subsite_id", "utc_minute"), relationship = "many-to-one")
local_midnight <- as.numeric(first(orpheus$date)) * 1440 - 60 * first(orpheus$utc_offset)
track <- sky |>
  filter(subsite_id == 40, between(utc_minute - local_midnight, 1080, 1440)) |>
  transmute(local_minute = utc_minute - local_midnight, moon_deg) |> arrange(local_minute)
stopifnot(identical(as.integer(track$local_minute), 1080:1440),
          !anyNA(orpheus_species$moon_deg))
write_csv(orpheus_species, "outputs/tables/07_orpheus_species.csv")
write_csv(track, "outputs/tables/07_orpheus_moon_track.csv")
