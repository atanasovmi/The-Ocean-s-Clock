# Working on The Ocean's Clock

Keep the R analysis readable by a student who must explain it. Prefer visible import, preparation, analysis, plotting and export stages; meaningful intermediate names; explicit join keys; relative paths; and ordinary tidyverse/ggplot2 code. Functions and additional dependencies should simplify actual repeated or difficult work. These are preferences, not fixed limits on code size or structure.

Read `docs/COURSE_REQUIREMENTS.md` for the assessment context and `docs/RESEARCH.md` for the data and analytical limitations. Apply the project skill at `.agents/skills/ocean-clock-analysis/SKILL.md` when changing the coral timing analysis.

Keep downloaded source files unchanged. Put derived data and figures in their designated output folders. Cache external responses so a normal analysis run does not depend on live APIs. Check meaningful risks: join cardinality, sampling units, missing-value codes, local dates and returned environmental timestamps. Explain analytical decisions in comments, including units and exclusions.

Use a clean-session run to verify reproducibility and inspect the exported PNGs at presentation size. Do not save an interactive `.RData` workspace or rely on `.Rhistory`. Do not add a website, dashboard or database unless it has a concrete analytical purpose requested by the user. Presentation slides are outside the current scope; the students will use Prezi.

The project is exploratory. Let additional questions emerge from the data; do not force a predetermined result or claim causal effects, calibrated spawning predictions, or scientific novelty that has not been established. Keep personal contribution and final author filenames truthful; do not invent names or authorship.
