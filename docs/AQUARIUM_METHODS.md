# What can the calendar predict before a spawning day?

Wild-reef records list spawning events and leave out the nights nobody watched, so they cannot support a daily yes-or-no model. The Okinawa Churaumi Aquarium diary can: it records 1,350 monitored days across fifteen seasons, including the days without spawning. This page tests how well each candidate cue predicts spawning in a year the model has never seen.

The answer is clear for this aquarium. **Season predicts spawning. The Moon adds no detectable skill once season is known, and preceding-week conditions add none either.**

## Result

All five models are scored on the same 1,007 dates. Each date is predicted by a model fitted without its year. Skill is the reduction in Brier score relative to the baseline, and a lower Brier score is better.

| Model | Terms | Parameters | Held-out Brier (95% interval) | Skill | Within-year AUC |
| --- | --- | ---: | --- | ---: | ---: |
| Baseline | Training-year prevalence | 1 | 0.1356 (0.1137 to 0.1552) | 0% | 0.500 |
| Moon | Two lunar harmonics | 5 | 0.1359 (0.1139 to 0.1569) | −0.2% | 0.570 |
| Season | One annual harmonic | 3 | 0.1129 (0.0940 to 0.1313) | 16.7% | 0.808 |
| Calendar | Season and Moon | 7 | 0.1114 (0.0909 to 0.1317) | 17.8% | 0.838 |
| Environment | Calendar and four weekly inputs | 11 | 0.1147 (0.0937 to 0.1354) | 15.4% | 0.835 |

The separate intervals overlap heavily, and that says little: a year that is hard for one model is hard for all of them. The comparison that answers the question is paired, using the same resampled years for both models. A positive difference means the second model scores better.

| Comparison | Difference in Brier | 95% interval | Years improved | Reading |
| --- | ---: | --- | ---: | --- |
| Baseline to calendar | +0.0241 | 0.0143 to 0.0333 | 13 of 14 | Clear gain |
| Baseline to season | +0.0227 | 0.0119 to 0.0319 | 12 of 14 | Clear gain |
| Baseline to Moon | −0.0003 | −0.0029 to 0.0021 | 8 of 14 | No gain |
| Season to calendar (adds the Moon) | +0.0014 | −0.0032 to 0.0059 | 10 of 14 | No detectable gain |
| Calendar to environment (adds weather) | −0.0033 | −0.0078 to 0.0006 | 5 of 14 | No gain, leaning worse |

Three conclusions follow.

1. **Season carries the forecast.** Its interval excludes zero, and it supplies 94% of the calendar model's improvement over the baseline.
2. **The Moon's added value is small at most.** The interval rules out a gain above 0.0059, about 4% of the baseline error, so this is a bounded result and more than a failure to find an effect.
3. **Preceding-week conditions do not help.** The most favourable end of the interval is a gain of 0.0006. With four more parameters the point estimate gets worse, which is what added variance without added signal looks like.

## Why the Moon can matter and still not forecast

The lunar terms are not empty. In the calendar model fitted to all fourteen years, the lunar curve peaks 3.5 days before full moon and reaches its low 13.1 days before it. That span is 1.41 logit units, about a fourfold change in the odds.

The seasonal curve peaks on 11 June and spans about 14 logit units across the sampled dates, 19 April to 10 August. Most dates are therefore already near zero or well inside the season before the Moon is considered, which leaves the lunar terms little to add. Moon alone cannot separate June from August at all, which is why it matches the baseline.

These are full-data fits, and their ordinary standard errors ignore dependence within a year, so they describe shape and do not test it. In the environment model, all four weather coefficients have a $z$ value below 2 in absolute size on that same optimistic scale.

## Design

### Response and sample

For diary date $t$, let $K_t$ be the number of tanks spawning. The source column `spawning_binary` holds this count, from 0 to 17, despite its name. The response is presence:

```math
\Large
Y_t=\mathrm{I}(K_t>0).
```

The diary has 1,350 dates, 90 per season from 2003 to 2017, with 208 spawning dates. Dates outside the diary are never treated as observed zeros, even where the environmental file has a score for them.

The weekly inputs need complete measurements, and missing tank temperatures remove all of 2003 and much of 2004 to 2007. The complete-case sample has 1,007 dates in fourteen years, with 162 spawning dates, a prevalence of 16.1%. Every model uses exactly these dates.

### Models

All models are binomial logistic regressions, with $p_t=\mathrm{P}(Y_t=1)$. With day of year $j_t$ and offset from full moon $d_t$, the angles are $u_t=2\pi j_t/365.2425$ and $v_t=2\pi d_t/29.53059$.

```math
\Large
\begin{aligned}
\log\!\left(\frac{p_t}{1-p_t}\right)&=\beta_0+S_t+L_t+\gamma^{\top}x_t,\\
S_t&=a\sin u_t+b\cos u_t,\\
L_t&=\sum_{h=1}^{2}[c_h\sin(hv_t)+e_h\cos(hv_t)].
\end{aligned}
```

