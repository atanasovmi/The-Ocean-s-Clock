# What sits behind the summaries

The analysis asks three related questions. Circular summaries describe when recorded spawning is concentrated. A fixed calendar measures how regional heat overlaps those recorded months. Held-out predictions test whether calendar and environmental information help anticipate a monitored spawning day. Each question needs its own observation unit, denominator and interpretation.

## Counting an event

The historical workbook contains separate observation, location and taxonomy tables. We join their published IDs and check that a many-to-one join leaves the observation count unchanged. A field record, a species record and a reef-night are different units. The lunar counts use one subsite-date; the evening plots use one median exact start per genus/subsite-date. Ex-situ records, missing-value codes and ambiguous midnight timing remain explicit in the preparation.

## Linking to NOAA

A recorded reef coordinate is assigned to a published NOAA region using a point-in-polygon join. That region ID and the date label connect to a daily record. Five subsites lie outside the published polygons; missing years and dates remain missing. There are 751 matched reef-nights. The region statistic is broad environmental context, not an in-water measurement at the exact spawning instant.

## A fixed spawning calendar

We use sites with at least ten recorded reef-nights across at least three years. Here a site is the combination of site name, country and NOAA region, pooling its recorded subsite-dates. Seventeen sites support calendars for fourteen regions.

### From recorded nights to calendar weights

Let $n_{s,m}$ be the number of recorded reef-nights at site $s$ in month $m$, and $S_r$ the number of eligible sites in region $r$. First normalise within each site, then average the site shares within the region.

```math
q_{s,m}=\frac{n_{s,m}}{\sum_{k=1}^{12}n_{s,k}},\qquad
w_{r,m}=\frac{1}{S_r}\sum_{s\in r}q_{s,m},\qquad
\sum_{m=1}^{12}w_{r,m}=1.
```

This gives each eligible site equal influence, so a heavily recorded site cannot dominate simply through its record count. Within a site, a month with no recorded events gets a share of zero. That zero describes the available records, while survey schedules still limit what we know about unobserved spawning.

### From daily heat to annual overlap

For region $r$, year $y$ and month $m$, let $D_{r,y,m}$ be the number of available daily records and $H_{r,y,m}$ the number with degree heating weeks (DHW) at least 4 °C-weeks. The monthly stress fraction and annual overlap are

```math
f_{r,y,m}=\frac{H_{r,y,m}}{D_{r,y,m}},\qquad
E_{r,y}=\sum_{m=1}^{12}w_{r,m}f_{r,y,m},\qquad
0\leq E_{r,y}\leq1.
```

Using a fraction accounts for different month lengths, including leap-year February. The coverage audit confirms complete daily records throughout 1986–2024 for the regions used here. The threshold of 4 °C-weeks belongs to this overlap calculation. Plot 7 separately counts regions reaching 8 °C-weeks in a year.

Suppose a region's calendar puts 60% of its weight in May and 40% in June. If half of May's days and one quarter of June's days meet the threshold, its overlap is $0.6\times0.5+0.4\times0.25=0.40$. If we draw a month using the calendar weights and then draw one of its days uniformly, 40% of those draws would meet the heat threshold.

The weights are held fixed for every year. Changes in $E_{r,y}$ therefore come from the heat series, with the recorded biological calendar held constant. This makes the historical comparison interpretable, while adaptation, changing spawning dates and reproductive success remain outside the index. The calendar pools historical records, so the exercise is retrospective.

Plot 8 shows all 39 years and compares equal-year decade means. Its change is

```math
\Delta E_r=
\frac{1}{10}\sum_{y=2015}^{2024}E_{r,y}
-\frac{1}{10}\sum_{y=1986}^{1995}E_{r,y}.
```

A change of 0.10 corresponds to ten percentage points. The implementation checks that each region's calendar weights sum to one. A separate Python calculation reproduces all 546 region-years from the source histories to numerical precision. [Calculation](../R/analyse_heat_exposure.R), [independent check](../tools/check_climate.py), [validation record](VALIDATION.md).

## Testing predictions

The aquarium diary explicitly supplies monitored non-spawning days. Its `spawning_binary` column counts spawning tanks, so we derive presence as a count above zero. We compare a training-prevalence baseline, a cyclic season model, a cyclic moon model, both together, and both with preceding-week environmental inputs.

### Why use cyclic logistic models?

Write $p_t$ for the probability of at least one tank spawning on a monitored date. Logistic regression keeps fitted probabilities between zero and one. The combined calendar model uses one seasonal harmonic and two lunar harmonics.

```math
\begin{aligned}
\log\!\left(\frac{p_t}{1-p_t}\right)
&=\beta_0+S_t+L_t,\\
S_t&=a\sin(2\pi j_t/365.2425)+b\cos(2\pi j_t/365.2425),\\
L_t&=\sum_{h=1}^{2}\left[
c_h\sin(2\pi h d_t/29.53059)
+e_h\cos(2\pi h d_t/29.53059)\right].
\end{aligned}
```

