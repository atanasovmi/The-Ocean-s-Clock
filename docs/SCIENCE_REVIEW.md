# Interpretation checks

The project uses several recording systems. They answer related questions but should not be treated as one uniform survey.

## Field records and timing

The historical workbook contains 6,178 observations. Its many-to-one joins preserve that count, and the natural-reef subset has 3,569 records representing 1,026 subsite-dates. Several species rows can describe the same night. The lunar plates count each recorded reef-date once; the evening plates count a median exact start within each genus/reef-date.

Counting choices materially affect the lunar summary: 80.3% of observation rows fall on days 0–7, compared with 67.7% of reef-nights or 76.2% with equal subsite weight. The plates use the reef-night unit. These are descriptive shares of recorded occurrences, not daily spawning probabilities. Sampling effort and geography remain uneven.

Daylight spawning is real. The workflow preserves two dawn observations more than twelve hours before same-date sunset, and flags an ambiguous 00:05 record rather than silently moving it to another evening. Plates 4 and 6 focus on evening starts; the 24-hour dial on plate 1 keeps the daylight records. Locations and species differ among genera, so it cannot isolate a causal genus effect. Seven historical reef-nights agree with the limited cached USNO reference; broader independent lunar validation is not claimed.

The separate Maldives dataset contains 81 spawning atoll-days and 3,026 colony observations. Its Acropora day-based concentration is compared with historical Acropora genus/reef-dates. The 69.8% and 70.4% summaries have different geographic and survey units; their similarity is descriptive, not a pooled estimate or a test of population equivalence.

## Three findings that change the reading

The pooled 67.7% hides two groups. Inside the tropics 88% of reef-nights fall on days 0–7; beyond them 51% do. Across the 23 sites with at least 12 reef-nights, lunar tightness falls with absolute latitude (Spearman ρ = −0.73). The trend survives removing Eilat and Kochi (ρ = −0.66), appears within Acropora alone across 17 sites (ρ = −0.63) and holds for seven common genera. Eilat was already loose in 1981–82, so this is not a recent change there. Tightness also falls with the number of recorded nights after allowing for latitude (p = 0.004). Heavier monitoring may catch more off-peak nights, so effort probably explains part of the pattern. The Maldives study, at 5° N, is looser than database sites at similar latitudes, which fits that reading.

The aquarium, the one record with zero days written down, puts 32% of its spawning days on days 0–7, against 27% of the days watched. Moon-only forecasts do no better than the baseline. Either field records overstate the lunar peak because teams go out near full moon, or tanks dull the signal, or both. These data cannot separate those explanations.

Start times stay close to sunset across the lunar month while moonrise moves about 46 minutes a night. This argues against moonrise setting the hour. It says nothing against a role for the dark gap after sunset in choosing the night.

## Ocean conditions and spawning calendars

The NOAA cache supplies 3,203,007 available daily records for 1985–2025. All 214 regions have complete years for 1986–2024, the common comparison period. Genuinely missing 2025 days remain missing. Region polygons contain 97 of 102 reef subsites; matching both region and date supplies context for 751 recorded reef-nights.

NOAA's regional statistics follow its published HotSpot procedure. They are not area means or thermometers at the coral. DHW thresholds describe accumulated heat-stress conditions, not observed reproductive failure. The worldwide line counts each region equally; it is not a measure of reef area affected.

Seventeen well-recorded sites define fixed monthly calendars in fourteen regions. Ten show higher overlap in 2015–2024 than in 1986–1995; four remain zero. Holding the calendar fixed measures changing environmental context. It cannot establish changed behaviour, adaptation or failed reproduction. Historical survey schedules can affect the calendar weights. Plate 8 shows all fourteen regions.

The overview uses the severe threshold DHW ≥8, while the calendar-overlap index uses DHW ≥4. The thresholds and denominators are printed on the relevant plates and explained in the plot guide.

## Aquarium models

The diary explicitly supplies 1,350 seasonal dates, including 208 positive dates. Its `spawning_binary` field counts tanks and is converted to presence. The paired prediction test uses the same 1,007 complete-case dates across fourteen years for every model. Environmental features strictly precede each response date.

Each whole year is held out. This retrospective design still trains on years on both sides of the excluded year. Whole-year bootstrap intervals condition on the held-out fits; they do not cover all possible model-selection uncertainty. Calendar Brier error is about 0.111, versus 0.115 after adding the specified environmental inputs. The paired interval includes no gain. That does not establish that weather has no biological effect or supply a wild-reef forecast.

Independent calculations reconstruct all 546 regional exposure values, all 4,028 lagged model inputs and all 56 held-out logistic fits. Numerical differences are documented in [VALIDATION.md](VALIDATION.md). Detailed model assumptions and equations remain in [AQUARIUM_METHODS.md](AQUARIUM_METHODS.md).
