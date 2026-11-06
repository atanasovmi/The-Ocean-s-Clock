# How tightly does each natural cycle hold the spawning records?
#
# Year, lunar month and day are all circles: the end of each runs into its start.
# So they are summarised the way a compass reading is. Every record becomes a unit
# arrow pointing at its place on the cycle, and the arrows are averaged. The average
# points at the typical moment. Its length is the "tightness": 1 means every record
# fell at the same moment, 0 means they are spread evenly around the cycle.
library(dplyr)
library(tidyr)
library(readr)

synodic_month <- 29.53

circular_summary <- function(value, period) {
  angle <- 2 * pi * value / period
  east <- mean(cos(angle))
  north <- mean(sin(angle))
  tibble(n = length(value), tightness = sqrt(east^2 + north^2),
         typical = atan2(north, east) * period / (2 * pi))
}

nights <- read_csv("data/derived/reef_nights.csv", show_col_types = FALSE)
seasons <- read_csv("data/derived/reef_night_seasons.csv", show_col_types = FALSE)
genus_starts <- read_csv("data/derived/genus_starts.csv", show_col_types = FALSE)
field <- read_csv("data/derived/field_observations.csv", show_col_types = FALSE)
maldives <- read_csv("data/derived/maldives_observations.csv", show_col_types = FALSE)
aquarium <- read_csv("data/derived/aquarium_diary.csv", show_col_types = FALSE)
moonrise <- read_csv("data/derived/moonrise_curve.csv", show_col_types = FALSE)

# The three clocks ----
# The Sun dial runs round 24 hours from sunset, so it also holds the starts made
# before sunset, including the dawn spawners. Only the ambiguous after-midnight
# records stay out.
all_exact_starts <- field |>
  filter(exact_start, !midnight_ambiguous) |>
  summarise(hours_after_sunset = median(sunset_offset_hours), .by = c(subsite_id, date, genus)) |>
  mutate(hours_on_dial = hours_after_sunset %% 24)

clock_summary <- bind_rows(
  circular_summary(seasons$days_from_peak, 365) |>
    mutate(clock = "year", unit = "days from the local temperature peak", period = 365),
  circular_summary(nights$lunar_day, synodic_month) |>
    mutate(clock = "moon", unit = "days from full moon", period = synodic_month),
  circular_summary(all_exact_starts$hours_on_dial, 24) |>
    mutate(clock = "sun", unit = "hours after sunset", period = 24)
)
write_csv(all_exact_starts, "data/derived/all_exact_starts.csv")
write_csv(clock_summary, "outputs/tables/clock_summary.csv")

# Lunar tightness place by place ----
# A site needs at least 12 recorded reef-nights to get its own row. The Maldives
# atolls and the aquarium are independent records and join on the same scale. The
# aquarium's latitude is its location at Motobu, Okinawa.
site_tightness <- nights |>
  mutate(place = site) |>
  summarise(circular_summary(lunar_day, synodic_month),
            latitude = median(latitude), years = n_distinct(year), .by = c(place, country)) |>
  filter(n >= 12) |>
  mutate(record = "field database")
independent_records <- bind_rows(
  circular_summary(maldives$PFM, synodic_month) |>
    mutate(place = "Maldives atolls", country = "Maldives", latitude = 4.7,
           years = n_distinct(maldives$Year), record = "field study"),
  circular_summary(aquarium$DAFM[aquarium$any_spawning == 1], synodic_month) |>
    mutate(place = "Churaumi Aquarium", country = "Japan", latitude = 26.7,
           years = n_distinct(aquarium$year), record = "every day watched")
)
place_tightness <- bind_rows(site_tightness, independent_records) |>
  mutate(abs_latitude = abs(latitude)) |>
  arrange(abs_latitude)
stopifnot(!anyDuplicated(place_tightness$place))