Here $j_t$ is day of year and $d_t$ is the supplied offset from full moon. A sine–cosine pair lets the data determine the phase of a cycle without a discontinuity at its boundary. The second lunar harmonic allows a more flexible shape, including two concentrations within a cycle. Separate season-only and moon-only fits reveal which set of terms contributes predictive information. The environmental extension adds preceding-week temperature, wind, solar flux and `log1p` rainfall.

All five models are evaluated on the same 1,007 complete-case dates in fourteen years, so each comparison has the same missing-data coverage. For each fold we exclude one entire year before fitting and predict its eligible dates. Environmental predictors use the seven calendar dates strictly before the target date. The baseline is the spawning prevalence in the training years, calculated afresh for each fold.

### Scoring predictions and their incremental value

Let $Y_t$ equal one when at least one tank spawned and zero otherwise. The Brier score averages squared probability errors over held-out dates.

```math
\mathrm{BS}=\frac{1}{n}\sum_{t=1}^{n}(p_t-Y_t)^2.
```

Lower scores are better. For example, a probability of 0.8 incurs loss 0.04 on a spawning day and 0.64 on a non-spawning day. This rewards useful probabilities and penalises confident mistakes. Each eligible date receives equal weight, so years with more complete dates contribute more to the pooled score.

We compare models through paired score differences on those same dates. For adding the Moon to season, the reported improvement is

```math
\Delta\mathrm{BS}=\mathrm{BS}_{\mathrm{season}}
-\mathrm{BS}_{\mathrm{season+moon}}.
```

A positive difference favours the added lunar terms. The estimate is 0.0014, with a 95% interval from −0.0032 to 0.0059. The interval allows both improvement and deterioration, limiting the evidence for an incremental lunar contribution in this sample.

Each of the 1,000 bootstrap replicates samples fourteen held-out years with replacement, keeps each year's dates together and recomputes the date-weighted score. Using the same resampled years for every model preserves the pairing. The intervals condition on the already fitted predictions. Folds can train on years before and after the excluded year, so the comparison measures retrospective predictive performance within this aquarium's monitored seasons. [Model implementation](../R/fit_aquarium_models.R), [detailed aquarium methods](AQUARIUM_METHODS.md).

## Tightness around a cycle

Year, lunar month and day are circles, so an ordinary mean can point to the wrong time. Days −14 and +14 are close across the lunar boundary, but their arithmetic mean is full moon. Each record with value $v_i$ on a cycle of period $P$ becomes a unit arrow at angle $\theta_i = 2\pi v_i / P$, and the arrows are averaged.

```math
\bar{R}=\sqrt{\bar{c}^{2}+\bar{s}^{2}},\qquad
\bar{c}=\frac{1}{n}\sum_{i=1}^{n}\cos\theta_i,\qquad
\bar{s}=\frac{1}{n}\sum_{i=1}^{n}\sin\theta_i.
```

$\bar{R}$ is the mean resultant length, labelled R in the plots. Its upper bound follows because the average of unit arrows has length at most one. A value of one means all arrows point in the same direction. A value near zero means their directions largely cancel. Two equally strong opposite clusters also cancel, so a low value alone cannot establish an even spread. The distributions shown beside the summaries reveal this structure.

The angle of the average arrow gives the circular mean, converted back to the original unit by

```math
\bar{v}=\frac{P}{2\pi}\operatorname{atan2}(\bar{s},\bar{c}).
```

`atan2` retains the correct quadrant. Equivalent values differ by a whole period. The direction becomes unstable when the resultant is close to zero and is undefined when it is exactly zero. Moving the origin of a cycle rotates every arrow equally and preserves $\bar{R}$, which makes the length useful across different reference times.

### What the three clocks actually compare

| Clock | Reference and period | Unit counted once | Sample | R |
| --- | --- | --- | ---: | ---: |
| Year | Days from each region's typical temperature peak, 365 days | Subsite-date with a regional seasonal curve | 884 | 0.72 |
| Moon | Days from full moon, 29.53 days | Recorded subsite-date | 1,026 | 0.57 |
| Sun | Hours from sunset, wrapped over 24 hours | Median exact start per genus/subsite-date | 346 | 0.90 |

The annual clock aligns each region to its own temperature peak before pooling. The solar clock includes genuine starts before sunset, wrapped onto the 24-hour dial, and excludes ambiguous after-midnight records. Its sample therefore differs from the after-sunset sample used for the sky plots.

These are dimensionless descriptions of concentration in the available samples. The differing observation units and coverage matter when interpreting their ranking. The values do not partition explained variance or estimate the causal contributions of the three cues. The exact values and sample sizes are exported alongside the calculation. [Clock calculation](../R/analyse_clocks.R), [clock summary](../outputs/tables/clock_summary.csv).

### Sensitivity to recording effort

