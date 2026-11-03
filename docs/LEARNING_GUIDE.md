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
4. **`R/02_enrich.R`** connects selected sites and dates to cached NOAA temperature data and checks available independent USNO full-moon calculations. It records the environmental requests and preserves actual returned dates and grid coordinates.
5. **The remaining numbered scripts** prepare the data for each question and create the graphics. Follow the named intermediate data to its `ggplot()` layers, labels and export. The names in `run.R` give their execution order.
6. **`R/style.R`** holds the shared colours, ggplot theme and PNG-export helper. This keeps the graphic family consistent without hiding the actual analysis in a framework.

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

**What does temperature represent?** NOAA supplies daily sea-surface temperature for a geographic grid cell. It gives regional surface-ocean context, not the exact water temperature at every coral's depth. The selected cell, returned date and years used for a baseline must be explicit.

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

Before submission, replace the entries below with actual names and responsibilities. Use the real work performed; do not claim an automated step as personal understanding without reviewing it. AI-assisted preparation does not remove the need for individual participation and the ability to explain the result.

| Student | Graphics mainly responsible for | Analytical/design decisions reviewed or made | Code sections understood and checked |
| --- | --- | --- | --- |
| To be recorded | To be recorded | To be recorded | To be recorded |
| To be recorded | To be recorded | To be recorded | To be recorded |

The course requires the main author's name in each submitted PNG filename. Assign this truthfully after reviewing the graphics. Both students should understand the overall source connections and support each other's work; the course also assesses individual participation.

See `COURSE_REQUIREMENTS.md` for unresolved course-format questions and the submission requirements, and `RESEARCH.md` for source provenance and the analytical limitations.
