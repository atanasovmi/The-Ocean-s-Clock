# Scientific review

Review date: 3 November 2026. These checks concern the actual data, transformations and interpretation. The historical wild-reef occurrence database, monitored seasonal aquarium diary, regional satellite histories and separate Maldives field study are distinct recording systems.

## Historical records and timing

The original workbook contains 6,178 observations. Reconstructing the site and accepted-taxonomy joins preserves that count without missing location or genus matches. The natural-reef subset contains 3,569 records representing 1,026 subsite-dates at 102 subsites and 68 named sites. Treating species rows as independent nights would exaggerate heavily documented events.

The share recorded on days 0–7 after nearest local full moon is 80.3% per observation row, 67.7% per reef-night and 76.2% with equal total weight per subsite. These are sensitivity results for a descriptive window, not confidence intervals, daily spawning probabilities or causal estimates. Pooled genus comparisons differ in geography, species and study composition. Lunar ridges use a stated three-bin circular smoother; accompanying percentages use unsmoothed counts. Displayed within-group shares sum to one.

The occurrence database does not consistently document surveyed non-spawning nights. Calendar zeros therefore mean no recorded event, rather than observed biological absence.

Two genuine dawn observations, 3975 and 3976, occur more than twelve hours before same-date sunset. Automatically wrapping every difference to a twelve-hour interval would misclassify them. The workflow preserves daylight events and flags the ambiguous 00:05 record 6153 rather than silently assigning another evening. Exact-time graphics use their stated narrower sample.

The Orpheus Island example on 24 November 1983 retains 17 species with exact starts from 0.25 to 3.5 hours after sunset. It was selected for informative coverage, not as a representative random night or a universal species schedule.

The independent USNO check converts UTC lunar instants to the source's local offset before comparing dates. All seven reef-nights covered by the cached 1995 phases agree. The wider historical analysis still uses source-supplied lunar fields; this limited check is not validation of every year.

## Regional histories and the calendar integration

The NOAA cache supplies 214 unique regions and 3,203,007 available daily records for 1985–2025. All 214 original-response SHA-256 hashes were independently checked. There are 1,643 missing station-days in 2025 across eighty regions; they are not filled with zero stress. The primary 1986–2024 period has 8,346 complete regional years. Initial 1985 heat-stress accumulations were not fully populated, so annual comparisons begin in 1986.

Actual NOAA polygons contain 97 of the 102 natural-reef subsites. Five at Amakusa, Kochi and Shikoku Bay lie outside. Date matching supplies context for 751 recorded reef-nights at 65 sites, 88 subsites and 41 regions. This is daily regional context, not an event-hour measurement at coral depth.

NOAA's regional values follow its specified 90th-percentile HotSpot procedure, rather than simple area means or one fixed pixel. DHW thresholds describe bleaching heat-stress conditions, not observed reproductive failure. In 2024, 202 of 214 regions reached DHW ≥4 and 171 reached DHW ≥8. Equal-weight region counts do not give the share of global reef area affected or the number of observed bleaching events.

Display grouping follows NOAA's five index headings. Longitude bands would misclassify the Pacific side of Central America and cannot separate Australia's coasts reliably. Overlapping source headings are retained in the mapping, while each unique region is displayed once. The colour scale is visually capped at 40 and labelled 40+; the single larger value, 40.0914 °C-weeks, remains unchanged in the table.

Seventeen sites with at least ten recorded reef-nights over at least three years define calendars in fourteen regions. Monthly shares are calculated within sites, then sites receive equal weight within a region. These fixed weights average monthly fractions of days at DHW ≥4. The index is influenced by the historical observation calendar; it does not estimate changed spawning behaviour.

An independent Python calculation reconstructs site weights from reef-night and spatial-lookup tables and heat-stress fractions directly from original NOAA archives. All 546 region-year exposures agree with R: maximum weight difference 1.11 × 10⁻¹⁶, maximum exposure difference 2.22 × 10⁻¹⁶. Decadal contrasts also agree. Ten regions have higher exposure in 2015–2024 than in 1986–1995; four remain zero and none decreases. Northern Taiwan has the largest increase, about 1.45% to 26.29%, or 24.84 percentage points.

Repeat the independent audit with `python tools/check_climate.py` after the R workflow. Its pandas and NumPy dependencies support validation only, not the R analysis.

## Aquarium prediction

The aquarium source has 1,350 explicitly recorded seasonal dates over fifteen years, including 208 positive dates. Its `spawning_binary` field counts tanks and must be converted to presence for the binomial analysis. These seasonal zeros are valid observations; extra environmental dates outside the diary are not extra monitored absences.

All model comparisons use identical complete-case dates: 1,007 days from fourteen years, including 162 positives. Environmental inputs average the seven calendar dates strictly preceding the response. Entire years are held out. Retrospective leave-year-out validation still trains on years on both sides of a held year; it is not a prospective deployment trial.

Held-out Brier scores are approximately 0.1114 for cyclic calendar terms, 0.1147 after adding the selected lagged environment variables and 0.1356 for training prevalence. The paired calendar-minus-environment difference is −0.0033, with a whole-year bootstrap interval of −0.0078 to +0.0006. This gives no clear predictive gain from those added inputs. It does not establish that environmental factors have no biological effect. The interval conditions on fitted held-out predictions and does not cover all model-selection uncertainty.

Separate calculations check lagged inputs and held-out probabilities. R retains convergence, matrix-rank and warning information by fold. [AQUARIUM_METHODS.md](AQUARIUM_METHODS.md) documents equations, complete-case selection and numerical audits. Pooled AUC can obscure between-year effects; within-year summaries are also supplied. The model should not be presented as a calibrated wild-reef forecasting service.

## Independent field comparison and scope

The Maldives study supplies 81 spawning atoll-days and 3,026 colony spawning observations from October 2021 to May 2024. The comparison is restricted to Acropora: 69.8% of historical genus-nights fall on days 0–7 after full moon, compared with 70.4% of Maldives spawning atoll-days and 73.9% of colony-weighted observations. This is useful descriptive replication with different units, geography, monitoring and weights, not interchangeable estimates from a common random sample.

The substantive work is the combined regional histories and biological calendars, sensitivity to counting, independently checked prediction and a separate field-data comparison. These are new analyses within this project. Claiming that the underlying ecological relationships were previously unknown would require a broader literature review and appropriate study design.

Figures should keep direct labels, stated denominators and sources. Their tables and vector exports allow inspection beyond presentation-sized PNGs. Visual review remains necessary: a clean script exit alone does not establish legibility, particularly for Windows UTF-8 labels.
