"""Builds docs/assets/hero.svg, the animated aquarium at the top of the README.

The still parts (water, reef, sand, title) are drawn as SVG with heavy lighting
filters, rendered once in a headless browser and embedded as WebP. Only the
living parts stay as vector animation, so the file stays light in a README.

One loop is one night on the reef and follows the project's findings:
day, sunset, a dark gap, spawning about two hours after sunset, then a late
moonrise and dawn.
"""
import math
import random
from base64 import b64encode

from common import ASSETS, data_uri, render_html, render_svg

W, H = 1280, 620
LOOP = 32  # seconds for one day and night

BEVEL = """
<filter id="bevel" x="-8%" y="-8%" width="116%" height="116%" color-interpolation-filters="sRGB">
  <feGaussianBlur in="SourceAlpha" stdDeviation="3" result="b"/>
  <feTurbulence type="fractalNoise" baseFrequency=".85" numOctaves="1" seed="5" result="n"/>
  <feColorMatrix in="n" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  .9 0 0 0 0" result="na"/>
  <feComposite in="b" in2="na" operator="arithmetic" k1="0" k2="1" k3=".1" k4="-.04" result="bump"/>
  <feSpecularLighting in="bump" surfaceScale="8" specularConstant=".95" specularExponent="26" lighting-color="#ffffff" result="s">
    <feDistantLight azimuth="240" elevation="48"/>
  </feSpecularLighting>
  <feComposite in="s" in2="SourceAlpha" operator="in" result="s2"/>
  <feDiffuseLighting in="bump" surfaceScale="8" diffuseConstant="1.12" lighting-color="#ffffff" result="d">
    <feDistantLight azimuth="240" elevation="56"/>
  </feDiffuseLighting>
  <feComposite in="SourceGraphic" in2="d" operator="arithmetic" k1="1" k2=".1" k3="0" k4="0" result="lit"/>
  <feComposite in="lit" in2="s2" operator="arithmetic" k1="0" k2="1" k3=".8" k4="0" result="shine"/>
  <feFlood flood-color="#0a64c8" flood-opacity=".08" result="tint"/>
  <feComposite in="tint" in2="shine" operator="atop" result="tinted"/>
  <feMerge result="m"><feMergeNode in="shine"/><feMergeNode in="tinted"/></feMerge>
  <feComposite in="m" in2="SourceAlpha" operator="in"/>
</filter>
"""


def poly(points):
    return "M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in points)


def staghorn(x, y, s, deep, mid, tip, seed, branches=7, spread=1.0, tips_out=None):
    """A branching Acropora colony, the genus at the centre of the project."""
    r = random.Random(seed)
    segments, tips = [], []

    def grow(px, py, angle, length, width, depth):
        points = [(px, py)]
        for _ in range(3):
            angle += r.uniform(-0.16, 0.16)
            px += math.sin(angle) * length / 3
            py -= math.cos(angle) * length / 3
            points.append((px, py))
        segments.append((points, width))
        if depth > 0:
            for _ in range(r.choice([2, 2, 3])):
                grow(px, py, angle + r.uniform(-0.8, 0.8) * spread,
                     length * r.uniform(0.62, 0.84), width * 0.74, depth - 1)
        else:
            tips.append((px, py, width))

    for i in range(branches):
        start = (i - (branches - 1) / 2) * 0.30 * spread + r.uniform(-0.08, 0.08)
        grow(x + r.uniform(-16, 16) * s, y, start, r.uniform(58, 90) * s, r.uniform(11, 15) * s, 3)

    top = min(py for points, _ in segments for _, py in points)
    uid = f"st{seed}"
    out = [f'<linearGradient id="{uid}" gradientUnits="userSpaceOnUse" x1="0" y1="{y}" x2="0" y2="{top:.0f}">'
           f'<stop offset="0" stop-color="{deep}"/><stop offset=".55" stop-color="{mid}"/><stop offset="1" stop-color="{tip}"/></linearGradient>',
           f'<g fill="none" stroke="url(#{uid})" stroke-linecap="round" stroke-linejoin="round">']
    out += [f'<path d="{poly(p)}" stroke-width="{w:.1f}"/>' for p, w in segments]
    out.append("</g>")
    out += [f'<circle cx="{px:.1f}" cy="{py:.1f}" r="{max(w * 0.62, 2):.1f}" fill="{tip}"/>' for px, py, w in tips]
    if tips_out is not None:
        tips_out.extend((px, py) for px, py, _ in tips)
    return "".join(out)


def table_coral(x, y, s, deep, mid, light, seed):
    """A flat table coral on a short stem."""
    r = random.Random(seed)
    out = [f'<path d="M{x - 13 * s},{y} Q{x - 7 * s},{y - 42 * s} {x - 4 * s},{y - 70 * s} L{x + 6 * s},{y - 70 * s} Q{x + 9 * s},{y - 42 * s} {x + 15 * s},{y} Z" fill="{deep}"/>']
    for level, (rx, ry, dy, colour) in enumerate([(124, 24, 62, deep), (116, 20, 72, mid), (96, 14, 80, light)]):
        points = []
        for i in range(44):
            a = 2 * math.pi * i / 44
            bump = 1 + r.uniform(-0.05, 0.05)
            points.append((x + math.cos(a) * rx * s * bump, y - dy * s + math.sin(a) * ry * s * bump))
        out.append(f'<path d="{poly(points)} Z" fill="{colour}"/>')
    for _ in range(46):
        a = r.uniform(0, 2 * math.pi)
        d = r.uniform(0.15, 0.98)
        out.append(f'<circle cx="{x + math.cos(a) * 104 * s * d:.1f}" cy="{y - 76 * s + math.sin(a) * 16 * s * d:.1f}" r="{r.uniform(1.6, 3.2) * s:.1f}" fill="{light}"/>')
    return "".join(out)