# Lunar bars for each place. Shares are of that place's own records, so places
# with few and many nights can be compared.
lunar_counts <- bind_rows(
  nights |> semi_join(site_tightness, by = c("site" = "place")) |>
    count(place = site, lunar_day),
  maldives |> count(lunar_day = PFM) |> mutate(place = "Maldives atolls"),
  aquarium |> filter(any_spawning == 1) |> count(lunar_day = DAFM) |>
    mutate(place = "Churaumi Aquarium")
) |>
  # Day +15 and +16 are the same point on the circle as day -15 and -14.
  mutate(lunar_day = if_else(lunar_day > 14, lunar_day - 30L, as.integer(lunar_day))) |>
  summarise(n = sum(n), .by = c(place, lunar_day)) |>
  mutate(share = n / sum(n), .by = place)

# A 95% bootstrap interval for each place's tightness. Nights from one spawning event
# are not independent, so these intervals may be too narrow, especially with few nights.
set.seed(20261106)
tightness_of <- function(days) circular_summary(days, synodic_month)$tightness
days_by_place <- lunar_counts |> uncount(n)
days_by_place <- split(days_by_place$lunar_day, days_by_place$place)
tightness_intervals <- lapply(names(days_by_place), function(place) {
  days <- days_by_place[[place]]
  resampled <- replicate(2000, tightness_of(sample(days, replace = TRUE)))
  tibble(place = place, tightness_low = quantile(resampled, 0.025, names = FALSE),
         tightness_high = quantile(resampled, 0.975, names = FALSE))
}) |> bind_rows()
place_tightness <- left_join(place_tightness, tightness_intervals, by = "place",
                             relationship = "one-to-one")
stopifnot(!anyNA(place_tightness$tightness_low))
write_csv(place_tightness, "outputs/tables/lunar_tightness_by_place.csv")
write_csv(lunar_counts, "outputs/tables/lunar_counts_by_place.csv")

# Does the pattern depend on latitude, or just on how much was recorded?
field_sites <- filter(place_tightness, record == "field database")
latitude_test <- cor.test(field_sites$tightness, field_sites$abs_latitude,
                          method = "spearman", exact = FALSE)
effort_model <- summary(lm(tightness ~ abs_latitude + log(n), data = field_sites))$coefficients
# The same question on ranks, so Eilat and Kochi cannot dominate through their size.
effort_rank_model <- summary(lm(rank(tightness) ~ rank(abs_latitude) + rank(n),
                                data = field_sites))$coefficients

# Few nights can look tight by chance, so cut every field site to the same 12 nights
# and repeat the test. This equalises sample size only. It cannot correct for when
# people chose to look.
field_days <- split(nights$lunar_day, nights$site)[field_sites$place]
equal_nights_rho <- replicate(2000, {
  thinned_tightness <- sapply(field_days, function(days) tightness_of(sample(days, 12)))
  cor(thinned_tightness, field_sites$abs_latitude, method = "spearman")
})

# The same test with a second measure, the share of nights in the eight-day box.
box_share <- lunar_counts |>
  summarise(box_share = sum(share[between(lunar_day, 0, 7)]), .by = place)
field_box_share <- left_join(field_sites, box_share, by = "place", relationship = "one-to-one")

tropic <- 23.44
lunar_week <- function(day) between(day, 0, 7)
lunar_statistics <- tibble(
  measure = c("share_all", "share_inside_tropics", "share_outside_tropics",
              "nights_inside_tropics", "nights_outside_tropics", "share_without_eilat_kochi",
              "aquarium_share", "aquarium_expected", "spearman_rho", "spearman_p",
              "latitude_p_given_effort", "effort_p_given_latitude", "effort_rank_p_given_latitude",
              "spearman_nights_tightness", "spearman_rho_equal_nights",
              "spearman_rho_equal_nights_low", "spearman_rho_equal_nights_high",
              "spearman_rho_box_share"),
  value = c(mean(lunar_week(nights$lunar_day)),
            mean(lunar_week(nights$lunar_day[abs(nights$latitude) <= tropic])),
            mean(lunar_week(nights$lunar_day[abs(nights$latitude) > tropic])),
            sum(abs(nights$latitude) <= tropic), sum(abs(nights$latitude) > tropic),
            mean(lunar_week(nights$lunar_day[!nights$site %in% c("Eilat", "Kochi")])),
            mean(lunar_week(aquarium$DAFM[aquarium$any_spawning == 1])),
            mean(lunar_week(aquarium$DAFM)),
            unname(latitude_test$estimate), latitude_test$p.value,
            effort_model["abs_latitude", 4], effort_model["log(n)", 4],
            effort_rank_model["rank(n)", 4],
            cor(field_sites$n, field_sites$tightness, method = "spearman"),
            median(equal_nights_rho), quantile(equal_nights_rho, c(0.025, 0.975), names = FALSE),
            cor(field_box_share$box_share, field_box_share$abs_latitude, method = "spearman")))
