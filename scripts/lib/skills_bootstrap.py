"""Skills preference sidecar, freshness, and bootstrap sync decisions."""

from __future__ import annotations

import json
import shutil
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any, Iterable, Literal

STALE_HOURS = 24
ISO_FORMAT = "%Y-%m-%dT%H:%M:%S.000Z"
VALID_MODES = frozenset({"auto", "local-only"})
DEFAULT_MODE = "auto"

OWNED_SKILL_NAMES = frozenset(
    {
        "accept",
        "build",
        "explain",
        "new",
        "modify",
        "matstudylab-bootstrap",
    }
)

SETUP_COMMANDS: tuple[tuple[str, ...], ...] = (
    (
        "npx",
        "skills@latest",
        "add",
        "mattpocock/skills",
        "--skill",
        "*",
        "-a",
        "cursor",
        "-y",
        "--copy",
    ),
    (
        "npx",
        "skills@latest",
        "add",
        "https://github.com/k-dense-ai/claude-scientific-skills",
        "--skill",
        "matlab",
        "-a",
        "cursor",
        "-y",
        "--copy",
    ),
    (
        "npx",
        "skills@latest",
        "add",
        "https://github.com/matlab/skills",
        "--skill",
        "matlab-performance-optimizer",
        "-a",
        "cursor",
        "-y",
        "--copy",
    ),
)

UPDATE_COMMAND: tuple[str, ...] = (
    "npx",
    "skills@latest",
    "update",
    "-p",
    "-y",
)

SyncAction = Literal["local-only", "fresh", "setup", "update"]


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


def lock_skills_map(lock: dict[str, Any]) -> dict[str, Any]:
    skills = lock.get("skills")
    if not isinstance(skills, dict):
        return {}
    return skills


def is_incomplete_setup(lock: dict[str, Any], pref: dict[str, Any]) -> bool:
    if not lock_skills_map(lock):
        return True
    return pref.get("last_synced_at") is None


def owned_skills_in_lock(lock: dict[str, Any]) -> list[str]:
    return sorted(OWNED_SKILL_NAMES & set(lock_skills_map(lock)))


def name_guard_collisions(planned_skill_names: Iterable[str]) -> list[str]:
    return sorted(OWNED_SKILL_NAMES & {name for name in planned_skill_names if name})


def node_available(*, force_no_node: bool = False) -> bool:
    if force_no_node:
        return False
    return shutil.which("npx") is not None


def decide_sync_action(
    lock: dict[str, Any], pref: dict[str, Any], now: datetime
) -> SyncAction:
    if pref.get("mode") == "local-only":
        return "local-only"
    if is_incomplete_setup(lock, pref):
        return "setup"
    if is_stale(pref.get("last_synced_at"), now):
        return "update"
    return "fresh"
