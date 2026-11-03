---
name: ocean-clock-analysis
description: Prepare or review coral spawning timing and environmental joins in The Ocean's Clock. Use for changes to this project's analytic samples, timing calculations or data claims.
---

# Coral timing analysis

Read `docs/RESEARCH.md` for the source tables, access details and limitations. Read `docs/COURSE_REQUIREMENTS.md` when a change affects assessed deliverables.

- The spawning source contains occurrences, not a complete record of surveyed nights with non-events. Describe proportions as distributions among recorded events; do not label them probabilities of spawning on an arbitrary future night.
- An observation row, a species record and a reef-night are different units. Choose and state the unit before aggregation. Repeated species records on the same subsite/date must not silently become independent nights. If comparing groups, deduplicate at the grouping level and describe that denominator.
- Join observations to sites with `Subsite_ID`, to accepted taxonomy with `Coral_ID`, then taxonomy to family with `Systematics_ID`. Validate key uniqueness and row counts before trusting the result. Do not join by potentially revised species names.
- Trim observation-setting and quality strings. Keep natural `In situ` observations distinct from `Ex situ` observations. Respect missing flags and distinguish exact from approximate starting times. Source `-99` codes in depth and colony counts represent missing values.
- Independent lunar timestamps are UTC. Convert them using the source offset before comparing local calendar dates; near the International Date Line this can change a full-moon day. Keep the circular lunar boundary and the convention for the nearest full moon explicit.
- Some corals spawn in daylight. Negative sunset-relative times are not automatically errors. Midnight handling should follow a documented local-date convention rather than silently dropping those records.
- NOAA point requests select a grid cell, not a coral-depth thermometer. Check the returned coordinates, water/missing mask, units and dates; never assign dates by requested row position. An earlier provider response returned different dates, so cached data must pass timestamp checks. Make any coastal-cell substitution explicit.
- The source already supplies calculated lunar and solar fields. Independent astronomy is a validation exercise; environmental data is an additional source. Neither correlations nor API use alone establish causation or scientific novelty.

Prefer small, visible checks of these risks and a clean-session rerun. Add reusable helpers only where they clarify real repeated calculations. Keep discovery open to unexpected or weak patterns instead of forcing the initial story.
