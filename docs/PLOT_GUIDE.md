# Explaining the plots

The plots answer one question: what tells a reef that tonight is the night, and how does that fit the rhythms of the ocean? Each plot has one job and is drawn at 16:9.

Colour means the same thing everywhere. Pink is a spawning record. Cream is the Moon, or a line you should read. Gold and blue are warming and cooling water. The ramp from purple to pale yellow is heat stress.

We presented plots 1, 2, 3, 7 and 9 live. The others are the supporting evidence and are explained here in the same way.

## 1. Three clocks

Each clock is one natural cycle, running clockwise. A pink bar is the number of records in that stretch of the cycle, and the thin ring is what random spawning would reach, so anything past it beats chance. The white line points at the average time on the circle. Its length R, the mean resultant length, is what we call tightness: 0 means evenly spread, 1 means all records at one moment. R describes how concentrated the records are. It is not a confidence interval.

Say that the reef answers three separate questions: which season, which night and which hour. Then compare the hands. The Sun's is longest and the Moon's is shortest, which surprises people who know this topic as a full-moon story.

If someone asks why you used circles: the end of each cycle runs straight into its start, so day −15 and day +14 are neighbours and a straight axis would cut them apart. These are rose diagrams, the form Florence Nightingale used. A pie chart shows parts of a whole; here the bars are counts along a cycle.

## 2. The year

The backdrop shows how fast the sea warms (gold) or cools (blue) at each latitude through the year, from all 214 NOAA regions. Each pink dot is one recorded reef-night at its real date and latitude.

Point at the northern cluster around April to August and the southern one around October to December. The months are about half a year apart, and both clusters sit on gold. Then give the number: 89% of reef-nights fall in the warming part of the local year, which is 47% of it.

Be ready for the survey question. Teams go looking when they expect spawning, so empty months are under-recorded and 89% is probably too high.

## 3. The Moon

Each row is one place, ordered from the equator at the top to 33° at the bottom. Each column is a day of the lunar month, and a brighter cell means more of that place's records fell on that day. The box marks the eight days from full moon. The strip on the right gives each place its tightness R (the mean resultant length), measured over the whole lunar month without using the box. Near 1 means one tight cluster. Near 0 means no single cluster: the nights are spread out, or two clusters on opposite sides of the month cancel out. Exactly 1 would need every night on one lunar day, so Raffles Lighthouse reaches 0.97 with its nights on six different days.

R is not a percentage and its scale is not even. It is an average of cosines, so it falls slowly while the nights stay close and faster as they spread: nights spread evenly over 3, 6, 8 and 15 days give about 0.98, 0.94, 0.89 and 0.63. Differences near the top of the strip are bigger than they look.

Read downwards. Near the equator the records pile up inside the box. Past the edge of the tropics they spread out, and at Eilat and Kochi they cover almost the whole month. That is why the old headline of 68% was misleading: it is 88% inside the tropics and 51% beyond them.

The honest caveat is on the plot. These are records of when people looked. The aquarium, watched every day, has R = 0.21, while nearby Sesoko and Akajima have 0.66 and 0.81, so field records may overstate tightness. The latitude pattern itself survives the checks we can run: cutting every field site to 12 nights gives ρ = −0.71, the share in the box gives ρ = −0.66, and it shows up within genera. A 95% bootstrap interval for each place's R is in `outputs/tables/03_moon.csv`; it is wide for places with few nights, such as Amakusa.

## 4. The sky

Plot 1 shows that the hour is tight, measured from sunset. This plot tests why, by setting the two possible timers against each other: moonrise moves 46 minutes a night, spawning about 2 on the same reef. This is the plot to spend time on. Time runs left to right through one lunar month. Hours after sunset run upward. The shading is the actual moonlight over these reefs: the bright band is when the Moon is up, and it slides up the chart as the Moon rises later each night.

Follow the cream line first: moonrise, about 46 minutes later every night. Then the nearly flat line through the dots: the start of spawning, about 2 minutes later every night when each genus is compared with itself on its own reef (1.7 minutes, 95% interval 0.5 to 3.4). If the Moon set the hour, the dots would climb with the line. They stay near two hours after sunset, whatever the sky is doing.

Expect a question about the two numbers in the label. One line through all reefs at once climbs about 4 minutes a night (3.9, interval −0.8 to 7.5). Reefs keep different hours, though: Lyudao spawns about 3.1 hours after sunset and Eilat about 1.0, so that slope also depends on which reefs were recorded on which nights. "Later every night" is a question about one reef, so the line on the plot has the same-reef slope.

The dots are the 327 exact natural-reef starts. The line also uses approximate times, 776 starts in all, because exact times alone are too few to pin the slope down (0.6, interval −1.0 to 2.6). Many approximate times are rounded to the hour or half hour and tanks are a different setting, so `outputs/tables/start_drift.csv` lists five samples of start times: +0.6 to +1.8 minutes on the same reef, +2.2 to +4.6 across reefs. Even the steepest is about a tenth of the pace of moonrise.

The second point is the dark wedge at the lower right. After full moon the evening starts dark, because the Moon has not risen yet, and that is where the dots sit. Lin et al. (2021) tested this dark gap in experiments. Our chart shows the geometry and does not prove a cue.