Small samples can look concentrated by chance. For the latitude comparison, sites need at least twelve recorded reef-nights. We repeat the comparison after drawing twelve nights without replacement from each field site, 2,000 times, and also use the share of nights from full moon through day +7 as a second concentration measure. Rank-based comparisons and adjustments for record count test whether a few well-recorded places drive the association. Equalising sample size still leaves seasonal and lunar choices about when observers searched.

The place-level 95% intervals resample individual recorded nights 2,000 times. Nights from the same spawning episode may remain dependent, so these intervals can be too narrow. Their resampling unit differs from the whole-year prediction bootstrap and the whole-reef drift bootstrap described below.

## The local temperature year

`R/prepare_seasons.R` averages NOAA's regional temperature by day of year over 1986–2024, smooths it with a 31-day moving average that wraps around the new year, and takes the change across a centred 30-day span as the warming rate. A reef-night counts as warming when that rate is above zero on its day of the year. The comparison figure is the warming share of each night's own region, averaged across nights. Five subsites outside NOAA polygons drop out, leaving 884 of 1,026 reef-nights. The typical year needs no same-date match, so nights before satellite coverage stay in.

If $\widetilde{T}_r(j)$ is the smoothed typical temperature on day $j$, the quantity used is

```math
g_r(j)=\widetilde{T}_r(j+15)-\widetilde{T}_r(j-15),
```

with day indices wrapped over 365 days. Its unit is °C per 30-day span. This local reference handles the seasonal reversal between hemispheres. The 47% comparison averages the warming fraction of the regions represented by the 884 nights, with one contribution per night, matching the weighting of the observed 89% warming share. It describes the typical seasonal curve rather than the actual temperature trend on an event date. The implementation drops day 366 when building the curve and retains the small leap-year shift in ordinal day numbering.

The backdrop of plot 2 averages the warming rate across all 214 regions by 2.5° latitude band and 5-day step. The band centred on 31.25° N is repeated once at 33.75° N so that the Kochi and Shikoku dots have a backdrop. NOAA has no region at that latitude.

## Rebuilding the sky

`R/prepare_sky.R` calculates Moon and Sun height with the low-precision formulas of the Astronomical Almanac. The Moon's height agrees with all 12,897 cached NASA/JPL Horizons positions to within 0.3°. At the sunset the source reports, the Sun sits at a median of −0.73°, which also confirms the conversion from local clock time to UTC.

For each of the 172 timed reef-nights the script steps through lunar days −15 to +14 around that night's full moon and through the hours after sunset, keeping its reef and its sunset clock time. Moonlight is the lit fraction of the disc times the sine of the Moon's height, averaged over nights. Clouds and water depth are ignored, and plot 4 shows the square root because the eye compresses brightness. Moonrise is the first upward crossing of an ideal horizon by the Moon's centre, without refraction, which matches the Horizons setting.

The drift of the spawning start uses all timed starts after sunset, without the ambiguous after-midnight records. One genus on one reef-night in one setting is one row, so a genus with an exact and an approximate record on the same night counts once. The fit keeps the eight best-recorded genera across lunar days −2 to +10, where nearly all records lie.

The headline sample combines exact and approximate times on natural reefs. The five timing samples keep exact times and tank observations visible as sensitivity checks. Approximate observations offer more coverage, though 38% of approximate natural-reef times fall on a whole or half hour. The moonrise delay is the slope of median moonrise over lunar days 0 to 10.

### Why the same-reef slope matters

Let $x_i$ be lunar day and $z_i$ the start in hours after sunset. Within each reef–genus group $g$, subtract the group's own averages. The estimated drift in minutes per lunar day is

```math
\widehat{\beta}_{\mathrm{within}}
=60\,\frac{\sum_g\sum_{i\in g}(x_i-\bar{x}_g)(z_i-\bar{z}_g)}
{\sum_g\sum_{i\in g}(x_i-\bar{x}_g)^2}.
```

This removes each group's persistent timing offset. A group observed on only one lunar day contributes no information about drift. Groups with more observations and more spread in lunar day contribute more to the slope. The implementation checks that this calculation agrees with a linear model containing reef–genus fixed effects to within $10^{-8}$ minutes per day.

The all-reefs model adjusts for genus and also picks up differences in which reefs were recorded on which lunar days. In the headline sample, its slope is 3.87 minutes per lunar day, compared with 1.73 within reefs. Holding year fixed as well gives 0.83. The 95% intervals use 2,000 whole-reef bootstrap replicates to keep each reef's genera and dates together. Observational selection and rounded start times limit how strongly these estimates can identify a biological timing mechanism. [Drift calculation](../R/analyse_clocks.R), [five timing samples](../outputs/tables/start_drift.csv).

## What the presentation leaves in the tables

The plots show selected summaries. Full regional histories, all fourteen exposure comparisons, model predictions, fitting audits and source records remain available. `tools/check_climate.py` independently reconstructs the exposure calculation from original NOAA files; `tools/check_aquarium.py` checks lagged features and refits the models with a separate solver. The [validation record](VALIDATION.md) reports their results.