def brain_coral(x, y, s, deep, mid, seed, uid):
    """A dome with meandering ridges, like Platygyra."""
    r = random.Random(seed)
    rx, ry = 92 * s, 70 * s
    dome = f"M{x - rx},{y} C{x - rx},{y - ry * 1.32} {x + rx},{y - ry * 1.32} {x + rx},{y} Z"
    out = [f'<clipPath id="{uid}"><path d="{dome}"/></clipPath>',
           f'<radialGradient id="{uid}g" cx=".4" cy=".2" r=".9"><stop offset="0" stop-color="#ffffff" stop-opacity=".55"/><stop offset=".5" stop-color="{mid}" stop-opacity="0"/><stop offset="1" stop-color="{deep}" stop-opacity=".85"/></radialGradient>',
           f'<path d="{dome}" fill="{mid}"/>',
           f'<g clip-path="url(#{uid})" fill="none" stroke="{deep}" stroke-width="{3.8 * s:.1f}" stroke-linecap="round">']
    row = y - ry * 1.05
    while row < y + 4:
        points, px = [], x - rx - 10
        phase = r.uniform(0, 6.28)
        while px < x + rx + 10:
            points.append((px, row + 6 * s * math.sin(px * 0.075 / s + phase) + r.uniform(-1.2, 1.2)))
            px += 7 * s
        out.append(f'<path d="{poly(points)}"/>')
        row += 10 * s
    out.append("</g>")
    out.append(f'<path d="{dome}" fill="url(#{uid}g)"/>')
    return "".join(out)


def sea_fan(x, y, s, colour, seed):
    """A gorgonian fan, branching thinly in one plane."""
    r = random.Random(seed)
    out = [f'<g fill="none" stroke="{colour}" stroke-linecap="round">']

    def grow(px, py, angle, length, width, depth):
        points = [(px, py)]
        for _ in range(3):
            angle += r.uniform(-0.12, 0.12)
            px += math.sin(angle) * length / 3
            py -= math.cos(angle) * length / 3
            points.append((px, py))
        out.append(f'<path d="{poly(points)}" stroke-width="{width:.1f}"/>')
        if depth > 0:
            grow(px, py, angle - r.uniform(0.18, 0.42), length * 0.84, width * 0.78, depth - 1)
            grow(px, py, angle + r.uniform(0.18, 0.42), length * 0.84, width * 0.78, depth - 1)

    for start in (-0.55, 0, 0.55):
        grow(x, y, start, 52 * s, 5 * s, 5)
    out.append("</g>")
    return "".join(out)


def sponges(x, y, s, deep, mid, light, dark, seed):
    """A cluster of tube sponges, shaded like cylinders."""
    r = random.Random(seed)
    uid = f"sp{seed}"
    out = [f'<linearGradient id="{uid}"><stop offset="0" stop-color="{deep}"/><stop offset=".32" stop-color="{mid}"/>'
           f'<stop offset=".5" stop-color="{light}"/><stop offset=".74" stop-color="{mid}"/><stop offset="1" stop-color="{deep}"/></linearGradient>']
    for i in [0, 4, 1, 3, 2]:
        cx = x + (i - 2) * 27 * s + r.uniform(-3, 3)
        height = (r.uniform(112, 142) if i == 2 else r.uniform(64, 108)) * s
        width = r.uniform(11, 14) * s
        lean = (i - 2) * 8 * s
        top = y - height
        out.append(f'<path d="M{cx - width * .72:.1f},{y + 8} C{cx - width * .8:.1f},{y - height * .45:.1f} {cx - width * 1.18 + lean:.1f},{top + height * .22:.1f} {cx - width * 1.12 + lean:.1f},{top:.1f} '
                   f'L{cx + width * 1.12 + lean:.1f},{top:.1f} C{cx + width * 1.18 + lean:.1f},{top + height * .22:.1f} {cx + width * .8:.1f},{y - height * .45:.1f} {cx + width * .72:.1f},{y + 8} Z" fill="url(#{uid})"/>')
        out.append(f'<ellipse cx="{cx + lean:.1f}" cy="{top:.1f}" rx="{width * 1.12:.1f}" ry="{width * .46:.1f}" fill="{light}"/>')
        out.append(f'<ellipse cx="{cx + lean:.1f}" cy="{top + 1:.1f}" rx="{width * .76:.1f}" ry="{width * .28:.1f}" fill="{dark}"/>')
    return "".join(out)


def anemone(x, y, s, base, tip, seed):
    """A soft cushion of tentacles."""
    r = random.Random(seed)
    out = ['<g fill="none" stroke-linecap="round">']
    for i in range(34):
        a = -1.25 + 2.5 * i / 33 + r.uniform(-0.05, 0.05)
        length = r.uniform(38, 62) * s
        ex, ey = x + math.sin(a) * length, y - math.cos(a) * length
        mx, my = x + math.sin(a * 0.5) * length * 0.6, y - math.cos(a * 0.5) * length * 0.7
        out.append(f'<path d="M{x},{y} Q{mx:.1f},{my:.1f} {ex:.1f},{ey:.1f}" stroke="{base}" stroke-width="{5.2 * s:.1f}"/>')
        out.append(f'<circle cx="{ex:.1f}" cy="{ey:.1f}" r="{3.3 * s:.1f}" fill="{tip}" stroke="none"/>')
    out.append("</g>")
    return "".join(out)


