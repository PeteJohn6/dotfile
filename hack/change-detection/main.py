#!/usr/bin/env python3
"""Classify repository changes from the repository file-classifier TOML."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path
from typing import Dict, Iterable, List


if sys.version_info < (3, 11):
    print("[change-detection] ERROR: Python 3.11+ is required for tomllib", file=sys.stderr)
    raise SystemExit(1)

import tomllib


FIELD_NAMES = {"includes", "patterns"}
SOURCE_MODES = {"workspace", "commit"}
REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_MANIFEST = REPO_ROOT / "file-classifier.toml"


class ChangeDetectionError(RuntimeError):
    """Raised when change detection cannot complete."""


def normalize_path(value: str) -> str:
    return value.replace("\\", "/").strip()


def load_manifest(path: Path) -> dict:
    try:
        with path.open("rb") as fh:
            return tomllib.load(fh)
    except FileNotFoundError as exc:
        raise ChangeDetectionError(f"missing manifest: {path}") from exc
    except tomllib.TOMLDecodeError as exc:
        raise ChangeDetectionError(f"invalid TOML in {path}: {exc}") from exc


def flatten_definitions(tree: dict) -> Dict[str, dict]:
    definitions: Dict[str, dict] = {}

    for key, value in tree.items():
        if not isinstance(value, dict):
            raise ChangeDetectionError(f"expected table at {key}")

        includes = value.get("includes", [])
        patterns = value.get("patterns", [])
        if not isinstance(includes, list) or not all(isinstance(item, str) for item in includes):
            raise ChangeDetectionError(f"{key}.includes must be an array of strings")
        if not isinstance(patterns, list) or not all(isinstance(item, str) for item in patterns):
            raise ChangeDetectionError(f"{key}.patterns must be an array of strings")

        extra_keys = set(value) - FIELD_NAMES
        if extra_keys:
            extras = ", ".join(sorted(extra_keys))
            raise ChangeDetectionError(f"{key} contains unsupported keys: {extras}")

        definitions[key] = {
            "includes": includes,
            "patterns": patterns,
        }

    return definitions


def dedupe(items: Iterable[str]) -> List[str]:
    seen = set()
    result = []
    for item in items:
        if item in seen:
            continue
        seen.add(item)
        result.append(item)
    return result


def resolve_patterns(definitions: Dict[str, dict], name: str) -> List[str]:
    cache: Dict[str, List[str]] = {}

    def resolve(current: str, stack: List[str]) -> List[str]:
        if current in cache:
            return cache[current]
        if current in stack:
            cycle = " -> ".join(stack + [current])
            raise ChangeDetectionError(f"include cycle detected: {cycle}")
        if current not in definitions:
            raise ChangeDetectionError(f"unknown classifier: {current}")

        definition = definitions[current]
        resolved: List[str] = []
        next_stack = stack + [current]
        for include in definition["includes"]:
            resolved.extend(resolve(include, next_stack))
        resolved.extend(normalize_path(pattern) for pattern in definition["patterns"])
        cache[current] = dedupe(resolved)
        return cache[current]

    return resolve(name, [])


def matches_pattern(path: str, pattern: str) -> bool:
    if pattern.endswith("/**"):
        return path.startswith(pattern[:-2])
    return path == pattern


def any_match(paths: Iterable[str], patterns: Iterable[str]) -> bool:
    normalized_patterns = [normalize_path(pattern) for pattern in patterns]
    for raw_path in paths:
        path = normalize_path(raw_path)
        if not path:
            continue
        for pattern in normalized_patterns:
            if matches_pattern(path, pattern):
                return True
    return False


def run_git(repo_root: Path, args: List[str], *, allow_failure: bool = False) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        ["git", *args],
        cwd=repo_root,
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0 and not allow_failure:
        stderr = result.stderr.strip()
        detail = f": {stderr}" if stderr else ""
        raise ChangeDetectionError(f"git {' '.join(args)} failed{detail}")
    return result


def split_git_paths(output: str) -> List[str]:
    return [line.strip() for line in output.splitlines() if line.strip()]


def is_null_revision(revision: str) -> bool:
    return bool(revision) and set(revision) == {"0"}


def git_commit_exists(repo_root: Path, revision: str) -> bool:
    result = run_git(repo_root, ["cat-file", "-e", f"{revision}^{{commit}}"], allow_failure=True)
    return result.returncode == 0


def collect_workspace_changes(repo_root: Path) -> List[str]:
    diff = run_git(repo_root, ["diff", "--name-only", "HEAD", "--"])
    untracked = run_git(repo_root, ["ls-files", "--others", "--exclude-standard"])
    return sorted(set(split_git_paths(diff.stdout) + split_git_paths(untracked.stdout)))


def collect_tree_paths(repo_root: Path, head: str) -> List[str]:
    tree = run_git(repo_root, ["ls-tree", "-r", "--name-only", head])
    return split_git_paths(tree.stdout)


def collect_commit_changes(repo_root: Path, base: str | None = None, head: str | None = None) -> List[str]:
    if (base is None) != (head is None):
        raise ChangeDetectionError("--base and --head must be provided together")

    if base is not None and head is not None:
        base = base.strip()
        head = head.strip()
        if not base or not head:
            raise ChangeDetectionError("--base and --head cannot be empty")
        if is_null_revision(base):
            return collect_tree_paths(repo_root, head)
        if not git_commit_exists(repo_root, base):
            print(
                f"[change-detection] WARNING: base revision {base} is unavailable; classifying full tree of {head}",
                file=sys.stderr,
            )
            return collect_tree_paths(repo_root, head)

        diff = run_git(repo_root, ["diff", "--name-only", base, head, "--"])
        return split_git_paths(diff.stdout)

    parent = run_git(repo_root, ["rev-parse", "--verify", "HEAD^1"], allow_failure=True)
    if parent.returncode == 0:
        diff = run_git(repo_root, ["diff", "--name-only", "HEAD^1", "HEAD", "--"])
        return split_git_paths(diff.stdout)

    return collect_tree_paths(repo_root, "HEAD")


def collect_changes(repo_root: Path, source: str, *, base: str | None = None, head: str | None = None) -> List[str]:
    if source == "workspace":
        if base is not None or head is not None:
            raise ChangeDetectionError("--base and --head are only valid with --source commit")
        return collect_workspace_changes(repo_root)
    if source == "commit":
        return collect_commit_changes(repo_root, base, head)
    raise ChangeDetectionError(f"unknown source: {source}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("classifier", help="Classifier name from the top-level TOML tables")
    parser.add_argument(
        "--source",
        choices=sorted(SOURCE_MODES),
        required=True,
        help="Changed-path source to classify.",
    )
    parser.add_argument(
        "--manifest",
        default=str(DEFAULT_MANIFEST),
        help="Path to the classifier TOML file",
    )
    parser.add_argument("--base", help="Base commit for explicit commit-range classification")
    parser.add_argument("--head", help="Head commit for explicit commit-range classification")
    return parser


def main(argv: List[str]) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    try:
        manifest = load_manifest(Path(args.manifest))
        definitions = flatten_definitions(manifest)
        patterns = resolve_patterns(definitions, args.classifier)

        changed_paths = collect_changes(REPO_ROOT, args.source, base=args.base, head=args.head)
        print("true" if any_match(changed_paths, patterns) else "false")
        return 0
    except ChangeDetectionError as exc:
        print(f"[change-detection] ERROR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
