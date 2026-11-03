# Reconstruct the published relational tables; keep the observational grain visible.
library(dplyr)
library(tidyr)
library(readxl)
library(readr)

dir.create("data/derived", recursive = TRUE, showWarnings = FALSE)
workbook <- "data/raw/coral/CSD_Tables.xlsx"
observations <- read_excel(workbook, sheet = "tblSpawningObservations", guess_max = 10000)
sites <- read_excel(workbook, sheet = "tblSitesForSpawningObservations", guess_max = 10000)
species <- read_excel(workbook, sheet = "tblCoralSpecies", guess_max = 10000)
systematics <- read_excel(workbook, sheet = "tblSystematics", guess_max = 10000)
stopifnot(!anyDuplicated(observations$Obs_ID), !anyDuplicated(sites$Subsite_ID),
          !anyDuplicated(species$Coral_ID), !anyDuplicated(systematics$Systematics_ID))

joined <- observations |>
  left_join(sites, by = "Subsite_ID", relationship = "many-to-one") |>
  left_join(select(species, Coral_ID, Current_Genus, Current_Species, Systematics_ID),
            by = "Coral_ID", relationship = "many-to-one") |>
  left_join(systematics, by = "Systematics_ID", relationship = "many-to-one") |>
  mutate(across(where(is.character), trimws))
stopifnot(nrow(joined) == nrow(observations), !anyNA(joined$Latitude),
          !anyNA(joined$Current_Genus))

# Excel stores sunrise/sunset as clock times on 1899-12-31, not event dates.
# Keep the same-calendar difference: daylight spawning can precede sunset.
# A lone after-midnight record is flagged, not silently moved to another date.
clock_minutes <- function(clock) {
  pieces <- strsplit(as.character(clock), ":", fixed = TRUE)
  vapply(pieces, function(x) {
    if (length(x) < 2 || anyNA(x)) return(NA_real_)
    suppressWarnings(as.numeric(x[1]) * 60 + as.numeric(x[2]))
  }, numeric(1))
}

joined <- joined |>
  mutate(date = as.Date(Date, format = "%d/%m/%Y"),
         year = as.integer(format(date, "%Y")), month = as.integer(format(date, "%m")),
         supplied_full_moon = as.Date(DoNFM), lunar_day = DoSRtNFM,
         genus = Current_Genus, species = Current_Species,
         site = Site, country = Country, subsite_id = Subsite_ID,
         latitude = Latitude, longitude = Longitude, utc_offset = Timezone,
         setting = Situation, start_quality = Quality_start,
         start_minutes = clock_minutes(Start_time),
         sunset_minutes = clock_minutes(format(Sunset, "%H:%M", tz = "UTC")),
         sunset_offset_hours = (start_minutes - sunset_minutes) / 60,
         midnight_ambiguous = !is.na(start_minutes) & start_minutes < 180,
         exact_start = !No_start & start_quality == "Exact" & !is.na(start_minutes),
         exact_start = replace_na(exact_start, FALSE),
         depth_m = na_if(Depth_m, -99), colony_count = na_if(N, -99))
stopifnot(!anyNA(joined$date), all(joined$lunar_day >= -15 & joined$lunar_day <= 15),
          all(joined$start_minutes[!is.na(joined$start_minutes)] < 1440))
field <- filter(joined, setting == "In situ")

# One reef-night is a subsite and local date. This is an occurrence database:
# no record means unknown observation effort, not an observed absence of spawning.
reef_nights <- field |>
  group_by(subsite_id, date) |>
  summarise(site = first(site), country = first(country),
            latitude = first(latitude), longitude = first(longitude),
            year = first(year), month = first(month), utc_offset = first(utc_offset),
            lunar_day = first(lunar_day), supplied_full_moon = first(supplied_full_moon),
            n_records = n(), n_genera = n_distinct(genus), .groups = "drop")
genus_nights <- field |>
  group_by(subsite_id, date, genus) |>
  summarise(site = first(site), country = first(country), latitude = first(latitude),
            longitude = first(longitude), year = first(year), month = first(month),
            lunar_day = first(lunar_day), utc_offset = first(utc_offset),
            n_records = n(), .groups = "drop")
stopifnot(nrow(reef_nights) == n_distinct(paste(field$subsite_id, field$date)))

quality <- tibble(
  measure = c("source_records", "joined_records", "natural_reef_records", "ex_situ_records",
              "field_reef_nights", "field_genus_nights", "field_named_sites", "field_subsites",
              "field_countries", "field_exact_start_records", "field_missing_start_records"),
  value = c(nrow(observations), nrow(joined), nrow(field), sum(joined$setting != "In situ"),
            nrow(reef_nights), nrow(genus_nights), n_distinct(field$site),
            n_distinct(field$subsite_id), n_distinct(field$country), sum(field$exact_start),
            sum(is.na(field$start_minutes))))
write_csv(joined, "data/derived/joined_observations.csv")
write_csv(field, "data/derived/field_observations.csv")
write_csv(reef_nights, "data/derived/reef_nights.csv")
write_csv(genus_nights, "data/derived/genus_nights.csv")
write_csv(quality, "data/derived/data_quality.csv")
print(quality)