Season keeps only $S_t$, Moon only $L_t$, calendar both, and environment adds $\gamma^{\top}x_t$. Sine and cosine pairs keep each cycle continuous across its boundary, and the second lunar harmonic allows two peaks in a month. The model forms were fixed before scoring: there is no stepwise selection, no tuning and no classification threshold.

The vector $x_t$ holds tank temperature, wind speed, `log1p` rainfall and solar flux, each averaged over the seven dates before $t$:

```math
\Large
\overline{x}_{t,-7:-1}=\frac{1}{7}\sum_{k=1}^{7}x_{t-k}.
```

The predicted day's own measurement never enters. A window with a missing value stays missing and is not filled.

### Validation

Each of the fourteen years is held out in turn. Models are fitted to the other thirteen, and the held-out dates are predicted. Adjacent days of one season never fall on both sides of a split, which a random split would allow. The baseline predicts the training-year prevalence, recalculated for each fold.

This is retrospective validation. A fold can learn from years after the one it predicts, so it measures how well the calendar generalises between years. It is not a test of live forecasting.

### Scores

The primary score is the Brier score over the $n$ held-out dates:

```math
\Large
\mathrm{BS}_M=\frac{1}{n}\sum_{t=1}^{n}(p_{M,t}-Y_t)^2.
```

It is a proper score, so it rewards honest probabilities. Accuracy would be a poor measure here, because always predicting no spawning is already right on 83.9% of dates. AUC is secondary: it measures ranking only, and the within-year version averages the 13 years that contain both outcomes. The pooled baseline AUC of 0.377 is an artefact, since a fold's training prevalence falls when its held-out year is rich in spawning.

Each date has equal weight, so full seasons count more than the short early ones, which hold 27 to 39 dates each. 2006 has no spawning date in the sample, so it affects Brier scores but not within-year AUC.

### Uncertainty

Days within a season are dependent, so the resampling unit is the year. Each of 1,000 replicates draws fourteen years with replacement, keeps their dates together and recomputes the date-weighted score for every model on the same draw:

```math
\Large
\mathrm{BS}^{*}_{M}=\frac{\sum_{y\in\mathcal{Y}^{*}}\sum_{t\in y}(p_{M,t}-Y_t)^2}{\sum_{y\in\mathcal{Y}^{*}}n_y}.
```

Paired differences come from the same replicates. The intervals are percentile intervals and condition on the fitted held-out predictions, so they do not include refitting uncertainty. With fourteen clusters they are approximate.

## Calibration

The calendar model's mean held-out probability is 0.160, and the observed rate is 0.161. Grouped into eight equal-sized bins by predicted probability, it looks like this.

| Bin | Dates | Predicted | Observed |
| ---: | ---: | ---: | ---: |
| 1 | 126 | 0.000 | 0.000 |
| 2 | 126 | 0.003 | 0.000 |
| 3 | 126 | 0.014 | 0.008 |
| 4 | 126 | 0.052 | 0.087 |
| 5 | 126 | 0.128 | 0.222 |
| 6 | 126 | 0.237 | 0.214 |
| 7 | 126 | 0.350 | 0.286 |
| 8 | 125 | 0.501 | 0.472 |

The ordering holds and the overall level is right, so the probabilities are usable within this diary. The middle is less exact: bin 5 under-predicts and bin 7 over-predicts. No date is predicted much above one half, so the model identifies likely periods more than single nights.

## What this does and does not show

The diary covers 90 days a year around the expected season, so season only has to locate a peak inside a window that was already chosen for spawning. Its skill would look different over a full year. This is one aquarium, with its own tanks, colonies and lighting. The result cannot say whether field records overstate the Moon because teams go out near full moon, or whether a tank dulls a lunar signal.

The weather result concerns these four inputs, averaged over this one window, in a daily model. It does not show that temperature or weather is biologically irrelevant, and it does not contradict [Sakai, Yamamoto and Maruyama (2024)](https://doi.org/10.1098/rsos.240183), who studied annual first and peak dates. This page is our own reanalysis of their data, and it does not forecast a wild reef.

A longer complete series, more aquaria or daily field monitoring with recorded zeros could narrow the Moon's interval further. A forward test, predicting each year only from earlier ones, would be the stricter check.

## Numerical audit

`python tools/check_aquarium.py` repeats the calculation outside R. It rebuilds all 4,028 weekly inputs from explicit date lookups, with a largest difference of $1.14\times10^{-13}$. It also refits all 56 held-out logistic models, four models in each of fourteen years, with a SciPy solver, and predicted probabilities differ by at most $8.75\times10^{-9}$. All fits converge at full rank with no numerical warnings, as recorded in `aquarium_fitting_audit.csv`.

The calculation is in [`R/fit_aquarium_models.R`](../R/fit_aquarium_models.R). The results are in [`aquarium_model_scores.csv`](../outputs/tables/aquarium_model_scores.csv), [`aquarium_environment_increment.csv`](../outputs/tables/aquarium_environment_increment.csv), [`aquarium_year_scores.csv`](../outputs/tables/aquarium_year_scores.csv) and [`aquarium_calibration.csv`](../outputs/tables/aquarium_calibration.csv). [Plot 5](../outputs/figures/05_diary.png) shows the diary.
