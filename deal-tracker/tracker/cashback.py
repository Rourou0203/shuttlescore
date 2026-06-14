import re
import requests
from bs4 import BeautifulSoup

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0.0.0 Safari/537.36"
    ),
    "Accept": "text/html,application/xhtml+xml,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
}

STORE_SLUGS = {
    "chewy": "chewy",
    "petsmart": "petsmart",
    "petlibro": "petlibro",
}

RAKUTEN_SLUGS = {
    "chewy": "chewy",
    "petsmart": "petsmart",
}


def get_cashback_rates(store: str) -> dict:
    result: dict = {
        "rakuten": None,
        "capital_one": None,
        "best_rate": None,
        "best_portal": None,
    }

    # Rakuten rates are in static HTML — fast and reliable
    rakuten_rate = _get_rakuten_rate(store)
    if rakuten_rate is not None:
        result["rakuten"] = rakuten_rate
        result["best_rate"] = rakuten_rate
        result["best_portal"] = "Rakuten"

    # CashbackMonitor aggregates all portals but requires a real browser
    cbm = _get_cashbackmonitor_rates(store)
    if cbm["rakuten"] is not None:
        result["rakuten"] = cbm["rakuten"]
    if cbm["capital_one"] is not None:
        result["capital_one"] = cbm["capital_one"]
    if cbm["best_rate"] is not None and (result["best_rate"] is None or cbm["best_rate"] > result["best_rate"]):
        result["best_rate"] = cbm["best_rate"]
        result["best_portal"] = cbm["best_portal"]

    return result


def _get_rakuten_rate(store: str) -> float | None:
    slug = RAKUTEN_SLUGS.get(store)
    if not slug:
        return None
    try:
        resp = requests.get(
            f"https://www.rakuten.com/store/{slug}",
            headers=HEADERS,
            timeout=10,
        )
        resp.raise_for_status()
        soup = BeautifulSoup(resp.text, "html.parser")
        text = soup.get_text(" ", strip=True)
        m = re.search(r"([\d.]+)\s*%\s*Cash\s*Back", text, re.IGNORECASE)
        return float(m.group(1)) if m else None
    except Exception:
        return None


def _get_cashbackmonitor_rates(store: str) -> dict:
    result: dict = {"rakuten": None, "capital_one": None, "best_rate": None, "best_portal": None}
    slug = STORE_SLUGS.get(store, store)
    url = f"https://www.cashbackmonitor.com/cashback-store/{slug}/"

    try:
        from playwright.sync_api import sync_playwright

        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            page = browser.new_page(user_agent=HEADERS["User-Agent"])
            page.goto(url, timeout=30000)
            # Wait until the loading spinner is gone and rate rows appear
            page.wait_for_load_state("networkidle", timeout=20000)

            soup = BeautifulSoup(page.content(), "html.parser")
            browser.close()

        best_rate = 0.0
        best_portal = ""

        for row in soup.select("tr"):
            cells = row.find_all(["td", "th"])
            if len(cells) < 2:
                continue
            portal = cells[0].get_text(strip=True)
            portal_lower = portal.lower()
            rate_text = " ".join(c.get_text(strip=True) for c in cells[1:])

            m = re.search(r"([\d.]+)\s*%", rate_text)
            if not m:
                continue
            rate = float(m.group(1))

            if "rakuten" in portal_lower:
                result["rakuten"] = max(result["rakuten"] or 0, rate)
            if "capital one" in portal_lower:
                result["capital_one"] = max(result["capital_one"] or 0, rate)
            if rate > best_rate:
                best_rate = rate
                best_portal = portal

        if best_rate > 0:
            result["best_rate"] = best_rate
            result["best_portal"] = best_portal

    except Exception as e:
        print(f"CashbackMonitor scrape failed for {store}: {e}")

    return result
