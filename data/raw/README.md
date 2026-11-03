# Public source data and provenance

These are public source files, retained unchanged. The teaching website and private
course files are not published here. Derived tables are rebuilt by `R/01_prepare.R`
and `R/02_enrich.R`; `data/derived/request_manifest.csv` records downloaded-file
URLs, byte counts and MD5 checksums. It is an integrity record, not a security claim.

## Coral Spawning Database

- Baird and colleagues, *An Indo-Pacific coral spawning database*, Scientific Data
  (2021), [doi:10.1038/s41597-020-00793-8](https://doi.org/10.1038/s41597-020-00793-8).
- Dataset version 1: [doi:10.25405/data.ncl.13082333.v1](https://doi.org/10.25405/data.ncl.13082333.v1).
- Original Excel export: <https://ndownloader.figshare.com/files/25048202>.
- Original catalogue response: <https://api.figshare.com/v2/articles/13082333>.
- Catalogue declares CC0. Attribution is retained. Public source author/reference
  information in the workbook belongs to that published dataset.

The relational tables contain 6,178 records, including both in-situ and ex-situ
observations. Natural-reef analyses use 3,569 in-situ records, representing 1,026
subsite-date combinations. Occurrence records do not record all surveyed nights:
an absent row is not a measured absence of spawning. The API-access pilot saved
the workbook and catalogue on 2 November 2026; they were migrated without alteration.

## NOAA/NCEI OISST v2.1 — bounded 2016 case study

- Product: NOAA/NCEI 0.25-degree daily optimum interpolation sea-surface temperature,
  final AVHRR product, version v02r01.
- Data DOI: <https://doi.org/10.25921/RE9P-PT57>.
- Official download root:
  <https://www.ncei.noaa.gov/data/sea-surface-temperature-optimum-interpolation/v2.1/access/avhrr/>.
- File pattern: `YYYYMM/oisst-avhrr-v02r01.YYYYMMDD.nc`.
- NOAA data acknowledgement: data provided by NOAA/NCEI. Product documentation and
  scientific references are embedded in each original NetCDF file.

The 21 cached daily grids cover the first day of each month in 2016 plus the union
of actual 2016 spawning dates at three selected subsites. The subsites were chosen
within Raffles Lighthouse, Orpheus Island and Sesoko by the largest number of
distinct observed nights **in 2016**, with subsite ID as a deterministic tie-break.
This is a small geographically contrasting case study, not a representative sample
of all reefs or years.

For each subsite, the nearest finite ocean grid cell is selected from the first
file using great-circle distance, then held fixed for every subsequent date.
The nearest-water search is bounded to 0.75 degrees in latitude/longitude and a
maximum accepted distance of 60 km. Actual selected distances are 3.98 km (Sesoko),
11.86 km (Orpheus Island) and 14.65 km (Raffles Lighthouse), all documented in
`data/derived/thermal_grid_cells.csv`. Missing values are not imputed.

R's `ncdf4` reader applies the source scale factor and fill-value mask. The script
checks `Celsius` units and the actual time coordinate (`days since 1978-01-01
12:00:00`) against the requested date. The point extract has **63 sampled daily
values**, including 12 monthly reference points per site, and joins all **9 observed
reef-nights** in the selected subsites during 2016. These are not 366-day annual
temperature series: lines connecting monthly points are visual guides. Event-date
values are extracted separately, not interpolated from the monthly points.

NOAA's daily date is a UTC product date; the observations are local calendar dates.
Matching their date labels supplies broad daily ocean context, not a subdaily
temperature at the instant of spawning. OISST is an interpolated surface-ocean field,
not a direct thermometer reading at the coral's depth. No causal temperature effect,
spawning probability or future prediction is inferred from this panel.

The initially tested NOAA PSL subset service timed out during project construction.
The final analysis uses the direct official NCEI files above; failed probes and the
earlier mismatched ERDDAP sample are excluded from this repository's analysis.

## US Naval Observatory — independent lunar check

- Original cached request:
  <https://aa.usno.navy.mil/api/moon/phases/date?date=1995-11-01&nump=5>.
- Documentation: <https://aa.usno.navy.mil/data/api.html>.
- Cached on 2 November 2026, migrated unchanged; five returned phases include
  full moons on 7 November and 7 December 1995 (UTC).

UTC full-moon timestamps are shifted by each source record's fixed UTC offset
before converting to a local calendar date. The closest local full-moon date is
compared with the supplied calendar-day offset. An exact calendar-distance tie
prefers the future moon, and is flagged. Only events within 15 days of one of
the cached full moons enter the independent check. All seven matched reef-nights
agree in this bounded sample. This validates that sample only. The supplied lunar
fields remain the basis of the full historical analysis; they were not independently
recalculated for the entire database. Fresh USNO requests failed with connection
resets during construction, so broader validation is not claimed.
