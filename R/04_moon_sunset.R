# Show distributions and individual records, rather than summaries alone.
source("R/style.R")
library(ggridges)
library(ggdist)
library(ggforce)
field <- read_csv("data/derived/field_observations.csv", show_col_types = FALSE)
gn <- read_csv("data/derived/genus_nights.csv", show_col_types = FALSE)

# Lunar timing: three-bin circular smoothing, unsmoothed shares in side panel.
groups <- gn |> count(genus, sort = TRUE) |> filter(n >= 30)
lunar <- gn |> semi_join(groups, by = "genus") |> count(genus, lunar_day) |>
  complete(genus, lunar_day = -15:14, fill = list(n = 0)) |>
  group_by(genus) |> arrange(lunar_day, .by_group = TRUE) |>
  mutate(total = sum(n), share = n / total,
         smooth_share = .6 * share + .2 * lag(share, default = last(share)) +
           .2 * lead(share, default = first(share))) |> ungroup() |>
  mutate(genus = factor(genus, levels = rev(groups$genus)))
lunar_summary <- lunar |> group_by(genus) |>
  summarise(total = first(total), after_moon = sum(share[lunar_day %in% 0:7]), .groups = "drop")
ridge <- ggplot(lunar, aes(lunar_day, genus, height = smooth_share)) +
  annotate("rect", xmin = -.5, xmax = 7.5, ymin = -Inf, ymax = Inf, fill = "#F3F6F8") +
  geom_ridgeline(scale = 3.3, fill = ocean, alpha = .8, colour = "white", linewidth = .3) +
  geom_vline(xintercept = 0, colour = coral, linewidth = .6) +
  scale_x_continuous(breaks = c(-15, -10, -5, 0, 5, 10, 14)) +
  scale_y_discrete(labels = setNames(paste0(groups$genus, "  (", groups$n, ")"), groups$genus), expand = expansion(add = c(.2, 1))) +
  labs(x = "Days from nearest local full moon", y = NULL, subtitle = "Recorded genus-nights (n) · shaded window: days 0–7") +
  theme_clock(13) + theme(panel.grid.major = element_blank(), plot.margin = margin(4, 8, 4, 4))
shares <- ggplot(lunar_summary, aes(after_moon, genus)) +
  geom_segment(aes(x = 0, xend = after_moon, yend = genus), colour = "#C3D2D9") +
  geom_point(colour = ocean, size = 2.6) +
  geom_text(aes(label = scales::percent(after_moon, accuracy = 1)), hjust = -.3, size = 3.5) +
  scale_x_continuous(limits = c(0, 1.15), breaks = c(0, .5, 1), labels = scales::label_percent()) +
  scale_y_discrete(expand = expansion(add = c(.2, 1))) +
  labs(x = "Recorded on days 0–7", y = NULL) + theme_clock(13) +
  theme(axis.text.y = element_blank(), panel.grid.major.y = element_blank(), plot.margin = margin(4, 12, 4, 4))
p <- (ridge | shares) + plot_layout(widths = c(3.5, 1)) +
  plot_annotation(title = "Recorded spawning is concentrated after full moon",
    subtitle = "The window differs among coral genera; a single average would conceal those differences.",
    caption = paste(source_coral, "Natural-reef records; one count per genus, subsite and date.\nRidges use a three-day circular smoother; percentages use unsmoothed counts. Coverage differs among locations."), theme = theme_clock())
save_figure(p, "03_lunar_calendars", height = 10)
write_csv(lunar, "outputs/tables/03_lunar_calendars.csv")
write_csv(lunar_summary, "outputs/tables/03_lunar_summary.csv")

# Exact timing: median within each genus / subsite / date.
exact <- field |> filter(exact_start, !midnight_ambiguous, !is.na(sunset_offset_hours)) |>
  group_by(subsite_id, date, genus) |>
  summarise(offset = median(sunset_offset_hours), clock_hour = median(start_minutes / 60), site = first(site), .groups = "drop")
night_groups <- exact |> filter(between(offset, 0, 6)) |> count(genus) |> filter(n >= 10)
night <- exact |> filter(between(offset, 0, 6)) |> semi_join(night_groups, by = "genus") |> mutate(genus = reorder(genus, offset, median))
a <- ggplot(night, aes(offset, genus)) +
  stat_halfeye(fill = ocean, alpha = .5, colour = ink, height = .7, .width = c(.5, .8), point_interval = median_qi, slab_linewidth = .3) +
  geom_sina(maxwidth = .15, size = 1.1, alpha = .5, colour = ink, seed = 42) +
  scale_x_continuous(breaks = 0:6) +
  labs(x = "Hours after sunset", y = NULL, subtitle = "Night sample · genera with ≥10 recorded genus-nights") +
  theme_clock(13) + theme(panel.grid.major.y = element_blank(), plot.margin = margin(4, 12, 4, 4))
