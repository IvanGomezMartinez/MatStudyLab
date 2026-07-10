"""Validation and scaffolding for the /new command."""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

STAGING_AREA = "new"
SNAKE_CASE = re.compile(r"^[a-z][a-z0-9_]*$")
VERB_PREFIXES = (
    "build_",
    "calculate_",
    "compute_",
    "create_",
    "generate_",
    "get_",
    "make_",
    "plot_",
    "run_",
)
CHECKLIST_ITEMS = (
    "optical magnitude and codes/<type>/ folder",
    "units and equipment",
    "inputs, outputs, and console behavior",
    "snake_case filename without verb prefix",
    "companion .md language",
)


@dataclass(frozen=True)
class NewBundleTarget:
    type_name: str
    bundle_name: str
    stem: str

    def bundle_dir(self, root: Path) -> Path:
        return root / STAGING_AREA / self.type_name / self.bundle_name

    def script_path(self, root: Path) -> Path:
        return self.bundle_dir(root) / f"{self.stem}.m"

    def companion_path(self, root: Path) -> Path:
        return self.bundle_dir(root) / f"{self.stem}.md"


def validate_type_folder(type_name: str) -> list[str]:
    errors: list[str] = []
    if not type_name or type_name != type_name.lower():
        errors.append("type folder must be kebab-case")
    if "_" in type_name:
        errors.append("type folder must use kebab-case, not snake_case")
    return errors


def validate_stem(stem: str) -> list[str]:
    errors: list[str] = []
    if not SNAKE_CASE.match(stem):
        errors.append("filename must be snake_case")
    for prefix in VERB_PREFIXES:
        if stem.startswith(prefix):
            errors.append(f"filename must not use verb prefix '{prefix}'")
    if not stem[0].isalpha():
        errors.append("filename must start with a letter")
    return errors


def assert_writes_only_new(root: Path, target: NewBundleTarget) -> None:
    bundle_dir = target.bundle_dir(root).resolve()
    new_root = (root / STAGING_AREA).resolve()
    if new_root not in bundle_dir.parents:
        raise ValueError(f"output must stay under new/: {bundle_dir}")


def scaffold_new_bundle(root: Path, target: NewBundleTarget, *, dry_run: bool = False) -> tuple[Path, Path]:
    errors = validate_type_folder(target.type_name) + validate_stem(target.stem)
    if target.bundle_name != target.stem:
        errors.extend(validate_stem(target.bundle_name))
    if errors:
        raise ValueError("; ".join(errors))

    assert_writes_only_new(root, target)
    script_path = target.script_path(root)
    companion_path = target.companion_path(root)

    if script_path.exists() or companion_path.exists():
        raise ValueError("bundle files already exist — resume by editing instead of scaffolding")

    if dry_run:
        return script_path, companion_path

    bundle_dir = target.bundle_dir(root)
    bundle_dir.mkdir(parents=True, exist_ok=False)
    script_path.write_text(
        "\n".join(
            [
                f"%% {target.stem}",
                "%% Parameters",
                "",
                "%% Load data",
                "",
                "%% Compute",
                "",
                "%% Plot",
                "",
            ]
        ),
        encoding="utf-8",
    )
    companion_path.write_text(
        "\n".join(
            [
                f"# {target.stem}",
                "",
                f"> Script: `new/{target.type_name}/{target.bundle_name}/{target.stem}.m`",
                "",
                "## Purpose",
                "",
                "(Fill after grill-me checklist.)",
                "",
            ]
        ),
        encoding="utf-8",
    )
    return script_path, companion_path
