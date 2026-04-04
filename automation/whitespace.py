#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

TRAILING_WHITESPACE_RE = re.compile(rb"[ \t]+(?=\r?\n|$)")
EXCLUDED_SUFFIXES = {".md", ".markdown"}


def get_repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def list_tracked_files(repo_root: Path) -> list[Path]:
    result = subprocess.run(
        ["git", "ls-files", "-z"],
        cwd=repo_root,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        stderr = result.stderr.decode("utf-8", errors="replace").strip()
        raise RuntimeError(f"git ls-files failed with exit code {result.returncode}: {stderr}")

    return [
        Path(path.decode("utf-8", errors="surrogateescape"))
        for path in result.stdout.split(b"\0")
        if path
    ]


def is_included_file(path: Path) -> bool:
    return path.suffix.lower() not in EXCLUDED_SUFFIXES


def read_candidate_files(repo_root: Path):
    for relative_path in list_tracked_files(repo_root):
        if not is_included_file(relative_path):
            continue

        absolute_path = repo_root / relative_path
        if not absolute_path.is_file():
            continue

        content = absolute_path.read_bytes()
        if b"\0" in content:
            continue

        yield relative_path, absolute_path, content


def find_violations(content: bytes) -> list[int]:
    violations: list[int] = []
    for line_number, line in enumerate(content.splitlines(), start=1):
        if line.endswith((b" ", b"\t")):
            violations.append(line_number)
    return violations


def command_check(repo_root: Path) -> int:
    violations_found = False

    for relative_path, _, content in read_candidate_files(repo_root):
        violations = find_violations(content)
        if not violations:
            continue

        if not violations_found:
            print("[whitespace] ERROR: Trailing whitespace found in non-Markdown tracked files:")
            violations_found = True

        for line_number in violations:
            print(f"{relative_path.as_posix()}:{line_number}")

    if violations_found:
        return 1

    print("[whitespace] OK: No trailing whitespace found in non-Markdown tracked files.")
    return 0


def command_fix(repo_root: Path) -> int:
    fixed_files: list[Path] = []

    for relative_path, absolute_path, content in read_candidate_files(repo_root):
        normalized = TRAILING_WHITESPACE_RE.sub(b"", content)
        if normalized == content:
            continue

        absolute_path.write_bytes(normalized)
        fixed_files.append(relative_path)
        print(f"[whitespace] Fixed {relative_path.as_posix()}")

    if not fixed_files:
        print("[whitespace] OK: No trailing whitespace found in non-Markdown tracked files.")
        return 0

    print(f"[whitespace] OK: Fixed trailing whitespace in {len(fixed_files)} file(s).")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Check or fix trailing whitespace in tracked non-Markdown files.")
    parser.add_argument("command", choices=("check", "fix"))
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    repo_root = get_repo_root()

    if args.command == "check":
        return command_check(repo_root)

    if args.command == "fix":
        return command_fix(repo_root)

    parser.error(f"unsupported command: {args.command}")
    return 2


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except RuntimeError as error:
        print(f"[whitespace] ERROR: {error}", file=sys.stderr)
        raise SystemExit(2)
