# Migrate Agent Unix Work to Docker

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This plan follows `PLANS.md` at the repository root. A future contributor should read this file and `PLANS.md` before changing the Docker-based agent validation workflow.

## Trigger / Why This Needs an ExecPlan

This task changes the repository's durable maintainer and agent validation environment from a devcontainer CLI workflow to a Docker CLI workflow. The change affects checked-in skill metadata, test harness files under `test/`, and maintainer documentation that tells agents how to prove the Unix `bootstrap -> install -> stow -> post` model still works. `AGENTS.md` requires an ExecPlan for significant refactors and for changes to supported environments, so this plan is mandatory.

The historical ExecPlans under `plans/` include devcontainer validation evidence. Those entries are not implementation instructions for this migration, and they should remain as historical records instead of being rewritten.

## Purpose / Big Picture

After this change, maintainers and agents can validate Unix-side behavior by using only standard Docker commands. The host repository is mounted read-only at `/repo-ro`, copied into a disposable `/workspace` inside a uniquely named container, and all Unix development, debugging, and validation commands run in that temporary copy. Removing the container discards package-manager state and generated files without treating the host checkout as runtime state.

The behavior is visible by building the Docker image, starting a uniquely named container, running `bash /repo-ro/test/container/init-workspace.sh`, and then running `bash bootstrap/bootstrap.sh`, `just install`, `just stow`, and `just post` from `/workspace`.

## Progress

- [x] (2026-04-22T01:53:37+08:00) Read `PLANS.md`, the current `devcontainer-for-unix-work` skill, `test/devcontainer/*`, and maintainer/package docs that reference the devcontainer workflow.
- [x] (2026-04-22T01:53:37+08:00) Created this ExecPlan before modifying repo-tracked implementation files.
- [x] (2026-04-22T02:15:26+08:00) Renamed `.agents/skills/devcontainer-for-unix-work` to `.agents/skills/docker-for-unix-work` at the tracked-file level and rewrote its instructions for Docker CLI usage.
- [x] (2026-04-22T02:17:26+08:00) Renamed the new skill interface from the interim `docker-for-unix-work` name to `container-for-unix-work` after user direction.
- [x] (2026-04-22T02:15:26+08:00) Renamed `test/devcontainer/` to `test/container/` at the tracked-file level, kept the Ubuntu 24.04 plus `rsync` image, kept the workspace copy script, and removed the devcontainer manifest.
- [x] (2026-04-22T02:15:26+08:00) Updated maintainer and package documentation to reference the Docker container workflow.
- [x] (2026-04-22T02:49:19+08:00) Ran skill validation, static diff validation, and Docker harness validation.
- [x] (2026-04-22T02:49:19+08:00) Recorded final validation evidence and retrospective notes in this plan.

## Surprises & Discoveries

- Observation: No new surprises have been discovered yet.
  Evidence: Initial inspection found the current devcontainer harness already uses a read-only `/repo-ro` mount and an `rsync` copy into `/workspace`, which matches the target Docker model.

- Observation: Windows refused to remove the now-empty `.agents/skills/devcontainer-for-unix-work/agents` directory after tracked files were deleted.
  Evidence: `Remove-Item -LiteralPath .agents\skills\devcontainer-for-unix-work -Recurse -Force` failed with `Access to the path ...\agents is denied`, while `git status --short` showed only tracked deletions and the new Docker skill files.

- Observation: Docker commands need access outside the repository workspace on this Windows host.
  Evidence: The first sandboxed `docker build -f test/container/Dockerfile -t dotfile-agent-test:local test/container` failed with `ERROR: open C:\Users\night\.docker\buildx\.lock: Access is denied`; rerunning with explicit approval completed successfully.

- Observation: The full workflow still prints apt misses for `nvm` and `uv`, but the composed workflow exits successfully.
  Evidence: `docker exec -w /workspace dotfile-agent-20260422022000 bash -lc "just install && just stow && just post"` exited 0 while output included `E: Unable to locate package nvm` and `E: Unable to locate package uv`.

- Observation: Windows also refused to remove the now-empty `.agents/skills/docker-for-unix-work/agents` directory after the user-requested skill rename to `container-for-unix-work`.
  Evidence: `Remove-Item -LiteralPath .agents\skills\docker-for-unix-work -Recurse -Force` failed with `Access to the path ...\agents is denied`; `git status --short` does not list those empty directories because they contain no tracked files.

## Decision Log

- Decision: Do not rewrite historical devcontainer evidence in existing plans.
  Rationale: The user plan explicitly asks to avoid rewriting old validation records, and those entries describe facts from prior work rather than current workflow instructions.
  Date/Author: 2026-04-22 / Codex

