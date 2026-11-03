# Reading and explaining the project

The project asks how recorded coral spawning aligns with natural cycles, what regional heat stress looks like around those historical seasons, and whether environmental measurements improve a separate aquarium prediction task. These questions use different kinds of evidence. Understanding that distinction matters more than memorising every package call.

## Rebuild first, inspect afterwards

Open `The-Oceans-Clock.Rproj` in RStudio. Run `source("setup.R")` once to install missing packages into the local `.Rlibrary`, then run `source("run.R", encoding = "UTF-8")` in a fresh session. Published source caches are included, so the analysis does not depend on data services being online. Package installation on a new computer still needs internet access.

The project disables automatic workspace restoration so an object left in memory cannot silently rescue an incomplete script. The delivered `.RData` snapshot can be loaded explicitly for inspection, and `.Rhistory` records commands actually executed during the build. These native files are included in the local delivery and submission ZIP when present, but excluded from Git. Neither is evidence of student participation or a replacement for scripts. Inspect the snapshot in a separate session with `load(".RData")`; reproducibility checks must start without it.

The large `regional_daily.rds` is a convenience cache reconstructed from committed NOAA gzip archives. It contains 3,203,007 available station-days, not artificial copies of coral observations.

## Follow the calculations

| Script | What to look for |
|---|---|
| `R/01_prepare.R` | Separate observation, site and taxonomy tables; unique keys; many-to-one joins; settings, dates and counting units. |
| `R/02_lunar_audit.R` | UTC full-moon instants converted to local dates. Seven historical reef-nights are independently checked. |
| `R/02_regional_environment.R` | All 214 NOAA regional histories; missing dates; point-in-polygon matches; coverage and environmental event joins. |
| `R/03_geography_seasons.R` | Geographic and temporal coverage, then within-site seasonal distributions. |
| `R/04_moon_sunset.R` | Genus lunar distributions, exact starting times and the Orpheus Island example. |
| `R/05_climate.R` | Regional heat-stress histories and the fixed-calendar exposure index. |
| `R/06_robustness.R` | How the lunar result changes when records, reef-nights or subsites receive the votes. |
| `R/analysis_methods.R` | The separate aquarium diary, lagged features, held-year-out models and uncertainty. |
| `R/09_maldives.R` | A separate Acropora field dataset, compared with its different monitoring unit retained. |
| `R/07_results.R` | Consequential checks and findings generated from the output tables. |
| `R/style.R` | Shared white-background design, typography and PNG/SVG exports. |

`run.R` lists the execution order and records session information. Preserved inputs live under `data/raw/`, prepared tables under `data/derived/`, and values behind the figures under `outputs/tables/`. If a mark looks surprising, find its table row before changing the graphic.

## Know what a row means

The historical wild-reef source has 3,569 natural-reef records, 1,026 subsite-dates and 1,942 genus/subsite-dates. Several species can be recorded on the same night. These units prevent double counting but are not automatically independent random samples. An unrecorded night is not an observed non-spawning night.

The aquarium diary supplies 1,350 seasonal dates over fifteen years, including explicit zeros and 208 positive dates. Its column `spawning_binary` actually counts spawning tanks; the model converts positive counts to presence. Environmental dates outside this diary supply preceding measurements only. Their zero scores are not promoted into extra observed absences.

The Maldives source records 81 spawning atoll-days and 3,026 colony spawning observations. Figure 12 shows both counting choices alongside historical Acropora genus-nights. Similar patterns provide a descriptive cross-check, not identical sampling designs.

NOAA rows are regional daily satellite statistics. The SST field follows a regional 90th-percentile HotSpot statistic; it is neither a coral-depth thermometer nor an ordinary regional mean. Coral coordinates are intersected with published NOAA polygons, then dates are joined. Of 1,026 recorded reef-nights, 751 have regional context. Nonmatches stay missing.

## Explain the calculations and their limits

For the climate integration, each site's recorded monthly spawning shares form a calendar. Sites receive equal total weight within their NOAA region. For every year, the index averages the monthly fraction of days at DHW ≥4 using those fixed weights. The comparison is 1986–1995 against 2015–2024, within the complete 1986–2024 record.

This measures overlap between a fixed historical calendar and regional heat-stress conditions. It does not measure changed spawning dates, fertilisation, mortality or adaptation. Four calendar-linked regions remain at zero exposure in both periods; this counterpoint belongs in the explanation.

For aquarium prediction, sine and cosine represent lunar and annual cycles continuously. The environmental model adds measurements averaged over the seven days strictly before the response date. Each entire year is withheld in turn, and all models use the same 1,007 complete dates from fourteen years. The Brier score measures squared probability error; lower is better. Whole-year resampling describes uncertainty while retaining some within-season dependence. See [AQUARIUM_METHODS.md](AQUARIUM_METHODS.md) for equations and selection choices.

The calendar model scores about 0.111, against 0.136 for training prevalence. Adding the chosen environmental inputs scores about 0.115 and gives no clear gain. That is a result about this sample and validation design, not evidence that weather and temperature are biologically irrelevant. The exercise is retrospective validation within one aquarium, not a wild-reef forecast.

## Take responsibility for the work

For each figure, explain the question, what one mark represents, which records were joined, the strongest supported finding and its most relevant limitation. Use the exported tables when rehearsing. The course allows at most two minutes per visualization, so select a coherent presentation subset rather than displaying all twelve figures.

`authors.csv` gives Mihael seven provisional main-author exports (01, 03, 05, 06, 07, 08 and 11), and Pirasanna five (02, 04, 09, 10 and 12). These are planned responsibilities, not a record of completed work. Update them if ownership changes.

| Student | Decisions and analysis reviewed or performed | Code and findings understood and checked |
|---|---|---|
| Mihael | To be completed from actual work | To be completed after review |
| Pirasanna | To be completed from actual work | To be completed after review |

Run `source("export_submission.R")` after agreeing on ownership to create named PNGs and the complete R-project ZIP. Attendance, participation, oral explanation and Moodle upload remain student responsibilities. [COURSE_REQUIREMENTS.md](COURSE_REQUIREMENTS.md) retains the instructions and outstanding format confirmations.
