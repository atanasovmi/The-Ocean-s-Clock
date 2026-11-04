"""Independently check R's new joins against original NASA and journal inputs.
Optional audit dependencies: pandas, numpy and pymupdf.
"""
import csv
import hashlib
import io
import json
import re
import zipfile
from pathlib import Path

import numpy as np
import pandas as pd
import pymupdf


# Decode the raw NASA rows and check observer coordinates before reconstructing
# event/reference joins. Datetime arithmetic here is independent of R's day count.
archive = Path("data/raw/horizons/reef_moon_positions.zip")
assert hashlib.sha256(archive.read_bytes()).hexdigest() == "42d29a8b62b56631bfdfe06ce3d4982c0020ccd0ae5d7baae54d1cb938d9d9e7"
field = pd.read_csv("data/derived/field_observations.csv")
evening = field[field.exact_start & ~field.midnight_ambiguous &
                (field.start_minutes >= field.sunset_minutes)].copy()
positions = {}
with zipfile.ZipFile(archive) as z:
    assert len(z.namelist()) == 35
    for name in z.namelist():
        site = int(name[5:8])
        reply = json.loads(z.read(name))
        assert reply["signature"]["source"] == "NASA/JPL Horizons API"
        text = reply["result"]
        assert "{source: DE441}" in text and "NO (AIRLESS)" in text
        coordinate = re.search(r"Center geodetic\s*:\s*([^,]+),\s*([^,]+),\s*([^\s]+)", text)
        lon, lat, km = map(float, coordinate.groups())
        original = evening[evening.subsite_id == site].iloc[0]
        assert abs((lon - original.longitude + 180) % 360 - 180) < 1e-5
        assert abs(lat - original.latitude) < 1e-5 and abs(km) < 1e-6
        rows = csv.reader(io.StringIO(text.split("$$SOE\n")[1].split("$$EOE")[0]))
        for row in rows:
            stamp = round((float(row[0]) - 2440587.5) * 1440)
            assert (site, stamp) not in positions
            positions[site, stamp] = float(row[4])

unique = evening.drop_duplicates(["subsite_id", "date", "start_minutes"]).copy()
utc = (pd.to_datetime(unique.date, utc=True) +
       pd.to_timedelta(unique.start_minutes - 60 * unique.utc_offset, unit="min"))
unique["utc_minute"] = (utc - pd.Timestamp("1970-01-01", tz="UTC")) // pd.Timedelta(minutes=1)
expected = []
for shift in range(-14, 15):
    heights = np.array([positions[site, minute + 1440 * shift]
                        for site, minute in zip(unique.subsite_id, unique.utc_minute)])
    checks = []
    for threshold in (0, -1, 1):
        records = unique[["subsite_id", "date"]].copy()
        records["below"] = heights < threshold
        nights = records.groupby(["subsite_id", "date"]).below.mean()
        checks.append(nights.mean())
        if threshold == 0:
            site_average = nights.groupby(level=0).mean().mean()
    expected.append([shift, *checks, site_average])
expected = pd.DataFrame(expected, columns=[
    "shift_days", "share_below", "low_threshold_share", "high_threshold_share", "equal_site_share"])
actual = pd.read_csv("outputs/tables/moon_calendar.csv")[expected.columns]
assert np.allclose(expected, actual, rtol=0, atol=1e-12)
assert len(positions) == 12897 and len(unique) == 538
assert unique[["subsite_id", "date"]].drop_duplicates().shape[0] == 172
recorded = actual.loc[actual.shift_days == 0].iloc[0]
print(f"NASA positions and all 29 date comparisons verified: recorded {recorded.share_below:.6%}.")

# Parse the same publisher table with a different PDF engine, then pair tags.
pdf = Path("data/raw/seasim/rspb20251558_si_001.pdf")
assert hashlib.sha256(pdf.read_bytes()).hexdigest() == "24e4bca7f5518cf8aabc12a395bc9695d11d965e5e9aaeb77a9c43428109f000"
with pymupdf.open(pdf) as document:
    table = "\n".join(document[i].get_text("text", sort=True) for i in (14, 15, 16))
rows = re.findall(
    r"^\s*(\d{1,2}/\d{2}/20\d\d)\s+(-?\d+)\s+(\d{15})\s+(\w+\s+\w+)\s+(\d+):(\d\d)\s*$",
    table, re.M)
independent = pd.DataFrame(rows, columns=["date", "lunar", "colony_tag", "species", "hour", "minute"])
independent["date"] = pd.to_datetime(independent.date, dayfirst=True)
independent["year"] = independent.date.dt.year
independent["minutes_after_sunset"] = independent.hour.astype(int) * 60 + independent.minute.astype(int)
independent["nights_after_full"] = independent.lunar.astype(int)
actual_entries = pd.read_csv("data/derived/seasim_colony_starts.csv", dtype={"colony_tag": str},
                             parse_dates=["date"])
keys = ["colony_tag", "date"]
pd.testing.assert_frame_equal(
    independent[actual_entries.columns].sort_values(keys).reset_index(drop=True),
    actual_entries.sort_values(keys).reset_index(drop=True), check_dtype=False)
paired = independent.groupby(["colony_tag", "species", "year"]).minutes_after_sunset.median().unstack().dropna()
paired["change"] = paired[2023] - paired[2022]
r_pairs = pd.read_csv("outputs/tables/seasim_colony_pairs.csv", dtype={"colony_tag": str}).set_index(["colony_tag", "species"])
assert paired.index.equals(r_pairs.sort_index().index)
assert np.allclose(paired.change, r_pairs.sort_index().change_minutes, rtol=0, atol=1e-12)
assert len(independent) == 172 and len(paired) == 28
print(f"All 172 publisher rows and 28 colony pairs verified: median change {paired.change.median():.1f} minutes.")
