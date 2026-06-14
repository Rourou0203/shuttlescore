import json
from pathlib import Path


def load_history(path: Path) -> dict:
    if path.exists():
        with open(path) as f:
            return json.load(f)
    return {}


def save_history(path: Path, today: str, results: list, history: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    history[today] = results

    # Keep last 30 days only
    for old_date in sorted(history)[:-30]:
        del history[old_date]

    with open(path, "w") as f:
        json.dump(history, f, indent=2)
