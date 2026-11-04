# Table S1 gives a tagged colony's actual release time after the programmed sunset.
# Extract the original table from its three printed pages, keeping the tag as text.
library(dplyr)
library(tidyr)
library(readr)
pages <- pdftools::pdf_text("data/raw/seasim/rspb20251558_si_001.pdf")[15:17]
lines <- unlist(strsplit(pages, "\n", fixed = TRUE), use.names = FALSE)
rows <- grep("^\\s*[0-9]{1,2}/[0-9]{2}/20[0-9]{2}\\s+", lines, value = TRUE)
entries <- read_table(I(paste(trimws(rows), collapse = "\n")),
                      col_names = c("date", "nights_after_full", "colony_tag", "genus", "species", "elapsed"),
                      col_types = "cicccc", show_col_types = FALSE) |>
  separate_wider_delim(elapsed, delim = ":", names = c("hour", "minute")) |>
  mutate(date = as.Date(date, "%d/%m/%Y"), year = as.integer(format(date, "%Y")),
         minutes_after_sunset = 60 * as.integer(hour) + as.integer(minute),
         species = paste(genus, species)) |>
  select(date, year, colony_tag, species, nights_after_full, minutes_after_sunset)
stopifnot(nrow(entries) == length(rows), !anyNA(entries),
          all(grepl("^[0-9]{15}$", entries$colony_tag)),
          !anyDuplicated(entries[c("colony_tag", "date")]),
          nrow(distinct(entries, colony_tag, species)) == n_distinct(entries$colony_tag))
write_csv(entries, "data/derived/seasim_colony_starts.csv")

# Some colonies released on several nights. Give each tag a single typical time
# per year, then pair only tags actually observed in both shifted seasons.
pairs <- entries |>
  summarise(n_nights = n(), median_minutes = median(minutes_after_sunset),
            .by = c(colony_tag, species, year)) |>
  pivot_wider(names_from = year, values_from = c(n_nights, median_minutes)) |>
  drop_na() |>
  mutate(change_minutes = median_minutes_2023 - median_minutes_2022) |>
  arrange(species, change_minutes, colony_tag)
stopifnot(!anyDuplicated(pairs$colony_tag), nrow(pairs) > 0)
write_csv(pairs, "outputs/tables/seasim_colony_pairs.csv")
