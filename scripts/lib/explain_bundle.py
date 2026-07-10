"""Script resolution and explain doc paths for the /explain command."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

SOURCE_AREAS = ("explain", "codes", "new", "modify", "import")
WRITE_AREA = "explain"
REQUIRED_SECTIONS = (
    "## Possible improvements (not implemented)",
    "## MATLAB concepts",
)


@dataclass(frozen=True)
class ExplainTarget:
    script_path: Path
    output_path: Path
    catalog_path: Path | None


def list_scripts_under_explain(root: Path) -> list[Path]:
    explain_root = root / WRITE_AREA
    if not explain_root.is_dir():
        return []
    return sorted(
        path
        for path in explain_root.rglob("*.m")
        if path.is_file() and not path.name.startswith(".")
    )


def _relative_under_area(script_path: Path, root: Path) -> Path | None:
    try:
        relative = script_path.relative_to(root)
    except ValueError:
        return None
    if not relative.parts or relative.parts[0] not in SOURCE_AREAS:
        return None
    return relative


def explain_output_path(root: Path, script_path: Path) -> Path:
    relative = _relative_under_area(script_path.resolve(), root.resolve())
    stem = script_path.stem
    if relative is None:
        raise ValueError(f"script must live under a known area: {script_path}")

    area = relative.parts[0]
    if area == WRITE_AREA:
        parent = Path(*relative.parts[1:-1])
    else:
        parent = Path(*relative.parts[1:-1])

    return root / WRITE_AREA / parent / f"explain_{stem}.md"


def find_catalog_script(root: Path, script_path: Path) -> Path | None:
    relative = _relative_under_area(script_path.resolve(), root.resolve())
    if relative is None:
        return None
    if relative.parts[0] == "codes":
        return script_path
    if len(relative.parts) >= 3:
        catalog_candidate = root / "codes" / relative.parts[1] / relative.parts[2] / script_path.name
        if catalog_candidate.is_file():
            return catalog_candidate
    return None


def resolve_script(root: Path, hint: str | None) -> ExplainTarget:
    if hint:
        candidate = Path(hint)
        if not candidate.is_absolute():
            candidate = root / candidate
        if not candidate.is_file() or candidate.suffix != ".m":
            raise ValueError(f"script not found: {hint}")
        script_path = candidate.resolve()
    else:
        scripts = list_scripts_under_explain(root)
        if len(scripts) == 0:
            raise ValueError("no .m files under explain/ — add a script or pass a path hint")
        if len(scripts) > 1:
            raise ValueError("multiple scripts under explain/ — pass an explicit path hint")
        script_path = scripts[0].resolve()

    output_path = explain_output_path(root, script_path)
    catalog_path = find_catalog_script(root, script_path)
    return ExplainTarget(script_path, output_path, catalog_path)


def assert_output_in_explain(root: Path, output_path: Path) -> None:
    explain_root = (root / WRITE_AREA).resolve()
    resolved = output_path.resolve()
    if explain_root not in resolved.parents and resolved != explain_root:
        raise ValueError(f"explain output must stay under explain/: {output_path}")


def scaffold_explain_doc(
    root: Path,
    target: ExplainTarget,
    *,
    language: str = "en",
    user_question: str | None = None,
    dry_run: bool = False,
) -> Path:
    assert_output_in_explain(root, target.output_path)
    if dry_run:
        return target.output_path

    target.output_path.parent.mkdir(parents=True, exist_ok=True)
    question_block = (
        f"\n## Your questions\n\n- {user_question}\n"
        if user_question
        else "\n## Your questions\n\n(No question provided.)\n"
    )
    content = f"""# Study: {target.script_path.stem}

> Script: `{target.script_path.relative_to(root)}`  
> Language: {language}

## Summary

(To be filled by the agent after reading the script.)

## Possible improvements (not implemented)

- (Ideas only — do not edit the `.m` file.)

## MATLAB concepts

- (Plain-language teaching notes.)
{question_block}
## Catalog handoff

Run `/accept` to attach this file to the catalog bundle when ready.
"""
    target.output_path.write_text(content, encoding="utf-8")
    return target.output_path


def validate_explain_doc(path: Path) -> bool:
    if not path.is_file():
        return False
    text = path.read_text(encoding="utf-8")
    return all(section in text for section in REQUIRED_SECTIONS)
