# Question: does the lunar pattern also appear in a separate Acropora field study?
source("R/plots/style.R")
comparison <- read_csv("data/derived/lunar_replication_summary.csv", show_col_types = FALSE) |>
  mutate(dataset = case_when(grepl("^Historical", sample) ~ "Historical reef study",
                             grepl("atoll-days", sample) ~ "Maldives field study", TRUE ~ NA_character_)) |>
  filter(!is.na(dataset)) |>
  mutate(dataset = factor(dataset, levels = c("Maldives field study", "Historical reef study")),
         label = paste0(scales::percent(share_week, accuracy = 0.1), "  (n = ", total, ")"))

distribution <- read_csv("data/derived/lunar_replication.csv", show_col_types = FALSE) |>
  mutate(dataset = case_when(grepl("^Historical", sample) ~ "Historical reef study",
                             grepl("atoll-days", sample) ~ "Maldives field study")) |>
  filter(!is.na(dataset)) |>
  mutate(dataset = factor(dataset, levels = c("Historical reef study", "Maldives field study")),
         in_window = lunar_day %in% 0:7)
comparison$dataset <- factor(comparison$dataset, levels = levels(distribution$dataset))
comparison_plot <- ggplot(distribution, aes(lunar_day, share, fill = in_window)) +
  geom_col(width = 0.82) +
  geom_text(data = comparison, aes(x = -14, y = 0.17, label = label),
            inherit.aes = FALSE, hjust = 0, size = 5.4, colour = blue) +
  facet_wrap(vars(dataset), ncol = 1) +
  scale_fill_manual(values = c("FALSE" = "#BCC9CB", "TRUE" = blue), guide = "none") +
  scale_x_continuous(breaks = c(-15, -10, -5, 0, 5, 10, 15),
                     labels = c("−15", "−10", "−5", "Full moon", "+5", "+10", "+15")) +
  scale_y_continuous(limits = c(0, 0.22), breaks = c(0, 0.1, 0.2),
                     labels = scales::label_percent(), expand = c(0, 0)) +
  labs(title = "Another field study shows a similar lunar rhythm",
       subtitle = "Acropora in historical records and in the Maldives  ·  Teal bars cover days 0–7",
       x = "Days before or after the nearest local full moon", y = "Share of recorded events",
       caption = "Historical study counts 400 genus/reef-dates. The Maldives study counts 81 spawning atoll-days. Survey coverage differs.\nSources: Baird et al. (2021) and Sheridan et al. (2025). Similar event distributions do not establish identical underlying populations.") +
  theme_presentation() + theme(panel.grid.major.x = element_blank(), panel.spacing.y = unit(0.8, "lines"))
save_plot(comparison_plot, "06_field_comparison")
write_csv(comparison, "outputs/tables/06_field_comparison.csv")
write_csv(distribution, "outputs/tables/06_field_distribution.csv")
