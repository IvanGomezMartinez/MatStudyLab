"""Skills lockfile staleness check and last_checked updates for matstudylab-bootstrap."""

from __future__ import annotations

import json
from datetime import datetime, timedelta, timezone
from pathlib import Path

STALE_HOURS = 24
ISO_FORMAT = "%Y-%m-%dT%H:%M:%S.000Z"


def parse_timestamp(value: str) -> datetime:
    normalized = value.replace("Z", "+00:00")
    return datetime.fromisoformat(normalized).astimezone(timezone.utc)


def format_timestamp(moment: datetime) -> str:
    return moment.astimezone(timezone.utc).strftime(ISO_FORMAT)


def is_stale(last_checked: str | None, now: datetime, stale_hours: int = STALE_HOURS) -> bool:
    if not last_checked:
        return True
    checked_at = parse_timestamp(last_checked)
    return now - checked_at > timedelta(hours=stale_hours)


def load_lockfile(path: Path) -> dict:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def write_lockfile(path: Path, data: dict) -> None:
    with path.open("w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2)
        handle.write("\n")


def touch_last_checked(path: Path, now: datetime) -> str:
    data = load_lockfile(path)
    timestamp = format_timestamp(now)
    data["last_checked"] = timestamp
    write_lockfile(path, data)
    return timestamp
