import yaml
from pathlib import Path
from datetime import date

from tracker.scraper import scrape_price
from tracker.cashback import get_cashback_rates
from tracker.notifier import send_email
from tracker.storage import load_history, save_history

CONFIG = Path("config.yaml")
DATA = Path("data/prices.json")


def main():
    with open(CONFIG) as f:
        config = yaml.safe_load(f)

    today = str(date.today())
    history = load_history(DATA)
    results = []

    for product in config["products"]:
        print(f"Tracking: {product['name']}")
        entry = {
            "name": product["name"],
            "id": product["id"],
            "date": today,
            "prices": {},
            "cashback": {},
        }

        for store_info in product["urls"]:
            store = store_info["store"]
            url = store_info["url"]
            print(f"  Fetching price from {store}...")
            price = scrape_price(store, url)
            entry["prices"][store] = {"price": price, "url": url}
            print(f"  {store}: {price}")

        for store in product.get("cashback_stores", []):
            print(f"  Fetching cashback rates for {store}...")
            rates = get_cashback_rates(store)
            entry["cashback"][store] = rates
            print(f"  {store} cashback: {rates}")

        results.append(entry)

    save_history(DATA, today, results, history)

    notify_cfg = config["notification"]
    send_email(
        to=notify_cfg["email"],
        results=results,
        history=history,
        today=today,
    )


if __name__ == "__main__":
    main()
