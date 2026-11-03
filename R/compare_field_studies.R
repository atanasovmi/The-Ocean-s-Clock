# Independent field-study check: keep the two recording systems separate.
library(dplyr)
library(tidyr)
library(readr)

maldives <- read_csv("data/raw/maldives/peerj-13-19447-s004.csv",
                     show_col_types = FALSE) |>
  rename_with(trimws) |>
  mutate(date = as.Date(as.character(Date), format = "%Y%m%d"))
stopifnot(nrow(maldives) == 81, sum(maldives$No_colonies) == 3026,
          !anyDuplicated(paste(maldives$Atoll, maldives$date)),
          all(maldives$No_colonies > 0), !anyNA(maldives$date))

# Match the biological genus, rather than comparing Acropora with all corals.
# CSD's unit is a genus/subsite-date; the new study aggregates to an atoll-date.
# These are different monitoring designs, so this is a descriptive replication.
historical <- read_csv("data/derived/genus_nights.csv", show_col_types = FALSE) |>
  filter(genus == "Acropora")
groups <- c("Historical database · Acropora reef-nights",
            "Maldives study · spawning atoll-days",
            "Maldives study · colony observations")
replication <- bind_rows(
  historical |> count(lunar_day, name = "count") |> mutate(sample = groups[1]),
  maldives |> count(lunar_day = PFM, name = "count") |> mutate(sample = groups[2]),
  maldives |> group_by(lunar_day = PFM) |>
    summarise(count = sum(No_colonies), .groups = "drop") |> mutate(sample = groups[3])) |>
  complete(sample, lunar_day = -15:15, fill = list(count = 0)) |>
  group_by(sample) |> mutate(share = count / sum(count), total = sum(count)) |> ungroup() |>
  mutate(sample = factor(sample, levels = groups))
summary <- replication |> group_by(sample) |>
  summarise(total = first(total), share_week = sum(share[lunar_day %in% 0:7]), .groups = "drop") |>
  mutate(headline = scales::percent(share_week, accuracy = 0.1),
         detail = paste0("on days 0–7\nn = ", format(total, big.mark = ",", trim = TRUE)))

write_csv(replication, "data/derived/lunar_replication.csv")
write_csv(summary, "data/derived/lunar_replication_summary.csv")
write_csv(maldives, "data/derived/maldives_observations.csv")
