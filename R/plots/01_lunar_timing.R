# Each subsite-date counts once, regardless of the number of species recorded.
source("R/plots/style.R")
nights <- read_csv("data/derived/reef_nights.csv", show_col_types = FALSE)
lunar_counts <- nights |> count(lunar_day) |>
  complete(lunar_day = -15:14, fill = list(n = 0)) |>
  mutate(share = n / sum(n), first_week = lunar_day %in% 0:7)
week_share <- sum(lunar_counts$share[lunar_counts$first_week])
p <- ggplot(lunar_counts, aes(lunar_day, share, fill = first_week)) +
  geom_col(width = 0.82) +
  geom_vline(xintercept = -0.5, linetype = "32", colour = muted, linewidth = 0.4) +
  annotate("text", x = -13.5, y = 0.13, label = scales::percent(week_share, accuracy = 0.1),
           hjust = 0, size = 12, colour = blue, fontface = "bold") +
  annotate("text", x = -13.5, y = 0.10, label = "of recorded reef-nights\nfell in days 0–7", hjust = 0,
           size = 5.1, lineheight = 1.08, colour = muted) +
  scale_fill_manual(values = c("FALSE" = "#BCC9CB", "TRUE" = blue), guide = "none") +
  scale_x_continuous(breaks = c(-15, -10, -5, 0, 5, 10, 14),
                     labels = c("−15", "−10", "−5", "Full moon", "+5", "+10", "+14")) +
  scale_y_continuous(labels = scales::label_percent(accuracy = 1), breaks = seq(0, 0.15, 0.05),
                     limits = c(0, 0.155), expand = expansion(mult = c(0, 0))) +
  labs(title = "Most spawning was recorded just after full moon",
       subtitle = "1,026 reef-nights  ·  Teal bars run from full moon through seven days later",
       x = "Days before or after the nearest local full moon", y = "Share of recorded reef-nights",
       caption = "One record per reef subsite and local date. Source: Baird et al. (2021), Coral Spawning Database.\nSurvey effort varies. These shares describe recorded events and cannot predict spawning on an unobserved night.") +
  theme_presentation() + theme(panel.grid.major.x = element_blank())
save_plot(p, "01_lunar_timing")
write_csv(lunar_counts, "outputs/tables/01_lunar_timing.csv")
