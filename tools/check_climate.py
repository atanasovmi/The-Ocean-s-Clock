"""Independent validation of R's calendar-weighted climate integration.

Uses the original NOAA ASCII caches and reconstructs the biological weights
separately in pandas. It does not call the R implementation being checked.
Run from the project root after R/05_climate.R. Requires pandas and numpy.
"""
from pathlib import Path
import gzip
import io
import json
import numpy as np
import pandas as pd

lookup = pd.read_csv("data/derived/reef_region_lookup.csv")
nights = pd.read_csv("data/derived/reef_nights.csv")
bio = nights.merge(lookup[["subsite_id", "station_id", "station_name"]],
                   on="subsite_id", how="left", validate="many_to_one")
bio = bio.dropna(subset=["station_id"])
keys = ["site", "country", "station_id", "station_name"]
eligible = bio.groupby(keys).agg(n_nights=("date", "size"), years=("year", "nunique"))
eligible = eligible.query("n_nights >= 10 and years >= 3").reset_index()
sample = bio.merge(eligible[keys], on=keys, validate="many_to_one")
counts = sample.groupby(keys + ["month"]).size().rename("n").reset_index()
full = eligible[keys].merge(pd.DataFrame({"month": range(1, 13)}), how="cross")
counts = full.merge(counts, on=keys + ["month"], how="left").fillna({"n": 0})
counts["weight"] = counts["n"] / counts.groupby(keys)["n"].transform("sum")
weights = counts.groupby(["station_id", "month"])["weight"].mean().reset_index()
r_weights = pd.read_csv("data/derived/spawning_calendar_weights.csv")
weight_check = weights.merge(r_weights, on=["station_id", "month"], validate="one_to_one")
weight_error = float((weight_check.weight - weight_check.calendar_weight).abs().max())
assert weight_error < 1e-12

parts = []
for station_id in weights.station_id.unique():
    payload = gzip.decompress(Path(f"data/raw/crw/{station_id}.txt.gz").read_bytes()).decode("ascii")
    lines = payload.splitlines()
    header = next(i for i, line in enumerate(lines) if line.startswith("YYYY"))
    source = pd.read_csv(io.StringIO(payload), sep=r"\s+", skiprows=header + 1,
                         header=None, names=["year", "month", "day", "sst_min", "sst_max",
                                             "sst", "ssta", "hotspot", "dhw", "alert"])
    source = source.query("1986 <= year <= 2024").copy()
    source["stress"] = source.dhw >= 4
    months = source.groupby(["year", "month"])["stress"].mean().reset_index()
    months = months.merge(weights.query("station_id == @station_id"),
                          on="month", validate="many_to_one")
    months["weighted_stress"] = months.stress * months.weight
    exposure = months.groupby(["station_id", "year"])["weighted_stress"].sum().reset_index()
    parts.append(exposure)
independent = pd.concat(parts, ignore_index=True)
r_exposure = pd.read_csv("outputs/tables/08_calendar_exposure.csv")
checked = independent.merge(r_exposure, on=["station_id", "year"], validate="one_to_one")
exposure_error = float((checked.weighted_stress - checked.calendar_exposure).abs().max())
assert exposure_error < 1e-12

early = independent.query("1986 <= year <= 1995").groupby("station_id").weighted_stress.mean()
recent = independent.query("2015 <= year <= 2024").groupby("station_id").weighted_stress.mean()
changes = recent - early
comparison = pd.read_csv("outputs/tables/08_decadal_exposure.csv").set_index("station_id")
assert np.max(np.abs(changes - comparison.change)) < 1e-12
summary = {"eligible_sites": len(eligible), "regions": len(changes),
           "independently_checked_region_years": len(checked),
           "max_weight_difference": weight_error, "max_exposure_difference": exposure_error,
           "increased_regions": int((changes > 1e-12).sum()),
           "unchanged_regions": int((changes.abs() <= 1e-12).sum()),
           "decreased_regions": int((changes < -1e-12).sum())}
print(json.dumps(summary, indent=2))
