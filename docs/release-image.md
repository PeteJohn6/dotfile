# Release Image

This repository publishes a prebuilt Ubuntu runtime image that has already completed the repository's container workflow. The published image is not a thin base image. It runs `bootstrap -> install -> stow -> post` during the image build, then finalizes the result so the selected software, deployed dotfiles, and post-install artifacts are already present when the image starts.

## Source of Truth

`ci/image/` remains the home for the published image Dockerfile and any image-specific build assets, but the Docker build context is the repository root. That is required because the image build consumes `.dotter/`, `packages/`, `bootstrap/`, `script/`, `justfile`, and `bootstrap-up.sh`.

Do not keep release image build inputs under `test/`. The `test/` tree is reserved for validation assets and disposable harnesses.
Use the root `.dockerignore` to keep the repository-root build context tight and to exclude local state such as `.dotter/local.toml` and `.dotter/cache.toml`.

## Image Name

The Ubuntu release image is published as:

    ghcr.io/petejohn6/ubuntu-dotfile

The default-branch publish job updates:

    ghcr.io/petejohn6/ubuntu-dotfile:latest

That tag is published as a multi-architecture image for `linux/amd64` and `linux/arm64`. The `linux/arm64` variant is intended for Linux container runtimes on Apple Silicon Macs and other ARM64 hosts.

## Local Build

From the repository root:

    docker build -f ci/image/Dockerfile -t ubuntu-dotfile:local .

The build context must remain the repository root so the release workflow and local builds use the same deployment inputs.

Fresh container bootstraps and this image build both seed `.dotter/local.toml` from `.dotter/default/container.toml`. During the image build, `bash bootstrap-up.sh` performs the normal repository workflow in `/workspace`. After that, `ci/image/finalize-image.sh` materializes any deployed symlinks under the container home directory that still point into `/workspace`, then removes `/workspace` so the final image no longer depends on the repository source tree.

The final image is a runtime artifact, not a repo-debug image. It does not preserve the working tree for later `just` or `dotter` reruns inside the container.

## GitHub Actions

`.github/workflows/ubuntu-dotfile.yml` is the release workflow for this image.

- Pull requests that touch image-affecting inputs such as `.dotter/**`, `packages/**`, `bootstrap/**`, `script/**`, `justfile`, `bootstrap-up.sh`, `.dockerignore`, or `ci/image/**` build the image but do not publish it.
- Pushes to the default branch that touch those same inputs build and publish `ghcr.io/petejohn6/ubuntu-dotfile:latest` to GHCR.
- Manual workflow dispatch is available for branch-local validation, but it does not publish or move the `latest` tag.
