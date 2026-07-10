"""Bundle validation and promotion for the /accept command."""

from __future__ import annotations

import shutil
from dataclasses import dataclass, field
from pathlib import Path

from bundle_utils import base_markdown_files

STAGING_AREAS = ("new", "modify")
EXPLAIN_AREA = "explain"


def _cleanup_empty_staging_dirs(start_dir: Path, staging_root: Path) -> None:
    current = start_dir.resolve()
    staging_root = staging_root.resolve()
    while staging_root in current.parents or current == staging_root:
        if current == staging_root:
            break
        if any(current.iterdir()):
            break
        current.rmdir()
        current = current.parent


def _attach_explain_docs(
    root: Path,
    destination: Path,
    explain_docs: list[Path],
    *,
    dry_run: bool,
) -> list[Path]:
    attached: list[Path] = []
    explain_root = root / EXPLAIN_AREA
    for explain_doc in explain_docs:
        target = destination / explain_doc.name
        if not dry_run:
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(explain_doc, target)
            explain_doc.unlink()
            _cleanup_empty_staging_dirs(explain_doc.parent, explain_root)
        attached.append(target)
    return attached


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


def _matlab_files(bundle_dir: Path) -> list[Path]:
    return sorted(bundle_dir.glob("*.m"))


def validate_bundle(bundle_dir: Path) -> ValidationResult:
    result = ValidationResult(ok=True)
    matlab_files = _matlab_files(bundle_dir)
    base_markdown = base_markdown_files(bundle_dir)

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


def explain_doc_stem(explain_doc: Path) -> str:
    if not explain_doc.name.startswith("explain_") or explain_doc.suffix != ".md":
        raise ValueError(f"not an explain doc: {explain_doc.name}")
    return explain_doc.stem[len("explain_") :]


def find_catalog_script_by_stem(root: Path, stem: str) -> Path | None:
    matches = sorted(root.glob(f"codes/*/*/{stem}.m"))
    if len(matches) > 1:
        raise ValueError(f"ambiguous stem {stem}: multiple catalog matches")
    return matches[0] if matches else None


def resolve_explain_attachment(
    root: Path, explain_doc: Path
) -> tuple[str, str, Path]:
    explain_root = (root / "explain").resolve()
    resolved = explain_doc.resolve()
    if explain_root not in resolved.parents:
        raise ValueError(f"explain doc must be under explain/: {explain_doc}")

    relative = resolved.relative_to(explain_root)
    stem = explain_doc_stem(resolved)

    if len(relative.parts) >= 3:
        type_name, bundle_name = relative.parts[0], relative.parts[1]
    elif len(relative.parts) == 1:
        script = find_catalog_script_by_stem(root, stem)
        if script is None:
            raise ValueError(f"no catalog .m for stem: {stem}")
        catalog_relative = script.relative_to(root / "codes")
        type_name, bundle_name = catalog_relative.parts[0], catalog_relative.parts[1]
    else:
        raise ValueError(f"cannot resolve catalog bundle for: {relative}")

    catalog_dir = root / "codes" / type_name / bundle_name
    if not catalog_dir.is_dir():
        raise ValueError(f"catalog bundle not found: codes/{type_name}/{bundle_name}")
    if not (catalog_dir / f"{stem}.m").is_file():
        raise ValueError(f"no matching .m in catalog: {stem}.m")

    return type_name, bundle_name, catalog_dir / explain_doc.name


def list_pending_explain_attachments(
    root: Path,
    *,
    type_name: str | None = None,
    bundle_name: str | None = None,
) -> list[Path]:
    explain_root = root / "explain"
    if not explain_root.is_dir():
        return []

    docs = sorted(
        path
        for path in explain_root.rglob("explain_*.md")
        if path.is_file() and not path.name.startswith(".")
    )
    if not type_name:
        return docs

    filtered: list[Path] = []
    for doc in docs:
        doc_type, doc_bundle, _ = resolve_explain_attachment(root, doc)
        if doc_type != type_name:
            continue
        if bundle_name and doc_bundle != bundle_name:
            continue
        filtered.append(doc)
    return filtered


def accept_explain_attachments(
    root: Path,
    *,
    type_name: str | None = None,
    bundle_name: str | None = None,
    dry_run: bool = False,
) -> list[Path]:
    attached: list[Path] = []
    explain_docs = list_pending_explain_attachments(
        root, type_name=type_name, bundle_name=bundle_name
    )
    for explain_doc in explain_docs:
        _, _, target = resolve_explain_attachment(root, explain_doc)
        if dry_run:
            attached.append(target)
            continue
        attached.extend(
            _attach_explain_docs(root, target.parent, [explain_doc], dry_run=False)
        )
    return attached


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

    attached = _attach_explain_docs(root, destination, explain_docs, dry_run=False)

    shutil.rmtree(source)
    _cleanup_empty_staging_dirs(source.parent, root / bundle.staging)
    return attached
