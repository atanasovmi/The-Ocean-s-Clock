# Validation

Checked on 3 November 2026. The delivery environment is recorded in `outputs/session-info.txt`.

## Sources and analytical units

All 214 NOAA gzip archives were independently decompressed and checked against their source SHA-256 hashes. The R parser retains **3,203,007 available station-days** for 1985–2025. It identifies **1,643 missing station-days** in 2025 across 80 regions rather than inventing zero-stress records. All **8,346 region-years** used for the 1986–2024 climate comparison have complete daily coverage.

The coral joins preserve 6,178 source rows and produce 3,569 field observations, 1,026 subsite-dates and 1,942 genus/subsite-dates. Official NOAA polygons and date keys connect 751 recorded reef-nights to environmental histories. Unmatched locations and years remain explicit. Regional values are not described as point measurements at coral depth.

The Maldives source contains 81 atoll-days and 3,026 colony spawning observations. These units stay separate. The aquarium source supplies 1,350 monitored diary dates, including explicit non-spawning dates. Its `spawning_binary` field actually counts tanks; spawning presence is derived explicitly. The complete-case model sample has 1,007 dates in fourteen years.

## Independent calculations

`python tools/check_climate.py` independently reconstructs site/month weights and reads the original NOAA histories. All **546 region-years** in the fourteen-region calendar integration match R, with a maximum absolute exposure difference of **2.22 × 10⁻¹⁶**. It confirms ten increases and four unchanged zero-exposure regions in the stated decade comparison.

`python tools/check_aquarium.py` reconstructs all **4,028** lagged features using explicit calendar-date ranges. The maximum difference is **1.14 × 10⁻¹³**. It independently refits all **28** held-out logistic models with SciPy; predicted probabilities differ by at most **8.75 × 10⁻⁹**. These Python tools provide separate checks and are not dependencies of the R analysis itself.

Every validation fit and both full-data aquarium fits converge with full rank and no numerical fitting warnings. No held-out-year responses enter a training fold; lagged measurements strictly precede the diary date. The bootstrap resamples whole years and uses the same date-weighted Brier estimand as the point estimate. Validation is retrospective leave-one-year-out, not a prospective deployment test.

## Timing and visual checks

Lunar and monthly-calendar shares sum to one within every displayed group. The source-relative lunar smoother wraps at the edge of its thirty day-offset bins; unsmoothed counts produce the printed percentages. Genuine dawn observations 3975/3976 remain more than twelve hours before the same-date sunset; midnight record 6153 is flagged separately. The limited cached USNO sample matches seven historical reef-nights exactly.

Twelve figures are exported as 300 dpi PNGs and scalable SVGs. White backgrounds, readable labels, direct annotations, map projection, scales and categorical units were reviewed in the actual output files. Individual panels use explicit denominators and retain meaningful exceptions rather than forcing a uniform pattern.

## Reproduction and native R files

The full workflow was run in a fresh native R terminal without restoring an earlier workspace. A genuine command history and a selected-object `.RData` snapshot accompany the delivery. Neither is needed to rebuild the analysis. The large parsed regional RDS cache is rebuilt from the included original archives and excluded from the submission ZIP to avoid duplicating the data.

The submission ZIP was extracted into a separate folder and rebuilt in a fresh R process with no workspace restored or live data download. All **70** compared PNGs, SVGs, plot-data tables and derived CSVs match the main build byte-for-byte. This caught an initially unspecified legend order; the final guide order is explicit and stable. The archive retains directory paths and produces twelve PNGs with the names assigned in `authors.csv`. Package installation on a new computer uses `setup.R`.

The student-dependent requirements—actual contribution review, attendance, accepted group/presentation format and Moodle upload—remain outside these numerical checks.
