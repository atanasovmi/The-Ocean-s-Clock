# Independent field-study check: keep the two recording systems separate.
source("R/style.R")

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

replication_plot <- ggplot(replication, aes(lunar_day, share, fill = sample)) +
  geom_col(width = 0.82) +
  geom_vline(xintercept = c(-0.5, 7.5), colour = "#A6AFB5", linetype = "dashed", linewidth = 0.35) +
  geom_text(data = summary, aes(x = -13.5, y = 0.16, label = headline),
            inherit.aes = FALSE, hjust = 0, colour = ink, size = 7, fontface = "bold") +
  geom_text(data = summary, aes(x = -13.5, y = 0.11, label = detail),
            inherit.aes = FALSE, hjust = 0, vjust = 1, colour = muted, size = 3.5) +
  facet_wrap(~sample, ncol = 1) +
  scale_fill_manual(values = setNames(c("#7D8C96", ocean, coral), groups), guide = "none") +
  scale_x_continuous(breaks = c(-15, -10, -5, 0, 5, 10, 15),
                     labels = c("−15", "−10", "−5", "Full moon", "+5", "+10", "+15")) +
  scale_y_continuous(labels = scales::label_percent(), limits = c(0, 0.22),
                     breaks = c(0, 0.1, 0.2), expand = expansion(mult = c(0, 0.02))) +
  labs(title = "Acropora spawning clusters after full moon in both datasets",
       subtitle = "An independent Maldives field study provides a second view of the lunar pattern",
       x = "Days before / after nearest full moon", y = "Share of recorded observations",
       caption = paste0("Sources: Baird et al. (2021), CSD v1; Sheridan et al. (2025), PeerJ 13:e19447, Supplement 4 (CC BY 4.0).",
                        "\nHistorical data: one genus/subsite-date. Maldives: 81 spawning atoll-days, representing 3,026 colony observations, Oct 2021–May 2024.",
                        "\nRecording designs and geographical units differ. Day 0–7 is a descriptive comparison; these percentages are not spawning probabilities.")) +
  theme_clock() + theme(panel.grid.major.x = element_blank(),
                         panel.spacing = grid::unit(1.3, "lines"),
                         strip.text = element_text(size = 13, face = "bold", hjust = 0))
save_figure(replication_plot, "12_maldives_replication", width = 15, height = 10.5)
write_csv(replication, "outputs/tables/12_maldives_replication.csv")
write_csv(summary, "outputs/tables/12_maldives_summary.csv")
write_csv(maldives, "data/derived/maldives_observations.csv")
