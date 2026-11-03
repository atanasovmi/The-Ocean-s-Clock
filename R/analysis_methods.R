# Independent validation of a published, explicitly seasonal aquarium diary.
# This is a separate system from the wild-reef occurrence database.
library(dplyr)
library(tidyr)
library(readr)
library(ggplot2)
library(patchwork)

aquarium_source <- "data/raw/aquarium/"
diary <- read_csv(paste0(aquarium_source, "Chura_spawning_data_DAFM.csv"),
                  show_col_types = FALSE) |>
  mutate(date = as.Date(date, format = "%Y/%m/%d"),
         # Despite its source name, spawning_binary is a COUNT of spawning tanks.
         tanks_spawning = spawning_binary,
         any_spawning = as.integer(spawning_binary > 0),
         year = as.integer(format(date, "%Y")))
environment <- read_csv(paste0(aquarium_source, "Chura_spawning_environment.csv"),
                        show_col_types = FALSE) |>
  mutate(date = as.Date(date, format = "%d/%m/%Y")) |>
  arrange(date)
stopifnot(nrow(diary) == 1350, !anyDuplicated(diary$date),
          !anyDuplicated(environment$date), all(diary$tanks_spawning >= 0),
          all(as.numeric(diff(environment$date)) == 1),
          all((diary |> count(year))$n == 90))

# A predictor for date t uses only dates t-7,...,t-1. Missing windows remain NA.
# Environmental records outside the diary supply preceding measurements only;
# their zero spawning scores are never promoted into observed non-spawning days.
previous_week <- function(x) {
  lag(as.numeric(stats::filter(x, rep(1 / 7, 7), sides = 1)))
}
lagged_environment <- environment |>
  mutate(temp_previous_week = previous_week(sst_M4_S1_mean),
         wind_previous_week = previous_week(wind_speed),
         rain_previous_week = previous_week(precipitation),
         solar_previous_week = previous_week(solar_flux)) |>
  select(date, source_score = spawning_score, temp_previous_week,
         wind_previous_week, rain_previous_week, solar_previous_week)
aquarium <- diary |>
  left_join(lagged_environment, by = "date", relationship = "one-to-one") |>
  mutate(lunar_sin = sin(2 * pi * DAFM / 29.53059),
         lunar_cos = cos(2 * pi * DAFM / 29.53059),
         lunar_sin2 = sin(4 * pi * DAFM / 29.53059),
         lunar_cos2 = cos(4 * pi * DAFM / 29.53059),
         annual_sin = sin(2 * pi * as.integer(format(date, "%j")) / 365.2425),
         annual_cos = cos(2 * pi * as.integer(format(date, "%j")) / 365.2425),
         log_rain_previous_week = log1p(rain_previous_week))
stopifnot(!anyNA(aquarium$source_score), all(aquarium$source_score == aquarium$spawning_score))
predictors <- c("temp_previous_week", "wind_previous_week", "log_rain_previous_week", "solar_previous_week")
eligible <- aquarium |> filter(if_all(all_of(predictors), is.finite))
stopifnot(nrow(eligible) > 900, n_distinct(eligible$year) >= 10)

# The same eligible dates are used for all three comparisons. Each complete
# year is held out; no row from that year's diary can enter a training fold.
calendar_formula <- any_spawning ~ lunar_sin + lunar_cos + lunar_sin2 + lunar_cos2 + annual_sin + annual_cos
environment_formula <- update(calendar_formula, . ~ . + temp_previous_week +
                                wind_previous_week + log_rain_previous_week + solar_previous_week)