write_csv(lunar_statistics, "outputs/tables/lunar_statistics.csv")

# Sun or Moon for the hour? ----
# If moonrise set the hour, a reef's starts would move later with the Moon, by about
# 50 minutes a night. So the test is how much later the same corals start each night.
#
# Every timed evening start joins in here, by the rule of prepare_sky.R: after sunset,
# without the ambiguous after-midnight records. Many approximate times are rounded to
# the hour or half hour, and tanks are a different setting, so no single sample is
# trusted: the drift is measured on each layer of start times separately.
all_records <- read_csv("data/derived/joined_observations.csv", show_col_types = FALSE,
                        guess_max = 10000)
evening_starts <- filter(all_records, !is.na(start_minutes), !midnight_ambiguous,
                         start_minutes >= sunset_minutes)
natural_starts <- filter(evening_starts, setting == "In situ")
tank_starts <- filter(evening_starts, setting == "Ex situ")
start_layers <- list(
  "Natural reefs, exact" = filter(natural_starts, exact_start),
  "Natural reefs, exact and approximate" = natural_starts,
  "Natural reefs and tanks, exact" = filter(evening_starts, exact_start),
  "Tanks, exact and approximate" = tank_starts,
  "All start times" = evening_starts
)

# The unit is one genus on one reef-night in one setting, so a genus with an exact and
# an approximate record on the same night still counts once. A tank is kept apart from
# the reef its colonies came from. Lunar days -2 to +10 hold nearly all the records.
genus_nights_in_window <- function(records) {
  records |>
    summarise(hours_after_sunset = median(sunset_offset_hours), lunar_day = first(lunar_day),
              site = first(site), year = first(year),
              .by = c(subsite_id, date, genus, setting)) |>
    filter(between(lunar_day, -2, 10)) |>
    mutate(reef = paste(site, setting))
}

# The eight best-recorded genera of a layer, so like is compared with like.
main_genera_only <- function(window) {
  main_genera <- names(sort(table(window$genus), decreasing = TRUE))[1:8]
  filter(window, genus %in% main_genera)
}

# One line through all reefs at once, with genus as a factor. Reefs keep different
# hours, so this slope also picks up which reefs happened to be recorded on which nights.
all_reefs_slope <- function(starts) {
  60 * coef(lm(hours_after_sunset ~ lunar_day + genus, data = starts))[["lunar_day"]]
}

# Each genus compared only with itself on its own reef: subtract the group's own
# averages, then take the slope. This equals lm() with one level per group. It is
# written out because each reef's two sums can then be resampled directly, which keeps
# the bootstrap fast. A group seen on one lunar day only says nothing about drift.
reef_sums <- function(starts, group) {
  starts |>
    filter(n_distinct(lunar_day) > 1, .by = all_of(group)) |>
    mutate(day_gap = lunar_day - mean(lunar_day),
           hour_gap = hours_after_sunset - mean(hours_after_sunset), .by = all_of(group)) |>
    summarise(starts = n(), cross = sum(day_gap * hour_gap), spread = sum(day_gap^2), .by = reef)
}
slope_of_sums <- function(sums) 60 * sum(sums$cross) / sum(sums$spread)

