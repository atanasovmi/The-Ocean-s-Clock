# Check consequential data and export properties after the presentation rebuild.
library(dplyr)
library(readr)
nights <- read_csv("data/derived/reef_nights.csv", show_col_types = FALSE)
matched <- read_csv("data/derived/regional_events.csv", show_col_types = FALSE)
weights <- read_csv("data/derived/spawning_calendar_weights.csv", show_col_types = FALSE)
field <- read_csv("data/derived/field_observations.csv", show_col_types = FALSE)
stopifnot(nrow(matched) == nrow(nights),
          !anyDuplicated(paste(matched$subsite_id, matched$date)),
          all(abs((weights |> summarise(s = sum(calendar_weight), .by = station_id))$s - 1) < 1e-10),
          all(field$sunset_offset_hours[field$Obs_ID %in% c(3975, 3976)] < -12),
          all(field$midnight_ambiguous[field$Obs_ID == 6153]))

# The three clocks
clocks <- read_csv("outputs/tables/clock_summary.csv", show_col_types = FALSE)
seasons <- read_csv("data/derived/reef_night_seasons.csv", show_col_types = FALSE)
stopifnot(setequal(clocks$clock, c("year", "moon", "sun")), all(between(clocks$tightness, 0, 1)),
          clocks$n[clocks$clock == "moon"] == nrow(nights),
          clocks$n[clocks$clock == "year"] == nrow(seasons),
          nrow(seasons) == sum(!is.na(left_join(
            nights, read_csv("data/derived/reef_region_lookup.csv", show_col_types = FALSE),
            by = "subsite_id", relationship = "many-to-one")$station_id)))

# Lunar rows: each place's shares must sum to one and carry its full record count.
places <- read_csv("outputs/tables/lunar_tightness_by_place.csv", show_col_types = FALSE)
lunar_counts <- read_csv("outputs/tables/lunar_counts_by_place.csv", show_col_types = FALSE)
place_totals <- lunar_counts |> summarise(n = sum(n), share = sum(share), .by = place)
stopifnot(!anyDuplicated(places$place), setequal(places$place, place_totals$place),
          all(abs(place_totals$share - 1) < 1e-10),
          all(place_totals$n == places$n[match(place_totals$place, places$place)]),
          all(c("Churaumi Aquarium", "Maldives atolls") %in% places$place),
          all(between(places$tightness_low, 0, 1)), all(between(places$tightness_high, 0, 1)),
          all(places$tightness_low <= places$tightness_high))

# Plot 3 says the latitude pattern survives equal sample sizes and a second measure.
lunar <- read_csv("outputs/tables/lunar_statistics.csv", show_col_types = FALSE)
lunar <- setNames(lunar$value, lunar$measure)
stopifnot(lunar[["spearman_rho_equal_nights_high"]] < 0, lunar[["spearman_rho_box_share"]] < 0)

# Sky: the plot says starts barely move on one reef while moonrise moves a lot, and
# that mixing reefs gives a steeper line. Each must hold in every layer of start times.
# The window counts catch a genus-night being counted twice, once per time quality.
genus_starts <- read_csv("data/derived/genus_starts.csv", show_col_types = FALSE)
sky <- read_csv("outputs/tables/sky_statistics.csv", show_col_types = FALSE)
sky <- setNames(sky$value, sky$measure)
start_drift <- read_csv("outputs/tables/start_drift.csv", show_col_types = FALSE)
window_starts <- setNames(start_drift$starts_in_window, start_drift$layer)
moon_calendar <- read_csv("outputs/tables/moon_calendar.csv", show_col_types = FALSE)
stopifnot(nrow(genus_starts) == 327, n_distinct(paste(genus_starts$subsite_id, genus_starts$date)) == 172,
          sky[["moonrise_delay_minutes_per_night"]] > 40,
          nrow(start_drift) == 5, window_starts[["Natural reefs, exact"]] == 311,
          window_starts[["Natural reefs, exact and approximate"]] == 1184,
          all(start_drift$same_reef < start_drift$all_reefs),
          all(start_drift$same_reef_low < start_drift$same_reef),
          all(start_drift$same_reef < start_drift$same_reef_high),
          sky[["same_reef_drift_high"]] < sky[["moonrise_delay_minutes_per_night"]] / 10,
          max(start_drift$all_reefs) < sky[["moonrise_delay_minutes_per_night"]] / 8,
          sky[["sd_from_sunset_hours"]] < sky[["sd_from_moonrise_hours"]],
          identical(moon_calendar$shift_days, as.numeric(-14:14)),
          all(moon_calendar$reef_nights == 172), all(moon_calendar$start_times == 538),
          all(between(moon_calendar$share_below, 0, 1)),
          all(moon_calendar$low_threshold_share <= moon_calendar$share_below),
          all(moon_calendar$share_below <= moon_calendar$high_threshold_share))

