"""Import scan and catalog operations for the /build command."""

from __future__ import annotations

import shutil
from dataclasses import dataclass
from pathlib import Path

IMPORT_AREA = "import"
CATALOG_AREA = "codes"


@dataclass(frozen=True)
class ImportBundleProposal:
    source_dir: Path
    bundle_name: str
    matlab_files: tuple[Path, ...]


@dataclass(frozen=True)
class CatalogResult:
    catalog_dir: Path
    moved_files: tuple[Path, ...]
    drafted_companion: Path | None


class HomonymError(ValueError):
    pass


def scan_import_matlab_files(root: Path) -> list[Path]:
    import_root = root / IMPORT_AREA
    if not import_root.is_dir():
        return []
    return sorted(
        path
        for path in import_root.rglob("*.m")
        if path.is_file() and not path.name.startswith(".")
    )


def _bundle_name_for_dir(import_root: Path, directory: Path, matlab_files: list[Path]) -> str:
    if directory == import_root:
        if len(matlab_files) != 1:
            raise ValueError("multiple .m files directly under import/ require subfolders")
        return matlab_files[0].stem
    return directory.name


def propose_bundles(root: Path) -> list[ImportBundleProposal]:
    import_root = root / IMPORT_AREA
    matlab_files = scan_import_matlab_files(root)
    grouped: dict[Path, list[Path]] = {}
    for matlab_file in matlab_files:
        grouped.setdefault(matlab_file.parent, []).append(matlab_file)

    proposals: list[ImportBundleProposal] = []
    for directory, files in sorted(grouped.items(), key=lambda item: str(item[0])):
        sorted_files = tuple(sorted(files))
        bundle_name = _bundle_name_for_dir(import_root, directory, list(sorted_files))
        proposals.append(
            ImportBundleProposal(
                source_dir=directory,
                bundle_name=bundle_name,
                matlab_files=sorted_files,
            )
        )
    return proposals


def homonym_exists(root: Path, type_name: str, bundle_name: str) -> bool:
    return (root / CATALOG_AREA / type_name / bundle_name).exists()


def _base_markdown_files(bundle_dir: Path) -> list[Path]:
    return [
        path
        for path in bundle_dir.glob("*.md")
        if path.is_file() and not path.name.startswith("explain_")
    ]


def draft_companion_md(bundle_dir: Path, primary_script: Path) -> Path:
    companion = bundle_dir / f"{primary_script.stem}.md"
    if companion.exists():
        return companion
    companion.write_text(
        f"# {primary_script.stem}\n\n> Draft companion from /build. Edit before sharing.\n",
        encoding="utf-8",
    )
    return companion


def catalog_from_import(
    root: Path,
    type_name: str,
    bundle_name: str,
    source_dir: Path,
    *,
    dry_run: bool = False,
) -> CatalogResult:
    import_root = (root / IMPORT_AREA).resolve()
    resolved_source = source_dir.resolve()
    if import_root not in resolved_source.parents and resolved_source != import_root:
        raise ValueError(f"source must be under import/: {source_dir}")

    if homonym_exists(root, type_name, bundle_name):
        raise HomonymError(
            f"catalog bundle already exists: codes/{type_name}/{bundle_name}"
        )

    destination = root / CATALOG_AREA / type_name / bundle_name
    files_to_move = sorted(
        path for path in resolved_source.iterdir() if path.is_file()
    )
    if not any(path.suffix == ".m" for path in files_to_move):
        raise ValueError("bundle folder has no .m files")

    if dry_run:
        return CatalogResult(destination, tuple(files_to_move), None)

    destination.mkdir(parents=True, exist_ok=False)
    moved: list[Path] = []
    for source_file in files_to_move:
        target = destination / source_file.name
        shutil.move(str(source_file), str(target))
        moved.append(target)

    primary_script = next(path for path in moved if path.suffix == ".m")
    drafted = None
    if not _base_markdown_files(destination):
        drafted = draft_companion_md(destination, primary_script)

    _cleanup_empty_import_dirs(resolved_source, import_root)
    return CatalogResult(destination, tuple(moved), drafted)


def _cleanup_empty_import_dirs(source_dir: Path, import_root: Path) -> None:
    current = source_dir
    while import_root in current.parents:
        if any(current.iterdir()):
            break
        current.rmdir()
        current = current.parent


def remove_cataloged_import_files(root: Path, import_files: list[Path]) -> None:
    import_root = (root / IMPORT_AREA).resolve()
    touched_dirs: set[Path] = set()
    for import_file in import_files:
        resolved = import_file.resolve()
        if import_root not in resolved.parents:
            raise ValueError(f"not under import/: {import_file}")
        if resolved.is_file():
            resolved.unlink()
            touched_dirs.add(resolved.parent)

    for directory in sorted(touched_dirs, key=lambda path: len(path.parts), reverse=True):
        if directory.is_dir() and not any(directory.iterdir()):
            directory.rmdir()