# Retain numerical warnings by fold instead of losing them in console output.
fit_binomial <- function(formula, train) {
  fit_warnings <- character()
  fit <- withCallingHandlers(
    glm(formula, data = train, family = binomial()),
    warning = function(w) {
      fit_warnings <<- c(fit_warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    })
  stopifnot(fit$converged, fit$rank == length(coef(fit)), all(is.finite(coef(fit))))
  list(model = fit, warnings = fit_warnings)
}
fold_predictions <- list()
fold_audits <- list()
for (held_out_year in sort(unique(eligible$year))) {
  train <- eligible |> filter(year != held_out_year)
  test <- eligible |> filter(year == held_out_year)
  calendar_result <- fit_binomial(calendar_formula, train)
  environment_result <- fit_binomial(environment_formula, train)
  calendar_fit <- calendar_result$model
  environment_fit <- environment_result$model
  fold_audits[[as.character(held_out_year)]] <- tibble(
    held_out_year = held_out_year, model = c("calendar", "environment"),
    n_training_dates = nrow(train), n_test_dates = nrow(test),
    n_training_years = n_distinct(train$year),
    converged = c(calendar_fit$converged, environment_fit$converged),
    model_rank = c(calendar_fit$rank, environment_fit$rank),
    warning_count = c(length(calendar_result$warnings), length(environment_result$warnings)),
    warning_messages = c(paste(calendar_result$warnings, collapse = " | "),
                         paste(environment_result$warnings, collapse = " | ")))
  fold_predictions[[as.character(held_out_year)]] <- test |>
    select(date, year, any_spawning, tanks_spawning) |>
    mutate(prevalence = mean(train$any_spawning),
           calendar = as.numeric(predict(calendar_fit, newdata = test, type = "response")),
           environment = as.numeric(predict(environment_fit, newdata = test, type = "response")))
}
predictions <- bind_rows(fold_predictions) |>
  pivot_longer(c(prevalence, calendar, environment), names_to = "model", values_to = "probability")
stopifnot(!anyNA(predictions$probability),
          all(predictions$probability > 0 & predictions$probability < 1),
          !anyDuplicated(paste(predictions$date, predictions$model)))

# Brier score is a squared probability error; a lower value is better.
# AUC uses the rank-sum definition and is secondary to the probability score.
auc_rank <- function(y, probability) {
  positives <- sum(y == 1)
  negatives <- sum(y == 0)
  if (positives == 0 || negatives == 0) return(NA_real_)
  (sum(rank(probability)[y == 1]) - positives * (positives + 1) / 2) / (positives * negatives)
}
year_scores <- predictions |>
  group_by(model, year) |>
  summarise(n_days = n(), n_spawning_days = sum(any_spawning),
            brier = mean((probability - any_spawning)^2),
            auc = auc_rank(any_spawning, probability), .groups = "drop")
scores <- predictions |>
  group_by(model) |>
  summarise(n_days = n(), n_spawning_days = sum(any_spawning),
            brier = mean((probability - any_spawning)^2),
            auc = auc_rank(any_spawning, probability), .groups = "drop")
scores <- scores |>
  left_join(year_scores |> summarise(mean_within_year_auc = mean(auc, na.rm = TRUE),
                                    n_auc_years = sum(is.finite(auc)), .by = model), by = "model")

# Resample whole years to retain within-season dependence in the uncertainty.
# This interval conditions on the fitted held-out predictions; it is not a
# guarantee for new reefs or a nested model-selection uncertainty estimate.
set.seed(20261103)
years <- sort(unique(predictions$year))
bootstrap_scores <- bind_rows(lapply(1:1000, function(replicate_id) {
  sampled <- sample(years, length(years), replace = TRUE)
  repeated_years <- tibble(year = sampled, sample_id = seq_along(sampled))
  predictions |>
    inner_join(repeated_years, by = "year", relationship = "many-to-many") |>
    summarise(brier = mean((probability - any_spawning)^2), .by = model) |>
    mutate(replicate = replicate_id)
}))
score_intervals <- bootstrap_scores |>
  group_by(model) |>
  summarise(low = quantile(brier, 0.025), high = quantile(brier, 0.975), .groups = "drop")
scores <- scores |> left_join(score_intervals, by = "model")
improvement <- bootstrap_scores |>
  select(replicate, model, brier) |>
  pivot_wider(names_from = model, values_from = brier) |>
  mutate(calendar_to_environment = calendar - environment)
improvement_summary <- tibble(
  comparison = "Calendar Brier minus calendar+environment Brier",
  estimate = scores$brier[scores$model == "calendar"] - scores$brier[scores$model == "environment"],
  low = quantile(improvement$calendar_to_environment, 0.025),
  high = quantile(improvement$calendar_to_environment, 0.975))

# Reliability bins are defined by held-out prediction ranks, not outcomes.
calibration <- predictions |>
  group_by(model) |> mutate(bin = ntile(probability, 8)) |>
  group_by(model, bin) |>
  summarise(n_days = n(), expected = mean(probability), observed = mean(any_spawning), .groups = "drop")

dir.create("outputs/models", recursive = TRUE, showWarnings = FALSE)
write_csv(aquarium, "data/derived/aquarium_diary.csv")
write_csv(eligible, "data/derived/aquarium_model_sample.csv")
write_csv(predictions, "outputs/tables/aquarium_held_out_predictions.csv")
write_csv(year_scores, "outputs/tables/aquarium_year_scores.csv")
write_csv(bind_rows(fold_audits), "outputs/tables/aquarium_fitting_audit.csv")
write_csv(scores, "outputs/tables/aquarium_model_scores.csv")
write_csv(calibration, "outputs/tables/aquarium_calibration.csv")
write_csv(improvement_summary, "outputs/tables/aquarium_environment_increment.csv")
write_csv(tibble(measure = c("diary_dates", "environment_dates", "diary_spawning_dates", "model_dates", "model_years"),
                 value = c(nrow(diary), nrow(environment), sum(diary$any_spawning), nrow(eligible), n_distinct(eligible$year))),
          "outputs/tables/aquarium_sample_audit.csv")
full_calendar <- fit_binomial(calendar_formula, eligible)
full_environment <- fit_binomial(environment_formula, eligible)
saveRDS(list(calendar = full_calendar$model,
             environment = full_environment$model,
             fitting_warnings = list(calendar = full_calendar$warnings, environment = full_environment$warnings),
             formulas = c(deparse(calendar_formula), deparse(environment_formula)),
             validation = "Leave one entire year out; models compared on identical complete-case dates"),
        "outputs/models/aquarium_models.rds")

# Publication-sized white figures, with measured quantities in the titles.
aq_blue <- "#216A91"
aq_orange <- "#D55E00"
aq_ink <- "#172A36"
model_labels <- c(prevalence = "Training prevalence", calendar = "Moon + season", environment = "Moon + season + environment")
model_colours <- c(prevalence = "#727C83", calendar = aq_blue, environment = aq_orange)
theme_aquarium <- function() {
    theme_minimal(base_size = 14, base_family = "Arial") +
    theme(plot.background = element_rect(fill = "white", colour = NA),
          panel.background = element_rect(fill = "white", colour = NA),
          text = element_text(colour = aq_ink),
          plot.title = element_text(face = "bold", size = 23, margin = margin(b = 10)),
          plot.subtitle = element_text(size = 13, margin = margin(b = 16)),
          plot.caption = element_text(size = 10, hjust = 0, lineheight = 1.2, margin = margin(t = 14)),
          plot.title.position = "plot", plot.caption.position = "plot",
          plot.margin = margin(22, 25, 20, 22),
          panel.grid.minor = element_blank(), panel.grid.major = element_line(colour = "#E8ECEF", linewidth = 0.3),
          legend.position = "bottom", legend.title = element_text(size = 11))
}
calendar_data <- aquarium |>
  mutate(calendar_day = as.numeric(as.Date(paste0("2001-", format(date, "%m-%d"))) - as.Date("2001-01-01")) + 1,
         year_label = factor(year, levels = rev(sort(unique(year)))))
month_days <- as.numeric(as.Date(paste0("2001-", sprintf("%02d", 4:8), "-01")) - as.Date("2001-01-01")) + 1
aquarium_calendar <- ggplot(calendar_data, aes(calendar_day, year_label)) +
  geom_tile(fill = "#EDF0F2", width = 0.98, height = 0.82) +
  geom_tile(data = filter(calendar_data, any_spawning == 1), aes(fill = tanks_spawning), width = 0.98, height = 0.82) +
  geom_point(data = filter(calendar_data, DAFM == 0), shape = 25, size = 1.5, fill = "white", colour = aq_ink, stroke = 0.4) +
  scale_fill_gradient(low = "#93C8DB", high = "#074569", name = "Spawning tanks", breaks = c(1, 5, 10, 17)) +
  scale_x_continuous(breaks = month_days, labels = c("Apr", "May", "Jun", "Jul", "Aug"), expand = expansion(add = 1)) +
  labs(title = "Fifteen years of daily spawning records",
       subtitle = "Okinawa Churaumi Aquarium, 2003–2017 | 1,350 dates in the supplied seasonal diary",
       x = NULL, y = NULL,
       caption = paste0("Blue: number of tanks recorded spawning. Light grey: zero in the diary. White beyond each strip: outside the supplied window.\n",
                        "Triangles mark full-moon dates in the source's lunar alignment. Tank counts and available colonies can differ between years.\n",
                        "Source: Sakai, Yamamoto & Maruyama (2024), Zenodo 10974150, CC BY 4.0. This aquarium series is kept separate from wild reefs.")) +
  theme_aquarium() + theme(panel.grid.major = element_blank())
ggsave("outputs/figures/10_aquarium_calendar.png", aquarium_calendar, width = 14, height = 8.8,
       dpi = 300, device = ragg::agg_png, bg = "white")
dir.create("outputs/vector", recursive = TRUE, showWarnings = FALSE)
ggsave("outputs/vector/10_aquarium_calendar.svg", aquarium_calendar, width = 14, height = 8.8,
       device = svglite::svglite, bg = "white")
write_csv(calendar_data, "outputs/tables/10_aquarium_calendar.csv")

score_plot <- scores |>
  mutate(label = factor(model_labels[model], levels = rev(model_labels))) |>
  ggplot(aes(brier, label, colour = model)) +
  geom_linerange(aes(xmin = low, xmax = high), linewidth = 1.1) +
  geom_point(size = 3.8) +
  geom_text(aes(label = sprintf("%.3f", brier)), nudge_y = 0.2, colour = aq_ink, size = 4.2) +
  scale_colour_manual(values = model_colours, guide = "none") +
  labs(x = "Held-out Brier score (lower is better)", y = NULL) +
  theme_aquarium() + theme(plot.margin = margin(8, 8, 8, 8), panel.grid.major.y = element_blank())
calibration_plot <- calibration |> filter(model != "prevalence") |>
  ggplot(aes(expected, observed, colour = model)) +
  geom_abline(intercept = 0, slope = 1, colour = "#8E979D", linetype = "dashed") +
  geom_line(linewidth = 0.8) + geom_point(size = 2.3) +
  scale_colour_manual(values = model_colours, labels = model_labels, name = NULL) +
  scale_x_continuous(limits = c(0, 0.75), labels = scales::label_percent(), breaks = c(0, .25, .5, .75)) +
  scale_y_continuous(limits = c(0, 0.75), labels = scales::label_percent(), breaks = c(0, .25, .5, .75)) +
  coord_equal() + labs(x = "Predicted chance", y = "Observed spawning share") +
  theme_aquarium() + theme(plot.margin = margin(8, 8, 8, 8), legend.position = "bottom")
validation_plot <- (score_plot | calibration_plot) + plot_layout(widths = c(1.1, 1)) +
  plot_annotation(title = "Environmental data added no clear predictive gain",
    subtitle = paste0(format(nrow(eligible), big.mark = ","), " diary dates from ", n_distinct(eligible$year),
                      " years | every prediction is tested on an entirely withheld year"),
    caption = paste0("Calendar model: cyclic lunar and annual terms. Environment adds preceding-seven-day tank temperature, wind, rainfall and solar flux.\n",
                     "All models use identical dates with complete lagged inputs; none uses measurements from the predicted day or future.\n",
                     "Left: whole-year bootstrap 95% intervals, conditional on held-out fits. Right: equal-count reliability bins; dashed line is perfect calibration.\n",
                     sprintf("Paired Brier improvement from environment: %.4f (95%% interval %.4f to %+.4f); positive would favour added inputs.\n",
                             improvement_summary$estimate, improvement_summary$low, improvement_summary$high),
                     "Source: Sakai et al. (2024). Retrospective validation within one aquarium and the supplied seasonal diary; not a wild-reef forecast."),
    theme = theme_aquarium())
ggsave("outputs/figures/11_prediction_validation.png", validation_plot, width = 15, height = 8,
       dpi = 300, device = ragg::agg_png, bg = "white")
ggsave("outputs/vector/11_prediction_validation.svg", validation_plot, width = 15, height = 8,
       device = svglite::svglite, bg = "white")
message("Aquarium validation: ", nrow(eligible), " dates, ", n_distinct(eligible$year), " held-out years.")
print(scores)
print(improvement_summary)
