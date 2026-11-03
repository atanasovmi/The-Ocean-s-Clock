# What sits behind the summaries

## Counting an event

The historical workbook contains separate observation, location and taxonomy tables. We join their published IDs and check that a many-to-one join leaves the observation count unchanged. A field record, a species record and a reef-night are different units. The main lunar histogram uses one subsite-date; the night-time plot uses one median exact start per genus/subsite-date. Ex-situ records, missing-value codes and ambiguous midnight timing remain explicit in the preparation.

## Linking to NOAA

A recorded reef coordinate is assigned to a published NOAA region using a point-in-polygon join. That region ID and the date label connect to a daily record. Five subsites lie outside the published polygons; missing years and dates remain missing. There are 751 matched reef-nights. The region statistic is broad environmental context, not an in-water measurement at the exact spawning instant.

## A fixed spawning calendar

We use sites with at least ten recorded reef-nights across three years. Each site's monthly event shares sum to one. Site shares are averaged within a NOAA region, giving sites equal influence. Seventeen sites support calendars for fourteen regions.

For region $r$ and year $y$, the overlap index is

$$
E_{r,y}=\sum_{m=1}^{12} w_{r,m}\,
\frac{\#\{d\text{ in month }m:\mathrm{DHW}_{r,d}\geq4\}}{\#\{d\text{ in month }m\}}.
$$

The calendar weights $w_{r,m}$ are held fixed for every year. This lets us examine changing heat around the same recorded calendar. It cannot tell us whether coral behaviour changed or reproduction failed. Survey schedules can influence the recorded calendar. The plotted comparison shows decade means for 1986–1995 and 2015–2024; the complete common environmental period is 1986–2024.

## Testing predictions

The aquarium diary explicitly supplies monitored non-spawning days. Its misleadingly named `spawning_binary` column actually counts spawning tanks; we derive presence as a count above zero. We compare a training-prevalence baseline, a cyclic moon/season logistic model and the same model with preceding-week environmental inputs. Each entire year is excluded before predicting it. All models use the same complete-case dates.

The Brier score is the average squared gap between predicted chance $p_t$ and observed presence $Y_t$:

$$\mathrm{BS}=\frac{1}{n}\sum_{t=1}^{n}(p_t-Y_t)^2.$$

Lower scores are better. Whole-year bootstrap intervals retain within-year dependence and condition on the held-out fits. This retrospective validation uses other years both before and after the excluded year. It is not a prospective deployment test. The detailed [aquarium methods](AQUARIUM_METHODS.md) include formulas, missingness and numerical checks.

## What the presentation leaves in the tables

The six figures show selected summaries. Full regional histories, all fourteen exposure comparisons, model predictions, fitting audits and source records remain available. `tools/check_climate.py` independently reconstructs the exposure calculation from original NOAA files; `tools/check_aquarium.py` checks lagged features and refits the models with a separate solver. The [validation record](VALIDATION.md) reports their results.
