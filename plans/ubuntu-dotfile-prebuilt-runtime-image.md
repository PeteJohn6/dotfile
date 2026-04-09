# Prebuild the `ubuntu-dotfile` Runtime Image

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This document is maintained in accordance with `PLANS.md` at the repository root.

## Trigger / Why This Needs an ExecPlan

This work changes a durable repository output: the published `ghcr.io/petejohn6/ubuntu-dotfile` image. The repository already contains release-image docs and a GitHub Actions workflow that describe this artifact, so the implementation must be driven by a checked-in ExecPlan rather than an ephemeral chat summary.

## Purpose / Big Picture

After this change, the published Ubuntu image is a real runtime artifact, not just a partially prepared build environment. Building `ci/image/Dockerfile` runs the repository's normal `bootstrap -> install -> stow -> post` workflow during `docker build`, then converts repository-backed Dotter symlinks in the container home directory into ordinary files and directories before the image is finalized. A person can verify the behavior by building the image locally, starting a container, and observing that files such as `/root/.zshrc` and `/root/.config/nvim/init.lua` exist without depending on `/workspace` or the repository checkout.

## Progress

- [x] (2026-04-10T06:42:17+08:00) Read `PLANS.md`, the release-image docs, the workflow, and the current Unix workflow implementation to confirm the current contract and the implementation gap.
- [x] (2026-04-10T06:42:17+08:00) Added the missing release-image implementation files: root `.dockerignore`, `ci/image/Dockerfile`, and `ci/image/finalize-image.sh`.
- [x] (2026-04-10T06:42:17+08:00) Updated user-facing and maintainer-facing docs so they describe release-image finalization rather than claiming that generic container `stow` always materializes symlinks.
- [x] (2026-04-10T06:42:17+08:00) Ran static validation with Linux `bash -n` inside a temporary Ubuntu container, built `ci/image/Dockerfile` locally, and verified that `/root/.zshrc`, `/root/.config/nvim/init.lua`, and `/root/.gitconfig` are ordinary files while `/workspace` is absent in the final runtime image.

## Surprises & Discoveries

- Observation: the repository already contained release docs and a GitHub Actions workflow that referenced `ci/image/Dockerfile`, but the Dockerfile itself was missing.
  Evidence: `.github/workflows/ubuntu-dotfile.yml` used `file: ./ci/image/Dockerfile` while `ci/image/` contained only `README.md`.
- Observation: the repo also documented a root `.dockerignore` as part of the release-image contract, but no such file existed.
  Evidence: `docs/release-image.md` referenced `.dockerignore`, and `Get-Content .dockerignore` failed before implementation.
- Observation: the current generic Unix `stow` path does not contain container-specific materialization logic. The "materialize symlinks in containers" behavior existed only in docs, not in `justfile` or shell scripts.
  Evidence: `justfile` runs Dotter deploy directly, and searching `bootstrap/`, `script/`, `.dotter/`, and `packages/` found no materialization implementation.
- Observation: removing `/workspace` during the image build was not sufficient by itself because the final Docker image still had `WORKDIR /workspace`, and Docker recreated that directory at container start.
  Evidence: after the first successful finalization pass, a validation container showed `/workspace` as an empty directory until the Dockerfile's final `WORKDIR` was changed to `/root`.
- Observation: the host's default `bash.exe` path was a Windows-to-WSL launcher that could not be used for local syntax checks in this session.
  Evidence: local `bash -n` returned a `Bash/Service/CreateInstance/E_ACCESSDENIED` error, while the same syntax checks passed inside `docker run ubuntu:24.04 bash -n ...`.

## Decision Log

- Decision: treat `ghcr.io/petejohn6/ubuntu-dotfile` as a runtime image whose final filesystem no longer depends on a repository checkout.
  Rationale: that matches the already-written release docs and the requested correction that the prebuilt image should contain deployed dotfiles, not just be a base image.
  Date/Author: 2026-04-10 / Codex
- Decision: keep the generic `justfile` command surface unchanged and implement symlink materialization only in a release-image finalization script.
  Rationale: the repository's maintained model says `justfile` is the stable user command surface. The release artifact needs extra cleanup behavior, but that requirement should not silently redefine normal `stow` semantics for every container workflow.
  Date/Author: 2026-04-10 / Codex
- Decision: use a single-stage Ubuntu 24.04 Dockerfile that runs `bash bootstrap-up.sh` and then a dedicated `ci/image/finalize-image.sh` script.
  Rationale: this keeps the image build aligned with the existing user workflow and avoids inventing a parallel install path for the release image.
  Date/Author: 2026-04-10 / Codex
- Decision: materialize only symlinks under `$HOME` that resolve into `/workspace`, then delete `/workspace`.
  Rationale: the requirement is to break the runtime dependency on the checked-out repository while preserving post-install artifacts and other non-repo files created during the build.
  Date/Author: 2026-04-10 / Codex
- Decision: set the final image `WORKDIR` to `/root` after the build completes.
  Rationale: otherwise Docker recreates `/workspace` at runtime even if the finalization step deleted it during the image build.
  Date/Author: 2026-04-10 / Codex

## Outcomes & Retrospective

The repository now contains a concrete implementation for the release image that matches the documented intent: build-time provisioning plus runtime-safe deployed files. Local validation proved the full image build, the Linux shell syntax checks, and the final runtime filesystem assertions. The main lesson was that the contract drift was not caused by an incorrect Dockerfile, but by the absence of the implementation files that the surrounding docs and workflow already assumed existed.

## Context and Orientation

