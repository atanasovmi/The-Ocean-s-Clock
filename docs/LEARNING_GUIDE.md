# Working through the project

Open `The-Oceans-Clock.Rproj` in RStudio and run `setup.R` once, then `run.R`. The project reads its source files explicitly. A previously saved workspace is useful for inspection but is not required to reproduce a figure.

## Follow one question through the files

For the lunar figure, begin with `R/prepare_coral.R`. It reads the separate observation, subsite and taxonomy tables, checks the keys and preserves the source row count through the joins. It then separates natural-reef records from ex-situ records. `R/plots/01_lunar_timing.R` reads the resulting reef-night table, counts events by lunar day and draws an ordinary bar chart. You can run that plot script alone from the project root once its prepared input exists.

The same pattern applies to the other questions:

| Calculation | File | Presentation script |
| --- | --- | --- |
| Observation and timing preparation | `R/prepare_coral.R` | `R/plots/01_lunar_timing.R`, `02_night_timing.R` |
| Daily NOAA histories and spatial/date joins | `R/prepare_ocean.R` | `R/plots/03_heat_stress.R` |
| Fixed-calendar heat overlap | `R/analyse_heat_exposure.R` | `R/plots/04_spawning_exposure.R` |
| Aquarium model fitting and held-out predictions | `R/fit_aquarium_models.R` | `R/plots/05_model_comparison.R` |
| Independent Acropora comparison | `R/compare_field_studies.R` | `R/plots/06_field_comparison.R` |

`R/check_lunar_reference.R` handles the small independent astronomy check. `R/export_spatial_data.R` writes the working Shapefiles and reads them back. `R/write_findings.R` generates the written results; `R/check_results.R` checks data totals, denominators and output names. The common plotting theme and save function are in `R/plots/style.R`.

## Three distinctions worth understanding

A **source row** is not necessarily a separate event. Several species can be documented at the same reef on the same date. The lunar plot counts that reef-date once. The timing plot first takes a median within each genus/reef-date, so a particularly detailed species list cannot dominate the comparison.

A **recorded spawning date** is different from a surveyed non-spawning date. The historical field database mostly supplies occurrences. Its missing dates cannot become zero observations. The aquarium diary explicitly records zeros within its supplied seasons, so it can support the separate prediction test.

A **NOAA region** is broader than an individual reef. The spatial join identifies which published polygon contains a coordinate. The date join then supplies regional context. A matching value is not a direct measurement at coral depth or at the exact hour of spawning.

## Reading the results aloud

Use the [plot guide](PLOT_GUIDE.md) before rehearsing. Start with the question, point to the axes, explain one mark, then state the main finding. The [findings](../outputs/RESULTS.md) provide concrete examples and the main limitations. If a word such as DHW or Brier score is necessary, explain it in one sentence before quoting a number.

The heat-overlap and model equations are in [METHODS.md](METHODS.md). For the model, follow how a whole year is removed from fitting and how the seven-day inputs are calculated before each response date. Those are the important safeguards; knowing the package names is not enough.

## Native R files and responsibility

`outputs/models/analysis_workspace.RData` contains selected analytical objects and fitted models. Load it explicitly in a separate R session if useful. `outputs/session.Rhistory` records commands actually run. The local `.RData` and `.Rhistory` copies are also included in the submission ZIP; automatic workspace restoration remains disabled.

`authors.csv` currently assigns three figures to Mihael (1, 3 and 5) and three to Pirasanna (2, 4 and 6). These are editable export assignments. Record actual work and understanding before presenting:

| Student | Decisions reviewed or made | Code and findings understood and checked |
| --- | --- | --- |
| Mihael | To be completed from actual work | To be completed after review |
| Pirasanna | To be completed from actual work | To be completed after review |

After reviewing ownership, run `export_submission.R` to create named PNGs and the project ZIP. The [course requirements](COURSE_REQUIREMENTS.md) retain the attendance, presentation and upload instructions.
