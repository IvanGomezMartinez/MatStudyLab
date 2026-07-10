"""E2E pipeline orchestration and safety assertions (T8)."""

from __future__ import annotations

import shutil
from dataclasses import dataclass
from pathlib import Path

from accept_bundle import BundleRef, accept_bundle
from build_import import catalog_from_import
from explain_bundle import ExplainTarget, resolve_script, scaffold_explain_doc
from modify_bundle import catalog_bundle_unchanged, copy_catalog_to_modify

FIXTURE_REL = Path("scripts/fixtures/e2e/iol_profiles_bundle")
E2E_TYPE = "iol-profiles"
E2E_BUNDLE = "synthetic_iol_profile"
E2E_STEM = "synthetic_iol_profile"


@dataclass
class E2EResult:
    catalog_dir: Path
    explain_doc: Path
    accepted_explain: Path


def snapshot_catalog_files(root: Path) -> dict[str, str]:
    codes_root = root / "codes"
    if not codes_root.is_dir():
        return {}
    snapshot: dict[str, str] = {}
    for path in sorted(codes_root.rglob("*")):
        if path.is_file():
            snapshot[str(path.relative_to(root))] = path.read_text(encoding="utf-8")
    return snapshot


def assert_codes_unchanged(root: Path, before: dict[str, str]) -> None:
    after = snapshot_catalog_files(root)
    if before != after:
        raise AssertionError("codes/ changed without an allowed pipeline step")


def seed_import_from_fixture(root: Path) -> Path:
    fixture = root / FIXTURE_REL
    if not fixture.is_dir():
        raise FileNotFoundError(f"missing E2E fixture: {FIXTURE_REL}")
    destination = root / "import" / E2E_TYPE / E2E_BUNDLE
    if destination.exists():
        shutil.rmtree(destination)
    shutil.copytree(fixture, destination)
    return destination


def snapshot_bundle(root: Path, type_name: str, bundle_name: str) -> dict[str, str]:
    bundle_dir = root / "codes" / type_name / bundle_name
    return {
        path.name: path.read_text(encoding="utf-8")
        for path in sorted(bundle_dir.iterdir())
        if path.is_file()
    }


def run_pipeline(root: Path) -> E2EResult:
    before = snapshot_catalog_files(root)
    assert_codes_unchanged(root, before)

    import_dir = seed_import_from_fixture(root)
    catalog_from_import(root, E2E_TYPE, E2E_BUNDLE, import_dir)

    catalog_dir = root / "codes" / E2E_TYPE / E2E_BUNDLE
    script_path = catalog_dir / f"{E2E_STEM}.m"
    if not script_path.is_file():
        raise AssertionError("build step did not catalog script into codes/")

    bundle_snapshot = snapshot_bundle(root, E2E_TYPE, E2E_BUNDLE)

    target = resolve_script(root, str(script_path.relative_to(root)))
    explain_doc = scaffold_explain_doc(
        root,
        target,
        user_question="What does the peak height mean optically?",
    )
    explain_doc.write_text(
        explain_doc.read_text(encoding="utf-8").replace(
            "(To be filled by the agent after reading the script.)",
            "Synthetic IOL profile peak for E2E validation.",
        ),
        encoding="utf-8",
    )

    if not catalog_bundle_unchanged(root, E2E_TYPE, E2E_BUNDLE, bundle_snapshot):
        raise AssertionError("codes/ bundle changed during explain (in-situ edit)")

    copy_catalog_to_modify(root, E2E_TYPE, E2E_BUNDLE)
    bundle = BundleRef("modify", E2E_TYPE, E2E_BUNDLE)
    attached = accept_bundle(root, bundle)

    accepted_explain = catalog_dir / explain_doc.name
    if not accepted_explain.is_file():
        raise AssertionError("accept did not attach explain doc to catalog bundle")
    if not attached:
        raise AssertionError("accept reported no explain attachments")

    if (root / "modify" / E2E_TYPE / E2E_BUNDLE).exists():
        raise AssertionError("modify staging was not cleared after accept")

    return E2EResult(catalog_dir, explain_doc, accepted_explain)


def assert_import_fixture_removed(root: Path) -> None:
    import_bundle = root / "import" / E2E_TYPE / E2E_BUNDLE
    if import_bundle.exists():
        raise AssertionError("import bundle was not removed after catalog")
