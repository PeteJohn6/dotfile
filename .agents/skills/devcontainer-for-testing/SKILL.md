---
name: devcontainer-for-testing
description: When Unix-side debugging or testing is needed, use devcontainer to create a disposable container-based test environment. Run setup, debugging, and test commands inside `/workspace` in the container rather than on the host.
---

# Devcontainer for Testing

## Overview

When Unix-side debugging or testing is needed, use the repository's test devcontainer defined at `test/devcontainer/devcontainer.json` as the default disposable environment. Manage its lifecycle through the devcontainer CLI rather than using ad hoc Docker commands. The container's `/workspace` contains the full source code. Operations inside `/workspace` do not need to worry about polluting the source code, so dependency installation, builds, debugging, and tests should all happen there unless the task explicitly targets the host.

## Workflow

1. Use `test/devcontainer/devcontainer.json` as the devcontainer manifest for the test environment.

2. Start the environment with the devcontainer CLI. Use `devcontainer up --workspace-folder <repo> --config test/devcontainer/devcontainer.json` to create the test environment. Let the devcontainer CLI configuration control image builds, mounts, features, and initialization instead of reproducing those steps manually. The configuration in `test/devcontainer/devcontainer.json` builds a safe test environment. There is no need to worry about polluting the source code.

3. Prepare the workspace inside the running container.
   `test/devcontainer/init-workspace.sh` rewrites `/workspace/packages/container.list` from `/workspace/packages/packages.list` so the disposable test workspace installs the broader toolchain without touching the host repo. After `devcontainer up`, always run `bash bootstrap/bootstrap.sh` and then `just install` in `/workspace` before starting tests or debugging.

4. Work inside the running container.
   Prefer `devcontainer exec --workspace-folder <repo> --config test/devcontainer/devcontainer.json <command>` for installs, tests, debugging, and inspection. Perform repository mutations inside `/workspace`. Do not shift work back to the host unless the task explicitly requires host-side behavior.

5. The host repository is synced one-way into `/workspace` inside the devcontainer. When the latest contents of the host repository need to overwrite `/workspace` inside the container, run `bash /repo-ro/test/devcontainer/init-workspace.sh`. After every resync, rerun `bash bootstrap/bootstrap.sh` and `just install` in `/workspace` before continuing.

6. Surface blockers precisely.
   If startup or execution fails, report the first blocking issue directly: missing devcontainer CLI, container runtime unavailable, invalid config, build failure, mount or permission error, or post-create failure. State the next concrete fix instead of silently switching workflows.

7. Clean up after the test run.
   Remove the disposable devcontainer when the test completes unless the user explicitly asks to keep it. Any intermediate files created inside the test container's `/workspace` are deleted together with the container, so they do not need to be removed manually.

8. Summarize the environment state.
   State which config was used, the command that started the environment, whether follow-up commands ran inside the container, whether `/workspace` was prepared with the `packages.list` -> `container.list` override, whether `/workspace` was resynced, what cleanup was performed, and whether the repository was returned to a clean post-test state.

## Command Pattern

```bash
devcontainer up --workspace-folder . --config test/devcontainer/devcontainer.json
devcontainer exec --workspace-folder . --config test/devcontainer/devcontainer.json bash -lc 'cd /workspace && bash bootstrap/bootstrap.sh'
devcontainer exec --workspace-folder . --config test/devcontainer/devcontainer.json bash -lc 'cd /workspace && just install'
devcontainer exec --workspace-folder . --config test/devcontainer/devcontainer.json <command>
devcontainer exec --workspace-folder . --config test/devcontainer/devcontainer.json bash /repo-ro/test/devcontainer/init-workspace.sh
devcontainer exec --workspace-folder . --config test/devcontainer/devcontainer.json bash -lc 'cd /workspace && bash bootstrap/bootstrap.sh'
devcontainer exec --workspace-folder . --config test/devcontainer/devcontainer.json bash -lc 'cd /workspace && just install'
devcontainer up --workspace-folder . --config test/devcontainer/devcontainer.json --remove-existing-container
```

## Guardrails

* Use the devcontainer CLI as the primary control surface for this workflow.
* Do not invent extra container setup when the devcontainer config already defines the environment.
* Do not treat `/workspace` as persistent across disposable test containers.
* Do not install project dependencies on the host as a shortcut for a broken container flow.
* If the repository has no suitable devcontainer config, say so plainly and stop unless the user asks to create one.
* Do not leave disposable containers or test-only generated artifacts behind after a completed test run.
