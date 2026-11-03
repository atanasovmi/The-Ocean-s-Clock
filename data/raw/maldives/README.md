# Independent Maldives field observations

Source: Sheridan K, Monfared MAA, Dixon SP, Errington AJF and Le Berre T (2025).
*Synchrony on the reef: how environmental factors shape coral spawning patterns in
Acropora corals in the Maldives.* PeerJ 13:e19447.

- Article: <https://doi.org/10.7717/peerj.19447>.
- Source table: Supplement 4, <https://doi.org/10.7717/peerj.19447/supp-4>.
- Archive package used to retrieve the original CSV:
  <https://www.ebi.ac.uk/europepmc/webservices/rest/PMC12126091/supplementaryFiles>.
- Licence: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/), confirmed in
  the publisher's full-text XML available through Europe PMC.
- Original CSV filename: `peerj-13-19447-s004.csv`. Retrieved 3 November 2026.

The CSV contains **81 atoll-days on which spawning was recorded**, spanning
October 2021–May 2024 in Baa and North Male Atolls. `No_colonies` sums to **3,026
colony spawning observations**. This count does not create 3,026 independent
dates, distinct long-term individual identities or a list of surveyed non-events.
No species identifiers are supplied in this particular table; it aggregates
Acropora spawning observations. `PFM` gives signed days relative to full moon.

Additional source fields describe daily wind, precipitation, mean SST during the
previous 30/90 days and tide depth. The replication graphic does not refit the
paper's environmental models or claim causal effects from these fields.

## Source discrepancy retained

The article's results text states that Baa's maximum daily count was 203 colonies.
The supplied CSV has `No_colonies = 243` for Baa on 2 November 2023. We preserve
the original value rather than silently changing it to match the narrative.
The CSV totals nevertheless agree with the article's overall 3,026 observations
(1,317 Baa; 1,709 North Male). The discrepancy does not affect the number of
spawning atoll-days. Weighted percentages use the published CSV values and should
be understood in that light.

The comparison uses historical **Acropora** genus/subsite-dates from CSD and the
new atoll-day records separately. Their spatial aggregation and monitoring designs
differ, so similar lunar windows are a descriptive replication, not a pooled
effect estimate or an independent random-sample hypothesis test.