The release artifact is centered in three places. `.github/workflows/ubuntu-dotfile.yml` is the publish workflow. `docs/release-image.md` and `ci/image/README.md` describe what the image is supposed to contain. The actual Unix user workflow lives in `bootstrap/bootstrap.sh`, `bootstrap-up.sh`, `script/install.sh`, `script/post.sh`, `justfile`, `.dotter/`, and `packages/`.

`Dotter` is the deployment tool used by the `stow` stage. In this repository it normally creates symbolic links from files under `packages/` into a user's home directory. A symbolic link is a filesystem entry that points to another path instead of storing its own data. That is acceptable on a normal checked-out machine, but it is wrong for a prebuilt runtime image if the final image deletes the repository tree.

The release image therefore needs one extra step after `just up` completes. That step must scan the deployed files in the container home directory, find the symbolic links that still point back into the build workspace, replace them with ordinary copied files or directories, and only then remove the workspace. This must happen only for the release image build, not for the general `stow` implementation.

## Plan of Work

Create the root `.dockerignore` so the repository-root build context excludes host-local state and obviously irrelevant directories such as `.git/`, `.tree/`, `test/`, `docs/`, and `plans/`, while keeping the actual workflow inputs in scope. Add `ci/image/Dockerfile` as the release-image build entrypoint. Use `ubuntu:24.04`, set the shell to `bash` with `pipefail`, set `container=docker` so the existing scripts select the container install list, copy the workflow inputs into `/workspace`, run `bash bootstrap-up.sh`, and then run a new `ci/image/finalize-image.sh`.

Implement `ci/image/finalize-image.sh` so it is narrow and explicit. It must search under `$HOME` for symbolic links whose resolved targets are inside `/workspace`, replace each one in place with a copied ordinary file or directory, verify that no such repository-backed links remain, and then delete `/workspace`. The script should refuse to delete an empty or root-like path and should print concise status messages that show what it materialized.

Update `README.md`, `docs/release-image.md`, and `ci/image/README.md` so they describe the actual implementation. The user-facing statement should be that normal Unix `stow` still deploys symbolic links, while the published Ubuntu image runs a finalization step during `docker build` that converts the deployed Dotter outputs into ordinary files for runtime use.

## Concrete Steps

From the repository root:

1. Add `plans/ubuntu-dotfile-prebuilt-runtime-image.md` with the required ExecPlan sections.
2. Add `.dockerignore`.
3. Add `ci/image/Dockerfile`.
4. Add `ci/image/finalize-image.sh`.
5. Update `README.md`, `docs/release-image.md`, and `ci/image/README.md`.
6. Run static validation:

       shellcheck bootstrap-up.sh ci/image/finalize-image.sh

7. Build the image locally:

       docker build -f ci/image/Dockerfile -t ubuntu-dotfile:local .

8. Prove the final image no longer depends on `/workspace`:

       docker run --rm ubuntu-dotfile:local bash -lc 'test -f ~/.zshrc && test ! -L ~/.zshrc && test -f ~/.config/nvim/init.lua && test ! -L ~/.config/nvim/init.lua && test ! -e /workspace'

9. Run the broader Unix workflow proof through the repository devcontainer:

       devcontainer up --workspace-folder . --config test/devcontainer/devcontainer.json --remove-existing-container
       devcontainer exec --workspace-folder . --config test/devcontainer/devcontainer.json bash -lc 'cd /workspace && bash bootstrap/bootstrap.sh'
       devcontainer exec --workspace-folder . --config test/devcontainer/devcontainer.json bash -lc 'cd /workspace && just up'

## Validation and Acceptance

Acceptance for the release image is behavioral. A successful local build of `ci/image/Dockerfile` must complete `bootstrap-up.sh` during `docker build`, and a container started from that image must contain deployed dotfiles under `/root` as ordinary files and directories rather than symlinks into `/workspace`. The final image must not retain `/workspace`.

Acceptance for the wider repository contract is that the usual Unix workflow still works when exercised through the disposable devcontainer environment described by `test/devcontainer/devcontainer.json`. The release-image finalization logic must not be required for normal `just up` execution in that validation surface.

## Idempotence and Recovery

The added files are safe to recreate. `ci/image/finalize-image.sh` only runs inside image builds and removes `/workspace` only after it has verified and materialized repository-backed links under `$HOME`. Re-running the Docker build starts from a fresh build container and does not depend on host-local `.dotter/local.toml`, `.dotter/cache.toml`, or `bin/`.

If validation fails during `docker build`, rerun the same build command after fixing the failing step; the build is naturally retried from scratch. If the devcontainer validation surface fails to start, the next contributor should capture the first blocking error and rerun the exact devcontainer commands above in an environment with the devcontainer CLI and Docker available.

## Artifacts and Notes

The important artifact added by this plan is `ci/image/finalize-image.sh`, which performs the conversion from repository-backed symlinks to ordinary filesystem content. The other essential artifact is the root `.dockerignore`, because the release-image docs already treat repository-root build context as part of the public maintenance model.

## Interfaces and Dependencies

The public artifact remains `ghcr.io/petejohn6/ubuntu-dotfile`. The release workflow in `.github/workflows/ubuntu-dotfile.yml` continues to build from repository root context with `ci/image/Dockerfile`.

The implementation depends on the existing Unix workflow interfaces that must remain unchanged:

- `bootstrap-up.sh` must continue to run `bootstrap/bootstrap.sh` followed by `just up`.
- `justfile` must continue to expose `install`, `stow`, `post`, and `up` without a release-image-specific branch.
- `ci/image/finalize-image.sh` is a release-image-only helper and must not be treated as part of generic `stow`.

Revision note: initial checked-in version created to bring the missing release-image implementation in line with the already documented repository contract.