- Decision: Use standard Docker CLI commands as the only supported control surface for the new skill.
  Rationale: The migration goal is to remove the devcontainer CLI dependency while preserving the same disposable container semantics.
  Date/Author: 2026-04-22 / Codex

- Decision: Name the maintained skill interface `container-for-unix-work`.
  Rationale: The user explicitly asked to rename the skill from the interim `docker-for-unix-work` name. The implementation still uses Docker CLI, but the skill name now describes the disposable container workflow rather than the specific command-line tool.
  Date/Author: 2026-04-22 / Codex

## Outcomes & Retrospective

The migration is implemented with the maintained skill interface named `container-for-unix-work`. The old devcontainer skill files and devcontainer manifest are deleted from tracked source, the Docker harness now lives under `test/container/`, and current maintainer/package docs point to the container skill and Docker container workflow. The implementation deliberately leaves historical ExecPlan validation records unchanged.

Validation completed successfully. `python C:/Users/night/.codex/skills/.system/skill-creator/scripts/quick_validate.py .agents/skills/container-for-unix-work` printed `Skill is valid!`. `git diff --check -- AGENTS.md docs .agents test plans` exited 0. Docker built `dotfile-agent-test:local`, started `dotfile-agent-20260422022000`, initialized `/workspace`, completed `bash bootstrap/bootstrap.sh`, completed `just install && just stow && just post`, proved `packages/container.list` matches `packages/packages.list`, and removed the named container. `docker ps -a --filter label=dotfile-agent-test=true --filter name=dotfile-agent-20260422022000` showed only the header row after cleanup.

The only residual local cleanup issue is that empty, untracked legacy directories under `.agents/skills/devcontainer-for-unix-work/` and `.agents/skills/docker-for-unix-work/` could not be removed because Windows denied access to their empty `agents` subdirectories. They contain no `SKILL.md` and are not part of the tracked result.

## Context and Orientation

The repository maintains a user-facing workflow described as `bootstrap -> install -> stow -> post`. `bootstrap` prepares platform prerequisites, `install` installs packages, `stow` deploys configuration through Dotter, and `post` performs post-deployment setup. Maintainers use a disposable Unix environment to prove those stages still work without installing Unix packages on the Windows host.

The current implementation is a skill at `.agents/skills/devcontainer-for-unix-work/` and a test environment at `test/devcontainer/`. The devcontainer manifest builds `test/devcontainer/Dockerfile`, mounts the host checkout read-only at `/repo-ro`, runs `test/devcontainer/init-workspace.sh`, and uses `/workspace` as the disposable copy. The target implementation keeps the image and copy model but removes `test/devcontainer/devcontainer.json` and replaces devcontainer CLI commands with direct Docker CLI commands.

The Docker image should be built from `test/container/Dockerfile` and tagged `dotfile-agent-test:local`. A validation run should create a unique container name such as `dotfile-agent-20260422015337`, label it with `dotfile-agent-test=true`, mount the host checkout read-only at `/repo-ro`, and keep it alive with `sleep infinity` while commands execute through `docker exec`.

## Plan of Work

First, rename the skill directory to `.agents/skills/container-for-unix-work/`. Rewrite `SKILL.md` so its frontmatter name is `container-for-unix-work`, its description still triggers on Unix development, debugging, reproduction, validation, testing, legacy "devcontainer" wording, and the interim `docker-for-unix-work` name, and the body documents Docker build, run, exec, resync, cleanup, and blocker-reporting behavior. Update `.agents/skills/container-for-unix-work/agents/openai.yaml` so the display name, short description, and default prompt all reference the container skill and `test/container`.

Next, rename `test/devcontainer/` to `test/container/`. Keep `Dockerfile` as an Ubuntu 24.04 image with `rsync` installed and `/workspace` created. Keep `init-workspace.sh` as the copy script, but ensure its comments and paths reference Docker rather than devcontainer. The script must copy `/repo-ro` into `/workspace`, exclude `.git`, `.tree`, local Dotter state, `bin/`, editor garbage, and other host-local files, and then replace `/workspace/packages/container.list` with `/workspace/packages/packages.list`. Delete `devcontainer.json` because the new workflow intentionally has no devcontainer compatibility entrypoint.

Then, update `AGENTS.md`, `docs/maintainer-workflow.md`, `docs/packages/alacritty.md`, and `docs/packages/wezterm.md` so current maintainer guidance names `container-for-unix-work` and the Docker container workflow. Do not change `justfile`, `README.md`, or the user workflow semantics because this migration only changes the maintainer validation environment.

Finally, validate the skill structure, check the diff for whitespace errors, and exercise the Docker harness. If Docker is unavailable or an external package source fails during the full workflow, record the first blocking point and the narrow proof already completed. Do not silently fall back to host execution or the old devcontainer workflow.

