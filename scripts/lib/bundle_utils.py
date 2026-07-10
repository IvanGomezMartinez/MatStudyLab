"""Shared bundle path helpers for workflow command scripts."""

from __future__ import annotations

from pathlib import Path


def base_markdown_files(bundle_dir: Path) -> list[Path]:
    return sorted(
        path
        for path in bundle_dir.glob("*.md")
        if path.is_file() and not path.name.startswith("explain_")
    )


def snapshot_bundle_dir(bundle_dir: Path) -> dict[str, str]:
    return {
        path.name: path.read_text(encoding="utf-8")
        for path in sorted(bundle_dir.iterdir())
        if path.is_file()
    }
