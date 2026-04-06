# User Workflow

This document defines the user-facing workflow of the repository. It is the logical interface exposed to operators who use this repo on a machine. It is not the maintainer workflow.

## Primary Maintained Model

`bootstrap -> install -> stow -> post` is the stable abstraction this repository is organized around.

- Maintainers should reason about changes in terms of stage semantics first.
- Internal directory layout is secondary to the stage contract.
- Changes should be judged by whether they alter bootstrap, install, stow, or post behavior.

## Execution Model

The user-workflow is expressed as a single stage model:

`bootstrap -> install -> stow -> post`

- `bootstrap/` provides the platform-specific entry scripts that prepare the machine for the rest of the workflow.
- `justfile` is the stable command surface users operate after bootstrap and the main orchestration surface for install, stow, and post.
- `bootstrap` calls the platform script under `bootstrap/`.
- `install` calls `script/install.sh` on Unix or `script/install.ps1` on Windows.
- `install` is maintained internally as `pre-install -> install` on every platform.
- `stow` deploys config from `packages/` through Dotter.
- `post` runs the post-deployment scripts that finish tool-specific setup.

## Interface Surface

- `bootstrap/` prepares the machine to run the repo.
- `justfile` exposes the stable command surface for install, deploy, preview, post-install, and teardown operations.
- `script/` contains the install and post-install orchestration those commands execute.
- `packages/` contains the package lists, hooks, and maintained configs used by that workflow.
- `README.md` is the human quick-start reference for that command surface.
- `.dotter/` contains the deployment definitions, seeded defaults, and local deployment state used during stow and uninstall.

`justfile` belongs to the user-facing interface and should stay stable unless the repo is intentionally changing its command surface.

This document should describe the paths involved when a user runs the repo. It should not be used to document development-only paths such as `docs/`, `plans/`, `test/`, `.agents/`, or `AGENTS.md`.

## Implementation Behind The Stages

- `bootstrap/` implements the bootstrap stage.
- `script/` and `packages/` implement install and post behavior.
- `.dotter/` and `packages/` implement stow behavior.
- `justfile` exposes the command surface for the full stage model.

## Stage Model

### 1. Bootstrap

Bootstrap prepares the minimum runtime needed to use the repo:

- installs or discovers a package manager where needed
- installs `just`
- downloads `dotter` into `bin/`
- seeds the local configuration under `.dotter/` from a default template when missing

Bootstrap does not install the full toolchain.

### 2. Install

`just install` resolves software packages for the current runtime:

- runs a `pre-install` phase before the package-manager installation pass
- detects platform, container context, and package manager
- selects the appropriate package list under `packages/`
- runs platform-specific pre-install logic when applicable
- skips tools already satisfied by CLI availability
- installs unresolved tools through the package manager

The install stage is intentionally split so the package-manager path stays clean:

- `pre-install` handles preparation, manual installation paths, and exceptional cases where the package manager is missing a package or cannot provide the required form.
- `install` handles packages that should be installed through the package manager.
- because the install step skips packages whose CLI is already available, a successful `pre-install` can satisfy a tool and keep the package-manager stage focused on normal package installs.
- on Unix, the explicit pre-install rule library lives under `packages/pre-install-unix.sh`.
- on Windows, the pre-install phase currently lives inside `script/install.ps1` and handles package-manager preparation before the main install loop.

Install is responsible for software availability, not configuration deployment.

### 3. Stow

`just stow` deploys selected repo-managed configs through dotter:

- uses Dotter to deploy config from `packages/`
- reads the canonical and local configuration under `.dotter/`
- applies included platform overlays
- deploys selected config packages
- uses the local deployment state under `.dotter/` to reconcile prior deployments

Normal redeploys should not require `just uninstall`.

### 4. Post

`just post` runs per-tool setup after configs are deployed:

- executes post-deployment scripts after stow completes
- discovers tool-specific setup hooks under `packages/`
- runs tool-specific setup such as plugin installation
- relies on each script to self-check whether its CLI is available

Post hooks stay tool-specific and should not absorb generic install logic.

## Supporting Commands

- `just dry` previews dotter deployment without changing targets.
- `just uninstall` undeploys repo-managed files.
- `install-force`, `stow-force`, and `up-force` are force variants of the same user-facing command surface.
- `just up` composes `install -> stow -> post`.

## User-Facing Guarantees

- The stages are independently runnable.
- The command surface is stable by default.
- Repository changes should preserve stage semantics unless the interface is being intentionally revised.
- If the command surface changes intentionally, `justfile`, `README.md`, and this document must change together.
