"""Refresh the NASA/JPL cache from the project root. Only public reef locations and
UTC minutes are sent. The R analysis reads the saved responses and runs offline.
"""
import csv
import io
import re
import tempfile
import time
import zipfile
from collections import defaultdict
from datetime import date
from pathlib import Path

import requests

API = "https://ssd.jpl.nasa.gov/api/horizons_file.api"
OUT = Path("data/raw/horizons")
EPOCH = date(1970, 1, 1)
MINUTES_PER_DAY = 1440


def requested_minutes():
    locations, minutes = {}, defaultdict(set)
    with open("data/derived/field_observations.csv", encoding="utf-8", newline="") as f:
        for row in csv.DictReader(f):
            if row["exact_start"] != "TRUE" or row["midnight_ambiguous"] != "FALSE":
                continue
            start, sunset = int(row["start_minutes"]), int(row["sunset_minutes"])
            if start < sunset:
                continue
            site = int(row["subsite_id"])
            location = (float(row["longitude"]), float(row["latitude"]))
            assert locations.setdefault(site, location) == location
            local_day = date.fromisoformat(row["date"])
            midnight_utc = (local_day - EPOCH).days * MINUTES_PER_DAY - round(60 * float(row["utc_offset"]))
            minutes[site].update(midnight_utc + start + d * MINUTES_PER_DAY for d in range(-14, 15))
            # Minute-by-minute track for the historical evening reconstructed in Figure 7.
            if site == 40 and local_day == date(1983, 11, 24):
                minutes[site].update(midnight_utc + m for m in range(18 * 60, 24 * 60 + 1))
    if not minutes:
        raise ValueError("No exact evening starts were found in the prepared field data")
    return locations, minutes


def fetch_site(session, location, minutes):
    lon, lat = location
    epochs = "\n ".join(f"'{2440587.5 + m / MINUTES_PER_DAY:.9f}'" for m in sorted(minutes))
    query = f"""!$$SOF
COMMAND='301'
OBJ_DATA='NO'
MAKE_EPHEM='YES'
EPHEM_TYPE='OBSERVER'
CENTER='coord@399'
COORD_TYPE='GEODETIC'
SITE_COORD='{lon:.9f},{lat:.9f},0'
QUANTITIES='4'
APPARENT='AIRLESS'
CSV_FORMAT='YES'
CAL_FORMAT='JD'
TIME_TYPE='UT'
TIME_DIGITS='FRACSEC'
TLIST_TYPE='JD'
TLIST= {epochs}
"""
    for attempt in range(3):
        try:
            response = session.post(API, data={"format": "json"},
                                    files={"input": ("reef.txt", query)}, timeout=120)
            response.raise_for_status()
            break
        except requests.RequestException:
            if attempt == 2:
                raise
            time.sleep(3 * (attempt + 1))
    result = response.json()
    body = result["result"]
    if "error" in result or not re.search(r"Target body name:\s+Moon \(301\)", body):
        raise ValueError(result.get("error", body[:900]))
    coord = re.search(r"Center geodetic\s*:\s*([^,]+),\s*([^,]+),\s*([^\s]+)", body)
    if not coord:
        raise ValueError("Response is missing its observer location")
    x, y, km = map(float, coord.groups())
    if abs((x - lon + 180) % 360 - 180) > 1e-5 or abs(y - lat) > 1e-5 or abs(km) > 1e-6:
        raise ValueError("Returned observer coordinates differ from the reef coordinates")
    rows = list(csv.reader(io.StringIO(body.split("$$SOE\n")[1].split("$$EOE")[0])))
    returned = [round((float(r[0]) - 2440587.5) * MINUTES_PER_DAY) for r in rows]
    if len(rows) != len(minutes) or set(returned) != minutes:
        raise ValueError("Returned UTC minutes differ from the request")
    return response.content


if __name__ == "__main__":
    locations, minutes = requested_minutes()
    OUT.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=OUT) as tmp, requests.Session() as session:
        archive = Path(tmp) / "reef_moon_positions.zip"
        with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED) as z:
            for site, epochs in sorted(minutes.items()):
                response = fetch_site(session, locations[site], epochs)
                z.writestr(f"site_{site:03d}.json", response)
                print(f"Reef {site}: {len(epochs):,} verified positions", flush=True)
        archive.replace(OUT / archive.name)
