# Explaining the figures

## 1. Spawning and full moon

Start with the horizontal axis: zero is the local full-moon date, negative values are earlier and positive values are later. Bar height is the share of the 1,026 recorded reef-nights. The blue bars cover days 0–7 and together contain 67.7% of the records. The useful finding is the concentration in a short part of the lunar cycle. We cannot turn it into the probability of spawning on an arbitrary night because survey effort and non-events are missing.

## 2. Starting times after sunset

Each box describes one of the six genera with the most exact night-time records. Its central line is the median; the box contains the middle half of the recorded starts. Whiskers extend to the usual 1.5-IQR limits and dots show observations beyond them. One input value is a median within a genus, subsite and date, so several species recorded that night do not get several votes. In this sample Galaxea tends to start closer to sunset; Acropora tends to start later. Species and locations differ, so the plot cannot isolate a biological genus effect. Daylight spawning is a separate part of the preserved data.

## 3. Regional heat stress

Each point on the line comes from the same 214 NOAA regions. It counts how many reached the severe heat-stress threshold that year, then divides by 214. The comparison moves from five regions in 1986 to 171 in 2024, with large variation between years. NOAA's degree-heating weeks combine how unusually hot the water was and how long the heat persisted over twelve weeks. Eight degree-heating weeks is not a sea-temperature reading of eight degrees. These are regional heat-stress indicators, not observations of dead reefs or a percentage of global reef area.

## 4. Heat around recorded spawning seasons

Grey bars describe 1986–1995 and blue bars describe 2015–2024. We show the five largest increases and Singapore as a zero-change comparison; all fourteen eligible regions remain in `data/derived/decadal_exposure.csv`. The comparison holds the historical spawning calendar fixed. If a site's records were all in May, its index would be the fraction of May days at DHW ≥4. Real calendars give weight to several months, and sites receive equal weight within their region. Northern Taiwan and the Gulf of Aqaba have much higher overlap in the later decade. This does not measure failed spawning or prove that the historical calendar still applies today. Notice that this index uses DHW ≥4; the severe-stress overview uses ≥8.

## 5. Prediction test

The horizontal axis measures prediction error; smaller values are better. The baseline gives a constant chance within each held-out year, estimated from the other years. The next model uses moon and seasonal timing. The last adds the preceding week's temperature, wind, rainfall and solar measurements. All are tested on the same 1,007 dates, with one whole year excluded from fitting at a time. The simple calendar score is 0.111 and the added-weather score is 0.115. The paired uncertainty interval includes no gain, so we found no clear predictive benefit from those extra inputs in this test. The lines show 95% intervals from resampling whole years. It is a retrospective aquarium comparison, not a wild-reef forecasting tool.

## 6. Independent field comparison

The historical Acropora data give 69.8% of 400 genus/reef-dates in days 0–7 after full moon. The Maldives study gives 70.4% of 81 spawning atoll-days. The bars start at zero, so their near equality is visible without exaggerating the difference. These are separate studies with different survey designs and spatial units. The comparison shows a similar recorded pattern; it is not a test that the underlying populations are identical.
