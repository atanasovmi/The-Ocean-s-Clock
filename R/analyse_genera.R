# Do coral genera keep the same time, or does each go its own way?
# The unit is one genus on one reef-night, so a night with many species of one
# genus counts once. These are recorded events: quiet nights are not in the data.
.libPaths(c(".Rlibrary", .libPaths()))
library(dplyr)
library(tidyr)
library(readr)

synodic_month <- 29.53
genus_nights <- read_csv("data/derived/genus_nights.csv", show_col_types = FALSE)
field <- read_csv("data/derived/field_observations.csv", show_col_types = FALSE, guess_max = 8000)

# Which sea, and which part of the month ----
# The Red Sea is told apart from Saudi Arabia's Gulf coast by longitude.
red_sea_countries <- c("Israel", "Jordan", "Egypt", "Sudan", "Saudi Arabia", "Eritrea", "Djibouti", "Yemen")
genus_nights <- genus_nights |>
  mutate(red_sea = country %in% red_sea_countries & longitude < 45,
         after_full = between(lunar_day, 0, 7),
         # lunar_day runs from -15 to +14, so these are the 7 days around new moon.
         near_new = abs(lunar_day) >= 12)

# Each genus across the month ----
# Mean direction and tightness R, the same measure as plot 1.
genus_summary <- genus_nights |>
  mutate(angle = 2 * pi * lunar_day / synodic_month) |>
  summarise(nights = n(), reefs = n_distinct(subsite_id),
            typical_day = atan2(mean(sin(angle)), mean(cos(angle))) * synodic_month / (2 * pi),
            tightness = sqrt(mean(cos(angle))^2 + mean(sin(angle))^2),
            share_after_full = mean(after_full), share_near_new = mean(near_new),
            .by = genus) |>
  arrange(desc(nights))
well_recorded <- filter(genus_summary, nights >= 20)

# Each genus across the day ----
# Every start with a time, exact or approximate, because 12 of the 22 Pocillopora
# times are approximate. After-midnight records stay out: their date is ambiguous.
# Times run from 4 h before sunset to 20 h after it, so a dawn start lands about
# 12 h after sunset rather than a negative number of hours before the next one.
genus_starts_all <- field |>
  filter(!is.na(sunset_offset_hours), !midnight_ambiguous) |>
  summarise(hours = median(sunset_offset_hours), .by = c(subsite_id, date, genus, site, country, longitude)) |>
  mutate(hours = (hours + 4) %% 24 - 4,
         red_sea = country %in% red_sea_countries & longitude < 45,
         evening = between(hours, -4, 6))
start_summary <- genus_starts_all |>
  summarise(timed_nights = n(), evening_share = mean(evening), .by = genus)

# The groups the plot compares ----
# Every genus with at least 40 nights gets one row. Pocillopora gets two, because
# it is the one genus whose timing depends on the sea it lives in.
outlier <- "Pocillopora"
crowd <- genus_summary |>
  filter(nights >= 40, genus != outlier) |>
  pull(genus)
assign_group <- function(data) {
  data |>
    mutate(group = case_when(
      genus %in% crowd ~ genus,
      genus == outlier & red_sea ~ "Pocillopora, Red Sea",
      genus == outlier ~ "Pocillopora, other seas"
    ))
}
grouped_nights <- genus_nights |> assign_group() |> filter(!is.na(group))
grouped_starts <- genus_starts_all |> assign_group() |> filter(!is.na(group))
group_summary <- grouped_nights |>
  summarise(nights = n(), reefs = n_distinct(subsite_id), share_after_full = mean(after_full),
            share_near_new = mean(near_new), .by = group) |>
  arrange(desc(share_after_full))

# Does genus matter on the same reef? ----
# Shuffling genus labels inside each reef keeps every reef's own pattern, so any
# difference left between genera cannot come from where they were recorded.
genus_spread <- function(hit, genus) {
  weights <- table(genus)
  sum(weights * (tapply(hit, genus, mean) - mean(hit))^2)
}
same_reef_test <- function(data, shuffles = 2000) {
  reef_rows <- split(seq_len(nrow(data)), data$site)
  observed <- genus_spread(data$after_full, data$genus)
  shuffled <- replicate(shuffles, {
    hit <- data$after_full
    for (rows in reef_rows) hit[rows] <- hit[rows][sample.int(length(rows))]
    genus_spread(hit, data$genus)
  })
  (sum(shuffled >= observed) + 1) / (shuffles + 1)
}
shared_reefs <- genus_nights |>
  filter(n() >= 20, .by = genus) |>
  filter(n_distinct(genus) >= 2, .by = site)
set.seed(9)
same_reef_p <- same_reef_test(shared_reefs)
same_reef_p_crowd <- same_reef_test(filter(shared_reefs, genus != outlier))

# The outlier in numbers ----
pocillopora_red <- filter(genus_nights, genus == outlier, red_sea)
pocillopora_other <- filter(genus_nights, genus == outlier, !red_sea)
pocillopora_times <- filter(genus_starts_all, genus == outlier)
other_times <- filter(genus_starts_all, genus != outlier)

genus_statistics <- tibble::tribble(
  ~measure, ~value,
  "genera_all", n_distinct(genus_nights$genus),
  "genera_well_recorded", nrow(well_recorded),
  "typical_day_min", min(well_recorded$typical_day),
  "typical_day_max", max(well_recorded$typical_day),
  "tightness_min", min(well_recorded$tightness),
  "tightness_max", max(well_recorded$tightness),
  "same_reef_p", same_reef_p,
  "same_reef_p_without_pocillopora", same_reef_p_crowd,
  "pocillopora_red_nights", nrow(pocillopora_red),
  "pocillopora_red_near_new", sum(pocillopora_red$near_new),
  "pocillopora_red_sites", n_distinct(pocillopora_red$site),
  "pocillopora_other_nights", nrow(pocillopora_other),
  "pocillopora_other_after_full", sum(pocillopora_other$after_full),
  "platygyra_share_near_new", genus_summary$share_near_new[genus_summary$genus == "Platygyra"],
  "pocillopora_timed", nrow(pocillopora_times),
  "pocillopora_evening", sum(pocillopora_times$evening),
  "other_timed", nrow(other_times),
  "other_evening_share", mean(other_times$evening)
)

write_csv(genus_summary, "outputs/tables/genus_summary.csv")
write_csv(start_summary, "outputs/tables/genus_start_summary.csv")
write_csv(group_summary, "outputs/tables/genus_group_summary.csv")
write_csv(genus_statistics, "outputs/tables/genus_statistics.csv")
write_csv(select(grouped_nights, group, subsite_id, date, site, lunar_day), "data/derived/genus_group_nights.csv")
write_csv(select(grouped_starts, group, subsite_id, date, site, hours), "data/derived/genus_group_starts.csv")