def rock(x, y, rx, ry, colour, seed):
    r = random.Random(seed)
    points = []
    for i in range(16):
        a = math.pi + math.pi * i / 15
        bump = r.uniform(0.86, 1.1)
        points.append((x + math.cos(a) * rx * bump, y + math.sin(a) * ry * bump))
    return f'<path d="{poly(points)} L{x + rx},{y + 26} L{x - rx},{y + 26} Z" fill="{colour}"/>'


def ridge(base, amplitude, seed, step=26):
    r = random.Random(seed)
    points, x = [(0, H)], -10
    while x < W + 30:
        points.append((x, base - abs(math.sin(x * 0.006 + seed)) * amplitude - r.uniform(0, amplitude * 0.45)))
        x += step
    points.append((W, H))
    return poly(points) + " Z"


def water_layer():
    """The opaque back of the tank: water, haze, distant reef and soft bokeh."""
    r = random.Random(3)
    bokeh = "".join(
        f'<circle cx="{r.uniform(0, W):.0f}" cy="{r.uniform(40, 430):.0f}" r="{r.uniform(5, 26):.0f}" fill="#ffffff" opacity="{r.uniform(.04, .16):.2f}"/>'
        for _ in range(46))
    back = random.Random(5)
    far_coral = "".join(
        staghorn(x, 505, sc, "#1a78c9", "#2b93dc", "#58b8ec", seed, branches=5)
        for x, sc, seed in [(110, 1.0, 21), (370, .75, 22), (560, .6, 23), (760, .62, 24), (965, .8, 25), (1190, 1.05, 26)])
    return f"""
    <svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
      <defs>
        <linearGradient id="w" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stop-color="#a6f1ff"/><stop offset=".1" stop-color="#57dcf9"/>
          <stop offset=".34" stop-color="#17aeea"/><stop offset=".7" stop-color="#0a7cd4"/>
          <stop offset="1" stop-color="#0757ac"/>
        </linearGradient>
        <radialGradient id="g" cx=".5" cy="-.05" r=".85">
          <stop offset="0" stop-color="#ffffff" stop-opacity=".7"/><stop offset=".5" stop-color="#ffffff" stop-opacity=".1"/>
          <stop offset="1" stop-color="#ffffff" stop-opacity="0"/>
        </radialGradient>
        <linearGradient id="fade" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#000"/></linearGradient>
        <mask id="top"><rect width="{W}" height="420" fill="url(#fade)"/></mask>
        <filter id="soft"><feGaussianBlur stdDeviation="5"/></filter>
        <filter id="softer"><feGaussianBlur stdDeviation="2.4"/></filter>
        <filter id="bok"><feGaussianBlur stdDeviation="1.6"/></filter>
        <filter id="caust" x="0" y="0" width="100%" height="100%">
          <feTurbulence type="turbulence" baseFrequency=".011 .024" numOctaves="2" seed="4"/>
          <feColorMatrix values="0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  3.4 0 0 0 -.62"/>
        </filter>
      </defs>
      <rect width="{W}" height="{H}" fill="url(#w)"/>
      <rect width="{W}" height="{H}" fill="url(#g)"/>
      <g mask="url(#top)"><rect width="{W}" height="420" filter="url(#caust)" opacity=".22"/></g>
      <g filter="url(#bok)">{bokeh}</g>
      <path d="{ridge(470, 80, 2)}" fill="#1a8fdf" opacity=".55" filter="url(#soft)"/>
      <path d="{ridge(505, 62, 4)}" fill="#1079cf" opacity=".65" filter="url(#soft)"/>
      <g filter="url(#softer)" opacity=".8">{far_coral}</g>
    </svg>"""


