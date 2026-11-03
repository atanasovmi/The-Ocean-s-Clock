# Does the lunar pattern depend on how much each recorded night can count?
source("R/style.R")
field <- read_csv("data/derived/field_observations.csv", show_col_types = FALSE)
nights <- read_csv("data/derived/reef_nights.csv", show_col_types = FALSE)
window_days <- 0:7

rows_curve <- field |> count(lunar_day) |> mutate(share = n / sum(n), method = "Every observation row")
nights_curve <- nights |> count(lunar_day) |> mutate(share = n / sum(n), method = "Every reef-night once")
sites_curve <- nights |> count(subsite_id, lunar_day) |>
  complete(subsite_id, lunar_day = -15:14, fill = list(n = 0)) |>
  group_by(subsite_id) |> mutate(share = n / sum(n)) |> ungroup() |>
  group_by(lunar_day) |> summarise(share = mean(share), .groups = "drop") |>
  mutate(method = "Equal weight per subsite")
curves <- bind_rows(rows_curve, nights_curve, sites_curve) |>
  mutate(method = factor(method, levels = c("Every observation row", "Every reef-night once", "Equal weight per subsite")))
window_summary <- curves |> filter(lunar_day %in% window_days) |>
  group_by(method) |> summarise(share = sum(share), .groups = "drop")

curve_plot <- ggplot(curves, aes(lunar_day, share, colour = method, linetype = method)) +
  annotate("rect", xmin = -0.5, xmax = 7.5, ymin = -Inf, ymax = Inf, fill = "#F1F4F6", alpha = 0.65) +
  geom_line(linewidth = 0.95) +
  scale_colour_manual(values = c(muted, ocean, coral), name = NULL) +
  scale_linetype_manual(values = c("dotted", "solid", "longdash"), name = NULL) +
  scale_y_continuous(labels = scales::label_percent(), expand = expansion(mult = c(0, 0.05))) +
  scale_x_continuous(breaks = c(-15, -10, -5, 0, 7, 14)) +
  labs(x = "Days before / after nearest local full moon", y = "Share of recorded events") +
  theme_clock() + theme(plot.margin = margin(8, 8, 8, 8), legend.position = "bottom")
summary_plot <- ggplot(window_summary, aes(share, reorder(method, share))) +
  geom_segment(aes(x = 0, xend = share, yend = reorder(method, share)), colour = grid_colour, linewidth = 1) +
  geom_point(colour = ocean, size = 4) +
  geom_text(aes(label = scales::percent(share, accuracy = 0.1)), hjust = -0.25, colour = ink, size = 5) +
  scale_x_continuous(limits = c(0, 1), labels = scales::label_percent(), breaks = c(0, 0.5, 1)) +
  labs(x = "Share on days 0–7 after full moon", y = NULL) +
  theme_clock() + theme(plot.margin = margin(8, 8, 8, 8), panel.grid.major.y = element_blank(), axis.text.y = element_text(size = 11))
robustness_plot <- (curve_plot / summary_plot) + plot_layout(heights = c(1.3, 1)) +
  plot_annotation(title = "Counting each reef-night once changes 80% to 68%",
    subtitle = "Repeated species records make the post-full-moon concentration look stronger.",
    caption = paste(source_coral, "\nNatural-reef observations; same supplied lunar offsets in all three views. Shading: a descriptive day 0–7 window,\nnot a fitted or independently validated forecast. Equal-subsite weighting gives each of 102 subsites equal total influence.\nUnknown survey effort remains: weighting cannot establish spawning probabilities or causal lunar effects."),
    theme = theme_clock())
save_figure(robustness_plot, "07_weighting_robustness", height = 10)
write_csv(curves, "outputs/tables/07_weighting_curves.csv")
write_csv(window_summary, "outputs/tables/07_weighting_summary.csv")
