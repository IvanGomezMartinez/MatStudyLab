"""Optional E2E build step against codigosRealesNoSubir/ (US40, local only)."""

from __future__ import annotations

import re
import shutil
from dataclasses import dataclass
from pathlib import Path

from build_import import catalog_from_import, propose_bundles

REAL_BANK = "codigosRealesNoSubir"
TYPE_HINTS = {
    "perfiles_iols": "iol-profiles",
    "moireeffect": "moire",
    "zernikes": "zernikes",
}


PREFERRED_SEGMENTS = (
    "perfiles_iol",
    "iol",
    "mtf",
    "psf",
    "zernike",
    "moire",
    "strehl",
    "fourier",
)


@dataclass(frozen=True)
class RealBankCandidate:
    source_dir: Path
    type_name: str
    matlab_count: int
    preferred: bool


def _is_real_matlab(path: Path) -> bool:
    return path.suffix == ".m" and not path.name.startswith("._")


def _type_from_path(source_dir: Path, bank_root: Path) -> str:
    relative = source_dir.relative_to(bank_root)
    for part in reversed(relative.parts):
        key = re.sub(r"[^a-z0-9]+", "", part.lower())
        if key in TYPE_HINTS:
            return TYPE_HINTS[key]
    leaf = relative.parts[0] if relative.parts else "imported"
    slug = re.sub(r"[^a-z0-9]+", "-", leaf.lower()).strip("-")
    return slug or "imported"


def _is_preferred_optical_path(source_dir: Path, bank_root: Path) -> bool:
    relative = str(source_dir.relative_to(bank_root)).lower()
    return any(segment in relative for segment in PREFERRED_SEGMENTS)


def find_smallest_candidate(bank_root: Path) -> RealBankCandidate | None:
    best: RealBankCandidate | None = None
    for directory in sorted(bank_root.rglob("*")):
        if not directory.is_dir():
            continue
        matlab_files = [path for path in directory.glob("*.m") if _is_real_matlab(path)]
        if not matlab_files:
            continue
        candidate = RealBankCandidate(
            source_dir=directory,
            type_name=_type_from_path(directory, bank_root),
            matlab_count=len(matlab_files),
            preferred=_is_preferred_optical_path(directory, bank_root),
        )
        rank = (0 if candidate.preferred else 1, candidate.matlab_count)
        best_rank = (0 if best.preferred else 1, best.matlab_count) if best else None
        if best is None or rank < best_rank:
            best = candidate
    return best


def run_real_bank_build(root: Path, bank_root: Path) -> Path:
    candidate = find_smallest_candidate(bank_root)
    if candidate is None:
        raise FileNotFoundError(f"no .m bundles under {bank_root}")

    import_dir = root / "import" / candidate.type_name / candidate.source_dir.name
    if import_dir.exists():
        shutil.rmtree(import_dir)
    shutil.copytree(
        candidate.source_dir,
        import_dir,
        ignore=shutil.ignore_patterns("._*", ".DS_Store"),
    )

    proposals = propose_bundles(root)
    matching = [item for item in proposals if item.source_dir.resolve() == import_dir.resolve()]
    if not matching:
        raise AssertionError("scan did not propose the copied real-bank bundle")

    proposal = matching[0]
    catalog_from_import(
        root,
        candidate.type_name,
        proposal.bundle_name,
        proposal.source_dir,
    )

    catalog_dir = root / "codes" / candidate.type_name / proposal.bundle_name
    if not any(path.suffix == ".m" for path in catalog_dir.iterdir() if path.is_file()):
        raise AssertionError("catalog step did not place .m files in codes/")

    if import_dir.exists():
        raise AssertionError("import bundle was not removed after catalog")

    return catalog_dir