def reef_layer(tips):
    """Transparent foreground: sand, rocks and the living reef."""
    r = random.Random(9)
    sand_top = "M0,540 C120,512 250,552 400,530 C560,508 720,550 880,528 C1020,510 1160,548 1280,520"
    ripples = "".join(
        f'<path d="M{x},{y} q40,-7 80,0 t80,0" fill="none" stroke="#fff6d8" stroke-opacity=".5" stroke-width="2"/>'
        for x, y in [(r.uniform(0, 1120), r.uniform(556, 610)) for _ in range(34)])
    rocks = [rock(190, 560, 176, 84, "#5b7ea3", 1), rock(1100, 556, 186, 96, "#54779d", 2), rock(650, 566, 120, 34, "#5f83a6", 3)]
    corals = [
        sea_fan(70, 524, 1.25, "#ff4fa3", 31),
        sea_fan(1236, 516, 1.2, "#b16bff", 32),
        table_coral(1086, 500, 1.14, "#a8481f", "#ea8a3e", "#ffd08a", 33),
        staghorn(205, 512, 1.1, "#4a1a9e", "#a65bf0", "#ffe4fa", 34, branches=8, tips_out=tips),
        brain_coral(336, 552, .92, "#8f5a0a", "#ffd44f", 35, "b1"),
        sponges(458, 556, .86, "#a8590c", "#f7a51f", "#ffe08a", "#5e2c08", 36),
        anemone(590, 568, 1.05, "#ff6fa8", "#ffe2ef", 37),
        brain_coral(752, 566, .66, "#137a44", "#7ff2a6", 38, "b2"),
        staghorn(868, 552, .9, "#8f1f4c", "#ff6f93", "#ffe6ee", 39, branches=6, tips_out=tips),
        sponges(978, 566, .68, "#8e2019", "#ff5e4d", "#ffc0a8", "#4d110c", 40),
        staghorn(1190, 566, .68, "#07635f", "#22cdb7", "#dcfff8", 41, branches=7, tips_out=tips),
        anemone(38, 584, .85, "#3fd8c6", "#e8fffb", 42),
        anemone(1252, 590, .8, "#ff9a30", "#fff0d0", 43),
    ]
    return f"""
    <svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
      <defs>
        {BEVEL}
        <linearGradient id="s" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stop-color="#fff0c0"/><stop offset=".5" stop-color="#eccf92"/><stop offset="1" stop-color="#b98f5a"/>
        </linearGradient>
        <filter id="grain" x="0" y="0" width="100%" height="100%">
          <feTurbulence type="fractalNoise" baseFrequency=".9" numOctaves="2" seed="8"/>
          <feColorMatrix values="0 0 0 0 .35  0 0 0 0 .22  0 0 0 0 .1  0 0 0 .9 -.32"/>
        </filter>
        <filter id="caust" x="0" y="0" width="100%" height="100%">
          <feTurbulence type="turbulence" baseFrequency=".016 .05" numOctaves="2" seed="11"/>
          <feColorMatrix values="0 0 0 0 1  0 0 0 0 1  0 0 0 0 .9  3.6 0 0 0 -.66"/>
        </filter>
        <clipPath id="sandclip"><path d="{sand_top} L1280,620 L0,620 Z"/></clipPath>
        <linearGradient id="blueveil" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stop-color="#0a6fd0" stop-opacity=".28"/><stop offset="1" stop-color="#0a6fd0" stop-opacity="0"/>
        </linearGradient>
      </defs>
      <g filter="url(#bevel)">{"".join(rocks)}</g>
      <path d="{sand_top} L1280,620 L0,620 Z" fill="url(#s)"/>
      <g clip-path="url(#sandclip)">
        <rect y="500" width="{W}" height="120" filter="url(#grain)" opacity=".7"/>
        {ripples}
        <rect y="500" width="{W}" height="120" filter="url(#caust)" opacity=".5"/>
      </g>
      <g filter="url(#bevel)">{"".join(corals)}</g>
    </svg>"""


def title_layer():
    return """
    <html><body style="margin:0;background:transparent;width:1280px;height:300px;display:flex;flex-direction:column;align-items:center;position:relative;">
      <div style="position:absolute;left:190px;top:42px;width:900px;height:200px;
                  background:radial-gradient(closest-side,rgba(0,74,160,.42),rgba(0,74,160,.2) 62%,rgba(0,74,160,0));"></div>
      <div style="position:relative;font:400 98px/1.1 'Segoe UI Semilight','Segoe UI',sans-serif;letter-spacing:-.5px;margin-top:58px;
                  color:#fff;text-shadow:0 1px 0 rgba(255,255,255,.6),0 2px 4px rgba(0,50,120,.7),0 8px 30px rgba(0,44,120,.8);">The Ocean's Clock</div>
      <div style="position:relative;font:400 29px/1.3 'Segoe UI',sans-serif;margin-top:4px;color:#fff;
                  text-shadow:0 1px 2px rgba(0,50,120,.9),0 4px 18px rgba(0,44,120,.85);">What tells a coral reef that tonight is the night?</div>
    </body></html>"""


def beam_layer():
    return f"""
    <svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
      <defs><linearGradient id="r" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f1ead7" stop-opacity=".95"/><stop offset=".75" stop-color="#cfe2ff" stop-opacity=".2"/><stop offset="1" stop-color="#cfe2ff" stop-opacity="0"/></linearGradient>
      <filter id="b" x="-20%" y="-10%" width="140%" height="120%"><feGaussianBlur stdDeviation="30"/></filter></defs>
      <path d="M560,-10 L780,-10 L1010,560 L410,560 Z" fill="url(#r)" filter="url(#b)"/>
    </svg>"""


def ray_layer(seed):
    """Soft shafts of light, baked at low resolution because they are blurred anyway."""
    r = random.Random(seed)
    shafts = ""
    for _ in range(6):
        x = r.uniform(40, 1240)
        top, bottom, lean = r.uniform(40, 110), r.uniform(120, 260), r.uniform(30, 110)
        shafts += f'<path d="M{x - top / 2:.0f},-10 L{x + top / 2:.0f},-10 L{x + lean + bottom / 2:.0f},540 L{x + lean - bottom / 2:.0f},540 Z" fill="url(#r)" opacity="{r.uniform(.3, .62):.2f}"/>'
    return f"""
    <svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
      <defs><linearGradient id="r" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".95"/><stop offset=".7" stop-color="#fff" stop-opacity=".22"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
      <filter id="b" x="-10%" y="-10%" width="120%" height="120%"><feGaussianBlur stdDeviation="17"/></filter></defs>
      <g filter="url(#b)">{shafts}</g>
    </svg>"""


def logo_layer():
    """A frosted mark in the upper-right corner of the tank glass."""
    mark = b64encode((ASSETS / "fhnw_mark.png").read_bytes()).decode("ascii")
    width = 100
    height = width * 1519 / 2560  # Preserve the transparent source's proportions.
    return f"""
    <g aria-label="FHNW">
      <defs>
        <filter id="fhnw-glass" x="-20%" y="-25%" width="140%" height="160%" color-interpolation-filters="sRGB">
          <feColorMatrix type="matrix" values="0 0 0 0 .92 0 0 0 0 .98 0 0 0 0 1 0 0 0 .94 0"/>
          <feDropShadow dx="0" dy="1.5" stdDeviation="1.4" flood-color="#063158" flood-opacity=".8"/>
        </filter>
      </defs>
      <image href="data:image/png;base64,{mark}" x="{W - width - 32}" y="30" width="{width}" height="{height:.4f}" filter="url(#fhnw-glass)"/>
    </g>"""


