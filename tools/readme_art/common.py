"""Shared helpers for the README artwork: headless rendering and image embedding."""
import base64
import io
from pathlib import Path

from PIL import Image
from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "docs" / "assets"
ASSETS.mkdir(parents=True, exist_ok=True)


def _shot(html, width, height, scale, transparent):
    with sync_playwright() as p:
        browser = p.chromium.launch(channel="msedge", headless=True)
        page = browser.new_page(viewport={"width": width, "height": height}, device_scale_factor=scale)
        page.set_content(html)
        page.wait_for_timeout(200)
        png = page.screenshot(omit_background=transparent)
        browser.close()
    return Image.open(io.BytesIO(png)).convert("RGBA")


def render_svg(svg, width, height, scale=1.0, transparent=False):
    page = f'<!doctype html><html><body style="margin:0;background:transparent">{svg}</body></html>'
    return _shot(page, width, height, scale, transparent)


def render_html(html, width, height, scale=1.0):
    return _shot("<!doctype html>" + html, width, height, scale, True)


def data_uri(image, quality=82):
    buffer = io.BytesIO()
    image.save(buffer, "WEBP", quality=quality, method=6)
    return "data:image/webp;base64," + base64.b64encode(buffer.getvalue()).decode()
