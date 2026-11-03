# Generate findings from the analytical outputs, with checks of their meaning.
library(dplyr)
library(readr)
nights <- read_csv("data/derived/reef_nights.csv", show_col_types = FALSE)
matched <- read_csv("data/derived/regional_events.csv", show_col_types = FALSE)
annual <- read_csv("data/derived/regional_annual.csv", show_col_types = FALSE)
weights <- read_csv("data/derived/spawning_calendar_weights.csv", show_col_types = FALSE)
change <- read_csv("outputs/tables/08_decadal_exposure.csv", show_col_types = FALSE)
scores <- read_csv("outputs/tables/aquarium_model_scores.csv", show_col_types = FALSE)
increment <- read_csv("outputs/tables/aquarium_environment_increment.csv", show_col_types = FALSE)
replication <- read_csv("outputs/tables/12_maldives_summary.csv", show_col_types = FALSE)
predictions <- read_csv("outputs/tables/aquarium_held_out_predictions.csv", show_col_types = FALSE)
lunar <- read_csv("outputs/tables/03_lunar_calendars.csv", show_col_types = FALSE)
seasons <- read_csv("outputs/tables/02_seasonal_calendars.csv", show_col_types = FALSE)
field <- read_csv("data/derived/field_observations.csv", show_col_types = FALSE)
stopifnot(nrow(matched) == nrow(nights),
          !anyDuplicated(paste(matched$subsite_id, matched$date)),
          all(abs((weights |> summarise(s = sum(calendar_weight), .by = station_id))$s - 1) < 1e-10),
          all(abs((lunar |> summarise(s = sum(share), .by = genus))$s - 1) < 1e-10),
          all(abs((seasons |> summarise(s = sum(share), .by = label))$s - 1) < 1e-10),
          all(field$sunset_offset_hours[field$Obs_ID %in% c(3975, 3976)] < -12),
          all(field$midnight_ambiguous[field$Obs_ID == 6153]),
          all(scores$brier >= 0 & scores$brier <= 1))
complete <- annual |> filter(between(year, 1986, 2024))
stopifnot(all(complete$complete_year), nrow(complete) == 214 * 39)
latest <- filter(complete, year == 2024)
biggest <- change |> slice_max(change, n = 1)
brier <- setNames(scores$brier, scores$model)
lines <- c("# Findings", "",
  "## What the combined records make possible", "",
  sprintf("The project connects %s recorded reef-nights to 214 official NOAA reef-region histories. Spatial polygons and exact date labels yield %s environmental matches. Regional ocean context is kept separate from direct measurements at coral depth.",
          format(nrow(nights), big.mark = ","), sum(!is.na(matched$sst_c))), "",
  sprintf("The parsed environmental record contains 3,203,007 available station-days for 1985–2025. The climate comparison uses %s complete region-years in 1986–2024; incomplete 2025 records remain available but do not enter that comparison.", format(nrow(complete), big.mark = ",")), "",
  "## Heat-stress conditions became geographically widespread", "",
  sprintf("In 2024, %s of 214 regions reached an annual maximum of at least 4 °C-weeks DHW; %s reached at least 8. These are equal-weight region counts, not the share of global reef area or a count of observed bleaching events.",
          sum(latest$max_dhw_c_weeks >= 4), sum(latest$max_dhw_c_weeks >= 8)), "",
  "## Spawning-season exposure is uneven", "",
  sprintf("Seventeen well-recorded sites define historical monthly spawning calendars in %s NOAA regions. Holding those calendars fixed, %s regions show a higher calendar-weighted fraction of days at DHW ≥4 in 2015–2024 than in 1986–1995. The other %s remain at zero in both periods.",
          nrow(change), sum(change$change > 1e-10), sum(abs(change$change) <= 1e-10)), "",
  sprintf("The largest increase is in %s: %.1f%% to %.1f%%, a change of %.1f percentage points. The result describes overlap between a fixed recorded calendar and regional heat-stress conditions. It does not measure a change in spawning dates, reproductive success, mortality or adaptation.",
          biggest$station_name, 100 * biggest[["1986–1995"]], 100 * biggest[["2015–2024"]], 100 * biggest$change), "",
  "Each eligible site has at least ten recorded subsite-dates over at least three years. Event shares are calculated within sites; sites receive equal weight within their NOAA region. Historical observation effort can affect the calendar. Regional DHW is a heat-stress statistic, not an organism-level reproductive threshold.", "",
  "## More predictors did not give better held-out aquarium predictions", "",
  sprintf("A separate fifteen-year aquarium diary contains 1,350 monitored seasonal dates, including explicit non-spawning dates. The paired prediction comparison uses 1,007 complete dates from fourteen years, with each entire year held out in turn. Brier scores are %.3f for the calendar model, %.3f after adding the preceding week's environmental measurements, and %.3f for the training-prevalence baseline; lower is better.", brier[["calendar"]], brier[["environment"]], brier[["prevalence"]]), "",
  sprintf("The paired calendar-minus-environment Brier difference is %.4f, with a whole-year bootstrap interval of %.4f to %+.4f. This comparison gives no clear evidence that adding those environmental features improves prediction. It does not establish that the environment has no biological effect.", increment$estimate, increment$low, increment$high), "",
  "The source's misleadingly named spawning_binary column counts tanks; the analysis explicitly derives spawning presence. Environmental features use the seven days strictly before each diary date. This retrospective held-year-out validation uses other years on both sides of the held year; it is not a prospective deployment trial or a wild-reef forecast. See docs/AQUARIUM_METHODS.md for equations, complete-case selection and checks.", "",
  "## A separate field dataset repeats the lunar concentration", "",
  sprintf("Among historical Acropora genus-nights, %.1f%% occur on days 0–7 after full moon. The independently published Maldives study records %.1f%% of its 81 spawning atoll-days in that window; weighting by its 3,026 colony spawning observations gives %.1f%%. The similarity is descriptive: geography, monitoring and counting units differ.",
          100 * replication$share_week[1], 100 * replication$share_week[2], 100 * replication$share_week[3]), "",
  "## Timing and observation effort still matter", "",
  "The original lunar concentration changes from 80.3% per observation row to 67.7% per recorded reef-night, or 76.2% with equal subsite weighting. All are conditional distributions among recorded occurrences. None gives the probability of spawning on an arbitrary night. Exact-time graphics retain genuine daylight spawning and flag the ambiguous midnight record.", "",
  "## Validation and scope", "",
  "Independent Python checks reconstruct all 546 calendar-exposure region-years from original NOAA archives. Separate model refits verify held-out predictions, and explicit date-range calculations verify lagged features. Details and numerical tolerances appear in docs/VALIDATION.md. The source USNO cross-check covers seven historical reef-nights only.", "",
  "These are new analyses within this project. A broader claim of scientific novelty would need an exhaustive literature review. Source data, code, model artefacts and numerical checks are retained so others can examine the conclusions.")
writeLines(lines, "outputs/RESULTS.md", useBytes = TRUE)
message("Sampling, calendar, climate coverage and timing checks passed.")