def caption_layer(text):
    return f"""
    <html><body style="margin:0;background:transparent;width:900px;height:64px;display:flex;align-items:center;justify-content:center;">
      <div style="font:500 21px/1 'Segoe UI',sans-serif;color:#fff;padding:12px 26px 13px;border-radius:999px;
                  background:linear-gradient(180deg,rgba(255,255,255,.34) 0,rgba(255,255,255,.1) 48%,rgba(4,44,104,.5) 52%,rgba(4,50,120,.42) 100%);
                  border:1px solid rgba(255,255,255,.6);box-shadow:inset 0 1px 0 rgba(255,255,255,.75),0 3px 12px rgba(0,30,80,.4);
                  text-shadow:0 1px 2px rgba(0,30,80,.8);">{text}</div>
    </body></html>"""


# Living parts ------------------------------------------------------------

BODY = "M-42,0 C-30,-24 18,-27 44,-5 C49,0 49,4 44,7 C18,27 -30,24 -42,0Z"
DISC = "M-36,0 C-30,-36 16,-38 42,-6 C47,0 47,4 42,8 C16,38 -30,36 -36,0Z"
TAIL = "M-38,0 C-50,-16 -62,-20 -68,-17 C-61,-5 -61,5 -68,17 C-62,20 -50,16 -38,0Z"
DORSAL = "M-20,-20 C-10,-38 14,-36 26,-17 C8,-22 -6,-22 -20,-20Z"
BELLY = "M-14,19 C-6,31 8,30 16,18 C6,21 -4,21 -14,19Z"

FISH = {
    "ember": dict(a="#ffb347", b="#ff5a1f", fin="#ff7a1a", tail="#ff7a1a", body=BODY,
                  marks='<path d="M-24,-24 C-16,-8 -16,8 -24,24 L-14,25 C-7,8 -7,-8 -14,-25Z M4,-27 C11,-9 11,9 4,27 L15,25 C21,8 21,-8 15,-25Z" fill="#fff"/>'),
    "royal": dict(a="#3b8cff", b="#0a31c4", fin="#0a31c4", tail="#ffd93b", body=BODY,
                  marks='<path d="M-30,-6 C-8,-20 18,-16 34,-3 C14,-8 -8,-8 -30,-6Z" fill="#071a66"/>'),
    "sun": dict(a="#fff06a", b="#ffb81c", fin="#ffc933", tail="#ffe34d", body=DISC,
                marks='<path d="M16,-30 C22,-12 22,12 16,30 L24,27 C29,12 29,-12 24,-27Z" fill="#1d1d1d" opacity=".82"/>'),
    "violet": dict(a="#c14dff", b="#7a1fd6", fin="#7a1fd6", tail="#ffc933", body=BODY,
                   marks='<path d="M-42,0 C-34,-20 -16,-25 -2,-25 C-8,-8 -8,8 -2,25 C-16,25 -34,20 -42,0Z" fill="#ffc933"/>'),
}


def fish_defs():
    out = []
    for name, f in FISH.items():
        out.append(f'<linearGradient id="f-{name}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{f["a"]}"/><stop offset="1" stop-color="{f["b"]}"/></linearGradient>')
        out.append(f'<clipPath id="c-{name}"><path d="{f["body"]}"/></clipPath>')
    return "".join(out)


def fish(name, y, scale, seconds, delay, leftward=False):
    f = FISH[name]
    flip = "scale(-1,1)" if leftward else ""
    swim = "swimL" if leftward else "swimR"
    bob = random.Random(int(y * 7 + seconds)).uniform(2.6, 4.2)
    return f"""
    <g style="animation:{swim} {seconds}s linear {delay}s infinite">
     <g class="bob" style="animation-duration:{bob:.1f}s">
      <g transform="translate(0,{y}) {flip} scale({scale})">
        <path class="tail" style="animation-duration:{0.55 + scale * .25:.2f}s" d="{TAIL}" fill="{f['tail']}"/>
        <path d="{DORSAL}" fill="{f['fin']}"/><path d="{BELLY}" fill="{f['fin']}"/>
        <path d="{f['body']}" fill="url(#f-{name})"/>
        <g clip-path="url(#c-{name})">{f['marks']}</g>
        <path d="M-26,-13 C-8,-22 18,-20 32,-8 C10,-13 -8,-12 -26,-13Z" fill="#fff" opacity=".42"/>
        <circle cx="29" cy="-5" r="6.2" fill="#fff"/><circle cx="30.5" cy="-5" r="3.6" fill="#0a1a2a"/><circle cx="32" cy="-6.6" r="1.3" fill="#fff"/>
      </g>
     </g>
    </g>"""


def school(y, seconds, delay, count=16):
    r = random.Random(int(y))
    members = []
    for _ in range(count):
        dx, dy = r.uniform(-120, 60), r.uniform(-46, 46)
        s = r.uniform(.8, 1.2)
        members.append(f'<g transform="translate({dx:.0f},{dy:.0f}) scale({s:.2f})"><path d="M-13,0 C-7,-6 7,-6 14,0 C7,6 -7,6 -13,0Z" fill="url(#silver)"/><path d="M-12,0 L-20,-5 L-18,0 L-20,5Z" fill="#c7f4ff"/><circle cx="9" cy="-1" r="1.1" fill="#072a52"/></g>')
    return f"""<g style="animation:swimR {seconds}s linear {delay}s infinite"><g class="bob" style="animation-duration:5.2s"><g transform="translate(0,{y})">{''.join(members)}</g></g></g>"""