## Concrete Steps

Run commands from the repository root `C:\Users\night\dotfile` unless noted otherwise.

Validate the skill structure:

    python C:/Users/night/.codex/skills/.system/skill-creator/scripts/quick_validate.py .agents/skills/container-for-unix-work

Run static validation:

    git diff --check -- AGENTS.md docs .agents test plans

Build the Docker image:

    docker build -f test/container/Dockerfile -t dotfile-agent-test:local test/container

Start a uniquely named container, replacing `<repo>` with the absolute host repository path and `<name>` with a unique value such as `dotfile-agent-20260422015337`:

    docker run -d --name <name> --label dotfile-agent-test=true --mount type=bind,source=<repo>,target=/repo-ro,readonly -e DEBIAN_FRONTEND=noninteractive dotfile-agent-test:local sleep infinity

Prepare the workspace:

    docker exec <name> bash /repo-ro/test/container/init-workspace.sh

The workspace preparation should print that it copied the repository from `/repo-ro` to `/workspace` and replaced `/workspace/packages/container.list` with `packages.list` for testing.

Observed output during validation:

    [init-workspace] Copied repository from /repo-ro to /workspace
    [init-workspace] Replaced /workspace/packages/container.list with packages.list for testing

Run the Unix workflow proof:

    docker exec -w /workspace <name> bash -lc 'bash bootstrap/bootstrap.sh'
    docker exec -w /workspace <name> bash -lc 'just install && just stow && just post'

Clean up the validation container:

    docker rm -f <name>
    docker ps -a --filter label=dotfile-agent-test=true --filter name=<name>

The final `docker ps` command should show no container matching the cleaned-up name.

Observed cleanup output during validation:

    docker rm -f dotfile-agent-20260422022000
    dotfile-agent-20260422022000
    docker ps -a --filter label=dotfile-agent-test=true --filter name=dotfile-agent-20260422022000
    CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES

## Validation and Acceptance

Acceptance requires the checked-in skill to validate successfully, the repository diff to pass `git diff --check`, and the Docker harness to build and run the workspace initialization script. Full acceptance requires the container to complete `bash bootstrap/bootstrap.sh` and `just install && just stow && just post` from `/workspace`.

If the full workflow cannot complete because Docker is unavailable, the Docker daemon is not running, the image build fails, a mount cannot be created, or an external package source fails, acceptance for this iteration is to document the exact first blocker in `Outcomes & Retrospective`, keep any narrower completed proof in this plan, and leave the repo in a state where the new Docker commands are the only documented path.

## Idempotence and Recovery

The Docker image build is repeatable and can overwrite the local `dotfile-agent-test:local` tag. Each validation run must use a unique container name to avoid collisions with other agents. The `init-workspace.sh` script is idempotent inside a running container because it uses `rsync --delete --delete-excluded` to refresh `/workspace` from `/repo-ro` and then rewrites `packages/container.list`.

If a validation container is left running, remove only that named container with `docker rm -f <name>`. Do not remove arbitrary containers. Since `/repo-ro` is mounted read-only and `/workspace` lives inside the container, cleanup discards runtime state without changing tracked source files on the host.

## Artifacts and Notes

Initial inspection found these source files for the migration:

    .agents/skills/devcontainer-for-unix-work/SKILL.md
    .agents/skills/devcontainer-for-unix-work/agents/openai.yaml
    test/devcontainer/Dockerfile
    test/devcontainer/init-workspace.sh
    test/devcontainer/devcontainer.json
    AGENTS.md
    docs/maintainer-workflow.md
    docs/packages/alacritty.md
    docs/packages/wezterm.md

The current `init-workspace.sh` already excludes `.git`, `.tree`, `.dotter/local.toml`, `.dotter/cache.toml`, `bin/`, editor metadata, swap files, backup files, and `packages/nvim/lazy-lock.json`, and it already copies `packages.list` over `container.list` inside `/workspace`.

Validation transcript excerpts:

    Skill is valid!
    [bootstrap] Bootstrap complete!
    container-list-overridden

## Interfaces and Dependencies

The required external dependency is Docker with a working Docker daemon. The repository-facing command interface is the `docker` CLI. The container image must provide Bash, Ubuntu 24.04 base userland, and `rsync`. Repository commands inside the container run as root in `/workspace`.

The maintained skill interface is `$container-for-unix-work`. The old `$devcontainer-for-unix-work`, the interim `$docker-for-unix-work` skill directory, and `test/devcontainer/devcontainer.json` are intentionally removed instead of kept as compatibility aliases.

Revision note: Created the initial plan before implementation to satisfy the repository ExecPlan policy and to capture the intended Docker-only workflow.
