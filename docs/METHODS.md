# What sits behind the summaries

## Counting an event

The historical workbook contains separate observation, location and taxonomy tables. We join their published IDs and check that a many-to-one join leaves the observation count unchanged. A field record, a species record and a reef-night are different units. The lunar counts use one subsite-date; the evening plots use one median exact start per genus/subsite-date. Ex-situ records, missing-value codes and ambiguous midnight timing remain explicit in the preparation.

## Linking to NOAA

A recorded reef coordinate is assigned to a published NOAA region using a point-in-polygon join. That region ID and the date label connect to a daily record. Five subsites lie outside the published polygons; missing years and dates remain missing. There are 751 matched reef-nights. The region statistic is broad environmental context, not an in-water measurement at the exact spawning instant.

## A fixed spawning calendar

We use sites with at least ten recorded reef-nights across three years. Each site's monthly event shares sum to one. Site shares are averaged within a NOAA region, giving sites equal influence. Seventeen sites support calendars for fourteen regions.

For region $r$ and year $y$, the overlap index is

$$
E_{r,y}=\sum_{m=1}^{12} w_{r,m}\,
\frac{\#\{d\text{ in month }m:\mathrm{DHW}_{r,d}\geq4\}}{\#\{d\text{ in month }m\}}.
$$

The calendar weights $w_{r,m}$ are held fixed for every year. This lets us examine changing heat around the same recorded calendar. It cannot tell us whether coral behaviour changed or reproduction failed. Survey schedules can influence the recorded calendar. Plot 8 shows every year of the common period, 1986–2024, and compares decade means for 1986–1995 and 2015–2024.

## Testing predictions

The aquarium diary explicitly supplies monitored non-spawning days. Its misleadingly named `spawning_binary` column actually counts spawning tanks; we derive presence as a count above zero. We compare a training-prevalence baseline, a cyclic season model, a cyclic moon model, both together, and both with preceding-week environmental inputs. Each entire year is excluded before predicting it. All models use the same complete-case dates.

The Brier score is the average squared gap between predicted chance $p_t$ and observed presence $Y_t$:

$$\mathrm{BS}=\frac{1}{n}\sum_{t=1}^{n}(p_t-Y_t)^2.$$

Lower scores are better. Whole-year bootstrap intervals retain within-year dependence and condition on the held-out fits. This retrospective validation uses other years both before and after the excluded year. It is not a prospective deployment test. The detailed [aquarium methods](AQUARIUM_METHODS.md) include formulas, missingness and numerical checks.

## Tightness around a cycle

Year, lunar month and day are circles, so an ordinary mean fails: day −14 and day +14 are neighbours. Each record with value $v_i$ on a cycle of period $P$ becomes a unit arrow at angle $\theta_i = 2\pi v_i / P$, and the arrows are averaged:

$$
R=\sqrt{\bar{c}^{2}+\bar{s}^{2}},\qquad
\bar{c}=\frac{1}{n}\sum_{i}\cos\theta_i,\qquad
\bar{s}=\frac{1}{n}\sum_{i}\sin\theta_i.
$$

$R$ is the tightness (statisticians call it the mean resultant length). It runs from 0, an even spread, to 1, every record at one moment. The direction of the same average is the typical moment. Two opposite clusters can also cancel to a low $R$, so the plots show the records beside the number. `R/analyse_clocks.R` calculates both.

## The local temperature year

`R/prepare_seasons.R` averages NOAA's regional temperature by day of year over 1986–2024, smooths it with a 31-day moving average that wraps around the new year, and takes the change across a centred 30-day span as the warming rate. A reef-night counts as warming when that rate is above zero on its day of the year. The comparison figure is the warming share of each night's own region, averaged across nights. Five subsites outside NOAA polygons drop out, leaving 884 of 1,026 reef-nights. The typical year needs no same-date match, so nights before satellite coverage stay in.

The backdrop of plot 2 averages the warming rate across all 214 regions by 2.5° latitude band and 5-day step. The band centred on 31.25° N is repeated once at 33.75° N so that the Kochi and Shikoku dots have a backdrop. NOAA has no region at that latitude.

## Rebuilding the sky

`R/prepare_sky.R` calculates Moon and Sun height with the low-precision formulas of the Astronomical Almanac. The Moon's height agrees with all 12,897 cached NASA/JPL Horizons positions to within 0.3°. At the sunset the source reports, the Sun sits at a median of −0.73°, which also confirms the conversion from local clock time to UTC.

For each of the 172 timed reef-nights the script steps through lunar days −15 to +14 around that night's full moon and through the hours after sunset, keeping its reef and its sunset clock time. Moonlight is the lit fraction of the disc times the sine of the Moon's height, averaged over nights. Clouds and water depth are ignored, and plot 4 shows the square root because the eye compresses brightness. Moonrise is the first upward crossing of an ideal horizon by the Moon's centre, without refraction, which matches the Horizons setting.

The drift of the spawning start uses all timed starts after sunset, without the ambiguous after-midnight records. One genus on one reef-night in one setting is one row, so a genus with an exact and an approximate record on the same night counts once. The fit keeps the eight best-recorded genera across lunar days −2 to +10, where nearly all records lie.

Two slopes are reported for each of five samples of start times in `outputs/tables/start_drift.csv`. The same-reef drift compares each genus with itself on its own reef, which is the slope `lm()` gives with one level per genus and reef. It is the headline, because a drift is a change on one reef from night to night. A stricter version also holds the year fixed. The all-reefs slope is one line through every reef with genus as a factor, and it also picks up which reefs were recorded on which nights. The 95% intervals resample whole reefs 2,000 times, because records from one reef are not independent.

The headline sample is natural reefs with exact and approximate times. Exact times alone are too few to pin the slope down, 38% of approximate natural-reef times fall on a whole or half hour, and tanks are a different setting, so the table keeps these layers apart. The moonrise delay is the slope of median moonrise over lunar days 0 to 10.

## What the presentation leaves in the tables

The eight plots show selected summaries. Full regional histories, all fourteen exposure comparisons, model predictions, fitting audits and source records remain available. `tools/check_climate.py` independently reconstructs the exposure calculation from original NOAA files; `tools/check_aquarium.py` checks lagged features and refits the models with a separate solver. The [validation record](VALIDATION.md) reports their results.
