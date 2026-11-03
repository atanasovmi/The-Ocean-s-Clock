# A limited independent astronomy check; full historical lunar fields remain supplied.
library(jsonlite)
library(dplyr)
library(readr)
nights <- read_csv("data/derived/reef_nights.csv", show_col_types = FALSE)
files <- list.files("data/raw/usno", pattern = "\\.json$", full.names = TRUE)
phases <- bind_rows(lapply(files, function(path) fromJSON(path)$phasedata)) |>
  filter(phase == "Full Moon") |>
  mutate(utc = as.POSIXct(sprintf("%04d-%02d-%02d %s", year, month, day, time),
                          format = "%Y-%m-%d %H:%M", tz = "UTC"))
audit <- bind_rows(lapply(seq_len(nrow(nights)), function(i) {
  event <- nights[i, ]
  local_dates <- as.Date(phases$utc + event$utc_offset * 3600, tz = "UTC")
  difference <- as.numeric(event$date - local_dates)
  nearest <- tail(which(abs(difference) == min(abs(difference))), 1)
  if (abs(difference[nearest]) > 15) return(NULL)
  mutate(event, usno_full_moon_utc = phases$utc[nearest], usno_full_moon_local = local_dates[nearest],
         usno_lunar_day = difference[nearest], difference_days = usno_lunar_day - lunar_day)
}))
write_csv(audit, "data/derived/lunar_audit.csv")
message(nrow(audit), " reef-nights covered by cached USNO phases; ", sum(audit$difference_days == 0), " exact agreements.")
