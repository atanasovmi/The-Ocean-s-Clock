# Source data

`coral/` preserves the original Coral Spawning Database workbook and public catalogue (CC0). Observation, site and taxonomy keys reconstruct the field sample; lunar and solar fields are provided by the source.

`crw/` contains all 214 NOAA regional virtual-station histories as lossless gzip files, official region polygons, catalogue, source grouping and checksums. See its README for the distinction between regional thermal statistics and point temperatures, missing 2025 dates and actual spatial joins.

`aquarium/` contains the fifteen-year Churaumi diary and environmental series, with CC BY 4.0 attribution and source archive checksum. The source's `spawning_binary` counts tanks, so the model explicitly derives spawning presence. Non-spawning dates are used only where explicitly supplied in the monitoring diary.

`maldives/` contains the separate CC BY 4.0 field-study observations, source hash and provenance. Its 3,026 colony spawning observations occupy 81 atoll-days; those are different counting units. The documented source-CSV/article maximum discrepancy remains visible.

`usno/` preserves the successful public November 1995 Moon-phase response from the original research. It supports a limited seven-reef-night independent timing check. Main historical lunar fields come from the coral database; broader USNO validation is not claimed.

Normal analysis uses cached inputs. The Python acquisition utility `tools/fetch_crw.py` recreates the NOAA download and catalogue when needed; the numerical checks are separate from analysis. Original source contents are not rewritten by the R scripts. The superseded nine-event 2016 OISST pilot is retained in Git history rather than the current project.
