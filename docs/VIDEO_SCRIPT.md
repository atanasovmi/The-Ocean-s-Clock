# The Ocean's Clock: video script

A short film about the project, told in eight scenes. Every number below comes from [the findings](../outputs/RESULTS.md).

Visuals: illustrated underwater scenes only. Show no plots, charts, tables or data figures, because those live in the repository's README.

## Scene 1: The question

On a few nights each year, a coral reef does something remarkable. Animals with no brain, fixed to the rock, release their eggs and sperm into the sea within the same few hours. Pink bundles drift up through the dark water, and a reef that looked still is suddenly spawning all at once.

So what tells a coral reef that tonight is the night?

## Scene 2: Why we asked

We are Mihael Atanasov and Pirasanna Siva, two students at the University of Applied Sciences and Arts Northwestern Switzerland studying in different fields. In our Applied Data Science blockweek we could have picked a business case. We chose a niche question from nature instead, with no business value to chase, and treated the week as an experimental lab.

## Scene 3: Six sources that were never meant to meet

No single dataset can answer this, so we connected six.

The Coral Spawning Database is the hub, with 6,178 historical observations. Each reef's coordinates fall inside one of NOAA's 214 reef regions, and a date then links it to the ocean of that day. NASA's Horizons system gave us 12,897 Moon positions, which confirmed our own Moon formula to within 0.3 degrees. Three more sources stand beside the hub, because they share no key with it: a fifteen-year aquarium diary, a tank where scientists moved the seasons and the light, and an independent field study from the Maldives.

Together that makes about 23 million values, and 98.9 percent of them are NOAA ocean records. The ocean is measured every day. The corals are not, and that sets the limit on what we can say.

## Scene 4: Three clocks

Time here is a circle. Day minus fourteen and day plus fourteen of the lunar month are neighbours, so ordinary averages fail. We used circular statistics and one measure of tightness, R, which runs from 0, spread evenly, to 1, all at one moment.

The records point to three clocks. Warming water opens the season: 89 percent of recorded reef-nights fall while the local sea is warming, which is only 47 percent of the year. R is 0.72.

The Moon narrows the night, far more in the tropics. There, 88 percent of reef-nights fall in the eight days from full moon. Beyond the tropics, it is 51 percent. R is 0.57, the loosest of the three.

The Sun sets the hour. Half of all starts come between one and a half and two and a half hours after sunset, and R is 0.90. Moonrise slips about 46 minutes later each night. On the same reef, the start of spawning moves only 1.7 minutes.

## Scene 5: We tried to break it

Then we tested our own story. Field teams go out when they expect spawning, so empty nights are missing from the records. The aquarium diary is different: it writes the empty days down.

There, 32 percent of spawning days fall in the same eight lunar days, against 27 percent of the days watched. We forecast each year from the others. Season cut the error by 17 percent. Adding the Moon gained almost nothing, and the interval includes zero.

Either field records overstate the Moon, or a tank dulls its signal. These data cannot separate the two, and we say so. Other results did not survive our checks either: one difference between genera disappeared once we left out a single site, so we withdrew it.

## Scene 6: The water around the clocks

These clocks run in a changing ocean. In 1986, five of 214 reef regions reached severe heat stress. In 2024, 171 did. Holding each region's spawning months fixed, ten of fourteen regions now see more heat inside those months.

That measures overlap. It does not show that corals moved or that spawning failed.

## Scene 7: What this is, and what it is not

This is exploratory student work. It describes recorded events and shows associations, without proving a cause. NOAA values are regional, and the forecast test comes from one aquarium. What we can offer is a reproducible analysis: one command rebuilds every result on a clean machine.

## Scene 8: From history to forecast

So far, this is history. To talk about the future, the data has to come first.

The most valuable addition would be survey effort logs, because knowing which nights people watched turns occurrences into rates. NASA POWER could add cloud and wind, to show whether the Moon was visible at all. The Coral Trait Database could show whether tight spawners share a biology. In-water loggers would measure the water at the coral, night-light satellites would add coastal light pollution, and CMIP6 climate scenarios would carry the heat forward.

Then the models. Each question has a different data shape, and the shape picks the method. Hierarchical generalised additive models with cyclic splines can estimate the chance of spawning tonight, sharing strength across reefs. Discrete-time hazard models fit the first night of a season as a time-to-event problem. Poisson point processes handle records without zeros, using survey effort as an offset. Von Mises regression keeps lunar timing on the circle and tests how tightness changes with latitude. Extreme value models with El Niño as a covariate estimate how often severe heat returns, and Bayesian space-time models run it forward under climate scenarios. Gradient boosting stays as a benchmark, and it stays in only if it beats the simpler models.

Every model would be tested forward in time, on reefs and years it has never seen, with proper scoring rules against a seasonal baseline. If a model cannot beat the calendar, it is not a forecast.

For now, the reef keeps time by three clocks, in water that keeps getting warmer. We wanted to understand how those clocks run. The next question is how well they will keep time.

The Ocean's Clock, by Mihael Atanasov and Pirasanna Siva, FHNW. With thanks to Martin Sterchi, Fabian Heimsch and Nathan Brack.
