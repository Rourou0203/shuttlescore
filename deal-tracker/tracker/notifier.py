import os
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from datetime import datetime
from typing import Optional


def _fmt_price(price: Optional[float]) -> str:
    return f"${price:.2f}" if price is not None else "N/A"


def _fmt_rate(rate: Optional[float]) -> str:
    return f"{rate:.1f}%" if rate is not None else "N/A"


def _effective_price(price: Optional[float], rate: Optional[float]) -> Optional[float]:
    if price is None or rate is None:
        return None
    return price * (1 - rate / 100)


def _prev_price(history: dict, yesterday: Optional[str], product_id: str, store: str) -> Optional[float]:
    if not yesterday or yesterday not in history:
        return None
    for p in history[yesterday]:
        if p["id"] == product_id:
            return p["prices"].get(store, {}).get("price")
    return None


def build_body(results: list, history: dict, today: str) -> str:
    dates = sorted(history.keys())
    idx = dates.index(today) if today in dates else -1
    yesterday = dates[idx - 1] if idx > 0 else None

    lines = [
        f"Daily Price Report — {datetime.now().strftime('%B %d, %Y')}",
        "=" * 52,
        "",
    ]

    for product in results:
        lines.append(f"  {product['name']}")
        lines.append("")

        best_effective = None
        best_desc = ""

        for store, info in product["prices"].items():
            price = info["price"]
            url = info["url"]
            cashback = product["cashback"].get(store, {})

            # Price change vs yesterday
            prev = _prev_price(history, yesterday, product["id"], store)
            change = ""
            if prev and price:
                diff = price - prev
                if diff < -0.01:
                    change = f"  ▼ ${abs(diff):.2f}"
                elif diff > 0.01:
                    change = f"  ▲ ${abs(diff):.2f}"

            best_rate = cashback.get("best_rate")
            best_portal = cashback.get("best_portal") or "?"
            rakuten = cashback.get("rakuten")
            c1 = cashback.get("capital_one")
            effective = _effective_price(price, best_rate)

            lines.append(f"  {store.title():10}  {_fmt_price(price)}{change}")
            lines.append(f"    URL: {url}")

            cb_parts = []
            if rakuten is not None:
                cb_parts.append(f"Rakuten {_fmt_rate(rakuten)}")
            if c1 is not None:
                cb_parts.append(f"Capital One {_fmt_rate(c1)}")
            if best_rate is not None:
                cb_parts.append(f"Best: {best_portal} {_fmt_rate(best_rate)}")
            if cb_parts:
                lines.append(f"    Cashback: {' | '.join(cb_parts)}")
            if effective is not None:
                lines.append(f"    Effective after cashback: {_fmt_price(effective)}")

            lines.append("")

            if best_effective is None or (effective is not None and effective < best_effective):
                best_effective = effective
                best_desc = (
                    f"{store.title()} {_fmt_price(price)} "
                    f"+ {best_portal} {_fmt_rate(best_rate)} "
                    f"= {_fmt_price(effective)}"
                )

        if best_desc:
            lines.append(f"  Best combo today: {best_desc}")
        lines.append("")
        lines.append("-" * 52)
        lines.append("")

    lines += [
        "Compare all cashback rates: https://www.cashbackmonitor.com",
        "",
        "To track a new product, add it to config.yaml in your deal-tracker repo.",
    ]
    return "\n".join(lines)


def send_email(to: str, results: list, history: dict, today: str) -> None:
    user = os.environ.get("GMAIL_USER")
    password = os.environ.get("GMAIL_APP_PASSWORD")
    body = build_body(results, history, today)

    if not user or not password:
        print("No email credentials — printing report instead:\n")
        print(body)
        return

    msg = MIMEMultipart()
    msg["Subject"] = f"Deal Tracker — {datetime.now().strftime('%b %d, %Y')}"
    msg["From"] = user
    msg["To"] = to
    msg.attach(MIMEText(body, "plain"))

    with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
        server.login(user, password)
        server.sendmail(user, to, msg.as_string())

    print(f"Email sent to {to}")
