# Question: when were spawning nights recorded relative to full moon?
source("R/plots/style.R")
nights <- read_csv("data/derived/reef_nights.csv", show_col_types = FALSE)
lunar_counts <- nights |>
  count(lunar_day) |>
  complete(lunar_day = -15:14, fill = list(n = 0)) |>
  mutate(share = n / sum(n), first_week = lunar_day %in% 0:7)
week_share <- sum(lunar_counts$share[lunar_counts$first_week])

lunar_plot <- ggplot(lunar_counts, aes(lunar_day, share, fill = first_week)) +
  geom_col(width = 0.85) +
  geom_vline(xintercept = -0.5, linetype = "dashed", linewidth = 0.4) +
  annotate("text", x = 9, y = 0.145,
           label = paste0(round(100 * week_share), "% in days 0–7"), size = 5) +
  scale_fill_manual(values = c("FALSE" = "grey75", "TRUE" = blue), guide = "none") +
  scale_x_continuous(breaks = c(-15, -10, -5, 0, 5, 10, 14),
                     labels = c("−15", "−10", "−5", "Full moon", "+5", "+10", "+14")) +
  scale_y_continuous(labels = scales::label_percent(accuracy = 1),
                     limits = c(0, 0.16), expand = expansion(mult = c(0, 0))) +
  labs(title = "Most recorded spawning nights followed the full moon",
       subtitle = "Each reef location and date is counted once.",
       x = "Days before / after the nearest local full moon", y = "Share of recorded reef-nights",
       caption = "1,026 natural-reef spawning nights. Source: Baird et al. (2021), Coral Spawning Database.\nThese are recorded events; unrecorded nights were not necessarily surveyed.") +
  theme_presentation()
save_plot(lunar_plot, "01_lunar_timing")
write_csv(lunar_counts, "outputs/tables/01_lunar_timing.csv")
