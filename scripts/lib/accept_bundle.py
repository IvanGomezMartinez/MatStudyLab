"""Bundle validation and promotion for the /accept command."""

from __future__ import annotations

import shutil
from dataclasses import dataclass, field
from pathlib import Path

STAGING_AREAS = ("new", "modify")


@dataclass(frozen=True)
class BundleRef:
    staging: str
    type_name: str
    bundle_name: str

    def source_path(self, root: Path) -> Path:
        return root / self.staging / self.type_name / self.bundle_name

    def catalog_path(self, root: Path) -> Path:
        return root / "codes" / self.type_name / self.bundle_name


@dataclass
class ValidationResult:
    ok: bool
    errors: list[str] = field(default_factory=list)
    matlab_files: list[Path] = field(default_factory=list)
    base_companion: Path | None = None


def list_pending_bundles(root: Path) -> list[BundleRef]:
    bundles: list[BundleRef] = []
    for staging in STAGING_AREAS:
        staging_root = root / staging
        if not staging_root.is_dir():
            continue
        for type_dir in sorted(staging_root.iterdir()):
            if not type_dir.is_dir() or type_dir.name.startswith("."):
                continue
            for bundle_dir in sorted(type_dir.iterdir()):
                if bundle_dir.is_dir() and not bundle_dir.name.startswith("."):
                    bundles.append(
                        BundleRef(staging, type_dir.name, bundle_dir.name)
                    )
    return bundles


def _base_markdown_files(bundle_dir: Path) -> list[Path]:
    return sorted(
        path
        for path in bundle_dir.glob("*.md")
        if not path.name.startswith("explain_")
    )


def _matlab_files(bundle_dir: Path) -> list[Path]:
    return sorted(bundle_dir.glob("*.m"))


def validate_bundle(bundle_dir: Path) -> ValidationResult:
    result = ValidationResult(ok=True)
    matlab_files = _matlab_files(bundle_dir)
    base_markdown = _base_markdown_files(bundle_dir)

    if not matlab_files:
        result.errors.append("missing .m file")
    if not base_markdown:
        result.errors.append("missing base companion .md")

    if len(base_markdown) > 1:
        result.errors.append("multiple base companion .md files; N:1 allows one .md")

    if matlab_files and base_markdown:
        companion = base_markdown[0]
        if len(matlab_files) == 1 and len(base_markdown) == 1:
            if matlab_files[0].stem != companion.stem:
                result.errors.append(
                    "1:1 bundle requires matching .m and .md stems"
                )
        result.base_companion = companion

    result.matlab_files = matlab_files
    result.ok = not result.errors
    return result


def find_explain_attachments(explain_root: Path, stems: list[str]) -> list[Path]:
    found: list[Path] = []
    if not explain_root.is_dir():
        return found
    for stem in stems:
        matches = sorted(explain_root.rglob(f"explain_{stem}.md"))
        found.extend(matches)
    return found


def accept_bundle(root: Path, bundle: BundleRef, *, dry_run: bool = False) -> list[Path]:
    source = bundle.source_path(root)
    destination = bundle.catalog_path(root)

    validation = validate_bundle(source)
    if not validation.ok:
        raise ValueError("; ".join(validation.errors))

    if bundle.staging == "new" and destination.exists():
        raise ValueError(
            f"catalog bundle already exists: codes/{bundle.type_name}/{bundle.bundle_name}"
        )

    stems = [path.stem for path in validation.matlab_files]
    explain_docs = find_explain_attachments(root / "explain", stems)

    if dry_run:
        return explain_docs

    if destination.exists():
        shutil.rmtree(destination)

    shutil.copytree(source, destination)

    attached: list[Path] = []
    for explain_doc in explain_docs:
        target = destination / explain_doc.name
        shutil.copy2(explain_doc, target)
        attached.append(target)

    shutil.rmtree(source)
    return attached
