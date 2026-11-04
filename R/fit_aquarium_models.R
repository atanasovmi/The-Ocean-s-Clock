# Independent validation of a published, explicitly seasonal aquarium diary.
# This is a separate system from the wild-reef occurrence database.
library(dplyr)
library(tidyr)
library(readr)

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
# Splitting the calendar model shows which clock carries the forecast.
season_formula <- any_spawning ~ annual_sin + annual_cos
moon_formula <- any_spawning ~ lunar_sin + lunar_cos + lunar_sin2 + lunar_cos2
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
  season_result <- fit_binomial(season_formula, train)
  moon_result <- fit_binomial(moon_formula, train)
  calendar_fit <- calendar_result$model
  environment_fit <- environment_result$model
  season_fit <- season_result$model
  moon_fit <- moon_result$model
  fold_audits[[as.character(held_out_year)]] <- tibble(
    held_out_year = held_out_year, model = c("calendar", "environment", "season", "moon"),
    n_training_dates = nrow(train), n_test_dates = nrow(test),
    n_training_years = n_distinct(train$year),
    converged = c(calendar_fit$converged, environment_fit$converged,
                  season_fit$converged, moon_fit$converged),
    model_rank = c(calendar_fit$rank, environment_fit$rank, season_fit$rank, moon_fit$rank),
    warning_count = c(length(calendar_result$warnings), length(environment_result$warnings),
                      length(season_result$warnings), length(moon_result$warnings)),
    warning_messages = c(paste(calendar_result$warnings, collapse = " | "),
                         paste(environment_result$warnings, collapse = " | "),
                         paste(season_result$warnings, collapse = " | "),
                         paste(moon_result$warnings, collapse = " | ")))
  fold_predictions[[as.character(held_out_year)]] <- test |>
    select(date, year, any_spawning, tanks_spawning) |>
    mutate(prevalence = mean(train$any_spawning),
           calendar = as.numeric(predict(calendar_fit, newdata = test, type = "response")),
           environment = as.numeric(predict(environment_fit, newdata = test, type = "response")),
           season = as.numeric(predict(season_fit, newdata = test, type = "response")),
           moon = as.numeric(predict(moon_fit, newdata = test, type = "response")))
}
predictions <- bind_rows(fold_predictions) |>
  pivot_longer(c(prevalence, calendar, environment, season, moon),
               names_to = "model", values_to = "probability")
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
  mutate(calendar_to_environment = calendar - environment,
         season_to_calendar = season - calendar)
brier_of <- function(name) scores$brier[scores$model == name]
improvement_summary <- tibble(
  comparison = c("Calendar Brier minus calendar+environment Brier",
                 "Season Brier minus season+moon Brier"),
  estimate = c(brier_of("calendar") - brier_of("environment"),
               brier_of("season") - brier_of("calendar")),
  low = c(quantile(improvement$calendar_to_environment, 0.025),
          quantile(improvement$season_to_calendar, 0.025)),
  high = c(quantile(improvement$calendar_to_environment, 0.975),
           quantile(improvement$season_to_calendar, 0.975)))

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


message("Aquarium models: ", nrow(eligible), " dates across ", n_distinct(eligible$year), " held-out years.")
