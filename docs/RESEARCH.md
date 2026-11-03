# The Ocean's Clock: research foundation

Selected topic: **What tells a reef that tonight is the night?** We combine coral spawning observations with astronomy and ocean-temperature data to explore natural timing patterns. Lunar phase, sunset, season, location and coral group are starting points; unexpected patterns and useful additional questions remain welcome.

This foundation was researched on **2 November 2026**, before the student R implementation. The checks below establish feasibility rather than final ecological conclusions. The topic is selected by the students; lecturer approval is a separate course step.

## Three connected sources

| Source | Content | Connection |
| --- | --- | --- |
| [Coral Spawning Database v1](https://doi.org/10.25405/data.ncl.13082333.v1), Baird and colleagues | Separate observation, site, taxonomy, systematics and reference tables; calculated lunar/solar fields | `Subsite_ID`, `Coral_ID`, `Systematics_ID`, `Ref_ID` |
| [US Naval Observatory astronomy API](https://aa.usno.navy.mil/data/api.html) | Independent full-moon timestamps; solar circumstances can support selected validation checks | UTC event time converted to the source's local offset, then matched to the local observation date |
| [NOAA OISST through PSL](https://psl.noaa.gov/data/gridded/data.noaa.oisst.v2.highres.html) | Historical daily gridded sea-surface temperature | Selected reef coordinates to a documented ocean grid cell; actual returned date to observation date |

The [database paper](https://www.nature.com/articles/s41597-020-00793-8) describes the observation collection. Source attribution is retained even though the [Figshare catalogue](https://api.figshare.com/v2/articles/13082333) declares **CC0** for the database version. NOAA requests acknowledgement of data provided by NOAA PSL, Boulder, Colorado, USA. Astronomy calculations should acknowledge USNO.

## Preserved public inputs

`data/raw/coral/CSD_Tables.xlsx` is the original Excel export downloaded from [Figshare file 25048202](https://ndownloader.figshare.com/files/25048202). It is copied unchanged from the initial research download. The accompanying `coral_catalogue.json` preserves the public catalogue response used to identify the file and licence. No authenticated course pages, personal university files or credentials are migrated into this public repository.

| File | Size | SHA-256 |
| --- | --- | --- |
| `CSD_Tables.xlsx` | 2,959,628 bytes | `a771879c77c7d360d891c77bb752b130165afac6c10cbba7d73c4d029147b5c0` |
| `coral_catalogue.json` | See file | `93ffa1e7e928973c0be20539d0139e29ab9fea5e3750934e57fa0bfd358bd66f` |

The original workbook includes an already joined view. Reconstruct the joins from these separate tables so that the analytical choices remain visible:

- `tblSpawningObservations`: observation rows; one spawning record is not necessarily an independent reef-night.
- `tblSitesForSpawningObservations`: unique subsite identifiers, location names and coordinates.
- `tblCoralSpecies`: unique coral identifiers and accepted taxonomy (`Current_Genus`, `Current_Species`).
- `tblSystematics`: family and broader classification, linked through `Systematics_ID`.
- `tblReferencesForSpawningObserva`: provenance, linked through `Ref_ID`.

## Initial feasibility checks

The downloaded observation table has **6,178 rows**. Many-to-one joins to sites and accepted taxonomy retained all rows and left no unmatched location or species identifiers.

After trimming setting labels, **3,569 rows** are `In situ` and **2,609** are `Ex situ`. The natural-reef subset contains **1,026 distinct subsite-date combinations**, across **68 named sites**, spanning **19 November 1978–20 November 2019**. The 876 natural-reef rows marked with an exact starting time and no missing-start flag are a narrower sample for within-day timing. These are audit counts from the initial research, not a claim of representative coverage.

One independent three-source match was verified for observation 2 at Faga'alu, American Samoa, dated 9 November 1995. USNO reports full moon at **07:21 UTC on 7 November**. The source offset of **−11 hours** gives a local full-moon date of **6 November**, matching the supplied three-day lunar offset. The separate NOAA PSL point subset contains **28.46 °C for 9 November** at the sampled grid cell. This proves the connection is workable; it does not establish a temperature effect.

The lunar fields already exist in the coral workbook. Independent astronomy therefore provides **validation**, rather than a claim to have invented a new feature. Sea-surface temperature provides a genuinely additional environmental source.

## Analytical decisions that matter

- **Define the denominator.** Several species recorded on the same reef-night are not independent nights. A genus comparison can count one subsite-date-genus; a site-season comparison can count one subsite-date. Describe those units explicitly.
- **Do not infer absences.** This is an occurrence collection without complete observation-effort or surveyed non-event nights. It can describe timing among recorded spawning events, not the probability that any arbitrary future night will spawn.
- **Keep setting and timing quality visible.** Natural observations and tank/ex-situ observations have different interpretations. Exact, approximate and missing starting times need distinct handling. The `-99` codes in depth and colony counts denote missing values.
- **Respect circular time.** Nearest-full-moon offsets wrap around a lunar cycle. Convert UTC events to local dates before comparing calendar days. State the rule used for midnight and nearest-event boundaries.
- **Keep daylight observations.** Some groups spawn before sunset; a negative sunset offset alone does not justify exclusion.
- **Account for sampling concentration.** Site, study, species and year coverage is uneven. Equal weighting of rows, reef-nights and sites can produce different summaries. A useful sensitivity comparison makes this visible.
- **Use SST as environmental context.** A coarse surface grid cell is not a temperature probe at the coral's depth. Check ocean masks and any offshore substitution, record returned coordinates, and avoid presenting spatial or seasonal associations as causal effects.

An initial NOAA CoastWatch response returned dates different from the request, including an incorrect date for a point query. That response is excluded from the project inputs. The separate NOAA PSL response successfully contained the requested day. Future downloads must check **actual returned timestamps** and trim date boundaries; never assign requested dates to rows by position.

## Opportunities for substantive extra effort

Useful extensions include independent lunar/solar checks, environmental enrichment for well-covered locations, a comparison of sampling weights and an explicit quality audit. These improve the credibility of the graphics. API calls, database hosting or extra files do not by themselves demonstrate analytical quality.

Possible visual questions include differences in seasonal timing, lunar windows across coral groups, time relative to sunset, local temperature cycles around observed spawning, and which findings persist under alternative defensible samples. The final selection should follow actual data coverage and results. A weak or inconsistent relationship is still a valid finding.

If any predictive timing exercise is attempted, keep whole reef-years or sites together when splitting samples, and describe the task as timing **conditional on a recorded event**. A calibrated future spawning forecast would require additional observation-effort and non-event data.
