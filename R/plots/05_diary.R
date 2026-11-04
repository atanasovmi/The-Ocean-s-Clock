# Plate 5. Is the lunar peak real, or a product of when people go looking?
# The aquarium is the one record with every day watched, so its empty days are true
# zeros. The same spawning days are laid out twice: by calendar and by the Moon.
source("R/plots/style.R")
library(patchwork)

diary <- read_csv("data/derived/aquarium_diary.csv", show_col_types = FALSE) |>
  mutate(day_of_year = as.integer(format(date, "%j")),
         # +15 and +16 are the same lunar days as -15 and -14 on the next cycle.
         lunar_day = if_else(DAFM > 14, DAFM - 30, DAFM))
scores <- read_csv("outputs/tables/aquarium_model_scores.csv", show_col_types = FALSE)
brier <- setNames(scores$brier, scores$model)
error_cut <- function(model) 100 * (1 - brier[[model]] / brier[["prevalence"]])

spawning_days <- filter(diary, any_spawning == 1)
full_moons <- filter(diary, DAFM == 0)
watched <- summarise(diary, first = min(day_of_year), last = max(day_of_year), .by = year)
stopifnot(nrow(diary) == 1350, nrow(spawning_days) == 208,
          # The headline below says the Moon alone does not help and weather adds nothing.
          error_cut("moon") < 1, brier[["environment"]] >= brier[["calendar"]])

# How often spawning happened per watched day, in steps along each axis.
rate_by <- function(data, step_of) {
  data |>
    mutate(step = step_of) |>
    summarise(rate = mean(any_spawning), days = n(), .by = step) |>
    filter(days >= 12) |>
    arrange(step)
}
calendar_rate <- rate_by(diary, (diary$day_of_year %/% 3) * 3 + 1.5)
lunar_rate <- rate_by(diary, diary$lunar_day)
top_rate <- max(calendar_rate$rate, lunar_rate$rate)

month_starts <- as.integer(format(as.Date(sprintf("2023-%02d-01", 5:8)), "%j"))
calendar_window <- c(min(diary$day_of_year) - 1, max(diary$day_of_year) + 1)
lunar_window <- c(-15.5, 14.5)

# The bars above each panel: spawning days as a share of days watched.
rate_strip <- function(rates, window, width, heading) {
  peak <- slice_max(rates, rate, n = 1, with_ties = FALSE)
  ggplot(rates, aes(step, rate)) +
    geom_col(width = width, fill = spawn) +
    geom_text(data = peak, aes(label = sprintf("%.0f%%", 100 * rate)), vjust = -0.35,
              family = font_label, size = pts(14), colour = moon) +
    scale_x_continuous(expand = c(0, 0)) +
    scale_y_continuous(expand = c(0, 0)) +
    coord_cartesian(xlim = window, ylim = c(0, top_rate), clip = "off") +
    labs(title = heading, x = NULL, y = NULL) +
    theme_plate() +
    theme(axis.text.x = element_blank(), axis.text.y = element_blank(), axis.ticks = element_blank(),
          plot.title = element_text(family = font_label, size = 15, colour = soft,
                                    margin = margin(b = 14)),
          plot.margin = margin(0, 0, 6, 0))
}

year_rows <- function(window, x_scale, x_title) {
  list(scale_size_area(max_size = 4.6, guide = "none"),
       x_scale,
       scale_y_reverse(breaks = 2003:2017, labels = function(y) ifelse(y %% 2 == 1, y, ""),
                       expand = expansion(add = 0.6)),
       coord_cartesian(xlim = window, clip = "off"),
       labs(x = x_title, y = NULL),
       theme_plate(),
       theme(axis.ticks.y = element_blank(), plot.margin = margin(0, 0, 0, 0)))
}

by_calendar <- ggplot(spawning_days, aes(day_of_year, year)) +
  geom_segment(data = watched, aes(x = first, xend = last, y = year, yend = year),
               inherit.aes = FALSE, colour = rule, linewidth = 0.4) +
  geom_point(data = full_moons, aes(day_of_year, year), inherit.aes = FALSE, shape = 21,
             size = 2.6, stroke = 0.65, colour = moon, fill = NA) +
  geom_point(aes(size = tanks_spawning), shape = 21, fill = spawn, colour = night, stroke = 0.25) +
  year_rows(calendar_window,
            scale_x_continuous(breaks = month_starts, labels = c("1 May", "1 Jun", "1 Jul", "1 Aug"),
                               expand = c(0, 0)),
            "Date")

by_moon <- ggplot(spawning_days, aes(lunar_day, year)) +
  geom_segment(data = watched, aes(x = lunar_window[1], xend = lunar_window[2], y = year, yend = year),
               inherit.aes = FALSE, colour = rule, linewidth = 0.4) +
  annotate("segment", x = 0, xend = 0, y = 2002.6, yend = 2017.4, colour = moon, linewidth = 0.4) +
  geom_point(aes(size = tanks_spawning), shape = 21, fill = spawn, colour = night, stroke = 0.25) +
  year_rows(lunar_window,
            scale_x_continuous(breaks = c(-14, -7, 0, 7, 14),
                               labels = c("−14", "−7", "Full moon", "+7", "+14"), expand = c(0, 0)),
            "Days from full moon") +
  theme(axis.text.y = element_blank())

calendar_strip <- rate_strip(calendar_rate, calendar_window, 2.6, "Sorted by the calendar")
moon_strip <- rate_strip(lunar_rate, lunar_window, 0.8, "The same days, sorted by the Moon")

# A gap between the left and right panels, without indenting the plate's outer edges.
left_gap <- theme(plot.margin = margin(0, 18, 0, 0))
right_gap <- theme(plot.margin = margin(0, 0, 0, 18))

diary_plate <- (calendar_strip + left_gap + moon_strip + right_gap) /
  (by_calendar + left_gap + by_moon + right_gap) +
  plot_layout(heights = c(1, 3.9)) +
  plot_annotation(
    title = "With every day watched, the season says far more than the Moon",
    subtitle = sprintf("Churaumi Aquarium in Okinawa kept a diary of 1,350 days over 15 years. Forecasting each year from the others, season\nalone cuts the error by %.0f%%. The Moon alone cuts nothing, and tank temperature, wind, rain and sunlight add nothing.",
                       error_cut("season")),
    caption = sprintf("Bars: share of watched days with spawning. Pink dot: a day with spawning, larger when more tanks spawned (1–17). Open circle: a full moon. Forecast test on 1,007 complete days, Brier error: no calendar %.3f,\nMoon %.3f, season %.3f, both %.3f, both plus weather %.3f. One aquarium, so this checks the field pattern and does not forecast a wild reef. Source: Sakai, Yamamoto & Maruyama (2024), reanalysed.",
                      brier[["prevalence"]], brier[["moon"]], brier[["season"]], brier[["calendar"]], brier[["environment"]]),
    theme = theme_plate() + theme(plot.subtitle = element_text(margin = margin(b = 14)))
  )

save_plate(diary_plate, "05_diary")
write_csv(select(scores, model, brier, low, high), "outputs/tables/05_diary.csv")
