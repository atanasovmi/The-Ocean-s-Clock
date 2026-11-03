# Understand and own the analysis

The project should be reproducible by R and explainable by its two students. Read the results alongside the scripts rather than memorising chart captions. The course asks you to explain the guiding question, data, approach, answer and limitations in at most two minutes per visualization.

## Begin with a clean R session

Open `The-Oceans-Clock.Rproj` in RStudio. It sets the project root for relative paths and disables automatic workspace/history restoration. Run `source("setup.R")` once to install any missing packages into the ignored local `.Rlibrary`. Then restart R and run `source("run.R")`.

The normal run recreates the preparation and graphics from explicit inputs. Preserved API responses allow the environmental data to be reused without depending on an interactive browser session. If a required response is missing, the enrichment script may need network access to retrieve it.

An `.RData` file would save whatever objects happened to exist in one person's interactive session. That can hide a missing preparation step. It is deliberately excluded here, as are `.Rhistory` and personal RStudio state. The `.Rproj`, scripts and documented source files are the reproducible project.

## Follow the data, one step at a time

1. **`setup.R`** checks package availability. It is installation support, not part of the analysis itself.
2. **`run.R`** lists the numbered analysis scripts in execution order. This is the main entry point; it also records the R session information.
3. **`R/01_prepare.R`** reads separate Excel tables, checks identifier uniqueness, joins locations and accepted taxonomy, parses dates/times, separates field observations and builds the analysis units. Read the checks beside the joins: they protect against multiplying observations accidentally.
4. **`R/02_enrich.R`** extracts temperature at three selected subsites from 21 cached NOAA daily NetCDF grids in 2016, producing 63 location-date values. The dates combine first-of-month references with the exact dates of nine recorded reef-nights. It checks actual NetCDF dates, units and valid ocean cells, holds the chosen grid cells fixed, records their distance from the reefs, and checks available independent USNO full-moon calculations.
5. **`R/03_geography_seasons.R`** creates figures 01 and 02: the coverage atlas and site-by-month spawning calendars. Compare the counted reef-nights with the source rows before reading the monthly percentages.
6. **`R/04_moon_sunset.R`** creates figures 03–05: genus lunar calendars, exact starting times relative to sunset, and species appointments on one Orpheus Island night. It keeps a focused local example distinct from pooled comparisons.
7. **`R/05_temperature.R`** creates figures **06 and 08**: the sampled 2016 temperature context and the integrated seasonal/lunar/temperature view. Both use the same nine selected reef-nights. Connecting first-of-month points guides the eye; it does not reconstruct daily temperatures.
8. **`R/06_robustness.R`** creates figure 07. It compares the same lunar pattern when counting every source row, every reef-night once, or each subsite with equal total weight.
9. **`R/07_results.R`** checks consequential data/timing invariants and writes the findings from the analytical tables. Read these generated results alongside the graphics.
10. **`R/style.R`** holds the shared colours, ggplot theme and PNG-export helper. This keeps the graphic family consistent without hiding the actual analysis in a framework.

`data/raw/` preserves source inputs and service responses. `data/derived/` contains reproducible analytical tables. The figures and their plot-data tables are exported under `outputs/`. A plot-data CSV is useful when checking an unexpected mark: it shows the numbers actually given to the chart.

## Three units that must not be confused

| Unit | Meaning | Why it matters |
| --- | --- | --- |
| Observation row | One record in the source collection | Several records can describe the same night and location. |
| Reef-night | One subsite and local date | Counts one recorded spawning night without giving heavily recorded species extra votes. |
| Genus-night | One subsite, local date and coral genus | Allows genus timing comparisons; a night with several genera can contribute to several groups. |

None of these units is automatically an independent random sample. Shared location, study and year can still connect the observations. Nor does an unrecorded date mean that spawning was surveyed and found absent.

## Five decisions to be able to explain

**Why filter to natural reefs?** `In situ` and `Ex situ` settings have different interpretations. Tank observations remain in the preserved input and quality accounting, but should not silently define a chart about natural reef behaviour.

**Why use local dates?** A full-moon timestamp is an instant in UTC. Near the International Date Line, the local calendar date may differ. At the verified American Samoa example, 7 November 1995 at 07:21 UTC is still 6 November at an offset of −11 hours. The event dated 9 November is therefore three local calendar days later.

**Why do timing samples have different sizes?** A date-only observation can inform season and lunar timing. A sunset comparison additionally needs a usable starting time, a clear recording convention and a stated quality filter. Use the sample named on the graphic.

**What does temperature represent?** NOAA supplies daily sea-surface temperature for a geographic grid cell. It gives regional surface-ocean context, not the exact water temperature at every coral's depth. Our bounded case study uses Raffles Lighthouse, Orpheus Island and Sesoko in **2016 only**: twelve first-of-month reference dates plus the actual spawning dates, totalling 21 distinct dates and 63 point extractions. These are individual daily values, not monthly averages, a complete annual series or a climatic baseline. The source's UTC-labelled daily date is matched to the local recorded date as a stated daily-date approximation; this does not provide an exact local event-hour temperature.

**What does a percentage mean?** It describes the share of the specified recorded observations or nights in the chosen sample. It does not give the probability of spawning on an arbitrary future night. Compare denominators before comparing percentages between charts.

## A short rehearsal for any figure

Point to the chart and answer:

- What single question does it answer?
- What does one mark or cell represent, and what is the denominator?
- Which source tables or services were joined, on which keys?
- What is the clearest result, and which mark supports that statement?
- What is the most relevant limitation or alternative explanation?

If a result changes under a different reasonable weighting or filter, explain that change. A sensitivity result can be more informative than an overly confident headline. Observed associations do not establish that the Moon, sunset or temperature caused the recorded event.

## Record actual student contributions

`authors.csv` records the team's **provisional export allocation**: Mihael is assigned figures 01, 03, 05, 07 and 08; Pirasanna is assigned 02, 04 and 06. These assignments identify planned main-author filenames, not evidence of work already performed. Update them if actual responsibility changes.

Before submission, complete the entries below with actual responsibilities and reviewed decisions. Use the real work performed; do not claim an automated step as personal understanding without reviewing it. AI-assisted preparation does not remove the need for individual participation and the ability to explain the result.

| Student | Graphics mainly responsible for | Analytical/design decisions reviewed or made | Code sections understood and checked |
| --- | --- | --- | --- |
| Mihael | Provisional: 01, 03, 05, 07, 08 | To be recorded from actual work | To be recorded after review |
| Pirasanna | Provisional: 02, 04, 06 | To be recorded from actual work | To be recorded after review |

The course requires the main author's name in each submitted PNG filename. Assign this truthfully after reviewing the graphics. Both students should understand the overall source connections and support each other's work; the course also assesses individual participation.

See `COURSE_REQUIREMENTS.md` for unresolved course-format questions and the submission requirements, and `RESEARCH.md` for source provenance and the analytical limitations.
