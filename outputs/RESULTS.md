# Findings

## What the combined records make possible

The project connects 1,026 recorded reef-nights to 214 official NOAA reef-region histories. Spatial polygons and exact date labels yield 751 environmental matches. Regional ocean context is kept separate from direct measurements at coral depth.

The parsed environmental record contains 3,203,007 available station-days for 1985–2025. The climate comparison uses 8,346 complete region-years in 1986–2024; incomplete 2025 records remain available but do not enter that comparison.

## Heat-stress conditions became geographically widespread

In 2024, 202 of 214 regions reached an annual maximum of at least 4 °C-weeks DHW; 171 reached at least 8. These are equal-weight region counts, not the share of global reef area or a count of observed bleaching events.

## Spawning-season exposure is uneven

Seventeen well-recorded sites define historical monthly spawning calendars in 14 NOAA regions. Holding those calendars fixed, 10 regions show a higher calendar-weighted fraction of days at DHW ≥4 in 2015–2024 than in 1986–1995. The other 4 remain at zero in both periods.

The largest increase is in Northern Taiwan: 1.5% to 26.3%, a change of 24.8 percentage points. The result describes overlap between a fixed recorded calendar and regional heat-stress conditions. It does not measure a change in spawning dates, reproductive success, mortality or adaptation.

Each eligible site has at least ten recorded subsite-dates over at least three years. Event shares are calculated within sites; sites receive equal weight within their NOAA region. Historical observation effort can affect the calendar. Regional DHW is a heat-stress statistic, not an organism-level reproductive threshold.

## More predictors did not give better held-out aquarium predictions

A separate fifteen-year aquarium diary contains 1,350 monitored seasonal dates, including explicit non-spawning dates. The paired prediction comparison uses 1,007 complete dates from fourteen years, with each entire year held out in turn. Brier scores are 0.111 for the calendar model, 0.115 after adding the preceding week's environmental measurements, and 0.136 for the training-prevalence baseline; lower is better.

The paired calendar-minus-environment Brier difference is -0.0033, with a whole-year bootstrap interval of -0.0078 to +0.0006. This comparison gives no clear evidence that adding those environmental features improves prediction. It does not establish that the environment has no biological effect.

The source's misleadingly named spawning_binary column counts tanks; the analysis explicitly derives spawning presence. Environmental features use the seven days strictly before each diary date. This retrospective held-year-out validation uses other years on both sides of the held year; it is not a prospective deployment trial or a wild-reef forecast. See docs/AQUARIUM_METHODS.md for equations, complete-case selection and checks.

## A separate field dataset repeats the lunar concentration

Among historical Acropora genus-nights, 69.8% occur on days 0–7 after full moon. The independently published Maldives study records 70.4% of its 81 spawning atoll-days in that window; weighting by its 3,026 colony spawning observations gives 73.9%. The similarity is descriptive: geography, monitoring and counting units differ.

## Timing and observation effort still matter

The original lunar concentration changes from 80.3% per observation row to 67.7% per recorded reef-night, or 76.2% with equal subsite weighting. All are conditional distributions among recorded occurrences. None gives the probability of spawning on an arbitrary night. Exact-time graphics retain genuine daylight spawning and flag the ambiguous midnight record.

## Validation and scope

Independent Python checks reconstruct all 546 calendar-exposure region-years from original NOAA archives. Separate model refits verify held-out predictions, and explicit date-range calculations verify lagged features. Details and numerical tolerances appear in docs/VALIDATION.md. The source USNO cross-check covers seven historical reef-nights only.

These are new analyses within this project. A broader claim of scientific novelty would need an exhaustive literature review. Source data, code, model artefacts and numerical checks are retained so others can examine the conclusions.
