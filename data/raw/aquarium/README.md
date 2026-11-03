# Okinawa Churaumi Aquarium spawning diary

Sakai, Y., Yamamoto, H. H. & Maruyama, S. (2024). *Long-term aquarium records delineate the synchronized spawning strategy of Acropora corals*. Royal Society Open Science 11:240183. [Article](https://doi.org/10.1098/rsos.240183). [Original data archive](https://doi.org/10.5281/zenodo.10974150), CC BY 4.0.

The catalogue is retained as `catalogue.json`. The original archive was downloaded from the catalogue's file URL, its MD5 checksum was verified as `f2e51a4aa5c88005e20ed9d79ea94ad2`, and the two supplied CSVs were extracted byte-for-byte without editing:

- `Chura_spawning_data_DAFM.csv`: 1,350 dates, 90 per season, 2003–2017. The seasonal windows are aligned to lunar cycles and span varying dates from April to August; they are not the same three Gregorian months every year.
- `Chura_spawning_environment.csv`: 5,479 calendar dates, 2003–2017. Tank water temperature, precipitation, wind speed and solar flux, plus a spawning score.

The source column `spawning_binary` is a **count of spawning tanks**, ranging from 0 to 17; it is not an already binary response. Our response is `spawning_binary > 0`. There are 208 positive dates and 1,142 zero dates in the supplied seasonal diary. The diary's spawning score exactly matches the environmental file on every included date.

The environmental file has zero spawning scores outside the seasonal diary too. Those extra dates are **not** treated as additional observed non-spawning dates. Only the explicitly supplied diary defines the model's eligible observation window.

Measurement context, verified against the paper: water temperature is an average of measurements in tanks M4 and S1 at 09:00 and 16:00; wind speed (m/s) and precipitation (mm) come from the Nago Japan Meteorological Agency station approximately 14 km away; solar flux comes from NASA CERES over a one-degree region. These are different spatial supports, not four direct measurements at each coral.

This semi-outdoor aquarium system is analysed separately from the wild-reef CSD. The authors monitored tanks containing Acropora; variation in tank/colony composition and colony availability can affect comparisons across years. The source archive contains the authors' own analyses too; this repository's daily, year-held-out validation is written independently and is not presented as a reproduction of their annual regression models.
