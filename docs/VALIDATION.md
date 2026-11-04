# Validation

Checked on 3 November 2026; plates and the new timing analyses rechecked on 4 November 2026. The delivery environment is recorded in `outputs/session-info.txt`.

## Sources and analytical units

All 214 NOAA gzip archives were independently decompressed and checked against their source SHA-256 hashes. The R parser retains **3,203,007 available station-days** for 1985–2025. It identifies **1,643 missing station-days** in 2025 across 80 regions rather than inventing zero-stress records. All **8,346 region-years** used for the 1986–2024 climate comparison have complete daily coverage.

The coral joins preserve 6,178 source rows and produce 3,569 field observations, 1,026 subsite-dates and 1,942 genus/subsite-dates. Official NOAA polygons and date keys connect 751 recorded reef-nights to environmental histories. Unmatched locations and years remain explicit. Regional values are not described as point measurements at coral depth.

The Maldives source contains 81 atoll-days and 3,026 colony spawning observations. These units stay separate. The aquarium source supplies 1,350 monitored diary dates, including explicit non-spawning dates. Its `spawning_binary` field actually counts tanks; spawning presence is derived explicitly. The complete-case model sample has 1,007 dates in fourteen years.

## Independent calculations

`python tools/check_climate.py` independently reconstructs site/month weights and reads the original NOAA histories. All **546 region-years** in the fourteen-region calendar integration match R, with a maximum absolute exposure difference of **2.22 × 10⁻¹⁶**. It confirms ten increases and four unchanged zero-exposure regions in the stated decade comparison.

`python tools/check_aquarium.py` reconstructs all **4,028** lagged features using explicit calendar-date ranges. The maximum difference is **1.14 × 10⁻¹³**. It independently refits all **56** held-out logistic models with SciPy; predicted probabilities differ by at most **8.75 × 10⁻⁹**. These Python tools provide separate checks and are not dependencies of the R analysis itself.

Every validation fit and both full-data aquarium fits converge with full rank and no numerical fitting warnings. No held-out-year responses enter a training fold; lagged measurements strictly precede the diary date. The bootstrap resamples whole years and uses the same date-weighted Brier estimand as the point estimate. Validation is retrospective leave-one-year-out, not a prospective deployment test.

## Timing and visual checks

The lunar counts use all 1,026 reef-nights once, and each place's shares sum to one. Calendar weights sum to one within each region. Genuine dawn observations 3975/3976 remain more than twelve hours before the same-date sunset; midnight record 6153 is flagged separately. The limited cached USNO sample matches seven historical reef-nights exactly.

Eight plates are exported as 300 dpi PNGs and scalable SVGs, and each was inspected at full size for label collisions, clipping and overflow. Bars start at zero. Regional selections, counting units and the two DHW thresholds are stated, and every plate has its plotted values in a CSV.

The colour roles were tested with a palette validator on the plate background. The five heat classes pass as an ordered ramp: lightness rises steadily, neighbouring steps stay distinct, and the lowest class reaches 2:1 contrast with the page. Pink, gold and blue stay apart under simulated colour blindness (worst ΔE 9.4 for deuteranopia). Plates never rely on colour alone: rows, positions and direct labels carry the same information.

The Moon formula in `R/prepare_sky.R` agrees with all 12,897 cached NASA/JPL Horizons positions to within 0.29°. The Sun sits at a median of −0.73° at the source's sunset, as expected for a sunset defined with refraction and the Sun's disc, which also confirms the local-time conversion. The script stops if either check fails.

The exported Shapefiles are read back: they contain all 214 region polygons and 102 reef coordinates, preserve their identifiers and region assignments, and retain WGS84 (EPSG:4326). Point coordinates are checked to numerical precision. The authoritative source polygons remain unchanged as GeoJSON.

## Reproduction and native R files

The full workflow was run in a fresh native R terminal without restoring an earlier workspace. A genuine command history and a selected-object `.RData` snapshot accompany the delivery. Neither is needed to rebuild the analysis. The large parsed regional RDS cache is rebuilt from the included original archives and excluded from the submission ZIP to avoid duplicating the data.

The current data and model calculations have passed the independent checks after the code was separated from plotting. The submission archive preserves directory paths and includes the author-named PNGs, the R project and all source inputs. Package installation on a new computer uses `setup.R`; cached data do not need a live service. `run.R` was rerun from a clean session for these eight plates; `R/check_results.R` confirms the totals and exports.

The student-dependent requirements—actual contribution review, attendance, accepted group/presentation format and Moodle upload—remain outside these numerical checks.
