"""Skills preference sidecar and 24h freshness for matstudylab-bootstrap."""

from __future__ import annotations

import json
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

STALE_HOURS = 24
ISO_FORMAT = "%Y-%m-%dT%H:%M:%S.000Z"
VALID_MODES = frozenset({"auto", "local-only"})
DEFAULT_MODE = "auto"


def parse_timestamp(value: str) -> datetime:
    normalized = value.replace("Z", "+00:00")
    return datetime.fromisoformat(normalized).astimezone(timezone.utc)


def format_timestamp(moment: datetime) -> str:
    return moment.astimezone(timezone.utc).strftime(ISO_FORMAT)


def is_stale(
    last_synced_at: str | None, now: datetime, stale_hours: int = STALE_HOURS
) -> bool:
    if not last_synced_at:
        return True
    synced_at = parse_timestamp(last_synced_at)
    return now - synced_at > timedelta(hours=stale_hours)


def default_pref() -> dict[str, Any]:
    return {"mode": DEFAULT_MODE, "last_synced_at": None}


def load_pref(path: Path) -> dict[str, Any]:
    if not path.exists():
        return default_pref()
    with path.open(encoding="utf-8") as handle:
        data = json.load(handle)
    mode = data.get("mode", DEFAULT_MODE)
    if mode not in VALID_MODES:
        mode = DEFAULT_MODE
    last_synced_at = data.get("last_synced_at")
    if last_synced_at is not None and not isinstance(last_synced_at, str):
        last_synced_at = None
    return {"mode": mode, "last_synced_at": last_synced_at}


def write_pref(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "mode": data.get("mode", DEFAULT_MODE),
        "last_synced_at": data.get("last_synced_at"),
    }
    if payload["mode"] not in VALID_MODES:
        payload["mode"] = DEFAULT_MODE
    with path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2)
        handle.write("\n")


def touch_last_synced_at(path: Path, now: datetime) -> str:
    data = load_pref(path)
    timestamp = format_timestamp(now)
    data["last_synced_at"] = timestamp
    write_pref(path, data)
    return timestamp


def load_lockfile(path: Path) -> dict:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)
