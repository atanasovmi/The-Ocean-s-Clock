"""Download NOAA's published regional time series; analysis remains in R.

Each original ASCII response is losslessly gzip-compressed with deterministic
metadata. A SHA-256 manifest records the uncompressed bytes and source URL.
Run from the project root. Existing caches are verified and reused.
"""
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from urllib.parse import urljoin
import csv
import gzip
import hashlib
import time
import requests
from bs4 import BeautifulSoup

BASE = "https://coralreefwatch.noaa.gov/product/vs/"
OUT = Path("data/raw/crw")
OUT.mkdir(parents=True, exist_ok=True)
index_path = OUT / "station_index.html"
if not index_path.exists():
    response = requests.get(urljoin(BASE, "data.php"), timeout=40)
    response.raise_for_status()
    index_path.write_bytes(response.content)
soup = BeautifulSoup(index_path.read_bytes(), "html.parser")
stations = {}
for row in soup.select("tr"):
    for link in row.select("a[href]"):
        href = link["href"]
        if href.endswith(".txt") and "data/" in href:
            station_id = Path(href).stem
            station_name = row.select("a[href]")[0].get_text(" ", strip=True)
            stations[station_id] = {"station_id": station_id, "station_name": station_name,
                                    "url": urljoin(BASE, href)}


def download(station):
    path = OUT / (station["station_id"] + ".txt.gz")
    if path.exists():
        payload = gzip.decompress(path.read_bytes())
    else:
        for attempt in range(3):
            try:
                response = requests.get(station["url"], timeout=45)
                response.raise_for_status()
                payload = response.content
                if b"SST_MIN" not in payload or len(payload.splitlines()) < 14000:
                    raise ValueError("Unexpected NOAA time-series response")
                path.write_bytes(gzip.compress(payload, compresslevel=9, mtime=0))
                break
            except Exception:
                if attempt == 2:
                    raise
                time.sleep(2 + attempt)
    lines = payload.decode("ascii").splitlines()
    header_index = next(i for i, line in enumerate(lines) if line.startswith("YYYY"))
    rows = [line.split() for line in lines[header_index + 1:] if line.strip()]
    return dict(station, path=path.as_posix(), raw_bytes=len(payload),
                gzip_bytes=path.stat().st_size, rows=len(rows),
                first_date="-".join(rows[0][:3]), last_date="-".join(rows[-1][:3]),
                sha256_raw=hashlib.sha256(payload).hexdigest())


results = []
with ThreadPoolExecutor(max_workers=4) as pool:
    futures = {pool.submit(download, station): station for station in stations.values()}
    for future in as_completed(futures):
        result = future.result()
        results.append(result)
        if len(results) % 20 == 0:
            print(f"Cached {len(results)}/{len(stations)} stations", flush=True)
results.sort(key=lambda row: row["station_id"])
with (OUT / "manifest.csv").open("w", newline="", encoding="utf-8") as stream:
    writer = csv.DictWriter(stream, fieldnames=list(results[0]))
    writer.writeheader()
    writer.writerows(results)
print(f"Finished: {len(results)} stations, {sum(x['rows'] for x in results):,} station-days, "
      f"{sum(x['gzip_bytes'] for x in results)/1e6:.1f} MB compressed", flush=True)
