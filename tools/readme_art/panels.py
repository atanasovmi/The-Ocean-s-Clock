"""Builds the supporting README graphics: dials, the data reef, buttons, icons,
wave dividers, the seabed footer, framed plot previews and the social card.

The dials read the real records, so they stay true to the analysis.
"""
import csv
import io
import math
import random
import re

from PIL import Image, ImageDraw
from playwright.sync_api import sync_playwright

import hero
from common import ASSETS, ROOT, data_uri, render_svg

FONT = "'Segoe UI','Helvetica Neue',Helvetica,Arial,sans-serif"
PINK = "#FF7E8B"
MOON = "#F1EAD7"
R_BAR = "R\u0304"  # the mean resultant length: R with a bar
MONO = "Consolas,'SF Mono',Menlo,'DejaVu Sans Mono',monospace"


def write(name, svg):
    (ASSETS / name).write_text(svg, encoding="utf-8")


def rows(path):
    with open(ROOT / path, encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


# Dials ---------------------------------------------------------------------

def histogram(values, period, bins):
    """Counts records around a cycle. Zero sits at the top of the dial."""
    counts = [0] * bins
    for value in values:
        position = (value / period) % 1
        counts[min(int(position * bins), bins - 1)] += 1
    return counts


def dial(cx, cy, counts, tightness, mean_fraction, top_label, bottom_label, delay):
    """Pink bars are the records around the cycle, the cream arrow is R-bar."""
    inner, reach = 58, 72
    peak = max(counts)
    step = 2 * math.pi / len(counts)
    bars = []
    for i, count in enumerate(counts):
        if not count:
            continue
        a0, a1 = i * step - math.pi / 2, (i + 1) * step - math.pi / 2
        outer = inner + reach * math.sqrt(count / peak)
        pts = [(math.cos(a0) * inner, math.sin(a0) * inner), (math.cos(a0) * outer, math.sin(a0) * outer),
               (math.cos(a1) * outer, math.sin(a1) * outer), (math.cos(a1) * inner, math.sin(a1) * inner)]
        bars.append("M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in pts) + " Z")
    angle = 2 * math.pi * mean_fraction - math.pi / 2
    length = tightness * 138
    ex, ey = math.cos(angle) * length, math.sin(angle) * length
    head_a, head_b = angle + 2.6, angle - 2.6
    head = f"M{ex + math.cos(head_a) * 14:.1f},{ey + math.sin(head_a) * 14:.1f} L{ex:.1f},{ey:.1f} L{ex + math.cos(head_b) * 14:.1f},{ey + math.sin(head_b) * 14:.1f}"
    return f"""
    <g transform="translate({cx},{cy})">
      <circle r="168" fill="url(#halo)"/>
      <circle r="150" fill="url(#sphere)" stroke="#ffffff" stroke-opacity=".55" stroke-width="2"/>
      <circle r="{inner}" fill="none" stroke="#ffffff" stroke-opacity=".22"/>
      <path d="{' '.join(bars)}" fill="{PINK}"/>
      <text y="-124" class="dial">{top_label}</text>
      <text y="136" class="dial">{bottom_label}</text>
      <g style="animation-delay:{delay}s" class="hand">
        <line x1="0" y1="0" x2="{ex:.1f}" y2="{ey:.1f}" stroke="{MOON}" stroke-width="6" stroke-linecap="round"/>
        <path d="{head}" fill="none" stroke="{MOON}" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>
      </g>
      <circle r="7" fill="{MOON}"/>
      <path d="M-118,-62 C-90,-140 90,-140 118,-62 C60,-104 -60,-104 -118,-62Z" fill="#ffffff" opacity=".2"/>
    </g>"""


def three_clocks():
    clocks = {r["clock"]: r for r in rows("outputs/tables/clock_summary.csv")}
    seasons = [float(r["days_from_peak"]) for r in rows("data/derived/reef_night_seasons.csv") if r.get("days_from_peak") not in ("", "NA", None)]
    nights = [float(r["lunar_day"]) for r in rows("data/derived/reef_nights.csv") if r["lunar_day"] not in ("", "NA")]
    starts = [float(r["hours_on_dial"]) for r in rows("data/derived/all_exact_starts.csv") if r["hours_on_dial"] not in ("", "NA")]

    def fraction(name):
        return float(clocks[name]["typical"]) / float(clocks[name]["period"])

    def r(name):
        return float(clocks[name]["tightness"])

    width, height = 1280, 560
    dials = [
        dial(213, 212, histogram(seasons, 365, 36), r("year"), fraction("year"), "warmest week", "half a year away", 0),
        dial(640, 212, histogram(nights, 29.53, 30), r("moon"), fraction("moon"), "full moon", "new moon", .5),
        dial(1067, 212, histogram(starts, 24, 48), r("sun"), fraction("sun"), "sunset", "12 hours later", 1),
    ]
    labels = [
        (213, "The year opens the season", f"{R_BAR} = {r('year'):.2f}", "89% of reef-nights fall while the local sea warms"),
        (640, "The Moon narrows the night", f"{R_BAR} = {r('moon'):.2f}", "88% in the tropics and 51% beyond them, in the eight days from full moon"),
        (1067, "The Sun sets the hour", f"{R_BAR} = {r('sun'):.2f}", "Half of all starts come 1.5 to 2.5 hours after sunset"),
    ]
    text = ""
    for x, head, value, note in labels:
        wrapped = wrap(note, 42)
        text += f'<text x="{x}" y="414" class="head">{head}</text><text x="{x}" y="456" class="value">{value}</text>'
        for i, line in enumerate(wrapped):
            text += f'<text x="{x}" y="{488 + i * 25}" class="note">{line}</text>'
    write("three_clocks.svg", f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" width="{width}" role="img" aria-labelledby="t d">
<title id="t">Three clocks on one scale</title>
<desc id="d">Three glass dials show recorded spawning around the year, the lunar month and the day. Pink bars count the records. A cream arrow shows the mean resultant length, R-bar: 0.72 for the year, 0.57 for the Moon and 0.90 for the Sun.</desc>
<defs>
<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0a7cd4"/><stop offset="1" stop-color="#053f8e"/></linearGradient>
<radialGradient id="sphere" cx=".5" cy=".36" r=".72"><stop offset="0" stop-color="#1383dd"/><stop offset=".72" stop-color="#084d9f"/><stop offset="1" stop-color="#042a66"/></radialGradient>
<radialGradient id="halo"><stop offset=".85" stop-color="#7fe8ff" stop-opacity=".35"/><stop offset="1" stop-color="#7fe8ff" stop-opacity="0"/></radialGradient>
<linearGradient id="gloss" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".3"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
</defs>
<style>
text{{font-family:{FONT};text-anchor:middle;fill:#fff}}
.dial{{font-size:15px;fill:#d7f4ff}}
.head{{font-size:26px;font-weight:600}}
.value{{font-size:30px;font-weight:300;fill:{MOON}}}
.note{{font-size:18px;fill:#d7f4ff}}
.hand{{animation:hand 12s ease-in-out infinite;transform-origin:0 0}}
@keyframes hand{{0%{{transform:scale(0);opacity:0}}16%{{transform:scale(1);opacity:1}}88%{{transform:scale(1);opacity:1}}100%{{transform:scale(0);opacity:0}}}}
@media (prefers-reduced-motion:reduce){{.hand{{animation:none}}}}
</style>
<rect width="{width}" height="{height}" rx="26" fill="url(#bg)"/>
<path d="M0,26 Q0,0 26,0 H{width - 26} Q{width},0 {width},26 V70 C900,120 380,120 0,76 Z" fill="url(#gloss)"/>
{''.join(dials)}
{text}
<rect x="1.5" y="1.5" width="{width - 3}" height="{height - 3}" rx="25" fill="none" stroke="#fff" stroke-opacity=".5" stroke-width="3"/>
</svg>""")


def wrap(text, limit):
    lines, line = [], ""
    for word in text.split():
        if len(line) + len(word) + 1 > limit:
            lines.append(line)
            line = word
        else:
            line = f"{line} {word}".strip()
    return lines + [line]


# Data reef -----------------------------------------------------------------

def node(x, y, name, how, amount):
    return f"""
    <g transform="translate({x},{y})">
      <rect x="-156" y="-52" width="312" height="104" rx="22" fill="url(#capsule)" stroke="#fff" stroke-opacity=".65" stroke-width="1.5"/>
      <path d="M-146,-30 Q-146,-44 -130,-44 H130 Q146,-44 146,-30 Q0,-6 -146,-30Z" fill="#fff" opacity=".2"/>
      <text y="-16" class="name">{name}</text><text y="10" class="how">{how}</text><text y="34" class="how">{amount}</text>
    </g>"""


def data_reef():
    width, height = 1280, 680
    hub_x, hub_y = 640, 340
    left = [(186, 150, "NOAA Coral Reef Watch", "214 regional files, bulk download", "22.9 million values"),
            (186, 340, "NASA/JPL Horizons", "API, queried once and saved", "12,897 Moon positions"),
            (186, 530, "US Naval Observatory", "API, one saved response", "7 reef-nights checked")]
    right = [(1094, 150, "Churaumi Aquarium", "Zenodo archive with zero days", "1,350 watched days"),
             (1094, 340, "Sea Simulator", "Table S1, read from a PDF in R", "172 timed records"),
             (1094, 530, "Maldives field study", "Journal supplement, one CSV", "81 spawning atoll-days")]
    keys = ["coordinates in a region polygon, then the date", "reef site and minute", "full-moon dates"]

    tubes, droplets, labels = "", "", ""
    for i, ((x, y, *_), key) in enumerate(zip(left, keys)):
        path = f"M{x + 156},{y} C{x + 290},{y} {hub_x - 240},{hub_y + (y - hub_y) * .35} {hub_x - 128},{hub_y + (y - hub_y) * .28}"
        tubes += f'<path id="k{i}" d="{path}" fill="none" stroke="#bff4ff" stroke-opacity=".85" stroke-width="5" stroke-linecap="round"/>'
        for n in range(3):
            droplets += (f'<circle r="6" fill="url(#drop)"><animateMotion dur="4.5s" begin="{-n * 1.5 - i * .4:.1f}s" repeatCount="indefinite"><mpath href="#k{i}"/></animateMotion></circle>')
        label_y = y - 44 if i == 0 else (y - 22 if i == 1 else y + 34)
        labels += f'<text x="{x + 182}" y="{label_y}" class="key" style="text-anchor:start">{wrap(key, 26)[0]}</text>'
        if len(wrap(key, 26)) > 1:
            labels += f'<text x="{x + 182}" y="{label_y + 19}" class="key" style="text-anchor:start">{wrap(key, 26)[1]}</text>'
    for i, (x, y, *_) in enumerate(right):
        path = f"M{x - 156},{y} C{x - 290},{y} {hub_x + 240},{hub_y + (y - hub_y) * .35} {hub_x + 128},{hub_y + (y - hub_y) * .28}"
        tubes += f'<path d="{path}" fill="none" stroke="#bff4ff" stroke-opacity=".6" stroke-width="3" stroke-dasharray="3 12" stroke-linecap="round"/>'

    nodes = "".join(node(*n) for n in left + right)
    write("data_reef.svg", f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" width="{width}" role="img" aria-labelledby="t d">
<title id="t">How the sources connect</title>
<desc id="d">The Coral Spawning Database is the hub. NOAA, NASA Horizons and the US Naval Observatory join it through real keys. The aquarium, the Sea Simulator and the Maldives study share no key with it and are compared side by side.</desc>
<defs>
<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0d8fe0"/><stop offset="1" stop-color="#053f8e"/></linearGradient>
<linearGradient id="capsule" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2aa7ee" stop-opacity=".92"/><stop offset="1" stop-color="#0a5cb4" stop-opacity=".92"/></linearGradient>
<radialGradient id="hub" cx=".42" cy=".3" r=".8"><stop offset="0" stop-color="#ffb3bc"/><stop offset=".6" stop-color="{PINK}"/><stop offset="1" stop-color="#c8355a"/></radialGradient>
<radialGradient id="drop" cx=".35" cy=".3" r=".8"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#7fe8ff"/></radialGradient>
<radialGradient id="halo"><stop offset=".8" stop-color="#ffb3bc" stop-opacity=".4"/><stop offset="1" stop-color="#ffb3bc" stop-opacity="0"/></radialGradient>
</defs>
<style>
text{{font-family:{FONT};text-anchor:middle;fill:#fff}}
.name{{font-size:21px;font-weight:600}} .how{{font-size:15.5px;fill:#e3f8ff}}
.key{{font-size:15px;fill:#fff;font-style:italic}}
.col{{font-size:21px;font-weight:600;fill:#d7f4ff}} .sub{{font-size:16px;fill:#d7f4ff}}
.hubname{{font-size:25px;font-weight:600;fill:#4a0d22}} .hubtext{{font-size:18px;fill:#4a0d22}}
.pulse{{animation:pulse 6s ease-in-out infinite;transform-origin:{hub_x}px {hub_y}px}}
@keyframes pulse{{0%,100%{{transform:scale(1)}}50%{{transform:scale(1.03)}}}}
@media (prefers-reduced-motion:reduce){{.pulse{{animation:none}}}}
</style>
<rect width="{width}" height="{height}" rx="26" fill="url(#bg)"/>
<text x="186" y="62" class="col">Joined by a real key</text>
<text x="1094" y="62" class="col">Side by side, no shared key</text>
{tubes}{droplets}{labels}
<g class="pulse"><circle cx="{hub_x}" cy="{hub_y}" r="160" fill="url(#halo)"/>
<circle cx="{hub_x}" cy="{hub_y}" r="128" fill="url(#hub)" stroke="#fff" stroke-opacity=".8" stroke-width="2"/>
<path d="M{hub_x - 100},{hub_y - 50} C{hub_x - 76},{hub_y - 118} {hub_x + 76},{hub_y - 118} {hub_x + 100},{hub_y - 50} C{hub_x + 50},{hub_y - 88} {hub_x - 50},{hub_y - 88} {hub_x - 100},{hub_y - 50}Z" fill="#fff" opacity=".42"/>
<text x="{hub_x}" y="{hub_y - 16}" class="hubname">Coral Spawning</text><text x="{hub_x}" y="{hub_y + 14}" class="hubname">Database</text>
<text x="{hub_x}" y="{hub_y + 46}" class="hubtext">6,178 records</text><text x="{hub_x}" y="{hub_y + 70}" class="hubtext">1,026 reef-nights</text></g>
{nodes}
<text x="{hub_x}" y="640" class="sub">Every source is a saved copy in data/raw, so a run needs no live service</text>
<rect x="1.5" y="1.5" width="{width - 3}" height="{height - 3}" rx="25" fill="none" stroke="#fff" stroke-opacity=".5" stroke-width="3"/>
</svg>""")


# Gel buttons, icons, logo plate --------------------------------------------

def button(name, label, width, top, bottom, ink="#ffffff"):
    height = 52
    write(name, f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" width="{width}" height="{height}" role="img" aria-label="{label}">
<defs>
<linearGradient id="b" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{top}"/><stop offset="1" stop-color="{bottom}"/></linearGradient>
<linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".78"/><stop offset="1" stop-color="#fff" stop-opacity=".1"/></linearGradient>
<linearGradient id="s" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset=".5" stop-color="#fff" stop-opacity=".6"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
<clipPath id="c"><rect x="2" y="2" width="{width - 4}" height="{height - 4}" rx="24"/></clipPath>
</defs>
<style>.shine{{animation:shine 8s ease-in-out infinite}}@keyframes shine{{0%,72%{{transform:translateX(-80px)}}100%{{transform:translateX({width + 80}px)}}}}@media (prefers-reduced-motion:reduce){{.shine{{animation:none;opacity:0}}}}</style>
<rect x="2" y="2" width="{width - 4}" height="{height - 4}" rx="24" fill="url(#b)" stroke="#ffffff" stroke-opacity=".7" stroke-width="1.5"/>
<g clip-path="url(#c)"><path d="M8,6 H{width - 8} Q{width - 4},6 {width - 4},12 Q{width / 2},30 4,12 Q4,6 8,6Z" fill="url(#g)"/><rect class="shine" y="0" width="60" height="{height}" fill="url(#s)"/></g>
<text x="{width / 2}" y="33" text-anchor="middle" fill="{ink}" font-family="{FONT.replace(chr(39), '&apos;')}" font-size="18" font-weight="600">{label}</text>
</svg>""")


ICONS = {
    # one record per night: many marks collapse into one
    "unit": '<circle cx="26" cy="30" r="3.4"/><circle cx="26" cy="42" r="3.4"/><circle cx="37" cy="24" r="3.4"/><circle cx="37" cy="48" r="3.4"/><path d="M44,36 h8" fill="none" stroke="#fff" stroke-width="3.4" stroke-linecap="round"/><circle cx="58" cy="36" r="6"/>',
    # a cycle has no start or end
    "circle": '<path d="M52,24 A20,20 0 1 0 56,38" fill="none" stroke="#fff" stroke-width="4.4" stroke-linecap="round"/><path d="M45,23 L53,23 L53,15" fill="none" stroke="#fff" stroke-width="4.4" stroke-linecap="round" stroke-linejoin="round"/>',
    # each region's own temperature year
    "year": '<path d="M14,44 C24,16 34,16 40,36 C46,56 56,56 62,28" fill="none" stroke="#fff" stroke-width="4.4" stroke-linecap="round"/>',
    # one hub, real keys only
    "hub": '<circle cx="38" cy="36" r="8"/><circle cx="18" cy="20" r="4.4"/><circle cx="60" cy="22" r="4.4"/><circle cx="20" cy="54" r="4.4"/><path d="M21,23 L33,32 M57,24 L44,32 M23,51 L33,41" stroke="#fff" stroke-width="3.2" stroke-linecap="round"/>',
    # absence recorded as zero
    "zero": '<ellipse cx="38" cy="36" rx="14" ry="19" fill="none" stroke="#fff" stroke-width="5"/>',
    # try to break the result
    "break": '<path d="M16,26 H28 C38,26 38,46 48,46 H60 M16,46 H28 C33,46 34,41 36,38 M42,31 C44,28 45,26 50,26 H60" fill="none" stroke="#fff" stroke-width="4" stroke-linecap="round"/><path d="M54,20 L61,26 L54,32 M54,40 L61,46 L54,52" fill="none" stroke="#fff" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>',
    # frozen, hashed sources
    "frozen": '<rect x="24" y="33" width="28" height="22" rx="4"/><path d="M29,33 V26 C29,14 47,14 47,26 V33" fill="none" stroke="#fff" stroke-width="4.4"/>',
    # hold the calendar still, change the heat
    "fixed": '<rect x="20" y="22" width="36" height="32" rx="5" fill="none" stroke="#fff" stroke-width="4"/><path d="M20,32 H56 M30,16 V26 M46,16 V26" stroke="#fff" stroke-width="4" stroke-linecap="round"/><circle cx="38" cy="43" r="4.6"/>',
}


def icons():
    for name, inner in ICONS.items():
        write(f"icon_{name}.svg", f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 76 76" width="76" height="76" role="img" aria-hidden="true">
<defs><radialGradient id="o" cx=".42" cy=".3" r=".78"><stop offset="0" stop-color="#7fe8ff"/><stop offset=".55" stop-color="#1596e6"/><stop offset="1" stop-color="#074a9e"/></radialGradient>
<linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".8"/><stop offset="1" stop-color="#fff" stop-opacity=".05"/></linearGradient></defs>
<circle cx="38" cy="38" r="36" fill="url(#o)" stroke="#fff" stroke-opacity=".75" stroke-width="1.5"/>
<g fill="#fff">{inner}</g>
<path d="M14,26 C20,6 56,6 62,26 C50,16 26,16 14,26Z" fill="url(#g)"/>
</svg>""")


def fhnw_plate():
    logo = (ASSETS / "fhnw-logo-en.svg").read_text(encoding="utf-8")
    inner = re.search(r"<svg[^>]*>(.*)</svg>", logo, re.S).group(1)
    write("fhnw_plate.svg", f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 460 104" width="460" height="104" role="img" aria-label="University of Applied Sciences and Arts Northwestern Switzerland FHNW">
<defs><linearGradient id="p" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffffff"/><stop offset="1" stop-color="#e6f8ff"/></linearGradient></defs>
<rect x="1.5" y="1.5" width="457" height="101" rx="24" fill="url(#p)" stroke="#7fe8ff" stroke-width="2"/>
<svg x="46" y="27" width="368" height="50" viewBox="732 401 349 50">{inner}</svg>
</svg>""")


# Dividers and footer ---------------------------------------------------------

_reef = {}


def reef_image():
    if "image" not in _reef:
        _reef["image"] = render_svg(hero.reef_layer([]), 1280, 620, scale=1.5, transparent=True)
    return _reef["image"]


def seabed():
    """The reef again at the very end of the page, on a transparent background."""
    reef = reef_image()
    top = 236
    uri = data_uri(reef.crop((0, int(top * 1.5), reef.width, reef.height)), quality=74)
    height = 620 - top
    weed = "".join([
        hero.kelp(18, height - 4, 250, 13, 26, 7.5, "kelpA", 1), hero.kelp(46, height - 2, 186, 11, 22, 6.2, "kelpB", 2),
        hero.kelp(1264, height - 2, 270, 13, 28, 8, "kelpA", 4), hero.kelp(1236, height - 2, 196, 11, 22, 6.6, "kelpB", 5),
        hero.kelp(690, height - 16, 92, 9, 14, 5.6, "kelpB", 9), hero.kelp(816, height - 14, 116, 9, 15, 6, "kelpA", 10)])
    write("seabed.svg", f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1280 {height}" width="1280" role="img" aria-label="A strip of sand, coral and swaying seaweed">
<defs>
<linearGradient id="kelpA" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="#056b3f"/><stop offset=".6" stop-color="#12ad62"/><stop offset="1" stop-color="#7ff0a8"/></linearGradient>
<linearGradient id="kelpB" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="#0a7a4a"/><stop offset=".6" stop-color="#2fd17a"/><stop offset="1" stop-color="#c4ff9c"/></linearGradient>
</defs>
<image href="{uri}" width="1280" height="{height}"/>
{weed}
</svg>""")


def water_band(name, seed):
    """A section break: a band of moving water with bubbles rising through it."""
    width, height = 1280, 84
    r = random.Random(seed)
    specks = ""
    for x in [r.uniform(60, 1220) for _ in range(11)]:
        size = r.uniform(2.4, 6.5)
        seconds = r.uniform(5, 9)
        specks += (f'<circle cx="{x:.0f}" cy="{height - 8}" r="{size:.1f}" fill="url(#bubble)" stroke="#7fe8ff" stroke-opacity=".8" stroke-width=".8" '
                   f'style="animation:up {seconds:.1f}s ease-in {-r.uniform(0, seconds):.1f}s infinite"/>')
    length = 80
    wave = "".join(f"q{length / 2},{7 if i % 2 == 0 else -7} {length},0 " for i in range(22))
    write(name, f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" width="{width}" role="presentation" aria-hidden="true">
<defs>
<radialGradient id="bubble" cx=".34" cy=".3" r=".78"><stop offset="0" stop-color="#ffffff" stop-opacity=".95"/><stop offset=".35" stop-color="#bff4ff" stop-opacity=".3"/><stop offset="1" stop-color="#27c2f0" stop-opacity=".5"/></radialGradient>
<linearGradient id="w" x1="0" y1="0" x2="0" y2="1"><stop offset=".15" stop-color="#27b4ee"/><stop offset="1" stop-color="#0a7fd6" stop-opacity="0"/></linearGradient>
<linearGradient id="mg" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000"/><stop offset=".08" stop-color="#fff"/><stop offset=".92" stop-color="#fff"/><stop offset="1" stop-color="#000"/></linearGradient>
<mask id="m"><rect width="{width}" height="{height}" fill="url(#mg)"/></mask>
</defs>
<style>.w{{animation:w 11s linear infinite}}
@keyframes w{{to{{transform:translateX(160px)}}}}
@keyframes up{{0%{{transform:translateY(0);opacity:0}}18%{{opacity:1}}100%{{transform:translateY(-66px);opacity:0}}}}
@media (prefers-reduced-motion:reduce){{*{{animation:none!important}}}}</style>
<g mask="url(#m)"><path class="w" d="M-160,{height - 40} {wave} V{height} H-160 Z" fill="url(#w)" opacity=".85"/></g>
{specks}
</svg>""")


def values_chart():
    """Every bubble is drawn to one scale, so the area shows the number of values."""
    sources = [("Coral Spawning Database", 170314, "0.74%"), ("Churaumi Aquarium", 68369, "0.30%"),
               ("NASA/JPL Horizons", 12897, "0.06%"), ("Sea Simulator", 1032, "&lt;0.01%"), ("Maldives study", 972, "&lt;0.01%")]
    noaa, total = 22877449, 23131033
    assert noaa + sum(v for _, v, _ in sources) == total
    width, height, big = 1280, 560, 226
    rows = ""
    for i, (name, value, share) in enumerate(sources):
        y = 150 + i * 68
        radius = big * math.sqrt(value / noaa)
        fill = "url(#coral)" if i == 0 else "#d7f7ff"
        rows += (f'<circle cx="668" cy="{y}" r="{radius:.2f}" fill="{fill}"/>'
                 f'<text x="716" y="{y + 7}" class="row">{name}</text>'
                 f'<text x="1110" y="{y + 7}" class="num">{value:,}</text>'
                 f'<text x="1228" y="{y + 7}" class="num">{share}</text>')
        if i < 4:
            rows += f'<line x1="630" x2="1228" y1="{y + 34}" y2="{y + 34}" stroke="#fff" stroke-opacity=".14"/>'
    write("values_chart.svg", f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" width="{width}" role="img" aria-labelledby="t d">
<title id="t">Where the 23.1 million values come from</title>
<desc id="d">Bubbles drawn to one scale. NOAA Coral Reef Watch has 22,877,449 values, 98.90 percent. The Coral Spawning Database has 170,314, the Churaumi Aquarium 68,369, NASA/JPL Horizons 12,897, the Sea Simulator 1,032 and the Maldives study 972. The total is 23,131,033.</desc>
<defs>
<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0a7cd4"/><stop offset="1" stop-color="#053f8e"/></linearGradient>
<radialGradient id="noaa" cx=".42" cy=".3" r=".82"><stop offset="0" stop-color="#57dcf9"/><stop offset=".6" stop-color="#1596e6"/><stop offset="1" stop-color="#0a5cb4"/></radialGradient>
<radialGradient id="coral" cx=".38" cy=".3" r=".8"><stop offset="0" stop-color="#ffc4cc"/><stop offset="1" stop-color="{PINK}"/></radialGradient>
<linearGradient id="gloss" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".6"/><stop offset="1" stop-color="#fff" stop-opacity=".02"/></linearGradient>
<linearGradient id="top" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".26"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
</defs>
<style>
text{{font-family:{FONT};fill:#fff}}
.row{{font-size:23px}} .num{{font-size:23px;text-anchor:end;font-variant-numeric:tabular-nums}}
.col{{font-size:17px;fill:#d7f4ff;text-anchor:end}} .side{{font-size:17px;fill:#d7f4ff}}
.big{{text-anchor:middle}} .name{{font-size:27px;font-weight:600}} .value{{font-size:48px;font-weight:300}} .share{{font-size:22px;fill:#e3f8ff}}
.total{{font-size:23px;font-weight:600}} .totalnum{{font-size:23px;font-weight:600;text-anchor:end;font-variant-numeric:tabular-nums}}
</style>
<rect width="{width}" height="{height}" rx="26" fill="url(#bg)"/>
<path d="M0,26 Q0,0 26,0 H{width - 26} Q{width},0 {width},26 V62 C900,104 380,104 0,68 Z" fill="url(#top)"/>
<circle cx="300" cy="280" r="{big}" fill="url(#noaa)" stroke="#fff" stroke-opacity=".7" stroke-width="2"/>
<path d="M126,216 C176,84 424,84 474,216 C400,150 200,150 126,216Z" fill="url(#gloss)"/>
<text x="300" y="256" class="big name">NOAA Coral Reef Watch</text>
<text x="300" y="312" class="big value">22,877,449</text>
<text x="300" y="350" class="big share">98.90% of all values</text>
<text x="630" y="92" class="side">Bubble area shows the number of values</text>
<text x="1110" y="92" class="col">Values</text><text x="1228" y="92" class="col">Share</text>
{rows}
<line x1="630" x2="1228" y1="470" y2="470" stroke="#fff" stroke-opacity=".5"/>
<text x="630" y="506" class="total">Total</text><text x="1110" y="506" class="totalnum">{total:,}</text><text x="1228" y="506" class="totalnum">100%</text>
<rect x="1.5" y="1.5" width="{width - 3}" height="{height - 3}" rx="25" fill="none" stroke="#fff" stroke-opacity=".5" stroke-width="3"/>
</svg>""")


def project_map():
    """Three folders in the order the data flows through them."""
    width, height = 1280, 470
    columns = [
        (40, "data/", "What goes in", [("raw/", "original files, unchanged"), ("derived/", "joined data and results"), ("spatial/", "Shapefiles for GIS")]),
        (460, "R/", "What happens", [("prepare_*.R", "read, join, build the sky"), ("analyse_*.R", "clocks, genera, heat"), ("fit_aquarium_models.R", "whole years held out"), ("check_*.R", "totals and exports"), ("plots/", "one script per plot")]),
        (880, "outputs/", "What comes out", [("figures/", "PNGs at 300 dpi"), ("vector/", "SVG copies"), ("tables/", "plot values, diagnostics"), ("models/", "fitted models"), ("RESULTS.md", "the findings in words")]),
    ]
    cards = ""
    for x, name, role, items in columns:
        lines = ""
        for i, (path, note) in enumerate(items):
            y = 128 + i * 46
            lines += f'<text x="{x + 26}" y="{y}" class="path">{path}</text><text x="{x + 26}" y="{y + 20}" class="note">{note}</text>'
        cards += (f'<rect x="{x}" y="28" width="360" height="346" rx="22" fill="url(#card)" stroke="#fff" stroke-opacity=".55" stroke-width="1.5"/>'
                  f'<path d="M{x + 10},52 Q{x + 10},38 {x + 26},38 H{x + 334} Q{x + 350},38 {x + 350},52 Q{x + 180},78 {x + 10},52Z" fill="#fff" opacity=".16"/>'
                  f'<text x="{x + 26}" y="70" class="folder">{name}</text><text x="{x + 334}" y="70" class="role">{role}</text>{lines}')
    tubes, droplets = "", ""
    for i, (x1, x2) in enumerate([(400, 460), (820, 880)]):
        tubes += f'<path id="t{i}" d="M{x1},200 H{x2}" stroke="#bff4ff" stroke-width="6" stroke-linecap="round"/>'
        droplets += "".join(f'<circle r="5" fill="#fff"><animateMotion dur="2.6s" begin="{-n * 1.3:.1f}s" repeatCount="indefinite"><mpath href="#t{i}"/></animateMotion></circle>' for n in range(2))
    pills = ""
    for x, w, path, note in [(40, 290, "run.R", "runs everything"), (350, 290, "setup.R", "installs packages"), (660, 280, "docs/", "methods, checks"), (960, 280, "tools/", "downloads, artwork")]:
        pills += (f'<rect x="{x}" y="394" width="{w}" height="50" rx="25" fill="#fff" fill-opacity=".14" stroke="#fff" stroke-opacity=".45"/>'
                  f'<text x="{x + 24}" y="425" class="pillpath">{path}</text><text x="{x + w - 22}" y="425" class="pillnote">{note}</text>')
    write("project_map.svg", f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" width="{width}" role="img" aria-labelledby="t d">
<title id="t">How the project is organised</title>
<desc id="d">Data flows from the data folder through the R scripts into the outputs folder. run.R runs everything, setup.R installs packages, docs holds methods and checks, tools holds downloads and artwork.</desc>
<defs><linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0a7cd4"/><stop offset="1" stop-color="#053f8e"/></linearGradient>
<linearGradient id="card" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2aa7ee" stop-opacity=".6"/><stop offset="1" stop-color="#0a5cb4" stop-opacity=".6"/></linearGradient></defs>
<style>text{{font-family:{FONT};fill:#fff}}
.folder{{font-family:{MONO};font-size:27px;font-weight:600}} .role{{font-size:16px;fill:#d7f4ff;text-anchor:end}}
.path{{font-family:{MONO};font-size:18px}} .note{{font-size:15.5px;fill:#d7f4ff}}
.pillpath{{font-family:{MONO};font-size:18px;font-weight:600}} .pillnote{{font-size:15.5px;fill:#e3f8ff;text-anchor:end}}</style>
<rect width="{width}" height="{height}" rx="26" fill="url(#bg)"/>
{tubes}{cards}{droplets}{pills}
<rect x="1.5" y="1.5" width="{width - 3}" height="{height - 3}" rx="25" fill="none" stroke="#fff" stroke-opacity=".5" stroke-width="3"/>
</svg>""")


# Plot previews and social card ------------------------------------------------

def plot_previews():
    target = ASSETS / "plots"
    target.mkdir(exist_ok=True)
    for source in sorted((ROOT / "outputs" / "figures").glob("*.png")):
        image = Image.open(source).convert("RGB")
        width = 1400
        image = image.resize((width, round(image.height * width / image.width)), Image.LANCZOS).convert("RGBA")
        scale = 3
        mask = Image.new("L", (image.width * scale, image.height * scale), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, mask.width - 1, mask.height - 1), 26 * scale, fill=255)
        image.putalpha(mask.resize(image.size, Image.LANCZOS))
        ring = Image.new("RGBA", (image.width * scale, image.height * scale), (0, 0, 0, 0))
        ImageDraw.Draw(ring).rounded_rectangle((2, 2, ring.width - 3, ring.height - 3), 26 * scale, outline=(127, 232, 255, 200), width=4 * scale)
        image.alpha_composite(ring.resize(image.size, Image.LANCZOS))
        image.save(target / (source.stem + ".webp"), "WEBP", quality=84, method=6)


def social_card():
    svg = (ASSETS / "hero.svg").read_text(encoding="utf-8")
    with sync_playwright() as p:
        browser = p.chromium.launch(channel="msedge", headless=True)
        page = browser.new_page(viewport={"width": 1280, "height": 640})
        page.set_content('<!doctype html><html><body style="margin:0;overflow:hidden;background:#075bb0"><div style="width:1324px;margin-left:-22px;margin-top:-2px">'
                         + svg.replace('width="1280" role="img"', 'width="1324" role="img"', 1) + "</div></body></html>")
        page.wait_for_timeout(500)
        page.evaluate("() => { for (const a of document.getAnimations()) { a.pause(); a.currentTime = 4800; } }")
        page.wait_for_timeout(200)
        page.screenshot(path=str(ASSETS / "social_preview.jpg"), type="jpeg", quality=90)
        browser.close()


def build():
    three_clocks()
    data_reef()
    button("btn_deck.svg", "Final presentation", 230, "#ff9aa5", "#e0476b")
    button("btn_findings.svg", "Findings", 150, "#4fd4f7", "#0a7fd6")
    button("btn_guide.svg", "How to read the plots", 250, "#4fd4f7", "#0a7fd6")
    button("btn_methods.svg", "Methods", 150, "#4fd4f7", "#0a7fd6")
    button("btn_checks.svg", "Validation", 160, "#4fd4f7", "#0a7fd6")
    icons()
    fhnw_plate()
    water_band("band_a.svg", 1)
    water_band("band_b.svg", 21)
    values_chart()
    project_map()
    seabed()
    plot_previews()
    social_card()
    print("panels built")


if __name__ == "__main__":
    build()
