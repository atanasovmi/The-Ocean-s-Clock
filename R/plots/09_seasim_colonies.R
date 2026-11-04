# Pair the same colony tags across both controlled out-of-season spawning years.
source("R/plots/style.R")
pairs <- read_csv("outputs/tables/09_seasim_colony_pairs.csv",
                  col_types = cols(colony_tag = col_character()))
groups <- pairs |> count(species, name = "n_colonies") |>
  mutate(label = paste0(sub("Acropora ", "A. ", sub("Montipora ", "M. ", species)),
                        "  ·  ", n_colonies, if_else(n_colonies == 1, " colony", " colonies")))
plot_data <- pairs |> left_join(groups, by = "species", relationship = "many-to-one") |>
  mutate(label = reorder(label, -change_minutes, median))
n_earlier <- sum(pairs$change_minutes < 0)
p <- ggplot(plot_data, aes(change_minutes, label)) +
  geom_vline(xintercept = 0, colour = muted, linetype = "32", linewidth = 0.7) +
  geom_point(position = position_jitter(width = 0, height = 0.15, seed = 190),
             shape = 21, size = 4.1, fill = blue, colour = "white", stroke = 0.7) +
  annotate("text", x = -40, y = 5.65, label = "Earlier in 2023", hjust = 0, size = 4.6, colour = blue) +
  annotate("text", x = 10, y = 5.65, label = "Later", hjust = 1, size = 4.6, colour = muted) +
  scale_x_continuous(limits = c(-43, 11), breaks = seq(-40, 10, 10),
                     labels = c("−40", "−30", "−20", "−10", "No change", "+10")) +
  scale_y_discrete(expand = expansion(add = c(0.5, 0.9))) +
  labs(title = "The same corals tended to start earlier a year later",
       subtitle = sprintf("%d of %d returning colonies  ·  Median shift of %.0f minutes earlier after their programmed sunset",
                          n_earlier, nrow(pairs), -median(pairs$change_minutes)),
       x = "Change in minutes after programmed sunset, 2023 minus 2022", y = NULL,
       caption = "Each dot follows one tagged colony across two shifted seasons at Australia's Sea Simulator. Repeated nights use a yearly median.\nSeasons were moved six months and the light cycle four hours. Shared tank conditions prevent isolating the cause of the year difference.\nSource: Koukoumaftsis et al. (2025), supplementary Table S1. Our matched-colony reanalysis uses only tags timed in both years.") +
  theme_presentation() + theme(panel.grid.major.y = element_blank())
save_plot(p, "09_seasim_colonies")
