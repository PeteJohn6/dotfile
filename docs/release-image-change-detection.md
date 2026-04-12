# Release Image Change Detection

This document describes the reusable change-detection scripts under `hack/` that support the `ubuntu-dotfile` workflow and other maintainer checks.

## Purpose

The repository has two related questions it needs to answer from repository state:

- did a user-workflow implementation input change?
- did any `ubuntu-dotfile` image input change?

Those questions are intentionally answered by two separate scripts so other CI jobs or lint checks can depend on the exact question they need instead of re-implementing path logic in YAML.

## Scripts

`hack/user_workflow_changed.sh` prints `true` when the selected diff source includes any of these paths:

- `.dotter/**`
- `bootstrap/**`
- `bootstrap-up.sh`
- `justfile`
- `packages/**`
- `script/**`

`hack/dotfile_image_inputs_changed.sh` prints `true` when the selected diff source includes any of the user-workflow paths above, plus:

- `.dockerignore`
- `ci/image/**`
- `.github/workflows/ubuntu-dotfile.yml`

Both scripts print exactly one line, either `true` or `false`.

## Source Modes

Both scripts require one positional argument:

- `workspace`: compare the current working tree against `HEAD`, including untracked files.
- `head`: compare `HEAD` against `HEAD^1`. If `HEAD` has no parent, the script falls back to a root-commit diff.

Use `workspace` for local maintainer checks before committing. Use `head` for commit-based CI checks and workflows that evaluate the current commit.

## Examples

From the repository root:

    bash hack/user_workflow_changed.sh workspace
    bash hack/dotfile_image_inputs_changed.sh workspace
    bash hack/user_workflow_changed.sh head
    bash hack/dotfile_image_inputs_changed.sh head

Typical interpretations:

- editing `packages/...` should make both scripts print `true`
- editing `ci/image/Dockerfile` should make only `hack/dotfile_image_inputs_changed.sh` print `true`
- editing docs only should make both scripts print `false`

## Workflow Usage

`.github/workflows/ubuntu-dotfile.yml` uses `head` mode because the workflow evaluates the checked-out commit, not a mutable working tree.

Keep the path rules in these scripts and keep the workflow YAML limited to orchestration. If another maintainer check needs the same classifications, call these scripts directly rather than duplicating path lists in the caller.
