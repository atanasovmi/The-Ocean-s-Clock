# Moon positions from NASA/JPL

`reef_moon_positions.zip` contains the original JSON response for each of 35 reef subsites. These were retrieved on 3 November 2026 through the public Horizons file API. The archive has 12,897 unique subsite/UTC-minute positions. Repeated dates and start times share the same ephemeris entry. Its SHA-256 is `42d29a8b62b56631bfdfe06ce3d4982c0020ccd0ae5d7baae54d1cb938d9d9e7`.

The target is the Moon, body 301. The observer is at the published reef longitude and latitude, at sea level on Earth. The returned solution identifies DE441. Quantity 4 supplies apparent topocentric azimuth and elevation, with atmospheric refraction switched off. UTC Julian dates are returned in every data row. Longitude is east-positive. The position is the Moon's centre relative to an ideal horizon. Clouds, surrounding topography, artificial lighting, water depth and underwater light attenuation are outside this calculation. [NASA Horizons documentation](https://ssd.jpl.nasa.gov/horizons/manual.html)

The request includes each exact evening start in the natural-reef data and the same clock time on each of the fourteen local dates before and after it. The supplied local UTC offset converts these times to UTC. The source's fixed offset is retained without attempting a separate historical daylight-saving reconstruction. Approximate starts, daylight starts and the ambiguous after-midnight record are excluded. The Orpheus Island record additionally requests each minute from 18:00 to midnight on 24 November 1983.

Refresh with `python tools/fetch_moon_positions.py` after preparing the coral data. This optional download needs Python's `requests` package and network access. It sends public coordinates and times, serially, and verifies returned timestamps and observer coordinates before replacing the cache. The regular R run reads the cache offline. [File API](https://ssd-api.jpl.nasa.gov/doc/horizons_file.html)

The 28 comparison dates are calculated reference positions. They supply no observations of spawning absence and are not independent biological replicates. The chart describes how observed timings sit within their local lunar geometry.
