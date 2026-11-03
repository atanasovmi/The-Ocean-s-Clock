# What we found

## Spawning follows a lunar pattern, but it is not one universal appointment

Of the 1,026 recorded reef-nights in the historical field data, 67.7% fall on days 0–7 after the nearest local full moon. That is the main pattern in [Figure 1](figures/01_lunar_timing.png): the week after full moon contains most of the records, while events also occur elsewhere in the cycle.

The night-time starts add another detail. [Figure 2](figures/02_night_timing.png) shows six well-recorded coral genera: some tend to start earlier after sunset, while others start later or have a wider spread. The locations and species differ between groups, so this is a description of the records rather than an isolated effect of genus. Daylight spawning records remain in the data; this plot focuses on exact starts after sunset.

The independent Maldives study gives a similar lunar result for Acropora: 70.4% of its 81 spawning atoll-days fall in the same week, compared with 69.8% of 400 historical Acropora reef-dates. [Figure 6](figures/06_field_comparison.png) keeps these studies separate because their survey designs and geographic units differ.

These percentages describe recorded spawning events. They do not give the chance that an arbitrary future night will contain spawning; the field databases do not list every surveyed non-spawning night.

## Heat stress increased, and its overlap with spawning seasons is uneven

The heat-stress comparison follows the same 214 NOAA reef regions over 39 complete years. In 1986, 5 reached the severe threshold; in 2024, 171 did. [Figure 3](figures/03_heat_stress.png) reduces the daily histories to one comparable count per year. There is considerable year-to-year variation, but recent years reach many more regions.

NOAA's degree-heating weeks (DHW) measure accumulated unusually high temperatures over twelve weeks. The threshold in Figure 3 is DHW ≥8. A region reaching that threshold is not the same as observing coral deaths there, and equally counting regions does not weight them by reef area.

To connect this with reproduction, we used the historical distribution of spawning months as a fixed calendar. For Northern Taiwan, its heat-stress overlap index rises from 1.5% in 1986–1995 to 26.3% in 2015–2024; the Gulf of Aqaba rises from 0.0% to 22.7%. [Figure 4](figures/04_spawning_exposure.png) shows the five largest increases and Singapore, where the index stays at zero. The full fourteen-region comparison is in [the data table](../data/derived/decadal_exposure.csv).

Across the full comparison, ten regions increase and four remain at zero. This tells us that regional heat-stress conditions increasingly overlap some recorded spawning seasons. It does not show that spawning dates moved, that reproduction failed, or that the old calendars still describe present-day behaviour. Historical survey effort can also influence those calendars. The index uses DHW ≥4, a lower threshold than the severe-stress overview.

## Extra weather inputs did not improve this prediction test

The aquarium diary records both spawning and non-spawning days, which allows a prediction test that the occurrence-only field data cannot support. We held out each entire year before predicting it, and compared all models on the same 1,007 dates from fourteen years.

The moon-and-season model has Brier error 0.111; adding the preceding week's environmental measurements gives 0.115. Lower is better. The paired uncertainty interval includes no improvement, so [Figure 5](figures/05_model_comparison.png) supports a modest conclusion: these extra inputs did not give a clear predictive gain in this specified test. That does not mean environmental conditions have no biological effect.

This is a retrospective comparison within one aquarium and its supplied monitoring seasons. It is not a forecasting service for wild reefs. The [model methods](../docs/AQUARIUM_METHODS.md) explain the lagged inputs, excluded dates, probability score and whole-year resampling.

## How much evidence sits behind the plots?

The project uses 6,178 historical source observations, 3,203,007 NOAA daily regional records, a fifteen-year aquarium study and an independent Maldives field table. The spatial and date joins match 751 historical reef-nights to NOAA context. The presentation shows summaries of those records; the raw sources, joins and full analytical tables remain available for inspection.
