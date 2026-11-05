# Generate the report from the same prepared values used in the plots.
library(dplyr)
library(readr)

read_statistics <- function(path) {
  statistics <- read_csv(path, show_col_types = FALSE)
  setNames(statistics$value, statistics$measure)
}
clocks <- read_csv("outputs/tables/clock_summary.csv", show_col_types = FALSE)
seasons <- read_csv("data/derived/reef_night_seasons.csv", show_col_types = FALSE)
lunar <- read_statistics("outputs/tables/lunar_statistics.csv")
sky <- read_statistics("outputs/tables/sky_statistics.csv")
scores <- read_csv("outputs/tables/aquarium_model_scores.csv", show_col_types = FALSE)
increments <- read_csv("outputs/tables/aquarium_environment_increment.csv", show_col_types = FALSE)
replication <- read_csv("data/derived/lunar_replication_summary.csv", show_col_types = FALSE)
moon_calendar <- read_csv("outputs/tables/moon_calendar.csv", show_col_types = FALSE)
minutes <- read_csv("outputs/tables/06_minutes.csv", show_col_types = FALSE)
colonies <- read_csv("outputs/tables/seasim_colony_pairs.csv", col_types = cols(colony_tag = col_character()))
heat <- read_csv("outputs/tables/07_heat_years.csv", show_col_types = FALSE)
heat_season <- read_csv("outputs/tables/08_heat_season.csv", show_col_types = FALSE)
genera <- read_statistics("outputs/tables/genus_statistics.csv")
genus_rows <- read_csv("outputs/tables/09_genera.csv", show_col_types = FALSE) |>
  filter(!grepl("Pocillopora", group))

tightness <- setNames(clocks$tightness, clocks$clock)
brier <- setNames(scores$brier, scores$model)
season_cut <- 100 * (1 - brier[["season"]] / brier[["prevalence"]])
moon_gain <- filter(increments, grepl("^Season", comparison))
below_on_date <- filter(moon_calendar, shift_days == 0)
below_elsewhere <- mean(moon_calendar$share_below[moon_calendar$shift_days != 0])
severe <- function(y) heat$n_severe[heat$year == y]
taiwan <- filter(heat_season, station_id == "northern_taiwan")
aqaba <- filter(heat_season, station_id == "gulf_of_aqaba")
group_spread <- function(name) minutes$middle_half[minutes$group == name]
acropora_share <- replication$share_week[grepl("^Historical", replication$sample)]
maldives_share <- replication$share_week[grepl("atoll-days", replication$sample)]

