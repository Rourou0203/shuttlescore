import re
import json
import time
import random
import requests
from bs4 import BeautifulSoup
from typing import Optional

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0.0.0 Safari/537.36"
    ),
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
}


def scrape_price(store: str, url: str) -> Optional[float]:
    time.sleep(random.uniform(1.5, 3.5))
    dispatch = {"petlibro": _petlibro, "chewy": _chewy, "petsmart": _petsmart}
    fn = dispatch.get(store)
    return fn(url) if fn else None


def _extract_json_ld_price(soup) -> Optional[float]:
    for script in soup.find_all("script", type="application/ld+json"):
        try:
            data = json.loads(script.string or "")
            for item in (data if isinstance(data, list) else [data]):
                if item.get("@type") == "Product":
                    offers = item.get("offers", {})
                    if isinstance(offers, list):
                        offers = offers[0]
                    price = offers.get("price") or offers.get("lowPrice")
                    if price:
                        return float(str(price).replace(",", ""))
        except Exception:
            continue
    return None


def _petlibro(url: str) -> Optional[float]:
    """Shopify store — product JSON endpoint bypasses HTML scraping."""
    try:
        handle = url.rstrip("/").split("/products/")[-1].split("?")[0]
        resp = requests.get(
            f"https://petlibro.com/products/{handle}.json",
            headers=HEADERS,
            timeout=10,
        )
        resp.raise_for_status()
        price_str = resp.json()["product"]["variants"][0]["price"]
        return float(price_str)
    except Exception:
        return None


def _chewy(url: str) -> Optional[float]:
    """Chewy uses Cloudflare — requires a real browser."""
    try:
        from playwright.sync_api import sync_playwright

        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            ctx = browser.new_context(
                user_agent=HEADERS["User-Agent"],
                locale="en-US",
            )
            page = ctx.new_page()
            page.goto(url, wait_until="domcontentloaded", timeout=30000)
            page.wait_for_load_state("networkidle", timeout=15000)

            soup = BeautifulSoup(page.content(), "html.parser")
            browser.close()

        price = _extract_json_ld_price(soup)
        if price:
            return price

        for sel in ['[data-testid="product-price"]', ".product-price", '[itemprop="price"]']:
            el = soup.select_one(sel)
            if el:
                text = el.get("content") or el.get_text()
                m = re.search(r"([\d,]+\.?\d*)", text.replace(",", ""))
                if m:
                    return float(m.group(1))
        return None
    except Exception as e:
        print(f"Chewy scrape failed: {e}")
        return None


def _petsmart(url: str) -> Optional[float]:
    try:
        resp = requests.get(url, headers=HEADERS, timeout=15)
        resp.raise_for_status()
        soup = BeautifulSoup(resp.text, "html.parser")

        price = _extract_json_ld_price(soup)
        if price:
            return price

        for sel in ['[data-component="price"]', ".primary-price", '[itemprop="price"]']:
            el = soup.select_one(sel)
            if el:
                text = el.get("content") or el.get_text()
                m = re.search(r"([\d,]+\.?\d*)", text.replace(",", ""))
                if m:
                    return float(m.group(1))
        return None
    except Exception:
        return None