morning <- exact |> filter(offset < 0) |> add_count(genus) |> filter(n >= 2) |> mutate(genus = reorder(genus, clock_hour, median))
b <- ggplot(morning, aes(clock_hour, genus)) +
  geom_sina(size = 2, maxwidth = .25, colour = coral, alpha = .75, seed = 42) +
  scale_x_continuous(breaks = seq(4, 18, 2), labels = function(x) sprintf("%02d:00", x)) +
  labs(x = "Recorded local clock time", y = NULL, subtitle = "Daylight observations\ninclude morning-spawning corals") +
  theme_clock(13) + theme(panel.grid.major.y = element_blank(), plot.margin = margin(4, 12, 4, 4))
p <- (a | b) + plot_layout(widths = c(2.2, 1)) +
  plot_annotation(title = "Spawning time varies within the night—and some corals spawn by day",
    subtitle = "Individual records reveal more than a median and a horizontal interval.",
    caption = paste(source_coral, "Exact natural-reef starts only; one median per genus/subsite/date.\nDots are recorded units; distributions show spread, not uncertainty about a biological effect. Midnight ambiguity is excluded."), theme = theme_clock())
save_figure(p, "04_sunset_timing", width = 16, height = 9)
write_csv(exact, "outputs/tables/04_sunset_timing.csv")

# An informative local case, shown against the wider exact-time record.
appointments <- field |> filter(subsite_id == 40, date == as.Date("1983-11-24"), exact_start) |>
  mutate(species_label = paste(genus, species)) |> group_by(species_label) |>
  summarise(first_start = min(sunset_offset_hours), last_start = max(sunset_offset_hours), n = n(), .groups = "drop") |>
  arrange(first_start, species_label) |> mutate(species_label = factor(species_label, levels = rev(species_label)))
a <- ggplot(appointments, aes(first_start, species_label)) +
  geom_segment(aes(x = 0, xend = first_start, yend = species_label), colour = grid_colour) +
  geom_segment(aes(xend = last_start, yend = species_label), colour = coral, linewidth = 1.3) +
  geom_point(size = 3, colour = ocean) +
  scale_x_continuous(limits = c(0, 4), breaks = 0:4, labels = c("Sunset", "+1 h", "+2 h", "+3 h", "+4 h")) +
  labs(x = "Time after sunset, recorded at 18:33", y = NULL, subtitle = "17 species · one subsite · exact recorded starts") +
  theme_clock(13) + theme(axis.text.y = element_text(face = "italic", size = 10.5), panel.grid.major.y = element_blank(), plot.margin = margin(4, 12, 4, 4))
spans <- field |> filter(exact_start, !midnight_ambiguous) |> group_by(subsite_id, date) |>
  summarise(site = first(site), n_species = n_distinct(paste(genus, species)), span_hours = (max(start_minutes) - min(start_minutes)) / 60, .groups = "drop") |>
  filter(n_species >= 5) |> mutate(case = subsite_id == 40 & date == as.Date("1983-11-24"))
b <- ggplot(spans, aes(n_species, span_hours)) + geom_point(colour = muted, alpha = .5, size = 2.5) +
  geom_point(data = filter(spans, case), colour = coral, size = 4) +
  ggrepel::geom_text_repel(data = filter(spans, case), aes(label = "Orpheus Island\n24 Nov 1983"), size = 3.5, min.segment.length = 0, seed = 42, nudge_y = 1.2) +
  labs(x = "Species with exact recorded starts", y = "First-to-last recorded start (h)", subtitle = paste(nrow(spans), "well-recorded reef-nights\nprovide context for this case")) +
  theme_clock(13) + theme(plot.margin = margin(4, 12, 4, 4))
p <- (a | b) + plot_layout(widths = c(2, 1.15)) +
  plot_annotation(title = "Spawning at Orpheus Island, 24 November 1983",
    subtitle = "Recorded starts span 3 hours 15 minutes. Sharing a night does not mean spawning at the same moment.",
    caption = paste(source_coral, "Species points show earliest recorded starts; orange extensions show additional starts.\nThe case was selected for coverage. Wider-record spans depend on survey effort and do not measure reproductive success."), theme = theme_clock())
save_figure(p, "05_one_reef_one_night", width = 16, height = 9.5)
write_csv(appointments, "outputs/tables/05_one_reef_one_night.csv")
write_csv(spans, "outputs/tables/05_recorded_night_spans.csv")