def jellyfish(x, y, s, seconds, delay):
    tentacles = []
    for i, dx in enumerate((-20, -10, 0, 10, 20)):
        a = f"M{dx},8 C{dx - 8},34 {dx + 8},58 {dx - 4},86"
        b = f"M{dx},8 C{dx + 8},34 {dx - 8},58 {dx + 4},86"
        tentacles.append(f'<path d="{a}" fill="none" stroke="#ffd2f2" stroke-opacity=".75" stroke-width="2.2" stroke-linecap="round">'
                         f'<animate attributeName="d" dur="{3.2 + i * .25:.2f}s" repeatCount="indefinite" values="{a};{b};{a}"/></path>')
    return f"""
    <g style="animation:drift {seconds}s ease-in-out {delay}s infinite">
      <g transform="translate({x},{y}) scale({s})">
        {''.join(tentacles)}
        <g class="pulse">
          <path d="M-34,10 C-36,-34 36,-34 34,10 C22,16 12,6 0,12 C-12,6 -22,16 -34,10Z" fill="url(#jelly)"/>
          <path d="M-22,-8 C-14,-22 2,-24 12,-20" fill="none" stroke="#fff" stroke-opacity=".85" stroke-width="3.4" stroke-linecap="round"/>
        </g>
      </g>
    </g>"""


def kelp(x, base, height, width, amplitude, seconds, fill, seed):
    """A ribbon of seaweed. A wave runs up it, so it moves like something alive."""
    phase0 = random.Random(seed).uniform(0, 6.28)

    def shape(phase):
        left, right = [], []
        for i in range(15):
            t = i / 14
            cx = x + amplitude * t * math.sin(2.1 * math.pi * t - phase)
            cy = base - height * t
            half = width * (1 - t) ** .55 * (.55 + .45 * math.sin(math.pi * min(t * 1.5, 1)))
            left.append((cx - half, cy))
            right.append((cx + half, cy))
        return poly(left + right[::-1]) + " Z"

    frames = [shape(phase0 + k * math.pi / 2) for k in range(5)]
    return (f'<path d="{frames[0]}" fill="url(#{fill})"><animate attributeName="d" dur="{seconds}s" '
            f'repeatCount="indefinite" values="{";".join(frames)}"/></path>')


def bubbles():
    r = random.Random(12)
    out = []
    for x in (120, 312, 470, 702, 836, 1040, 1200):
        for _ in range(3):
            size = r.uniform(4, 13)
            seconds = r.uniform(9, 15)
            out.append(f'<g style="animation:rise {seconds:.1f}s ease-in {-r.uniform(0, seconds):.1f}s infinite">'
                       f'<circle cx="{x + r.uniform(-14, 14):.0f}" cy="560" r="{size:.1f}" fill="url(#bubble)" stroke="#fff" stroke-opacity=".55" stroke-width=".8"/>'
                       f'</g>')
    for x, size, seconds, start in [(250, 22, 17, 2), (640, 16, 21, 9), (1006, 28, 19, 5), (1168, 18, 23, 13)]:
        out.append(f'<g style="animation:rise {seconds}s ease-in {-start}s infinite">'
                   f'<circle cx="{x}" cy="566" r="{size}" fill="url(#bubble)" stroke="#fff" stroke-opacity=".7" stroke-width="1"/>'
                   f'<ellipse cx="{x - size * .34:.1f}" cy="{566 - size * .4:.1f}" rx="{size * .3:.1f}" ry="{size * .17:.1f}" fill="#fff" opacity=".85" transform="rotate(-28 {x - size * .34:.1f} {566 - size * .4:.1f})"/>'
                   f'</g>')
    return "".join(out)


