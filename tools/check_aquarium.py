"""Independent numerical checks for the aquarium models; not an R dependency."""
from pathlib import Path
import numpy as np
import pandas as pd
from scipy.special import expit
from scipy.optimize import minimize

root = Path(__file__).resolve().parents[1]
env = pd.read_csv(root / "data/raw/aquarium/Chura_spawning_environment.csv")
env["date"] = pd.to_datetime(env["date"], dayfirst=True)
env = env.set_index("date")
sample = pd.read_csv(root / "data/derived/aquarium_model_sample.csv", parse_dates=["date"])
prediction = pd.read_csv(root / "outputs/tables/aquarium_held_out_predictions.csv", parse_dates=["date"])
source_columns = {"temp_previous_week": "sst_M4_S1_mean", "wind_previous_week": "wind_speed",
                  "rain_previous_week": "precipitation", "solar_previous_week": "solar_flux"}
largest_lag_difference = 0.0
for row in sample.itertuples(index=False):
    dates = pd.date_range(row.date - pd.Timedelta(days=7), row.date - pd.Timedelta(days=1))
    for target, source in source_columns.items():
        values = env.loc[dates, source]
        assert len(values) == 7 and values.notna().all()
        difference = abs(float(values.mean()) - getattr(row, target))
        largest_lag_difference = max(largest_lag_difference, difference)
assert largest_lag_difference < 1e-10

calendar = ["lunar_sin", "lunar_cos", "lunar_sin2", "lunar_cos2", "annual_sin", "annual_cos"]
weather = ["temp_previous_week", "wind_previous_week", "log_rain_previous_week", "solar_previous_week"]
largest_prediction_difference = 0.0
fit_count = 0
for year in sorted(sample.year.unique()):
    train = sample.loc[sample.year.ne(year)]
    test = sample.loc[sample.year.eq(year)]
    assert set(train.year).isdisjoint(set(test.year))
    for model, columns in [("calendar", calendar), ("environment", calendar + weather),
                           ("season", calendar[4:]), ("moon", calendar[:4])]:
        center, scale = train[columns].mean(), train[columns].std(ddof=0)
        x = np.column_stack([np.ones(len(train)), (train[columns] - center) / scale])
        x_test = np.column_stack([np.ones(len(test)), (test[columns] - center) / scale])
        y = train.any_spawning.to_numpy()
        def objective(beta):
            eta = x @ beta
            return np.sum(np.logaddexp(0, eta) - y * eta)
        def gradient(beta):
            return x.T @ (expit(x @ beta) - y)
        def hessian(beta):
            p = expit(x @ beta)
            return x.T @ ((p * (1 - p))[:, None] * x)
        fit = minimize(objective, np.zeros(x.shape[1]), jac=gradient, hess=hessian,
                       method="trust-exact", options={"gtol": 1e-9, "maxiter": 500})
        p = expit(x_test @ fit.x)
        r_predictions = prediction.loc[(prediction.year == year) & (prediction.model == model)]
        r_predictions = test[["date"]].merge(r_predictions, on="date", validate="one_to_one")
        difference = float(np.max(np.abs(p - r_predictions.probability)))
        largest_prediction_difference = max(largest_prediction_difference, difference)
        assert np.linalg.norm(gradient(fit.x), ord=np.inf) < 1e-5
        fit_count += 1
assert largest_prediction_difference < 1e-5
print(f"Checked {len(sample) * 4} lag features; maximum absolute difference {largest_lag_difference:.3g}")
print(f"Refitted {fit_count} held-out logistic models in independent SciPy solver; maximum probability difference {largest_prediction_difference:.3g}")
