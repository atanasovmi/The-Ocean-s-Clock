# Sources, purpose and analytical decisions

Research updated **3 November 2026**. This document describes the completed data connections and the questions they can support. It separates earlier scientific findings from this project's reanalysis.

## Why examine reproductive timing alongside heat stress?

Coral spawning is relevant to monitoring, larval collection and restoration because successful external fertilization depends on coordinated release. The [Coral Spawning Database paper](https://www.nature.com/articles/s41597-020-00793-8) documents a broad historical record of these events and the importance of describing their timing. Biological calendars differ among taxa and places; a common full-moon reference does not imply one universal timetable.

Environmental associations are established subjects of research. [Sakai, Yamamoto and Maruyama (2024)](https://doi.org/10.1098/rsos.240183) used long-term aquarium records to examine synchronized spawning strategies and environmental correlates. [Sheridan et al. (2025)](https://doi.org/10.7717/peerj.19447) examined Acropora spawning in two Maldivian atolls. Their studies motivate our work; they are not discoveries made by this project.

Our additional questions are practical: how does a fixed historical spawning calendar overlap a changing regional heat record, and does preceding-week environmental information improve daily predictions on an excluded aquarium year? Both can produce useful results without assuming that every added predictor helps or that a statistical association identifies a causal cue.

## Wild-reef observations

[Coral Spawning Database v1](https://doi.org/10.25405/data.ncl.13082333.v1), Baird and colleagues, is preserved in `data/raw/coral/`. Its catalogue declares CC0. Attribution is retained regardless. The original [Excel export](https://ndownloader.figshare.com/files/25048202) is copied unchanged; its SHA-256 is `a771879c77c7d360d891c77bb752b130165afac6c10cbba7d73c4d029147b5c0`.

The observation table joins to sites through `Subsite_ID`, accepted taxonomy through `Coral_ID`, and family/systematics through `Systematics_ID`. Keys are unique on the receiving side and many-to-one joins must preserve all 6,178 observation rows. An already joined workbook sheet is not used as a substitute for these visible joins.

After trimming setting labels, the natural-reef subset contains 3,569 rows, 1,026 distinct subsite-dates, 102 subsites and 68 named sites. There are 876 exact-start rows before further timing-specific handling. Row, reef-night and genus-night are deliberately different analytical units. A heavily documented multi-species night is not silently treated as many independent nights.

The source contains occurrences with unknown survey effort. Therefore, a month or night without a record is not a verified non-spawning period. Ex-situ records remain in the preserved data but do not define figures about natural reefs. Missing-value codes, exact/approximate timing and local-date conventions are explicit in preparation.

Daylight spawning is retained. A shortest circular sunset difference would move genuine dawn observations to an apparent following night, so same-date sunset differences are used and an ambiguous post-midnight record is flagged. Nearest-full-moon offsets remain source-derived. Seven covered historical reef-nights agree with the cached [USNO](https://aa.usno.navy.mil/data/api.html) lunar reference; that limited audit is not claimed to validate all years.

## Regional ocean history

[NOAA Coral Reef Watch's Regional Virtual Stations](https://coralreefwatch.noaa.gov/product/vs/data.php) provide 214 unique regional series. The losslessly compressed source cache contains 3,268,207 station-days through 1 November 2026; the frozen R daily table contains 3,203,007 available records from 1985–2025. Source URLs, response hashes and date ranges are retained in its manifest.

These are regional statistics assembled from 5-km reef pixels, not point thermometers at each coral. In particular, the selected SST and accumulated heat-stress series are associated with NOAA's regional 90th-percentile HotSpot statistic. The [regional methodology](https://coralreefwatch.noaa.gov/product/vs/description.php) and [DHW methodology](https://coralreefwatch.noaa.gov/product/5km/methodology.php) define their meaning. DHW accumulates qualifying heat stress over the preceding twelve weeks; thresholds of 4 and 8 °C-weeks supply bleaching-stress context, not experimentally established spawning-failure thresholds.

The spatial connection uses NOAA's [published polygons](https://coralreefwatch.noaa.gov/product/vs_v3/vs_polygons.json), not marker proximity. Ninety-seven of the 102 natural-reef subsites intersect a region. Matching both region and actual date supplies context for 751 of 1,026 recorded reef-nights across 41 regions. Out-of-region sites and dates before satellite coverage remain missing. A NOAA UTC daily-date label matched to a local observation date supplies daily regional context rather than exact temperature at spawning time.

All region-years in 1986–2024 are complete and form the primary common comparison period. Initial 1985 DHW values precede a fully accumulated window. Some 2025 series have genuine missing dates, which are recorded in a gap table rather than filled as zero stress. The early/recent contrast is 1986–1995 versus 2015–2024. Full definitions, coverage and attribution are in [`data/raw/crw/README.md`](../data/raw/crw/README.md).

For calendar-weighted exposure, a site needs at least ten recorded reef-nights across three years. Monthly recorded-night proportions are calculated within each site, then eligible sites receive equal weight within their NOAA region. Seventeen sites support fourteen regional calendars. Holding those weights fixed while changing the heat record measures environmental overlap with the historical calendar. It cannot reveal whether spawning dates themselves changed or whether gametes, larvae or adults were harmed. Observational sampling may influence the historical weights.

## A diary that includes zero dates

The [Okinawa Churaumi Aquarium data](https://doi.org/10.5281/zenodo.10974150), published with Sakai, Yamamoto and Maruyama (2024), are CC BY 4.0. The supplied seasonal diary contains 1,350 dates, ninety per season during 2003–2017; the associated environmental table contains 5,479 dates. Only the diary defines observed positive and zero dates. Extra zeros elsewhere in the environmental file do not become additional surveyed non-events.

The column called `spawning_binary` actually counts spawning tanks, with values from zero to seventeen. The daily response is explicitly converted to any spawning (`>0`). Calendar terms use lunar and seasonal sine/cosine harmonics. Environmental terms use only measurements from the seven preceding dates. Missing tank-temperature observations reduce the common complete-case comparison to 1,007 dates from fourteen years.

Models are compared by leaving a whole year out, fitting to the other eligible years and predicting the excluded year. This is retrospective validation rather than a chronological operational forecast. Brier error is the primary score; a whole-year bootstrap preserves within-year dependence. The paired change between calendar and calendar-plus-environment models is evaluated directly. All three comparisons use identical dates. See [`AQUARIUM_METHODS.md`](AQUARIUM_METHODS.md) for equations, response definitions, uncertainty and actual results.

Aquarium tank temperature, local-station weather and regional solar flux have different spatial supports. Tank/colony composition and observation availability can vary. These constraints keep the model's conclusions specific to the monitored system and specified analysis; they do not show that weather is biologically irrelevant or forecast spawning on a wild reef.

## Independent Maldives observations

[Sheridan et al. (2025)](https://doi.org/10.7717/peerj.19447), Supplement 4, supplies 81 spawning atoll-days from October 2021–May 2024, representing 3,026 Acropora colony observations. The published CSV and attribution are preserved under [`data/raw/maldives/`](../data/raw/maldives/), CC BY 4.0.

We compare the historical **Acropora** genus-night sample with the new atoll-day data. Their monitoring designs and geographical aggregation remain different. The presentation compares recorded dates; the colony-weighted calculation remains in the full analytical table. The similar day 0–7 concentration is a descriptive comparison, not a pooled effect estimate or a newly discovered natural mechanism.

An audit found a source discrepancy: the article text gives a Baa maximum of 203 colonies, while the CSV records 243 on 2 November 2023. The source CSV is preserved unchanged and its overall counts agree with the paper. The raw-data README records the discrepancy; weighted calculations use the supplied table.

## R tools

The course teaches tidyverse preparation and ggplot2 alongside packages such as sf, viridis, zoo and leaflet. No exclusive package whitelist was found in the archived assignment and assessment instructions. The current implementation uses a small set with specific jobs.

- `readxl`, `readr`, `dplyr` and `tidyr` read and prepare the tables.
- [sf](https://r-spatial.github.io/sf/) performs the point-in-polygon join and exports the working Shapefiles.
- [ggplot2](https://ggplot2.tidyverse.org/) draws each presentation chart with standard geoms and `theme_bw()`.
- Base R's `stats` functions fit the binomial models and perform the lag calculations.
- [ragg](https://ragg.r-lib.org/) and [svglite](https://svglite.r-lib.org/) provide reliable raster and vector exports.

The figures use one chart per question, readable axes and at most a small number of series. Detailed records and diagnostics stay in the tables. The separate Python utilities download the public NOAA histories and independently check numerical calculations; they are not required for the cached R workflow.

## Contribution and limits

The source integration, exposure-index specification and held-out daily prediction comparison are this project's analytical work. Prior published studies already investigate lunar, seasonal and environmental associations. A claim of globally novel science would require a much broader review and stronger data than this course project can establish. The useful contribution is to show what these connected sources support, where a result replicates, and where an apparently richer model fails to improve validation.