report <- c(
  "# What we found", "",
  sprintf("The records point to three natural cycles working at different scales: the yearly warming of the sea, the Moon and sunset. They do not hold spawning equally firmly. Measured on one scale from 0 (spread evenly around the cycle) to 1 (everything at one moment), the Sun scores %.2f, the year %.2f and the Moon %.2f ([plot 1](figures/01_three_clocks.png)). The full-moon story that usually leads this topic is the loosest of the three.",
          tightness[["sun"]], tightness[["year"]], tightness[["moon"]]),
  "",
  "## The year opens the season", "",
  sprintf("Calendar months cannot be compared across the equator, so each NOAA region gets its own typical temperature year. Of the %s reef-nights inside a NOAA region, %.0f%% fall while the local sea is warming, a stretch that covers %.0f%% of the year. The typical reef-night sits %.0f days before the warmest week ([plot 2](figures/02_season.png)). Field teams look for spawning when they expect it, so quiet months are under-recorded and this share is likely too high.",
          format(nrow(seasons), big.mark = ","), 100 * mean(seasons$warming),
          100 * mean(seasons$warming_share_of_year), -clocks$typical[clocks$clock == "year"]),
  "",
  "## The Moon narrows the night, more in the tropics", "",
  sprintf("Of 1,026 recorded reef-nights, %.1f%% fall in the eight days from full moon, where an even spread would give 27%%. That single figure hides two groups. Inside the tropics the share is %.0f%%; beyond them it is %.0f%% ([plot 3](figures/03_moon.png)). Without Eilat and Kochi it rises to %.0f%%.",
          100 * lunar[["share_all"]], 100 * lunar[["share_inside_tropics"]],
          100 * lunar[["share_outside_tropics"]], 100 * lunar[["share_without_eilat_kochi"]]),
  "",
  sprintf("Across the 23 sites with at least 12 reef-nights, lunar tightness falls with distance from the equator (Spearman ρ = %.2f, p < 0.001). Seven common genera each look looser beyond 26°, and the trend holds with Eilat and Kochi removed and within Acropora alone. Sites with more recorded nights also look looser, even after allowing for latitude (p = %.3f), so heavier monitoring probably explains part of the pattern. This describes the records. It does not show why the Moon matters less at higher latitudes.",
          lunar[["spearman_rho"]], lunar[["effort_p_given_latitude"]]),
  "",
  sprintf("For Acropora, %.1f%% of 400 historical genus/reef-dates and %.1f%% of 81 spawning atoll-days from a separate Maldives study fall in those eight days. The two studies use different units and are kept apart.",
          100 * acropora_share, 100 * maldives_share),
  "",
  "## The Sun sets the hour", "",
  sprintf("We calculated moonrise for each timed reef-night and checked the formula against 12,897 NASA/JPL Horizons positions; the largest gap is 0.3°. Moonrise moves about %.0f minutes later each night in this sample. The start of spawning moves %.1f minutes a night (95%% interval %.1f to %.1f), comparing like with like within the eight best-recorded genera. Starts scatter %.1f times less around sunset than around moonrise ([plot 4](figures/04_sky.png)). Half of them fall between %.1f and %.1f hours after sunset.",
          sky[["moonrise_delay_minutes_per_night"]], sky[["start_drift_minutes_per_night"]],
          sky[["start_drift_low"]], sky[["start_drift_high"]],
          sky[["sd_from_moonrise_hours"]] / sky[["sd_from_sunset_hours"]],
          sky[["q25_start_hours"]], sky[["q75_start_hours"]]),
  "",
  sprintf("So the Moon may help pick a night, but it does not set the hour. The two still interact: %.0f%% of starts on or after full moon happen before moonrise, in the dark gap that opens after sunset once the Moon starts rising late. Holding reefs and clock times fixed, the Moon is below the horizon for %.0f%% of recorded starts, against %.0f%% on the 28 surrounding dates. Experiments have tested that dark gap directly, including [Lin et al. (2021)](https://doi.org/10.1073/pnas.2101985118); our sky reconstruction cannot establish a cue by itself.",
          100 * sky[["share_moon_down_after_full"]], 100 * below_on_date$share_below, 100 * below_elsewhere),
  "",
  "## A diary with every day watched", "",
  sprintf("The Churaumi Aquarium diary is the one record with its empty days written down, so it can check the field pattern for observer bias. It weakens the lunar story: %.0f%% of its 208 spawning days fall in the same eight days, against %.0f%% of the days watched ([plot 5](figures/05_diary.png)).",
          100 * lunar[["aquarium_share"]], 100 * lunar[["aquarium_expected"]]),
  "",
  sprintf("We forecast each year from the others, on the same 1,007 complete days. With no calendar the Brier error is %.3f. The Moon alone gives %.3f, season alone %.3f, both %.3f, and both plus the previous week's tank temperature, wind, rain and sunlight %.3f. Season cuts the error by %.0f%%. Adding the Moon to season gains %.4f (95%% interval %.4f to %.4f), which includes zero.",
          brier[["prevalence"]], brier[["moon"]], brier[["season"]], brier[["calendar"]], brier[["environment"]],
          season_cut, moon_gain$estimate, moon_gain$low, moon_gain$high),
  "",
  "We cannot tell from this whether field records overstate the Moon, because teams go out near full moon, or whether a tank dulls the signal. This is one aquarium. Its result is a reason for caution about the field numbers and does not forecast a wild reef.",
  "",
  "## Each species keeps its own time", "",
  sprintf("In the Australian Sea Simulator the seasons were moved by six months and the light cycle by four hours, and corals spawned on the moved schedule. Against one programmed sunset, half of the Acropora loripes releases fall within %.0f minutes; in the wild, with places and species mixed, Acropora spreads over %.0f ([plot 6](figures/06_minutes.png)). Tank species keep distinct times, from about 80 to about 210 minutes after sunset.",
          group_spread("A. loripes"), group_spread("Acropora")),
  "",
  sprintf("Of the 28 tagged colonies timed in both years, %d started earlier in 2023, with a median shift of %.0f minutes. Both years used shifted cues, and shared tank conditions prevent isolating a cause.",
          sum(colonies$change_minutes < 0), -median(colonies$change_minutes)),
  "",
  "## Genera share a timetable, with one clear outlier", "",
  sprintf("Across the %d genera with at least 20 reef-nights, the typical night falls %.0f to %.0f days after full moon. Tightness varies more than timing: among the %d genera with at least 40 nights, the share of nights in the eight days after full moon runs from %.0f%% to %.0f%% ([plot 9](figures/09_genera.png)). Those differences hold on the same reef (genus labels shuffled within reefs, p < 0.001, also without Pocillopora), so location alone does not explain them.",
          genera[["genera_well_recorded"]], genera[["typical_day_min"]], genera[["typical_day_max"]], nrow(genus_rows),
          100 * min(genus_rows$share_after_full), 100 * max(genus_rows$share_after_full)),
  "",
  sprintf("Pocillopora is the clear outlier. All %d of its timed starts come after sunrise, while %.1f%% of the other %s timed starts fall between 4 hours before and 6 hours after sunset. On the Moon, all %d of its nights outside the Red Sea fall in the eight days after full moon, and all %d inside the Red Sea, from %d sites, fall in the seven days around new moon. Platygyra also has a smaller new-moon peak (%.0f%% of its nights). The Red Sea sample is small, and these records describe recorded events, so they do not explain why the timing differs.",
          genera[["pocillopora_timed"]], 100 * genera[["other_evening_share"]], format(genera[["other_timed"]], big.mark = ","),
          genera[["pocillopora_other_nights"]], genera[["pocillopora_red_nights"]], genera[["pocillopora_red_sites"]],
          100 * genera[["platygyra_share_near_new"]]),
  "",
  "## The heat is changing around these clocks", "",
  sprintf("NOAA's 214 reef regions are followed through 39 complete years. %d reached the severe level of 8 degree heating weeks in 1986 and %d in 2024, about four in five ([plot 7](figures/07_heat_years.png)). The years 1998, 2010, 2016 and 2024 each followed an El Niño. Regions count equally whatever their reef area, and degree heating weeks measure accumulated heat, not coral death.",
          severe(1986), severe(2024)),
  "",
  sprintf("Holding each region's historical spawning months fixed, ten of fourteen regions now see more heat stress in those months, and four stay clear ([plot 8](figures/08_heat_season.png)). Northern Taiwan rises from %.1f%% to %.1f%% of the season and the Gulf of Aqaba from %.1f%% to %.1f%%, comparing 1986–1995 with 2015–2024. The index uses DHW ≥4 and measures overlap only. It cannot show that spawning moved or that reproduction failed.",
          100 * taiwan$early, 100 * taiwan$recent, 100 * aqaba$early, 100 * aqaba$recent),
  "",
  "## What sits behind the plots", "",
  "The project uses 6,178 historical coral records, 3,203,007 daily NOAA regional records, fifteen aquarium seasons, the Maldives field table, 172 timed colony records from the Sea Simulator and 12,897 NASA ephemeris positions. Field percentages describe recorded events, so they are not the chance of spawning on an unobserved night. Sources, joins and full tables stay in the project."
)
writeLines(enc2utf8(report), "outputs/RESULTS.md", useBytes = TRUE)
