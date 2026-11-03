# The Moon, sunset, and an unusually well-documented single reef-night.
source("R/style.R")
field <- read_csv("data/derived/field_observations.csv", show_col_types = FALSE)
genus_nights <- read_csv("data/derived/genus_nights.csv", show_col_types = FALSE)

# Lunar calendar ----
groups <- genus_nights |> count(genus, sort = TRUE) |> slice_head(n = 8)
lunar <- genus_nights |>
  semi_join(groups, by = "genus") |>
  count(genus, lunar_day) |>
  complete(genus, lunar_day = -15:14, fill = list(n = 0)) |>
  group_by(genus) |> mutate(total = sum(n), share = n / total) |> ungroup() |>
  mutate(label = paste0(genus, "  |  n = ", total),
         label = factor(label, levels = rev(paste0(groups$genus, "  |  n = ", groups$n))))
lunar_plot <- ggplot(lunar, aes(lunar_day, label, fill = share)) +
  geom_tile(width = 0.96, height = 0.86) +
  geom_vline(xintercept = 0, colour = coral, linewidth = 0.7, linetype = "dashed") +
  scale_fill_gradient(low = "#F0EFE7", high = ocean,
                      name = "Share within genus", labels = scales::label_percent()) +
  scale_x_continuous(breaks = c(-15, -10, -5, 0, 5, 10, 14),
                     labels = c("−15", "−10", "−5", "Full moon", "+5", "+10", "+14")) +
  labs(title = "Do corals share one lunar calendar?",
       subtitle = "Eight well-recorded genera, aligned to the nearest local full moon",
       x = "Calendar days before / after full moon", y = NULL,
       caption = paste(source_coral, "\nUnit: one genus per subsite-date; n is the number of recorded genus-nights. Natural-reef records only.\nRow shares describe recorded events, not the probability of spawning on an arbitrary night. Lunar phase wraps at the edges.")) +
  theme_clock() + theme(panel.grid.major = element_blank(), axis.text.y = element_text(size = 13))
save_figure(lunar_plot, "03_lunar_calendars")
write_csv(lunar, "outputs/tables/03_lunar_calendars.csv")

# Daily calendar ----
# Species rows on the same genus/subsite/date are collapsed before comparison.
exact <- field |>
  filter(exact_start, !midnight_ambiguous, !is.na(sunset_offset_hours)) |>
  group_by(subsite_id, date, genus) |>
  summarise(offset = median(sunset_offset_hours), .groups = "drop")
daily <- exact |> group_by(genus) |>
  summarise(n = n(), low = quantile(offset, 0.1), high = quantile(offset, 0.9),
            middle = median(offset), .groups = "drop") |>
  filter(n >= 10) |> arrange(middle) |>
  mutate(label = factor(paste0(genus, "  |  n = ", n),
                        levels = paste0(genus, "  |  n = ", n)))
daily_plot <- ggplot(daily, aes(middle, label)) +
  annotate("rect", xmin = -Inf, xmax = 0, ymin = -Inf, ymax = Inf,
           fill = "#EBDBB8", alpha = 0.4) +
  geom_vline(xintercept = 0, colour = coral, linetype = "dashed", linewidth = 0.7) +
  geom_segment(aes(x = low, xend = high, yend = label), linewidth = 1.3, colour = ocean) +
  geom_point(size = 3.8, colour = ink) +
  scale_x_continuous(breaks = seq(-14, 12, 2)) +
  labs(title = "Sunset is a reference, not a universal alarm",
       subtitle = "Exact recorded starts • point = median • line = middle 80% of observed genus-nights",
       x = "Hours before / after same-date sunset", y = NULL,
       caption = paste(source_coral, "\nUnit: median exact start within each genus/subsite-date; genera require ≥10 such units.\nDawn-spawning observations remain before same-date sunset. An ambiguous post-midnight event is excluded;\ncoverage differs among genera, and these are not controlled comparisons of biological timing.")) +
  theme_clock() + theme(panel.grid.major.y = element_blank())
save_figure(daily_plot, "04_sunset_timing")
write_csv(daily, "outputs/tables/04_sunset_timing.csv")

# One reef-night, species-level timing ----
appointments <- field |>
  filter(subsite_id == 40, date == as.Date("1983-11-24"), exact_start) |>
  mutate(species_label = paste(genus, species)) |>
  group_by(species_label) |>
  summarise(first_start = min(sunset_offset_hours), last_start = max(sunset_offset_hours),
            n = n(), .groups = "drop") |>
  arrange(first_start, species_label) |>
  mutate(species_label = factor(species_label, levels = rev(species_label)))
stopifnot(nrow(appointments) > 0)
appointments_plot <- ggplot(appointments, aes(first_start, species_label)) +
  geom_segment(aes(x = 0, xend = first_start, yend = species_label), colour = grid_colour, linewidth = 0.7) +
  geom_segment(aes(xend = last_start, yend = species_label), colour = coral, linewidth = 1.5) +
  geom_point(shape = 21, size = 3.8, fill = ocean, colour = paper, stroke = 0.8) +
  scale_x_continuous(limits = c(0, 4), breaks = 0:4,
                     labels = c("Sunset", "+1 h", "+2 h", "+3 h", "+4 h")) +
  labs(title = "One reef. One night. Many appointments.",
       subtitle = paste0(nrow(appointments), " species at Orpheus Island, Australia • 24 November 1983 • four days after full moon"),
       x = "Time after local sunset (18:33)", y = NULL,
       caption = paste(source_coral, "\nOne subsite and one date; exact in-situ starting times only. Each point is a species' earliest recorded start;\na coloured extension indicates another recorded start that night. This is an illustrative case, not a universal species schedule.")) +
  theme_clock() + theme(panel.grid.major.y = element_blank(), axis.text.y = element_text(face = "italic", size = 11.5))
save_figure(appointments_plot, "05_one_reef_one_night", height = 9.5)
write_csv(appointments, "outputs/tables/05_one_reef_one_night.csv")
