# Plot 6. How precise is the Sun clock?
# Wild records mix places, years and species. In the Sea Simulator every colony
# shares one programmed sunset, so the spread that remains is the coral's own.
source("R/plots/style.R")

wild <- read_csv("data/derived/genus_starts.csv", show_col_types = FALSE) |>
  transmute(group = genus, minutes = 60 * hours_after_sunset, setting = "wild")
tank <- read_csv("data/derived/seasim_colony_starts.csv",
                 col_types = cols(colony_tag = col_character())) |>
  transmute(group = sub("Montipora ", "M. ", sub("Acropora ", "A. ", species)),
            minutes = minutes_after_sunset, setting = "tank")

# The six best-recorded genera in the wild; all six species in the tanks.
top_genera <- count(wild, group, sort = TRUE) |> slice_head(n = 6) |> pull(group)
records <- bind_rows(filter(wild, group %in% top_genera), tank)

summaries <- records |>
  summarise(n = n(), median_minutes = median(minutes), q25 = quantile(minutes, 0.25),
            q75 = quantile(minutes, 0.75), .by = c(setting, group)) |>
  mutate(middle_half = q75 - q25) |>
  arrange(desc(setting), median_minutes) |>
  # A gap separates the wild block from the tanks.
  mutate(row = -(row_number() + if_else(setting == "tank", 1.6, 0)),
         label = sprintf("%s (%d)", group, n),
         spread_label = sprintf("%.0f min", middle_half))
dots <- records |>
  left_join(select(summaries, setting, group, row), by = c("setting", "group"),
            relationship = "many-to-one")
stopifnot(!anyNA(dots$row))

loripes <- filter(summaries, group == "A. loripes")
acropora <- filter(summaries, group == "Acropora")
wild_top <- max(summaries$row[summaries$setting == "wild"])
tank_top <- max(summaries$row[summaries$setting == "tank"])
headers <- tibble(row = c(wild_top + 0.85, tank_top + 0.85),
                  label = c("Wild reefs, by genus (n dots)", "Research tanks, by species (n dots)"))

label_x <- -7
key_y <- wild_top + 0.85
spread_x <- 300

minutes_plot <- ggplot(dots, aes(minutes, row)) +
  geom_hline(data = summaries, aes(yintercept = row), colour = "#1B3044", linewidth = 0.3) +
  # Sideways nudges are small: tank times share round values, and dots would hide each other.
  geom_point(position = position_jitter(width = 1.4, height = 0.3, seed = 6),
             shape = 21, size = 2.2, stroke = 0.22, fill = spawn, colour = night) +
  geom_segment(data = summaries, aes(x = q25, xend = q75, y = row, yend = row),
               colour = night, linewidth = 2.6, lineend = "round") +
  geom_segment(data = summaries, aes(x = q25, xend = q75, y = row, yend = row),
               colour = moon, linewidth = 1.2, lineend = "round") +
  geom_text(data = summaries, aes(x = label_x, label = label), hjust = 1, family = font_note,
            size = pts(14.5), colour = soft) +
  geom_text(data = headers, aes(x = label_x, label = label), hjust = 1, family = font_label,
            size = pts(14.5), colour = moon) +
  geom_text(data = summaries, aes(x = spread_x, label = spread_label), hjust = 1,
            family = font_note, size = pts(14.5), colour = moon) +
  annotate("text", x = spread_x, y = wild_top + 0.85, hjust = 1, family = font_label,
           size = pts(14.5), colour = soft, label = "Middle 50% spans") +
  # The key sits in the header row, drawn with the same marks as the rows below.
  annotate("point", x = 6, y = key_y, shape = 21, size = 2.2, stroke = 0.22, fill = spawn, colour = night) +
  plot_note(10, key_y, "One spawning start") +
  annotate("segment", x = 62, xend = 80, y = key_y, yend = key_y, colour = moon, linewidth = 1.2,
           lineend = "round") +
  plot_note(84, key_y, "White bar: interquartile range (middle 50% of dots). Shorter = more exact") +
  plot_note(2, tank_top + 0.85, "All tanks share one programmed sunset") +
  scale_x_continuous(breaks = seq(0, 240, 60), labels = c("Sunset", "+1 h", "+2 h", "+3 h", "+4 h"),
                     expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  coord_cartesian(xlim = c(-96, spread_x), ylim = c(min(summaries$row) - 0.6, wild_top + 1.3),
                  clip = "off") +
  labs(title = "In the tanks, each species keeps its own time",
       subtitle = sprintf("Scientists moved the tanks’ sunset by four hours and the corals moved with it. Each species spawns at its own time:\nhalf of A. loripes releases fall within %.0f minutes. Wild Acropora, with places and species mixed, spreads over %.0f.",
                          loripes$middle_half, acropora$middle_half),
       x = NULL, y = NULL,
       caption = "Wild dots: one genus on one night. Tank dots: one tagged coral on one night, counted from the tanks’ sunset, 2022–23. Dots are nudged apart so they stay visible.\nA. = Acropora, M. = Montipora. Sources: Baird et al. (2021); Koukoumaftsis et al. (2025), supplementary Table S1.") +
  theme_plot() +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(),
        plot.subtitle = element_text(margin = margin(b = 12)))

save_plot(minutes_plot, "06_minutes")
write_csv(select(summaries, setting, group, n, median_minutes, q25, q75, middle_half),
          "outputs/tables/06_minutes.csv")
