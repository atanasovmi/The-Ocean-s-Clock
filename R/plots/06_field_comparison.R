# Question: does the lunar pattern also appear in a separate Acropora field study?
source("R/plots/style.R")
comparison <- read_csv("data/derived/lunar_replication_summary.csv", show_col_types = FALSE) |>
  mutate(dataset = case_when(grepl("^Historical", sample) ~ "Historical reef study",
                             grepl("atoll-days", sample) ~ "Maldives field study", TRUE ~ NA_character_)) |>
  filter(!is.na(dataset)) |>
  mutate(dataset = factor(dataset, levels = c("Maldives field study", "Historical reef study")),
         label = paste0(scales::percent(share_week, accuracy = 0.1), "  (n = ", total, ")"))

comparison_plot <- ggplot(comparison, aes(share_week, dataset)) +
  geom_col(width = 0.45, fill = blue) +
  geom_text(aes(label = label), hjust = -0.1, size = 4.7) +
  scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2), labels = scales::label_percent(),
                     expand = expansion(mult = c(0, 0))) +
  labs(title = "Both field studies show a similar lunar pattern",
       subtitle = "About 70% of Acropora records fall in the week after full moon.",
       x = "Recorded location-dates in days 0–7 after full moon", y = NULL,
       caption = "Historical study: 400 genus/reef-dates; Maldives: 81 spawning atoll-days. Survey coverage differs.\nSources: Baird et al. (2021); Sheridan et al. (2025). These are shares of recorded spawning events.") +
  theme_presentation() + theme(panel.grid.major.y = element_blank())
save_plot(comparison_plot, "06_field_comparison", width = 11, height = 5.8)
write_csv(comparison, "outputs/tables/06_field_comparison.csv")
