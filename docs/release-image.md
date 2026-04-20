# Release Image

This repository publishes a prebuilt Ubuntu runtime image that has already completed the repository's container workflow. The image runs `bootstrap -> install -> stow -> post` during build, then finalizes the result so selected software, deployed dotfiles, and post-install artifacts are present when the image starts.

## Source of Truth

`ci/image/` is the home for the published image Dockerfile and image-specific build assets. The Docker build context is the repository root because the image build consumes `.dotter/`, `packages/`, `bootstrap/`, `script/`, `justfile`, and `bootstrap-up.sh`.

Do not keep release image build inputs under `test/`. The `test/` tree is reserved for validation assets and disposable harnesses.
Use the root `.dockerignore` to keep the repository-root build context tight and to exclude local state such as `.dotter/local.toml` and `.dotter/cache.toml`.

## Image Name

The Ubuntu release image is published as:

    ghcr.io/petejohn6/ubuntu-dotfile

A `push` publish job only runs for `master` and updates:

    ghcr.io/petejohn6/ubuntu-dotfile:master

When `master` is the default branch, the same publish job also updates:

    ghcr.io/petejohn6/ubuntu-dotfile:latest

Published tags are multi-architecture images for `linux/amd64` and `linux/arm64`. The `linux/arm64` variant is intended for Linux container runtimes on Apple Silicon Macs and other ARM64 hosts.

## Local Build

From the repository root:

    docker build -f ci/image/Dockerfile -t ubuntu-dotfile:local .

The build context must remain the repository root so the release workflow and local builds use the same deployment inputs.

Fresh container bootstraps and this image build both seed `.dotter/local.toml` from `.dotter/default/container.toml`. During the image build, `bash bootstrap-up.sh` performs the normal repository workflow in `/workspace`. Then `ci/image/finalize-image.sh` materializes deployed symlinks under the container home directory that still point into `/workspace` and removes `/workspace`.

The final image is a runtime artifact, not a repo-debug image. It does not preserve the working tree for later `just` or `dotter` reruns inside the container.

## Change Detection

The release workflow uses changed-file classification so the image build only runs when the selected commit or push range can affect the image artifact. Workflow YAML stays limited to orchestration; watched-path facts live in `file-classifier.toml`, and `hack/change-detection/main.py` evaluates those facts.

The repository answers three related questions from one fact file:

- `user_workflow_changed`: did a broad maintained user-workflow implementation input change?
- `user_workflow_container_changed`: did the container-specific subset of user-workflow inputs change?
- `dotfile_image_manifest_changed`: did any release-image manifest input change?

Among the change-detection outputs, only `dotfile_image_manifest_changed` gates the image job. It covers the container-specific user-workflow inputs plus `file-classifier.toml`, `hack/change-detection/main.py`, `.dockerignore`, `ci/image/**`, and `.github/workflows/ubuntu-dotfile.yml`.

`file-classifier.toml` is intentionally flat. Each top-level TOML table is one classifier. A classifier can include another classifier additively, and the final watched-path list is the union of included patterns and direct patterns. The fact file does not support excludes or negative matching.

The Python CLI prints exactly one line, either `true` or `false`:

    python3 hack/change-detection/main.py --source workspace user_workflow
    python3 hack/change-detection/main.py --source workspace user_workflow_container
    python3 hack/change-detection/main.py --source workspace dotfile_image_manifest
    python3 hack/change-detection/main.py --source commit --base <sha> --head <sha> dotfile_image_manifest

Use `workspace` for local maintainer checks before committing. It compares the current working tree against `HEAD`, including untracked files. The workflow uses `commit`. Without an explicit range, `commit` compares checked-out `HEAD` against `HEAD^1` and falls back to the complete `HEAD` file tree when `HEAD` has no parent. For push events, the workflow passes GitHub's event `before` SHA and checked-out `sha` with `--base` and `--head`, so a multi-commit `master` push is classified across the complete pushed range.

If the explicit push base is GitHub's all-zero null SHA or the base object is unavailable in the checkout, the CLI classifies the complete file tree of the selected head. That intentionally fails open toward building the image rather than silently skipping a possible release-image input change.

Typical interpretations:

- editing `packages/alacritty/...` makes only `user_workflow` print `true`
- editing `packages/zsh/...` makes all three classifiers print `true`
- adding `packages/post/foo.sh` makes all three classifiers print `true`
- editing `ci/image/Dockerfile` makes only `dotfile_image_manifest` print `true`
- editing `file-classifier.toml` or `hack/change-detection/main.py` makes only `dotfile_image_manifest` print `true`
- editing docs only makes all three classifiers print `false`

## GitHub Actions

`.github/workflows/ubuntu-dotfile.yml` is the release workflow for this image.

- The workflow triggers on every `pull_request`, on `push` to `master`, and on manual dispatch.
- The `detect-changes` job always runs first and classifies either the pull request merge commit or the explicit push range before deciding whether the image job is needed.
- Pull requests that set `dotfile_image_manifest_changed=true` build the image but do not publish it.
- Pushes to `master` that set `dotfile_image_manifest_changed=true` build and publish `ghcr.io/petejohn6/ubuntu-dotfile:master`; when `master` is the default branch, they also publish `ghcr.io/petejohn6/ubuntu-dotfile:latest`.
- Pushes to other branches do not trigger the release workflow and cannot publish image tags.
- Manual workflow dispatch bypasses diff classification and always runs the image build for branch-local validation, but it does not publish images.
