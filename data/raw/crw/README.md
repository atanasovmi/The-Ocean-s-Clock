# NOAA Coral Reef Watch regional histories

Downloaded on **3 November 2026** from the official [regional station index](https://coralreefwatch.noaa.gov/product/vs/data.php). The source reports the latest observation date as 1 November 2026. The index lists 219 entries, including five duplicate regions; the cache contains **214 unique regional time series**.

The `*.txt.gz` files are losslessly compressed copies of NOAA's original ASCII responses. Gzip metadata is deterministic. `manifest.csv` records each source URL, row count, date range and SHA-256 of the **uncompressed original response**. The cache contains **3,268,207 source station-days** and occupies approximately **44.1 MB** compressed. This is genuine daily environmental history, not simulated data or replicated spawning records.

`tools/fetch_crw.py` can retrieve missing station archives. It requires Python, `requests` and `beautifulsoup4` only for acquisition; the included caches mean the normal R analysis needs none of them. `R/prepare_ocean.R` performs the parsing, checks, spatial joins and summaries in R. The downloaded `station_index.html` and official `station_markers.xlsx` preserve the discovery catalogue. The latter is a reference; the R parser obtains marker coordinates directly from each ASCII header.

## Meaning of a regional value

These are **NOAA Version 3.1 daily 5-km Regional Virtual Station statistics**, not individual 5-km pixel histories and not measurements at a particular coral's depth. NOAA's [method description](https://coralreefwatch.noaa.gov/product/vs/description.php) explains how a region combines its reef pixels. The selected thermal-stress statistic follows the region's 90th-percentile Coral Bleaching HotSpot. The associated SST is therefore neither a simple regional mean nor a fixed pixel thermometer. The same source contains regional SST minima/maxima, SST anomaly, HotSpot, Degree Heating Weeks and alert classifications.

The R table uses these names:

| R column | NOAA source field | Interpretation |
|---|---|---|
| `sst_min_c`, `sst_max_c` | `SST_MIN`, `SST_MAX` | Region's daily SST range, °C |
| `sst_c` | `SST@90th_HS` | SST associated with the regional 90th-percentile HotSpot statistic, °C |
| `ssta_c` | `SSTA@90th_HS` | Associated SST anomaly, °C |
| `hotspot_c` | `90th_HS>0` | Positive regional HotSpot statistic, °C |
| `dhw_c_weeks` | `DHW_from_90th_HS>1` | NOAA's accumulated regional heat-stress statistic, °C-weeks |
| `alert_level` | `BAA_7day_max` | NOAA's seven-day maximum bleaching-alert classification |

Use DHW thresholds as **NOAA bleaching heat-stress context**, not proven thresholds of reproductive failure. Regional counts are counts of regions; equally weighted regions do not measure the fraction of global reef area affected. Region sizes differ.

## Frozen analytical coverage and missing dates

The normal R analysis retains **3,203,007 available station-days from 1985 through 2025**. Partial 2026 is preserved in the original responses but excluded from the analytical daily table. Initial 1985 DHW values precede a fully populated accumulation window, so annual heat-stress comparisons begin in 1986.

The downloaded source has genuine gaps in 2025. `regional_calendar_gaps.csv` records the missing dates. `regional_annual.csv` gives `n_days`, `expected_days`, `coverage` and `complete_year` rather than silently creating zero-stress days. Eighty regions have an incomplete 2025 calendar. Every regional year in **1986–2024** is complete, making that the common period for primary comparisons. A reproducible early/recent contrast uses **1986–1995 versus 2015–2024**.

## Spatial connection to spawning observations

`station_polygons.geojson` is NOAA's original public [regional geometry](https://coralreefwatch.noaa.gov/product/vs_v3/vs_polygons.json), discovered through its [map](https://coralreefwatch.noaa.gov/product/vs/map.php). It contains 214 marker points and 214 region polygons. The R script selects the polygon features, checks valid geometry and unique region identifiers, and performs a real geographic point-in-polygon intersection using `sf`.

The source coral database has 102 natural-reef subsites. **97 fall inside a published NOAA region**, and five lie outside (at Amakusa, Kochi and Shikoku Bay, Japan). No nearest-region substitution is made. After the date match, **751 of 1,026 recorded reef-nights** have regional environmental context, spanning 65 named sites, 88 subsites and 41 NOAA regions during 1985–2019. Earlier coral events predate these satellite records. Both geographic and temporal nonmatches remain visible as missing values.

The date join compares NOAA's UTC daily date label with the source's local observation date. This is daily regional context, not a subdaily temperature at the spawning instant. A region's modern heat stress can be compared with historical spawning-month windows, but such an overlay does not demonstrate that spawning still occurred on those dates, that reproduction failed, or that a seasonal pattern changed.

## Geographic display groups

`station_groups.csv` preserves NOAA's five top-level index headings: Atlantic (43 unique regions), Pacific (44), Southeast Asia (53), Australia (24) and Indian Ocean (50). These are display groups, not ocean-basin boundaries. A region listed under more than one heading is displayed once under its first source appearance; `all_source_groups` retains the other headings. The acquisition script reconstructs the mapping from the cached HTML, and the R parser writes it to `region_display_groups.csv`.

This avoids a real classification error from using longitude alone: the Pacific side of Central America must not be labelled Atlantic, while western Australia and the Great Barrier Reef cannot be separated into oceans by a single longitude cut.

## Reproduction and attribution

Original compressed sources are committed; the approximately 37.5-MB `regional_daily.rds` is a rebuildable local intermediate. Smaller catalogue, spatial lookup, gap and annual/event tables are plain CSVs. Regenerate them by sourcing `R/prepare_ocean.R` after the coral preparation step.

Data: NOAA Coral Reef Watch, Version 3.1 Daily 5-km Regional Virtual Stations, released 2019, updated daily; accessed 3 November 2026. Follow NOAA's [citation recommendations](https://coralreefwatch.noaa.gov/satellite/docs/recommendations_crw_citation.php) and acknowledge NOAA Coral Reef Watch. Public NOAA products remain subject to their source disclaimers; the analysis does not imply NOAA endorsement.
