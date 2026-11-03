# Delivery checks

Validated on 3 November 2026 with the R environment recorded in `outputs/session-info.txt`.

- The full workflow completed from cached public inputs in a fresh `Rscript` process, without restoring `.RData`.
- Source-table keys were unique. Many-to-one joins preserved all 6,178 observation rows; all site and accepted-genus matches were present.
- Explicit analytical units: 3,569 natural-reef rows, 1,026 subsite-dates, 1,942 genus/subsite-dates. Exact-time comparisons use a narrower sample and exclude the ambiguous midnight case.
- Seasonal and lunar heatmap shares sum to one within every displayed group. Their zero cells represent zero recorded occurrences, not verified absence.
- Genuine dawn observations 3975/3976 retain a same-date sunset difference below −12 hours. Record 6153 remains flagged as ambiguous, rather than silently shifted to another date.
- Twenty-one original NOAA daily grids have checked date coordinates and Celsius units. The selected valid ocean cell is held fixed at each of three sites. All nine 2016 event dates match exactly; 63 point extractions include monthly reference samples and event-day samples.
- Seven reef-nights in the cached USNO coverage agree with the supplied lunar offsets. This is a limited cross-check, not validation of all years.
- All eight PNGs were inspected, including the resolved Windows UTF-8 issue. Exports are 4,200 pixels wide at 300 dpi. Plot-data tables accompany every figure.
- Eight PNG copies have the main-author names assigned in `authors.csv`.
- The submission ZIP preserves relative directory paths. It was extracted into a separate folder and rebuilt in a fresh R process, using the same installed packages. All **30** compared figure, plot-data and derived-data files were byte-identical to the main build. No live source download was needed. Package installation on a new computer still needs `setup.R` and internet access.

These checks establish reproducibility and specific data invariants. They do not turn this observational database into a representative survey or a causal experiment. See `outputs/RESULTS.md` for interpretation.

Student-dependent items remain: actual contribution review, attendance, lecturer confirmation of two people/Prezi, later rubric/report instructions, oral presentation and Moodle submission.
