# What can the calendar predict before a spawning day?

The wild-reef database records occurrences without complete non-event monitoring. It can show when recorded events happened, but cannot by itself support a daily yes/no spawning model. A second study supplies a different kind of evidence: a fifteen-year seasonal diary from the Okinawa Churaumi Aquarium, with explicit zero as well as positive dates. We keep these systems separate.

The [source paper](https://doi.org/10.1098/rsos.240183) examined environmental associations with annual first and peak spawning dates. Our additional question is about validation: **does environmental information improve predictions for a year that was excluded from model fitting?** This is our independently specified reanalysis of published data, not a claim to have discovered coral spawning cues for the first time.

## Response and sample

For diary date $t$, let $K_t$ be the number of spawning tanks. The indicator $Y_t$ equals one if any tank spawned and zero otherwise.

```math
\Large
Y_t=\mathrm{I}(K_t>0).
```

The source variable is unfortunately called `spawning_binary`, but contains counts from zero to seventeen. It is converted explicitly, rather than passed incorrectly into a binomial model. The 1,350 diary dates include 208 positive dates. Extra zero scores outside the supplied seasonal diary are not counted as surveyed absences.

Weather and tank-temperature measurements from the seven preceding calendar dates are averaged:

```math
\Large
\overline{x}_{t,-7:-1}=\frac{1}{7}\sum_{k=1}^{7}x_{t-k}.
```

The predicted day's measurement is never included. A missing measurement makes that seven-day average missing; we do not fill it using later dates. All three model comparisons use the **same 1,007 complete-case dates from 14 years**, including 162 positive dates. The raw diary remains available for describing the full fifteen seasons. Missing tank-temperature records, notably 2003, explain the narrower model sample.

## Three comparisons

The reference model predicts the spawning share in the training years. The calendar model is a binomial logistic regression using two lunar harmonics and one seasonal harmonic. For the offset from full moon $d_t$ and the day of year $j_t$, use the angles $v_t=2\pi d_t/29.53059$ and $u_t=2\pi j_t/365.2425$.

```math
\Large
\begin{aligned}
\log\!\left(\frac{p_t}{1-p_t}\right)&=\beta_0+S_t+L_t,\\
S_t&=a\sin u_t+b\cos u_t,\\
L_t&=\sum_{h=1}^{2}[c_h\sin(hv_t)+e_h\cos(hv_t)].
\end{aligned}
```

Sine and cosine represent cycles continuously: the end of a lunar cycle is close to its beginning. The second harmonic allows more than one broad concentration of spawning dates per cycle. These terms are specified before fitting the comparisons; no stepwise search selects a favourable model.

The environmental model adds preceding-week mean tank temperature, wind speed, rainfall and solar flux. Rainfall is transformed with `log1p` to reduce the influence of large wet-day averages. No feature uses future measurements or a response-derived peak date.

## Testing and uncertainty

One complete year is withheld, the models are fitted to all the other eligible years, and predictions are made for that excluded year. This repeats across fourteen years. It is retrospective leave-one-year-out validation, not a chronological operational forecast: a fold can use later years to predict an earlier excluded year. No random split places adjacent dates from the same season on both sides of the comparison.

The primary score is the Brier score:

```math
\Large
\mathrm{BS}=\frac{1}{n}\sum_{t=1}^{n}(p_t-Y_t)^2.
```

Lower values mean smaller squared probability errors. Equal-count reliability bins compare predicted probabilities with observed spawning shares. AUC is exported as a secondary ranking measure, both pooled and averaged within held-out years containing both response classes; years without both classes still count in Brier scoring. The training-prevalence reference is constant within a fold, so its within-year AUC is 0.5; its pooled AUC can differ because training prevalence changes inversely with held-out-year prevalence.

Class imbalance makes ordinary classification accuracy a poor headline here: always predicting no spawning would already classify about 84% of the eligible dates correctly. The Brier score instead evaluates probabilities against a reference fitted without the test year's responses. No arbitrary classification threshold is chosen to make a result look better.

Confidence intervals resample whole held-out years 1,000 times, preserving within-year dependence. They are conditional on the already fitted held-out predictions; they do not refit models in each bootstrap or capture all possible feature-selection uncertainty. We also bootstrap the **paired difference** between calendar and environmental scores, rather than deciding from overlap of separate intervals.

The reported score weights each eligible date equally. The cluster bootstrap resamples complete years and recomputes that same date-weighted score on the resampled dates; it does not switch to an equal-year point estimate. Years with more complete eligible dates therefore have more influence on the main point estimate. That estimand is stated explicitly because the early years have substantial temperature missingness.

## Result and meaning

The calendar model achieves Brier **0.111** versus **0.136** for training prevalence, an approximately 18% reduction in squared probability error. Adding preceding-week environmental variables produces **0.115**. The paired calendar-minus-environment improvement is **−0.0033**, with a whole-year bootstrap 95% interval of **−0.0078 to +0.0006**. In this specified comparison, the added variables provide no clear gain on excluded years.

This is an informative limit on prediction. It does not show that temperature or weather is biologically irrelevant, nor contradict the source paper's annual associations: the response, lag window, model form and validation question differ. Tank and colony composition, missingness, the limited number of years and aquarium-specific conditions also restrict interpretation. The fitted model is not a wild-reef forecasting service.

See `R/fit_aquarium_models.R`, `outputs/tables/aquarium_*`, `outputs/models/aquarium_models.rds` and plot 5 for executable calculations, held-out predictions and visual checks.

## Independent numerical audit

The 4,028 lagged inputs in the complete model sample were separately reconstructed in Python using explicit calendar-date lookups, rather than R's rolling filter. The maximum absolute difference was below \(1.2\times10^{-13}\). All twenty-eight held-out logistic models were independently refitted with a SciPy maximum-likelihood solver, using feature scaling calculated on each training fold only. The maximum difference from the R probabilities was below \(8.8\times10^{-9}\). The optional check can be repeated with `python tools/check_aquarium.py` after installing Python's NumPy, pandas and SciPy. Those packages are not dependencies of the R analysis itself.

The R workflow records convergence, matrix rank and warning counts for every fold in `aquarium_fitting_audit.csv`; full-data models are saved separately from the held-out predictions. There is no global or test-informed feature standardization in the R fitting code.

## Which clock carries the forecast?

The calendar model mixes lunar and seasonal terms, so each half is also fitted alone, on the same folds and the same 1,007 dates.

| Model | Held-out Brier error |
| --- | --- |
| Same chance every day | 0.136 |
| Moon only | 0.136 |
| Season only | 0.113 |
| Moon and season | 0.111 |
| Moon, season and preceding-week conditions | 0.115 |

Season alone delivers about 94% of the improvement that the calendar model makes over the baseline, and the Moon alone delivers none. Adding the Moon to season improves the Brier error by 0.0014, with a whole-year bootstrap interval of −0.0032 to 0.0059, which includes zero. The lunar terms are not empty: inside the main late-May-to-June window the spawning rate is highest in the days just before full moon. They add little once the season is known.

The diary covers 90 days a year around the expected season, so the season term only has to find a peak inside that window. It is one aquarium with its own tanks and lighting. The result is a reason for caution about the field concentration, not an estimate for wild reefs.
