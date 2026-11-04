# Question: did preceding-week weather improve predictions for an excluded year?
source("R/plots/style.R")
scores <- read_csv("outputs/tables/aquarium_model_scores.csv", show_col_types = FALSE) |>
  mutate(model_label = recode(model,
    prevalence = "Same chance every day", calendar = "Moon + season",
    environment = "Moon + season + conditions"),
    model_label = factor(model_label, levels = c("Moon + season + conditions", "Moon + season", "Same chance every day")))

model_plot <- ggplot(scores, aes(brier, model_label)) +
  geom_linerange(aes(xmin = low, xmax = high), linewidth = 1.1, colour = "#90A5A9") +
  geom_point(aes(colour = model == "calendar"), size = 4.5) +
  geom_text(aes(x = high + 0.006, label = sprintf("%.3f", brier)), hjust = 0, size = 4.7) +
  scale_colour_manual(values = c("FALSE" = muted, "TRUE" = blue), guide = "none") +
  scale_x_continuous(limits = c(0.075, 0.175), breaks = c(0.08, 0.10, 0.12, 0.14, 0.16)) +
  labs(title = "Extra environmental data did not improve this test",
       subtitle = "1,007 aquarium diary dates  ·  Each whole year was excluded before its predictions were made",
       x = "Prediction error (Brier score; lower is better)", y = NULL,
       caption = "Points show held-out error. Lines show 95% intervals from resampling years. The paired improvement interval also includes zero.\nExtra inputs are preceding-week tank temperature, wind, rain and solar radiation. Source: Sakai et al. (2024), reanalysed here.") +
  theme_presentation() + theme(panel.grid.major.y = element_blank())
save_plot(model_plot, "05_model_comparison")
write_csv(scores, "outputs/tables/05_model_comparison.csv")
