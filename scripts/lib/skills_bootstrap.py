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


def record_successful_sync(path: Path, now: datetime) -> str:
    """Stamp last_synced_at and force mode auto after SETUP_OK / UPDATE_OK only."""
    data = load_pref(path)
    timestamp = format_timestamp(now)
    data["mode"] = DEFAULT_MODE
    data["last_synced_at"] = timestamp
    write_pref(path, data)
    return timestamp


def touch_last_synced_at(path: Path, now: datetime) -> str:
    """Backward-compatible alias for tests that only need a timestamp write."""
    return record_successful_sync(path, now)


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


def skill_on_disk(skills_dir: Path, name: str) -> bool:
    skill_path = skills_dir / name
    return skill_path.is_dir() or (skill_path / "SKILL.md").is_file()


def check_local_integrity(
    repo_root: Path,
    lock_path: Path | None = None,
    pref_path: Path | None = None,
) -> list[str]:
    """Assert lock + on-disk skills; parse pref if present. No network."""
    root = repo_root
    lock_file = lock_path if lock_path is not None else root / "skills-lock.json"
    pref_file = (
        pref_path if pref_path is not None else root / ".matstudylab" / "skills-pref.json"
    )
    skills_dir = root / ".agents" / "skills"
    failures: list[str] = []

    if not lock_file.is_file():
        failures.append(f"missing lockfile: {lock_file}")
        return failures

    try:
        lock = load_lockfile(lock_file)
    except (OSError, json.JSONDecodeError, TypeError, ValueError) as exc:
        failures.append(f"unreadable lockfile: {lock_file} ({exc})")
        return failures

    for name in sorted(lock_skills_map(lock)):
        if not skill_on_disk(skills_dir, name):
            failures.append(f"missing locked skill on disk: {name}")

    for name in sorted(OWNED_SKILL_NAMES):
        if not skill_on_disk(skills_dir, name):
            failures.append(f"missing owned skill on disk: {name}")

    if pref_file.is_file():
        try:
            with pref_file.open(encoding="utf-8") as handle:
                raw = json.load(handle)
            if not isinstance(raw, dict):
                failures.append(f"preference is not an object: {pref_file}")
            else:
                # Ensure load_pref can normalize mode + last_synced_at
                load_pref(pref_file)
        except (OSError, json.JSONDecodeError, TypeError, ValueError) as exc:
            failures.append(f"unreadable preference: {pref_file} ({exc})")

    return failures


def release_freshness_ok(
    pref_path: Path, now: datetime, stale_hours: int = STALE_HOURS
) -> tuple[bool, str]:
    """Release gate: last_synced_at must exist and be within stale_hours."""
    if not pref_path.is_file():
        return False, f"missing preference file: {pref_path}"
    try:
        pref = load_pref(pref_path)
    except (OSError, json.JSONDecodeError, TypeError, ValueError) as exc:
        return False, f"unreadable preference: {pref_path} ({exc})"
    last_synced_at = pref.get("last_synced_at")
    if not last_synced_at:
        return False, "last_synced_at is missing"
    if is_stale(last_synced_at, now, stale_hours=stale_hours):
        return False, f"last_synced_at is stale (> {stale_hours}h): {last_synced_at}"
    return True, f"fresh last_synced_at: {last_synced_at}"
