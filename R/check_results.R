# Check consequential data and export properties after the presentation rebuild.
library(dplyr)
library(readr)
library(sf)
nights <- read_csv("data/derived/reef_nights.csv", show_col_types = FALSE)
matched <- read_csv("data/derived/regional_events.csv", show_col_types = FALSE)
weights <- read_csv("data/derived/spawning_calendar_weights.csv", show_col_types = FALSE)
annual <- read_csv("data/derived/regional_annual.csv", show_col_types = FALSE)
lunar <- read_csv("outputs/tables/01_lunar_timing.csv", show_col_types = FALSE)
heat <- read_csv("outputs/tables/03_heat_stress.csv", show_col_types = FALSE)
field <- read_csv("data/derived/field_observations.csv", show_col_types = FALSE)
stopifnot(nrow(matched) == nrow(nights),
          !anyDuplicated(paste(matched$subsite_id, matched$date)),
          all(abs((weights |> summarise(s = sum(calendar_weight), .by = station_id))$s - 1) < 1e-10),
          sum(lunar$n) == nrow(nights), abs(sum(lunar$share) - 1) < 1e-10,
          all(heat$n_regions == 214), nrow(heat) == 39,
          all(field$sunset_offset_hours[field$Obs_ID %in% c(3975, 3976)] < -12),
          all(field$midnight_ambiguous[field$Obs_ID == 6153]))
authors <- read_csv("authors.csv", show_col_types = FALSE)
stopifnot(setequal(list.files("outputs/figures", pattern = "\\.png$"), authors$figure),
          length(list.files("outputs/vector", pattern = "\\.svg$")) == nrow(authors))
message("Data totals, calendar denominators, timing and the six export names passed checks.")
