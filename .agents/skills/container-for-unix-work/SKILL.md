---
name: container-for-unix-work
description: Use when Codex needs to develop, debug, reproduce, validate, or test Unix-side changes in this repository with the disposable Docker CLI container environment built from `test/container/Dockerfile`. Prefer this skill for Linux/macOS command execution, bootstrap or install debugging, shell or profile investigation, package-manager or path issues, and requests phrased like "test in devcontainer", "debug in devcontainer", "use devcontainer", or "use docker-for-unix-work"; handle legacy names through Docker CLI commands. Run setup, development, debugging, and validation commands inside `/workspace` unless the task is explicitly host-only.
---

# Container for Unix Work

## Overview

Use the repository's Docker test harness under `test/container/` as the default environment for Unix-side development, debugging, reproduction, and validation. Build the image with the Docker CLI, start a uniquely named disposable container, mount the host repository read-only at `/repo-ro`, and copy it into `/workspace` with `rsync`. Treat `/workspace` as disposable runtime state. Keep repo-tracked source edits on the host workspace unless the task explicitly asks for a throwaway prototype inside the container.

## Trigger Rules

Use this skill by default when Unix-side command execution is part of the task, including:

- Developing, debugging, or reproducing Linux/macOS issues in `bootstrap.sh`, `install.sh`, shell configs, or package-manager flows
- Validating Unix-side behavior after a code change, even when the user only says "debug", "reproduce", "validate", or "test"
- Requests phrased like `test in devcontainer`, `debug in devcontainer`, or `use devcontainer`
- Requests that mention the old `devcontainer-for-unix-work` skill or the interim `docker-for-unix-work` name but clearly need the current Unix validation environment

Skip this skill only when the work is clearly host-only, Windows-only, or intentionally targets behavior outside the disposable container.

## Common Examples

- Debug a Linux bootstrap or install failure in `bootstrap/bootstrap.sh` or `script/install.sh`
- Reproduce a shell, PATH, package-manager, or permission issue on Unix
- Validate a Unix-side code change before summarizing results
- Run repository tests in the disposable Docker container instead of on the host

## Workflow

1. Build the local test image when the harness changed or the image is missing.
   Use `docker build -f test/container/Dockerfile -t dotfile-agent-test:local test/container`.

2. Create a unique container for each task.
   Use a name such as `dotfile-agent-<timestamp>` so parallel agents do not share a singleton environment. Mount the absolute host repository path read-only at `/repo-ro`, set `DEBIAN_FRONTEND=noninteractive`, label the container with `dotfile-agent-test=true`, and run `sleep infinity` as the long-lived command.

3. Prepare the workspace inside the running container.
   Run `docker exec <name> bash /repo-ro/test/container/init-workspace.sh`. The script refreshes `/workspace` from `/repo-ro`, excludes host-local state such as `.git`, `.tree`, `.dotter/local.toml`, `.dotter/cache.toml`, and `bin/`, and rewrites `/workspace/packages/container.list` from `/workspace/packages/packages.list` so the disposable test workspace installs the broader toolchain without touching the host repo.

4. Bootstrap before Unix work.
   After the first workspace initialization, run `docker exec -w /workspace <name> bash -lc 'bash bootstrap/bootstrap.sh'`. For install-sensitive debugging, run `docker exec -w /workspace <name> bash -lc 'just install'` before starting narrower tests.

5. Work inside the running container.
   Use `docker exec -w /workspace <name> bash -lc '<command>'` for installs, tests, debugging, and inspection. When tracked source changes are needed, edit the host repository, resync `/workspace`, and rerun the relevant setup commands instead of treating container-local edits as the source of truth.

6. Resync after host edits.
   When the latest host repository contents need to overwrite `/workspace`, run `docker exec <name> bash /repo-ro/test/container/init-workspace.sh`. After a resync, rerun `bash bootstrap/bootstrap.sh` and any stage setup needed by the next command.

7. Surface blockers precisely.
   If startup or execution fails, report the first blocking issue directly: missing Docker CLI, Docker daemon unavailable, image build failure, mount or permission error, workspace initialization failure, or package source failure. Do not silently switch to host execution or the old devcontainer workflow.

8. Clean up only the current task container.
   Remove the named disposable container with `docker rm -f <name>` when the test completes unless the user explicitly asks to keep it. Do not remove arbitrary containers, even if they share the `dotfile-agent-test=true` label.

9. Summarize the environment state.
   State which image tag was used, the container name, whether `/workspace` was prepared with the `packages.list` to `container.list` override, what commands ran in `/workspace`, what cleanup was performed, and whether any blocker stopped full workflow validation.

## Command Pattern

```bash
docker build -f test/container/Dockerfile -t dotfile-agent-test:local test/container
docker run -d --name <name> --label dotfile-agent-test=true --mount type=bind,source=<absolute-repo-path>,target=/repo-ro,readonly -e DEBIAN_FRONTEND=noninteractive dotfile-agent-test:local sleep infinity
docker exec <name> bash /repo-ro/test/container/init-workspace.sh
docker exec -w /workspace <name> bash -lc 'bash bootstrap/bootstrap.sh'
docker exec -w /workspace <name> bash -lc 'just install'
docker exec -w /workspace <name> bash -lc '<command>'
docker exec <name> bash /repo-ro/test/container/init-workspace.sh
docker exec -w /workspace <name> bash -lc 'bash bootstrap/bootstrap.sh'
docker exec -w /workspace <name> bash -lc 'just install && just stow && just post'
docker rm -f <name>
```

PowerShell example for creating the unique name and mount source:

```powershell
$name = "dotfile-agent-$((Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss'))"
$repo = (Get-Location).Path
docker run -d --name $name --label dotfile-agent-test=true --mount "type=bind,source=$repo,target=/repo-ro,readonly" -e DEBIAN_FRONTEND=noninteractive dotfile-agent-test:local sleep infinity
```

## Guardrails

* Use Docker CLI as the primary control surface for this workflow.
* Do not use the devcontainer CLI or recreate a devcontainer compatibility manifest.
* Do not treat `/workspace` as persistent across disposable test containers.
* Do not treat container-local source edits as durable repo changes.
* Do not install project dependencies on the host as a shortcut for a broken container flow.
* If the repository has no suitable Docker harness, say so plainly and stop unless the user asks to create one.
* Do not leave the current task's disposable container running after a completed test run.