def spawn(tips):
    """Pink gamete bundles rise from the coral tips, about two hours after sunset."""
    r = random.Random(4)
    chosen = r.sample(tips, min(64, len(tips)))
    out = []
    for x, y in chosen:
        size = r.uniform(2.6, 5.4)
        lag = r.uniform(0, 3.6)
        out.append(f'<g class="bundle" style="animation-delay:{lag:.1f}s"><circle cx="{x:.0f}" cy="{y:.0f}" r="{size * 2.4:.1f}" fill="url(#spawnglow)"/>'
                   f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{size:.1f}" fill="#ffc4cc"/></g>')
    return "".join(out)


def surface():
    wave = "".join(f"q40,{16 if i % 2 == 0 else -16} 80,0 " for i in range(40))
    return (f'<path class="waveA" d="M-160,14 {wave} V-40 H-160 Z" fill="#ffffff" opacity=".55"/>'
            f'<path class="waveB" d="M-160,24 {wave} V-40 H-160 Z" fill="#dffbff" opacity=".38"/>')


CAPTIONS = [
    ("Warming water opens the spawning season", 3, 33),
    ("Sunset sets the clock for the night", 42, 51),
    ("About two hours after sunset, spawning begins", 53, 69),
    ("Moonrise comes about 46 minutes later each night", 71, 86),
]


def build():
    tips = []
    water = data_uri(render_svg(water_layer(), W, H, scale=1.5), quality=72)
    reef = data_uri(render_svg(reef_layer(tips), W, H, scale=1.5, transparent=True), quality=78)
    title = data_uri(render_html(title_layer(), W, 300, scale=1.5), quality=90)
    beam = data_uri(render_svg(beam_layer(), W, H, scale=.5, transparent=True), quality=60)
    rays_a = data_uri(render_svg(ray_layer(1), W, H, scale=.5, transparent=True), quality=60)
    rays_b = data_uri(render_svg(ray_layer(2), W, H, scale=.5, transparent=True), quality=60)
    captions = [data_uri(render_html(caption_layer(text), 900, 64, scale=1.5), quality=90) for text, _, _ in CAPTIONS]

    caption_css, caption_tags = [], []
    for i, ((text, start, end), uri) in enumerate(zip(CAPTIONS, captions)):
        caption_css.append(f"@keyframes cap{i}{{0%,{start - 1}%{{opacity:0}}{start + 1}%,{end - 1}%{{opacity:1}}{end + 1}%,100%{{opacity:0}}}}")
        caption_tags.append(f'<image href="{uri}" x="190" y="548" width="900" height="64" style="animation:cap{i} {LOOP}s linear infinite;opacity:0"/>')

    css = f"""
    .bob{{animation:bob 3.4s ease-in-out infinite}}
    .tail{{transform-box:fill-box;transform-origin:100% 50%;animation:wag .7s ease-in-out infinite}}
    .pulse{{transform-box:fill-box;transform-origin:50% 100%;animation:pulse 3.6s ease-in-out infinite}}
    .rayA{{animation:rayA 11s ease-in-out infinite}}
    .rayB{{animation:rayB 11s ease-in-out infinite}}
    .waveA{{animation:wave 9s linear infinite}}
    .waveB{{animation:wave 13s linear reverse infinite}}
    .dusk{{opacity:0;animation:dusk {LOOP}s linear infinite}}
    .night{{opacity:0;animation:night {LOOP}s linear infinite}}
    .sun{{animation:sun {LOOP}s linear infinite}}
    .moon{{opacity:0;animation:moon {LOOP}s linear infinite}}
    .bundle{{opacity:0;animation:bundle {LOOP}s linear infinite}}
    .beam{{opacity:0;animation:beam {LOOP}s linear infinite}}
    @keyframes swimR{{from{{transform:translateX(-240px)}}to{{transform:translateX(1520px)}}}}
    @keyframes swimL{{from{{transform:translateX(1520px)}}to{{transform:translateX(-240px)}}}}
    @keyframes bob{{0%,100%{{transform:translateY(-7px)}}50%{{transform:translateY(7px)}}}}
    @keyframes wag{{0%,100%{{transform:rotate(-15deg)}}50%{{transform:rotate(15deg)}}}}
    @keyframes pulse{{0%,100%{{transform:scale(1,1)}}50%{{transform:scale(1.12,.84)}}}}
    @keyframes drift{{0%,100%{{transform:translate(0,14px)}}50%{{transform:translate(26px,-34px)}}}}
    @keyframes rayA{{0%,100%{{opacity:.85;transform:translateX(-14px)}}50%{{opacity:.15;transform:translateX(14px)}}}}
    @keyframes rayB{{0%,100%{{opacity:.15;transform:translateX(16px)}}50%{{opacity:.85;transform:translateX(-16px)}}}}
    @keyframes wave{{from{{transform:translateX(0)}}to{{transform:translateX(160px)}}}}
    @keyframes rise{{0%{{transform:translate(0,0);opacity:0}}8%{{opacity:.95}}30%{{transform:translate(9px,-170px)}}60%{{transform:translate(-8px,-340px)}}92%{{opacity:.9}}100%{{transform:translate(6px,-556px);opacity:0}}}}
    @keyframes dusk{{0%,33%{{opacity:0}}42%{{opacity:.62}}50%,100%{{opacity:0}}}}
    @keyframes night{{0%,38%{{opacity:0}}50%,84%{{opacity:.78}}95%,100%{{opacity:0}}}}
    @keyframes sun{{0%{{transform:translate(150px,44px);opacity:1}}22%{{transform:translate(640px,18px);opacity:1}}42%{{transform:translate(1130px,120px);opacity:1}}47%,94%{{transform:translate(1210px,170px);opacity:0}}95%{{transform:translate(40px,120px);opacity:0}}100%{{transform:translate(150px,44px);opacity:1}}}}
    @keyframes moon{{0%,68%{{transform:translate(70px,190px);opacity:0}}72%{{transform:translate(120px,96px);opacity:1}}76%{{transform:translate(230px,38px);opacity:1}}88%{{transform:translate(700px,34px);opacity:1}}93%,100%{{transform:translate(870px,40px);opacity:0}}}}
    @keyframes beam{{0%,71%{{opacity:0}}78%,86%{{opacity:.42}}92%,100%{{opacity:0}}}}
    @keyframes bundle{{0%,52%{{opacity:0;transform:translate(0,0)}}55%{{opacity:1;transform:translate(0,-14px)}}68%{{opacity:1;transform:translate(10px,-210px)}}76%{{opacity:.8;transform:translate(-8px,-330px)}}81%,100%{{opacity:0;transform:translate(0,-400px)}}}}
    @media (prefers-reduced-motion:reduce){{*{{animation:none!important}}.sun{{transform:translate(640px,18px)}}}}
    {''.join(caption_css)}
    """

    far = [fish("royal", 300, .62, 46, -30, True), fish("sun", 372, .5, 52, -12), school(250, 40, -6), jellyfish(1010, 260, .92, 17, -3), jellyfish(300, 300, .62, 21, -9)]
    near = [fish("ember", 420, .95, 30, -8), fish("violet", 346, .72, 36, -24, True), fish("sun", 460, .8, 42, -32, True), fish("royal", 300, .86, 34, -18)]
    weed = "".join([
        kelp(18, 616, 250, 13, 26, 7.5, "kelpA", 1), kelp(46, 618, 186, 11, 22, 6.2, "kelpB", 2), kelp(78, 620, 120, 9, 16, 5.4, "kelpA", 3),
        kelp(1264, 618, 270, 13, 28, 8, "kelpA", 4), kelp(1236, 618, 196, 11, 22, 6.6, "kelpB", 5), kelp(1206, 620, 130, 9, 16, 5.8, "kelpA", 6),
        kelp(528, 600, 104, 9, 14, 5.2, "kelpB", 7), kelp(546, 602, 76, 8, 12, 4.6, "kelpA", 8),
        kelp(690, 604, 92, 9, 14, 5.6, "kelpB", 9), kelp(816, 606, 116, 9, 15, 6, "kelpA", 10)])

    svg = f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" role="img" aria-labelledby="t d">
<title id="t">The Ocean's Clock</title>
<desc id="d">An animated aquarium with corals, fish, jellyfish, seaweed and bubbles. Each loop is one night on the reef: the sun crosses the tank and sets, pink gamete bundles rise from the corals about two hours later, and the Moon rises afterwards.</desc>
<defs>
<clipPath id="tank"><rect width="{W}" height="{H}" rx="28"/></clipPath>
{fish_defs()}
<linearGradient id="kelpA" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="#056b3f"/><stop offset=".6" stop-color="#12ad62"/><stop offset="1" stop-color="#7ff0a8"/></linearGradient>
<linearGradient id="kelpB" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="#0a7a4a"/><stop offset=".6" stop-color="#2fd17a"/><stop offset="1" stop-color="#c4ff9c"/></linearGradient>
<linearGradient id="silver" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f2fdff"/><stop offset="1" stop-color="#79d7ee"/></linearGradient>
<radialGradient id="jelly" cx=".5" cy=".25" r=".8"><stop offset="0" stop-color="#ffffff" stop-opacity=".92"/><stop offset=".6" stop-color="#ffb8ee" stop-opacity=".66"/><stop offset="1" stop-color="#d36bff" stop-opacity=".4"/></radialGradient>
<radialGradient id="bubble" cx=".34" cy=".3" r=".78"><stop offset="0" stop-color="#ffffff" stop-opacity=".95"/><stop offset=".3" stop-color="#ffffff" stop-opacity=".18"/><stop offset=".8" stop-color="#bff4ff" stop-opacity=".12"/><stop offset="1" stop-color="#ffffff" stop-opacity=".6"/></radialGradient>
<radialGradient id="spawnglow"><stop offset="0" stop-color="#ff9fac" stop-opacity=".95"/><stop offset=".45" stop-color="#ff7e8b" stop-opacity=".5"/><stop offset="1" stop-color="#ff7e8b" stop-opacity="0"/></radialGradient>
<radialGradient id="sunfill"><stop offset="0" stop-color="#ffffff"/><stop offset=".22" stop-color="#fff7d0" stop-opacity=".95"/><stop offset=".55" stop-color="#ffe9a0" stop-opacity=".4"/><stop offset="1" stop-color="#ffe9a0" stop-opacity="0"/></radialGradient>
<radialGradient id="moonglow"><stop offset="0" stop-color="#f1ead7" stop-opacity=".75"/><stop offset=".4" stop-color="#cfe2ff" stop-opacity=".26"/><stop offset="1" stop-color="#cfe2ff" stop-opacity="0"/></radialGradient>
<radialGradient id="moonface" cx=".38" cy=".34" r=".8"><stop offset="0" stop-color="#fffdf2"/><stop offset="1" stop-color="#d9cfb2"/></radialGradient>
<linearGradient id="dusk" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ff9a4d" stop-opacity=".95"/><stop offset=".55" stop-color="#d9477f" stop-opacity=".55"/><stop offset="1" stop-color="#3a1a78" stop-opacity=".5"/></linearGradient>
<linearGradient id="night" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0b2a66"/><stop offset="1" stop-color="#030b2a"/></linearGradient>
<linearGradient id="gloss" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffffff" stop-opacity=".42"/><stop offset="1" stop-color="#ffffff" stop-opacity=".02"/></linearGradient>
</defs>
<style>{css}</style>
<g clip-path="url(#tank)">
<image href="{water}" width="{W}" height="{H}"/>
<image class="rayA" href="{rays_a}" width="{W}" height="{H}"/>
<image class="rayB" href="{rays_b}" width="{W}" height="{H}"/>
<g class="sun"><circle r="120" fill="url(#sunfill)"/></g>
{surface()}
{''.join(far)}
<image href="{reef}" width="{W}" height="{H}"/>
{weed}
{''.join(near)}
<g>{bubbles()}</g>
<rect class="dusk" width="{W}" height="{H}" fill="url(#dusk)"/>
<rect class="night" width="{W}" height="{H}" fill="url(#night)"/>
<image class="beam" href="{beam}" width="{W}" height="{H}"/>
<g class="moon"><circle r="110" fill="url(#moonglow)"/><circle r="30" fill="url(#moonface)"/></g>
<g>{spawn(tips)}</g>
<path d="M0,0 H{W} V58 C900,120 380,120 0,70 Z" fill="url(#gloss)" opacity=".4"/>
<image href="{title}" width="{W}" height="300"/>
{logo_layer()}
{''.join(caption_tags)}
</g>
<rect x="1.5" y="1.5" width="{W - 3}" height="{H - 3}" rx="27" fill="none" stroke="#ffffff" stroke-opacity=".7" stroke-width="3"/>
</svg>"""
    target = ASSETS / "hero.svg"
    target.write_text(svg, encoding="utf-8")
    print(f"hero.svg: {target.stat().st_size / 1024:.0f} KB, {len(tips)} coral tips")


if __name__ == "__main__":
    build()
