import re
import requests
from bs4 import BeautifulSoup
from typing import Optional

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0.0.0 Safari/537.36"
    ),
    "Accept": "text/html,application/xhtml+xml,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
}

# CashbackMonitor store slugs (lowercase, hyphenated)
STORE_SLUGS = {
    "chewy": "chewy",
    "petsmart": "petsmart",
    "petlibro": "petlibro",
}


def get_cashback_rates(store: str) -> dict:
    slug = STORE_SLUGS.get(store, store)
    url = f"https://www.cashbackmonitor.com/cashback-store/{slug}/"

    result: dict = {
        "rakuten": None,
        "capital_one": None,
        "best_rate": None,
        "best_portal": None,
    }

    try:
        resp = requests.get(url, headers=HEADERS, timeout=15)
        resp.raise_for_status()
        soup = BeautifulSoup(resp.text, "html.parser")

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

    except Exception:
        pass

    return result
