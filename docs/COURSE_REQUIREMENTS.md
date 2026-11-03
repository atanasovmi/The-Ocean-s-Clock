# Course requirements and project decisions

Working summary of the FHNW Applied Data Science blockweek instructions captured on **2 November 2026**. This is our summary, not an official marking rubric or a replacement for in-class updates.

Official sources: [assignment](https://rapp.fhnw.ch/RAPP/ProjektWoche_DataScience/OD_HT01/) and [assessment / Leistungsbewertung](https://rapp.fhnw.ch/RAPP/ProjektWoche_DataScience/OD_HT01/#section-leistungsbewertung). Authentication may be required. The full course archive remains outside this public repository.

## What the course requires

- Attend at least four of the five course days.
- Produce an identifiable original contribution and at least one high-quality visualization per person. The whole group shares responsibility for the output.
- Use interesting guiding questions, integrate relevant data, prepare it carefully and choose suitable chart types and scales. The assessment specifically values accessible, purposeful colours; clear axes and legends; attention to `theme()` details; originality; and answers supported by the graphics. Pie charts are discouraged in the stated criteria.
- Present Friday, **6 November 2026**, in the afternoon. Everyone presents their own work; allow at most two minutes per visualization and prepare for questions about the data, method, answer and limitations.
- Submit high-quality **PNGs**, each named for the person mainly responsible, and a complete **R project ZIP with all required scripts and files** through Moodle by **6 November 2026, 23:59**. Swiss local time is the working assumption.
- The course-specific weighting is **60% group visualizations / 40% individual participation**. Individual grades can differ. The accessible material does not state a numerical passing cutoff or the exact jury/lecturer split within the 60%.

The course requests approximately 3–5 PowerPoint slides. The students intend to present in Prezi; that format substitution needs lecturer acceptance. This repository delivers analysis and graphics rather than a slide deck.

## Decisions for this project

- Two students are developing several substantial graphics. The published brief specifies **3–5 people**, so a two-person exception still needs lecturer confirmation.
- The selected topic is **The Ocean's Clock**. English is used for code and graphic labels. Presentation narration can be German.
- The first implementation covers the data and analysis project, graphics and reproducible packaging. No website or dashboard is required.
- Questions remain exploratory: lunar, daily, seasonal and environmental patterns are starting points rather than a boundary on discovery.
- A minimum graphic count is not the quality target. Every retained figure should answer a useful question, use an explicit denominator and contribute to a coherent story.
- Keep the R/tidyverse/ggplot2 approach familiar from the course. Add tools only where they materially improve the analysis.

## Software and the scope of the examples

The [installation section](https://rapp.fhnw.ch/RAPP/ProjektWoche_DataScience/OD_HT01/#section-installation-von-r-und-rstudio) teaches local R and RStudio. The DataViz tutorials introduce ggplot2 layers and scales; the case scripts use tidyverse preparation, `sf` for geographic data, `viridis` and `colorspace` for colours, `zoo::rollmean()` for rolling summaries, and `leaflet` for interactive map examples. Other supplied examples load packages such as `gridExtra`, `eurostat`, `classInt`, `MASS`, `ggimage` and `rsvg`.

These are demonstrated tools, **not an exclusive package whitelist**: no such restriction was found in the captured course instructions. Conversely, their inclusion does not formally approve every possible advanced technique. Our use of ggplot2 and explicit tidyverse joins follows the taught approach; packages for Excel import, API access, figure composition and PNG export serve concrete project needs. A database or interactive website is unnecessary for the present analysis.

Sources: [DataViz](https://rapp.fhnw.ch/RAPP/ProjektWoche_DataScience/OD_HT02/) and [case tutorials](https://rapp.fhnw.ch/RAPP/ProjektWoche_DataScience/OD_HT03/), reviewed through the local read-only course extraction. This paragraph describes what was found, rather than adding a new course rule.

## Items the students must still resolve

- Lecturer Good to Go, including group-size and Prezi-format exceptions.
- The later jury rubric and any Moodle/in-class changes.
- Actual individual ownership, final author names in PNG filenames and both students' understanding of their contribution.
- Attendance, participation, presentation and final Moodle upload.

The generic module-description PDF refers to a report/presentation split of 70%/30%, conflicting with the live course and semester programme's matching 60%/40%. Confirm whether a separate report is expected. Do not infer that it is required or waived from this summary.
