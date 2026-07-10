"""Copy catalog bundles to modify/ for the /modify command."""

from __future__ import annotations

import shutil
from pathlib import Path

from bundle_utils import snapshot_bundle_dir

CATALOG_AREA = "codes"
STAGING_AREA = "modify"


def catalog_bundle_path(root: Path, type_name: str, bundle_name: str) -> Path:
    return root / CATALOG_AREA / type_name / bundle_name


def modify_bundle_path(root: Path, type_name: str, bundle_name: str) -> Path:
    return root / STAGING_AREA / type_name / bundle_name


def assert_writes_only_modify(root: Path, path: Path) -> None:
    modify_root = (root / STAGING_AREA).resolve()
    resolved = path.resolve()
    if modify_root not in resolved.parents and resolved != modify_root:
        raise ValueError(f"writes must stay under modify/: {path}")


def copy_catalog_to_modify(
    root: Path,
    type_name: str,
    bundle_name: str,
    *,
    overwrite: bool = False,
    dry_run: bool = False,
) -> Path:
    source = catalog_bundle_path(root, type_name, bundle_name)
    destination = modify_bundle_path(root, type_name, bundle_name)

    if not source.is_dir():
        raise ValueError(f"catalog bundle not found: codes/{type_name}/{bundle_name}")

    if destination.exists():
        if not overwrite:
            return destination
        if not dry_run:
            shutil.rmtree(destination)

    if dry_run:
        return destination

    shutil.copytree(source, destination)
    assert_writes_only_modify(root, destination)
    return destination


def catalog_bundle_unchanged(root: Path, type_name: str, bundle_name: str, snapshot: dict[str, str]) -> bool:
    bundle_dir = catalog_bundle_path(root, type_name, bundle_name)
    return snapshot_bundle_dir(bundle_dir) == snapshot
