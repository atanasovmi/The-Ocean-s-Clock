# Question: did preceding-week weather improve predictions for an excluded year?
source("R/plots/style.R")
scores <- read_csv("outputs/tables/aquarium_model_scores.csv", show_col_types = FALSE) |>
  mutate(model_label = recode(model,
    prevalence = "Same chance every day", calendar = "Moon + season",
    environment = "Moon + season + weather"),
    model_label = factor(model_label, levels = c("Moon + season + weather", "Moon + season", "Same chance every day")))

model_plot <- ggplot(scores, aes(brier, model_label)) +
  geom_linerange(aes(xmin = low, xmax = high), linewidth = 0.8, colour = "grey45") +
  geom_point(aes(colour = model == "calendar"), size = 3.2) +
  geom_text(aes(x = high + 0.006, label = sprintf("%.3f", brier)), hjust = 0, size = 4.7) +
  scale_colour_manual(values = c("FALSE" = "grey35", "TRUE" = blue), guide = "none") +
  scale_x_continuous(limits = c(0.075, 0.175), breaks = c(0.08, 0.10, 0.12, 0.14, 0.16)) +
  labs(title = "Adding weather data showed no clear improvement",
       subtitle = "1,007 aquarium diary dates; each whole year was excluded before predicting it.",
       x = "Prediction error (Brier score; lower is better)", y = NULL,
       caption = "Points: held-out scores. Lines: 95% intervals from resampling whole years.\nSource: Sakai et al. (2024), reanalysed here. Results concern this aquarium, not forecasts for wild reefs.") +
  theme_presentation() + theme(panel.grid.major.y = element_blank())
save_plot(model_plot, "05_model_comparison", width = 11, height = 6.3)
write_csv(scores, "outputs/tables/05_model_comparison.csv")
