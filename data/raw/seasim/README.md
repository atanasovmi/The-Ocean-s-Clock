# Tagged coral observations from the Australian Sea Simulator

The original, unchanged supplementary PDF accompanies Koukoumaftsis et al. (2025), *Controlled out-of-season spawning of reef-forming corals using offset environmental cues*. The researchers shifted seasonal cues by six months and the solar/lunar light schedules by four hours. Their experiment motivates the question of how repeat observations of the same colony compare across the two shifted seasons. [Paper](https://doi.org/10.1098/rspb.2025.1558)

The PDF was downloaded on 3 November 2026 from the publisher's Figshare article 29940717, version 1, file 57284016. The licence is CC BY 4.0. The file is 4,713,419 bytes, with SHA-256 `24e4bca7f5518cf8aabc12a395bc9695d11d965e5e9aaeb77a9c43428109f000`. [Supplement](https://doi.org/10.6084/m9.figshare.29940717.v1)

`R/prepare_seasim.R` uses `pdftools` to read Table S1 on printed pages 15–17 directly. Each row is a tagged colony on a spawning date, with minutes after the programmed sunset. The 15-digit tag remains text to preserve its identity. There are 172 timed rows, 65 in 2022 and 107 in 2023. They cover 63 distinct tags in total, with 28 observed in both years. Each tag's yearly median is paired across years.

The complete Dryad catalogue was also researched. Its downloads returned authorization/forbidden responses in this environment. The publisher's openly downloadable supplement supplies the identifiable rows used here. No inaccessible CSV is represented as an analysed source. [Dryad catalogue](https://doi.org/10.5061/dryad.v15dv4281)

Some means calculated from Table S1 differ from Table S11 in the same PDF. For example, the seven 2023 *Acropora elseyi* rows average 144.57 minutes in S1, while S11 lists 134.43. Our calculation preserves every printed S1 row and makes no adjustment to match the summary table. The analysis concerns these timed, matched tags. Counts of all spawning colonies elsewhere in the paper have a different scope.

LiteParse and a separate Python PDF reader were used to check extraction against the native R result. The shared facility, unequal species counts and selection of returning timed colonies limit generalisation. A difference between the two years does not isolate the effect of the imposed clock shift, because both years used shifted environmental cues.
