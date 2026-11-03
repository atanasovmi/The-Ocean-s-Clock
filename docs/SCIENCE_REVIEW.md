# Scientific and visual review

Independent workbook audit, 3 November 2026. Counts below were calculated from the public workbook, after trimming observation-setting labels and joining locations and accepted taxonomy. They describe this collection of recorded events.

## What the sampling supports

The 3,569 underwater (`In situ`) records represent 1,026 subsite-date combinations at 102 subsites and 68 named sites. A record may describe several colonies; colony count is sometimes missing or a lower bound. It is unsuitable as a universal precision weight.

The collection contains spawning observations, without consistent surveyed non-spawning nights. Consequently, percentages must be labelled as shares of **recorded events**, not chances that a coral spawns on a given night. Blank calendar cells mean no recorded event in this extract; they do not demonstrate biological absence.

One subsite-date is a useful counting unit, but nearby subsites, successive nights, species and references may still be dependent. Avoid calling these statistically independent replicates. No significance testing is needed for the descriptive graphics.

## Recommended visual story

| Question | Graphic | Counting unit and interpretation |
| --- | --- | --- |
| Where do these observations come from? | Geographic atlas with scaled points and a restrained coverage summary | Unique spawning dates per subsite. Show coverage, not global reef abundance. |
| Does every reef share the same season? | Site-by-month heatmap, ordered by latitude | Share of each site's recorded subsite-dates, with sample sizes. Months and years of survey effort are unknown. |
| Do coral groups share the same lunar calendar? | Genus-by-lunar-day heatmap | One subsite-date-genus vote. Normalize within genus and name the denominator. Site composition differs between genera. |
| Does the pattern survive a different way of counting? | Aligned lunar distributions for records, subsite-dates and equal-subsite weighting | Same in-situ sample; compare weighting choices explicitly. |
| How does spawning relate to sunset? | Genus distributions of exact start times relative to sunset | Aggregate repeated records to a subsite-date-genus median. Preserve genuine daytime spawning. |
| What happens within one real reef-night? | Ranked species starts at Orpheus Island, 24 November 1983 | Earliest exact field start per species, with extensions to the latest start where several records exist, within one subsite-date. An illustrative case, not a universal sequence. |
| What thermal setting surrounds recorded spawning? | Selected reefs' sampled 2016 SST context with observed event dates | A documented representative subsite per location, first-of-month reference values and exact event dates, and actual sampled grid coordinates. Connecting lines guide the eye, rather than reconstructing daily SST. Surface-temperature context, not coral-depth temperature or a causal trigger. |
| What difference can a time-zone-aware join make? | Small annotated UTC/local-date example and audit summary | A reproducible astronomy check. Display disagreements as well as agreements if found. |

The final selection should favour distinct useful findings over a fixed chart count. Use direct labels, shared scales where comparable, and sequential palettes for ordered magnitudes. Purposeful colour and appropriate measurement scales match the course's DataViz guidance. A few visual case studies may be easier to explain than a single dense multi-axis chart.

## Findings worth communicating

Using the supplied nearest-full-moon day, the share in days 0 through 7 is:

- **80.3%** when each of the 3,569 records receives one vote.
- **67.7%** when each of the 1,026 subsite-dates receives one vote.
- **76.2%** when each of the 102 subsites receives equal total weight.

These are sensitivity results, not confidence intervals or estimates of all reefs. The concentration persists, while its apparent strength depends on the counting unit. The graphics use source-supplied lunar offsets; independent USNO checks cover only the successful cached sample and do not validate all years.

Genus-night counts for the seven largest field groups are Acropora 400, Platygyra 257, Galaxea 192, Favites 152, Montipora 137, Goniastrea 109 and Dipsastraea 95. These counts are smaller than species/colony record totals.

The exact-time field subset has 876 records. After grouping by subsite-date-genus, useful samples include Acropora 87, Favites 36, Montipora 23, Platygyra 23, Goniastrea 15 and Galaxea 14. Excluding the ambiguous midnight observation described below reduces Acropora to 86 units in the comparative sunset graphic. Pocillopora has ten genus-nights at only two subsites, all morning starts. It provides an interesting exception, with its limited coverage stated.

At Orpheus Island, subsite 40, on 24 November 1983, the exact field sample contains 18 records spanning 17 accepted species and nine genera. Starts run from 18:48 to 22:03; supplied sunset is approximately 18:33, and the supplied lunar offset is +4 days. Porites cylindrica has two starts; the figure marks each species' earliest start and extends the mark to the latest start where they differ. This is a strong illustration that sharing a night does not require sharing the same minute.

## Timing pitfalls requiring explicit handling

The [database paper](https://www.nature.com/articles/s41597-020-00793-8) defines exact starts as observed onset under continuous observation, distinguishes field from recently collected tank observations, and supplies date-specific UTC offsets. Its lunar convention ranges from -15 to +14 days; the solar fields are calculated benchmarks.

Do not automatically map every sunset difference into the shortest circular interval. Doing so changes the two Pavona varians records 3975 and 3976 at Uva Island from a morning start at 05:15, 13.29 hours before that day's sunset, to an apparently evening-relative +10.71 hours. They must remain visibly identifiable as dawn observations.

Exact field record 6153 (Acropora valida, Eilat, 12 June 2017, 00:05) requires special midnight handling. The calendar date alone does not establish which evening the recorder intended. Excluding this single ambiguous record from comparative sunset summaries is defensible if documented; assigning it to the previous sunset must be labelled as an assumption. Other true daytime records should not be removed merely because they are negative relative to sunset.

The source uses local full-moon dates rather than simply subtracting UTC calendar dates. Independently retrieved lunar instants must be converted with each record's supplied offset before comparison. Near the middle of the lunar cycle, two candidate full-moon dates can tie or differ by a day from another convention; retain and investigate rather than silently treating all differences as errors.

For SST, match returned timestamps explicitly and verify year/date coverage. A coastal grid point may be land or a different water body. Record distance, valid-water selection and representative-subsite choice. The final temperature case study is bounded to 2016 at three selected subsites: 21 original daily NetCDF files provide 63 location-date extractions, including first-of-month references and nine exact recorded reef-nights. These are daily samples, not monthly means, a complete annual curve or a climatological baseline. Matching UTC-labelled daily fields to a recorded local calendar date is a daily-date approximation rather than an event-hour temperature measurement.

## Claims to avoid

- This project newly discovers the connection between spawning, the Moon and sunset.
- A high share of recorded events means a high probability of spawning on an arbitrary future night.
- A temperature association proves temperature causes a timing shift.
- Pooled genus differences isolate genus effects from location, species or observer differences.
- Every exact time has minute-level biological precision; some sources assign identical times to many species.
- More API calls, a database or a more elaborate architecture automatically earns a higher grade.

The distinctive contribution is the combination of sources, the transparency of the counting and alignment choices, and the clarity of the resulting visual explanation.

## Independent output checks

The geography/season and Moon/sunset scripts were independently executed in R. Their exported plot-data tables were checked separately: the seasonal calendar contains 168 cells for 14 locations, and the lunar calendar contains 240 cells for eight genera. Shares sum to one within every displayed location/genus, to numerical precision. The single-night case retains 17 species and spans 0.25 to 3.5 hours after sunset. The sunset comparison excludes the ambiguous midnight record.

Initial PNG inspection detected a Windows source-encoding problem affecting Unicode labels. The main workflow must read the R scripts as UTF-8 and visually inspect the regenerated exports; a successful script exit alone does not establish visual correctness.