# Aquarium: every model is scored on the same dates.
scores <- read_csv("outputs/tables/aquarium_model_scores.csv", show_col_types = FALSE)
stopifnot(setequal(scores$model, c("prevalence", "moon", "season", "calendar", "environment")),
          n_distinct(scores$n_days) == 1, all(scores$n_days == 1007))

# Tank colonies
colony_starts <- read_csv("data/derived/seasim_colony_starts.csv",
                          col_types = cols(colony_tag = col_character()))
colony_pairs <- read_csv("outputs/tables/seasim_colony_pairs.csv",
                         col_types = cols(colony_tag = col_character()))
stopifnot(nrow(colony_starts) == 172, nrow(colony_pairs) == 28,
          sum(colony_pairs$change_minutes < 0) == 24, !anyDuplicated(colony_pairs$colony_tag),
          median(colony_pairs$change_minutes) == -8)

# Heat
heat <- read_csv("outputs/tables/07_heat_years.csv", show_col_types = FALSE)
heat_season <- read_csv("outputs/tables/08_heat_season.csv", show_col_types = FALSE)
stopifnot(all(heat$n_regions == 214), nrow(heat) == 39,
          heat$n_severe[heat$year == 1986] == 5, heat$n_severe[heat$year == 2024] == 171,
          nrow(heat_season) == 14, sum(heat_season$change > 0) == 10)

# Genera: each reef-night sits in one row, and the plot's outlier claims still hold.
genus_groups <- read_csv("outputs/tables/09_genera.csv", show_col_types = FALSE)
genus_stats <- read_csv("outputs/tables/genus_statistics.csv", show_col_types = FALSE)
genus_stats <- setNames(genus_stats$value, genus_stats$measure)
genus_group_nights <- read_csv("data/derived/genus_group_nights.csv", show_col_types = FALSE)
stopifnot(!anyDuplicated(genus_group_nights[c("group", "subsite_id", "date")]),
          sum(genus_groups$nights) == nrow(genus_group_nights),
          genus_stats[["pocillopora_daytime"]] == genus_stats[["pocillopora_timed"]],
          genus_stats[["pocillopora_red_near_new"]] == genus_stats[["pocillopora_red_nights"]],
          genus_stats[["pocillopora_red_max_days_from_new"]] < 2,
          genus_stats[["pocillopora_other_after_full"]] == genus_stats[["pocillopora_other_nights"]],
          genus_stats[["same_reef_p_without_eilat"]] > 0.05)

# Exports: one PNG and one SVG per plot script, and no private font names left in the SVGs.
plot_scripts <- setdiff(list.files("R/plots", pattern = "\\.R$"), "style.R")
expected_figures <- sub("\\.R$", ".png", plot_scripts)
svg_files <- list.files("outputs/vector", pattern = "\\.svg$", full.names = TRUE)
stopifnot(setequal(list.files("outputs/figures", pattern = "\\.png$"), expected_figures),
          setequal(sub("\\.svg$", ".png", basename(svg_files)), expected_figures),
          !any(vapply(svg_files, function(file) any(grepl("Plot (Title|Text|Note|Tick|Label)",
                                                          readLines(file, warn = FALSE))), logical(1))))
message("Data totals, clock summaries, sky statistics, model samples, colony pairing and exports passed.")