Plot 4 has a second version, `04.01_sky`. It shows the same data with one row per evening, read from sunset to the right. The moons mark moonrise. The single dots look like a scatter with no trend, and that is the result: start time barely depends on the night (Spearman 0.08). Most of the spread comes from mixing reef sites and genera.

## 5. The diary

This is the check on the field data. The aquarium recorded every day, so its empty days are real zeros. The left panel sorts the 208 spawning days by calendar date and the right panel sorts the same days by the Moon. Open circles are full moons, and you can see them jump around between years.

Compare the bars on top. By calendar date they rise to a clear hump. By the Moon they stay fairly flat. Then give the forecast result: predicting each year from the others, season alone cuts the error by 17%, the Moon alone by nothing, and the weather inputs add nothing.

Do not oversell this. It is one aquarium, and a tank could dull the Moon's signal. It could also mean field records overstate the Moon because people go out near full moon. We cannot separate those two, and saying so will sound stronger than pretending otherwise.

## 6. Minutes

Each dot is one spawning, and the white bar is the interquartile range, the middle 50% of the dots in each row. The top block is wild reefs by genus. The bottom block is tanks at Australia's Sea Simulator by species, all timed from one programmed sunset.

The researchers moved the seasons by six months and the light cycle by four hours, and the corals followed. That is the closest thing here to an experiment. The contrast is in the width of the rows: Acropora in the wild spreads over 84 minutes, while A. loripes in a tank falls within 5, and each species keeps a different time.

Dots are nudged apart slightly so they stay visible. The positions in the table are the real values.

## 7. The heat

Every row is one NOAA reef region and every column a year, grouped by ocean. Brighter means more accumulated heat, and the bars on top count regions above the severe line of 8 degree heating weeks.

Look at the vertical stripes: 1998, 2010, 2016, then 2024 across almost everything. In 1986 five regions crossed the line. In 2024, 171 of 214 did. The four named years each followed an El Niño, which adds a slower rhythm of the ocean on top of the three clocks. That El Niño link is background knowledge, not something we calculated.

Regions count equally whatever their reef area, and degree heating weeks measure heat stress, not dead coral.

## 8. Heat in the spawning season

This uses the same grammar as plot 7, counted only inside each region's historical spawning months. Each row keeps those months fixed, so a brighter cell means more of that season was under heat stress that year. Heat stress here means 4 or more degree heating weeks, a lower line than plot 7. The numbers on the right compare 1986–1995 with 2015–2024.

Ten of fourteen regions rose, and four stayed clear. This measures overlap only. We did not measure whether spawning moved or failed, and the fixed calendar comes from when people happened to record it.

## 9. The genera

Every wave is one genus across the lunar month, and a higher wave means more of its spawning nights fall on that day. The month starts before full moon and runs past new moon, so a new-moon peak stays whole. The percentages count nights inside the white frame. The strip on the right shows the hour spawning starts, with one dot for one genus on one night.

Read it from top to bottom. Eleven genera peak in the week after full moon and start around sunset, so their timing is alike. The share inside the frame still falls from 100% to 53%, but much of that gap comes from where each genus was recorded. Pocillopora is the outlier. All 22 of its timed starts come after sunrise, and its 10 Red Sea nights all fall within 2 days of new moon, while its 31 nights elsewhere fall after full moon.

Questions to expect:

- **Is 10 nights enough?** It is few. They are 6 spawning events at 3 sites from 2 studies, 30 years apart. Published Red Sea work reports the same morning spawning just before new moon ([Bouwmeester et al. 2021](https://doi.org/10.1002/ecs2.3340)), and morning spawning after full moon is reported at Lizard Island ([Schmidt-Roach et al. 2012](https://researchonline.jcu.edu.au/24820/1/24820_Schmidt-Roach_et_al_2012.pdf)). This is known biology that our data shows again, not a new discovery.
- **Do genera differ on the same reef?** Mostly not. Shuffling genus labels within reefs gives p < 0.001, but p = 0.25 without Eilat, so that result rests on one reef. On most shared reefs, genera look alike.
- **Why split Pocillopora by sea?** We chose that after seeing the data, and the caption says so. The genus may also hide look-alike species, so "same genus" does not mean the same species everywhere.
- **Do people only look near full moon?** Partly, and plot 5 shows the Moon's signal shrinks when every day is watched. That bias would hide new-moon spawning, so it cannot create the Red Sea wave, but it may make the eleven waves look tighter than they are.
- **Is Pocillopora the only one?** It is the only well-recorded genus that always spawns by day. Other genera have 4 daytime starts out of 1,460, and Platygyra has a small new-moon peak.

The waves are smoothed by about a day. The plot shows that timing differs, not why.

## Words you may need

A reef-night, called a spawning night on the plots, is one reef subsite on one local date, however many species were recorded there. On plot 9 a spawning night is one genus on one reef on one date, and a genus is a group of related species. Tightness runs from 0 (spread evenly around the cycle) to 1 (everything at one moment). Degree heating weeks add up how far and how long the water stayed above its usual summer maximum over the last twelve weeks. The Brier error is the average squared gap between a predicted chance and what happened, so lower is better.