# Records from one reef are not independent: they share observers, nights and colonies.
# So the 95% intervals resample whole reefs. They are wider than the interval lm()
# prints, which treats every genus start as a separate piece of evidence.
interval_of <- function(draws) quantile(draws, c(0.025, 0.975), names = FALSE)
resample_reef_sums <- function(sums) {
  interval_of(replicate(2000, slope_of_sums(sums[sample(nrow(sums), replace = TRUE), ])))
}
measure_drift <- function(records, layer) {
  window <- genus_nights_in_window(records)
  starts <- main_genera_only(window)
  rows_by_reef <- split(seq_len(nrow(starts)), starts$reef)
  all_reefs_interval <- interval_of(replicate(2000, {
    all_reefs_slope(starts[unlist(sample(rows_by_reef, replace = TRUE)), ])
  }))
  same_reef <- reef_sums(starts, c("reef", "genus"))
  same_year <- reef_sums(starts, c("reef", "genus", "year"))
  same_reef_interval <- resample_reef_sums(same_reef)
  same_year_interval <- resample_reef_sums(same_year)
  tibble(layer = layer, starts_in_window = nrow(window), starts_fitted = nrow(starts),
         reefs_fitted = n_distinct(starts$reef),
         all_reefs = all_reefs_slope(starts),
         all_reefs_low = all_reefs_interval[1], all_reefs_high = all_reefs_interval[2],
         same_reef_starts = sum(same_reef$starts), same_reef_reefs = nrow(same_reef),
         same_reef = slope_of_sums(same_reef),
         same_reef_low = same_reef_interval[1], same_reef_high = same_reef_interval[2],
         same_year = slope_of_sums(same_year),
         same_year_low = same_year_interval[1], same_year_high = same_year_interval[2])
}
set.seed(20261106)
start_drift <- bind_rows(Map(measure_drift, start_layers, names(start_layers)))
write_csv(start_drift, "outputs/tables/start_drift.csv")

# The natural reefs carry the headline: the largest sample from the real setting.
# The written-out slope must equal the model it stands for.
headline <- filter(start_drift, layer == "Natural reefs, exact and approximate")
headline_starts <- main_genera_only(genus_nights_in_window(natural_starts))
same_reef_model <- lm(hours_after_sunset ~ lunar_day + interaction(reef, genus, drop = TRUE),
                      data = headline_starts)
stopifnot(abs(60 * coef(same_reef_model)[["lunar_day"]] - headline$same_reef) < 1e-8)

moonrise_model <- lm(moonrise_hours ~ lunar_day, data = filter(moonrise, between(lunar_day, 0, 10)))
with_moonrise <- filter(genus_starts, !is.na(moonrise_hours))
sky_statistics <- tibble(
  measure = c("same_reef_drift_minutes_per_night", "same_reef_drift_low", "same_reef_drift_high",
              "same_reef_drift_starts", "same_reef_drift_reefs",
              "same_year_drift_minutes_per_night", "same_year_drift_low", "same_year_drift_high",
              "all_reefs_drift_minutes_per_night", "all_reefs_drift_low", "all_reefs_drift_high",
              "same_reef_drift_smallest_layer", "same_reef_drift_largest_layer",
              "all_reefs_drift_smallest_layer", "all_reefs_drift_largest_layer",
              "moonrise_delay_minutes_per_night", "median_start_hours", "q25_start_hours",
              "q75_start_hours", "sd_from_sunset_hours", "sd_from_moonrise_hours",
              "share_moon_down", "share_moon_down_after_full"),
  value = c(headline$same_reef, headline$same_reef_low, headline$same_reef_high,
            headline$same_reef_starts, headline$same_reef_reefs,
            headline$same_year, headline$same_year_low, headline$same_year_high,
            headline$all_reefs, headline$all_reefs_low, headline$all_reefs_high,
            range(start_drift$same_reef), range(start_drift$all_reefs),
            60 * coef(moonrise_model)[["lunar_day"]],
            quantile(genus_starts$hours_after_sunset, c(0.5, 0.25, 0.75), names = FALSE),
            sd(with_moonrise$hours_after_sunset),
            sd(with_moonrise$hours_after_sunset - with_moonrise$moonrise_hours),
            mean(genus_starts$moon_deg < 0),
            mean(genus_starts$moon_deg[genus_starts$lunar_day >= 0] < 0)))
write_csv(sky_statistics, "outputs/tables/sky_statistics.csv")
