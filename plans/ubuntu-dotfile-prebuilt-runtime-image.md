# Prebuild the `ubuntu-dotfile` Runtime Image

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This document is maintained in accordance with `PLANS.md` at the repository root.

## Trigger / Why This Needs an ExecPlan

This work changes a durable repository output: the published `ghcr.io/petejohn6/ubuntu-dotfile` image and the reusable maintainer automation that decides when to build it. The repository already contains release-image docs and a GitHub Actions workflow that describe this artifact, so the implementation must continue to be driven by a checked-in ExecPlan rather than an ephemeral chat summary. The classifier revision was required because the original classifier plan hard-coded path rules in shell and treated `packages/` as one unit, while the intended behavior became narrower: container-specific workflow inputs must come from a TOML fact file with additive include semantics. This 2026-04-21 revision is required because automatic branch push builds were too broad; only `master` pushes should attempt and publish the image build automatically. The same revision also tightens push change detection so a multi-commit `master` push is classified across the full GitHub push range rather than only the checked-out commit's first parent.

## Purpose / Big Picture

After this change, the published Ubuntu image remains a real runtime artifact that runs `bootstrap -> install -> stow -> post` during `docker build`, then converts repository-backed Dotter symlinks in the container home directory into ordinary files and directories before the image is finalized. In addition, the repository gains a machine-readable fact file that explains which repository paths belong to the full user workflow, which belong specifically to the container view of that workflow, and which additionally affect the release-image manifest. A maintainer can verify the result by editing representative files such as `packages/alacritty/...`, `packages/zsh/...`, or `ci/image/Dockerfile` and observing that the new classifiers answer the three questions consistently. Automatic push builds are limited to `master`, so ordinary feature branch pushes no longer consume multi-architecture image build capacity or publish branch tags. A `master` push that contains more than one commit is still classified correctly because the workflow passes GitHub's push `before` SHA and checked-out `sha` to the classifier.

## Progress

- [x] (2026-04-10T06:42:17+08:00) Read `PLANS.md`, the release-image docs, the workflow, and the current Unix workflow implementation to confirm the current contract and the implementation gap.
- [x] (2026-04-10T06:42:17+08:00) Added the missing release-image implementation files: root `.dockerignore`, `ci/image/Dockerfile`, and `ci/image/finalize-image.sh`.
- [x] (2026-04-10T06:42:17+08:00) Updated user-facing and maintainer-facing docs so they describe release-image finalization rather than claiming that generic container `stow` always materializes symlinks.
- [x] (2026-04-10T06:42:17+08:00) Ran static validation with Linux `bash -n` inside a temporary Ubuntu container, built `ci/image/Dockerfile` locally, and verified that `/root/.zshrc`, `/root/.config/nvim/init.lua`, and `/root/.gitconfig` are ordinary files while `/workspace` is absent in the final runtime image.
- [x] (2026-04-10T07:35:00+08:00) Revised the release workflow so branch pushes publish branch-specific GHCR tags, enabling end-to-end validation of the GitHub-hosted prebuilt image before merging to the default branch.
- [x] (2026-04-10T11:20:00+08:00) Replaced the workflow-level hard-coded `paths` trigger with reusable changed-file classifiers under `hack/`, then rewired the image job to consume that shared output.
- [x] (2026-04-12T11:35:00+08:00) Re-read the workflow, the classifier scripts, `packages/container.list`, Dotter profiles, and the release docs to map which repository paths actually affect the container workflow and the image manifest.
- [x] (2026-04-13T00:39:00+08:00) Replaced the shell-hard-coded classifier rule sets with the initial manifest/parser-wrapper model under `hack/change-detection/`, initially keeping the existing `workspace|head` command surface.
- [x] (2026-04-19T10:15:00+08:00) Flattened the then-current TOML fact file so the repository kept three main classifier blocks and only one additive include edge, reducing maintenance overhead without changing the external classifier interface.
- [x] (2026-04-19T10:28:00+08:00) Simplified the TOML schema again so the manifest is classifier-only: each top-level table is a classifier, and the parser no longer requires a `classifiers` namespace.
- [x] (2026-04-19T10:42:00+08:00) Reorganized `hack/` so the then-current public wrapper scripts stayed at the top level, while the shared manifest/parser/helper implementation moved under `hack/change-detection/`.
- [x] (2026-04-19T15:20:00+08:00) Replaced the shell wrapper layer with a single Python CLI at `hack/change-detection/main.py`, removed the `match` subcommand from the normal path, and renamed the CI diff source from `head` to `commit`.
- [x] (2026-04-20T02:30:09+08:00) Moved the watched-path fact source to the repository root as `file-classifier.toml`, kept the Python CLI under `hack/change-detection/`, and made the release-image classifier include both the fact file and CLI implementation.
- [x] (2026-04-20T02:32:00+08:00) Validated the migrated classifier path with Python bytecode compilation and `workspace` classification showing the current fact-file and CLI edits only affect `dotfile_image_manifest`.
- [x] (2026-04-20T02:47:29+08:00) Split ongoing `file-classifier.toml` maintenance into `plans/file-classifier.md` so this plan can remain focused on the release-image artifact and workflow.
- [x] (2026-04-20T04:03:38+08:00) Merged release-image change-detection documentation into `docs/release-image.md`, making that file the single user-facing reference for image build gating.
- [x] (2026-04-13T00:40:00+08:00) Introduced `user_workflow_container_changed` and renamed `dotfile_image_inputs_changed` to `dotfile_image_manifest_changed` across scripts, workflow outputs, and docs.
- [x] (2026-04-13T00:49:00+08:00) Ran static validation in the disposable devcontainer with `python3 -m py_compile` and `bash -n`, then exercised representative path classifications for broad user-workflow, container-only, and image-only cases through the shared parser.
- [x] (2026-04-13T00:49:00+08:00) Confirmed the then-current Git-based wrapper runtime remained structurally intact but could not complete end-to-end wrapper execution inside the devcontainer because the disposable `/workspace` copy omits `.git` and the read-only worktree mount points at a host-only Windows Git metadata path.
- [x] (2026-04-21T00:15:50+08:00) Limited automatic release-image push builds to the `master` branch and updated the release-image documentation to remove general branch-publish behavior.
- [x] (2026-04-21T00:25:00+08:00) Validated the trigger change with Python bytecode compilation, PyYAML parsing, workflow trigger assertions, workspace classification showing `false`, `false`, `true`, and `git diff --check`.
- [x] (2026-04-21T00:47:00+08:00) Extended push change detection to classify the full GitHub push range and keep Python bytecode cache output out of the worktree.
- [x] (2026-04-21T00:56:52+08:00) Validated the push-range correction with Python bytecode compilation, PyYAML workflow parsing, explicit workflow assertions, workspace classification, explicit empty-range and null-base commit classification, `git diff --check`, and post-validation `__pycache__` cleanup.
- [x] (2026-04-21T01:24:12+08:00) Fixed review feedback by replacing exact release-image post hook watched paths with `packages/post/**`.
- [x] (2026-04-21T01:26:39+08:00) Validated the review fix with a temporary new post hook that made all three workspace classifiers print `true`, then removed the temporary hook and reran static validation.

## Surprises & Discoveries

- Observation: the repository already contained release docs and a GitHub Actions workflow that referenced `ci/image/Dockerfile`, but the Dockerfile itself was missing before the initial image implementation.
  Evidence: `.github/workflows/ubuntu-dotfile.yml` used `file: ./ci/image/Dockerfile` while `ci/image/` contained only `README.md`.
- Observation: the repo also documented a root `.dockerignore` as part of the release-image contract, but no such file existed before the initial image implementation.
  Evidence: `docs/release-image.md` referenced `.dockerignore`, and `Get-Content .dockerignore` failed before implementation.
- Observation: the current generic Unix `stow` path does not contain container-specific materialization logic. The "materialize symlinks in containers" behavior existed only in docs, not in `justfile` or shell scripts.
  Evidence: `justfile` runs Dotter deploy directly, and searching `bootstrap/`, `script/`, `.dotter/`, and `packages/` found no materialization implementation.
- Observation: removing `/workspace` during the image build was not sufficient by itself because the final Docker image still had `WORKDIR /workspace`, and Docker recreated that directory at container start.
  Evidence: after the first successful finalization pass, a validation container showed `/workspace` as an empty directory until the Dockerfile's final `WORKDIR` was changed to `/root`.
- Observation: the host's default `bash.exe` path was a Windows-to-WSL launcher that could not be used for local syntax checks in this session.
  Evidence: local `bash -n` returned a `Bash/Service/CreateInstance/E_ACCESSDENIED` error, while the same syntax checks passed inside `docker run ubuntu:24.04 bash -n ...`.
- Observation: the first version of the workflow only generated `latest` on the default branch, so branch pushes built successfully but emitted no tags and could not publish a pullable GHCR artifact for branch-level verification.
  Evidence: the successful branch run reported `No Docker tag has been generated. Check tags input.` and skipped GHCR login because publish was default-branch-only.
- Observation: the original release workflow duplicated the image input surface directly in YAML, which made the trigger logic hard to reuse and easy to let drift away from the maintained user-workflow input set.
  Evidence: `.github/workflows/ubuntu-dotfile.yml` originally hard-coded `.dotter/**`, `bootstrap/**`, `bootstrap-up.sh`, `justfile`, `packages/**`, and `script/**` inline before the first classifier scripts existed.
- Observation: `packages/container.list` is only one part of the container workflow. Dotter package deployment for containers is determined separately by `.dotter/default/container.toml`, `.dotter/unix.toml`, and `.dotter/global.toml`, and post-install hooks still run from `packages/post/*.sh`.
  Evidence: `script/install.sh` switches to `packages/container.list`, `bootstrap/bootstrap.sh` seeds `.dotter/local.toml` from `.dotter/default/container.toml`, and `script/post.sh` iterates every Unix post hook under `packages/post/`.
- Observation: the disposable devcontainer workspace at `/workspace` is intentionally not a Git checkout, and the read-only host worktree mount cannot satisfy Git commands because its `.git` file points at a Windows host path.
  Evidence: the wrappers executed from `/workspace` failed in `head` mode with "Not a git repository", while `/repo-ro` failed with `fatal: not a git repository: /repo-ro/C:/Users/night/code/dotfile-1/.git/worktrees/hack`.
- Observation: the first TOML manifest shape was technically correct but too granular for the small number of current classifiers.
  Evidence: most of the initial `path_sets.*` blocks were one-use only, so understanding the file required jumping across many small sections just to reconstruct one classifier.
- Observation: even the flattened classifier-first manifest still felt heavier than necessary when every classifier lived under a redundant `classifiers.*` prefix.
  Evidence: the file existed solely to classify changes, so the extra namespace added ceremony without expressing any extra domain concept.
- Observation: the top-level `hack/` directory became cluttered once the public wrapper scripts and their internal support files all lived side by side.
  Evidence: maintainers browsing `hack/` had to distinguish the three actual entrypoints from the parser, helper shell library, manifest, and a generated `__pycache__` entry.
- Observation: once the shell wrapper layer was removed, the TOML file was more important than the `hack/` implementation directory around it.
  Evidence: `file-classifier.toml` is read by the CLI, documented as the single source of watched-path truth, and changes to it should cause the release-image workflow to rebuild the image.
- Observation: invoking `python3` without a script on the Windows host can fail in the interactive console path, but non-interactive script execution works.
  Evidence: plain `python3` entered Python 3.13.2 and failed in `_pyrepl` with `WinError 6`, while `python3 -c "import sys; print(sys.version)"` completed successfully.
- Observation: publishing on every branch push is too broad for the current repository maintenance model.
  Evidence: `.github/workflows/ubuntu-dotfile.yml` triggered on all `push` events and the docs promised a branch-specific image tag for every branch, even though the current requested behavior is to try image builds automatically only from `master`.
- Observation: `actionlint` is not installed in the current host environment.
  Evidence: `Get-Command actionlint -ErrorAction SilentlyContinue` returned no command, so workflow validation used PyYAML parsing plus explicit assertions for `on.push.branches: [master]` and the `refs/heads/master` job guard.
- Observation: comparing only `HEAD^1..HEAD` can under-classify a direct `master` push that contains multiple commits.
  Evidence: the current classifier `commit` mode runs `git diff --name-only HEAD^1 HEAD --`, so an image input changed in an earlier commit of the same push would not be present in that single-commit diff.
- Observation: Python bytecode validation creates local generated files unless they are ignored and removed after validation.
  Evidence: `python3 -m py_compile hack/change-detection/main.py` produced `hack/change-detection/__pycache__/main.cpython-313.pyc` in the working tree.
- Observation: newly added Unix post hooks are image inputs even before they appear in any current exact-file classifier rule.
  Evidence: `script/post.sh` executes every `"$POST_DIR"/*.sh`, so a new `packages/post/foo.sh` would run during `bootstrap -> install -> stow -> post` inside the release image.

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
- Decision: publish branch-specific tags on every branch `push`, while keeping `latest` reserved for the default branch.
  Rationale: this historical decision enabled testing the actual GitHub-built prebuilt image from a feature branch without weakening the meaning of `latest`. It is superseded by the 2026-04-21 decision to limit automatic push builds to `master`.
  Date/Author: 2026-04-10 / Codex
- Decision: limit automatic push-triggered release image builds and publishing to `master`.
  Rationale: feature branch push builds create too many multi-architecture image builds and branch tags. Pull requests and manual workflow dispatch still provide explicit validation paths without publishing images.
  Date/Author: 2026-04-21 / Codex
- Decision: for `push` events, pass GitHub's event `before` SHA and checked-out `sha` into the classifier and compare that whole range.
  Rationale: a single push can contain more than one commit. The build gate must answer whether any commit in the pushed range affects the image manifest, not whether only the last commit does.
  Date/Author: 2026-04-21 / Codex
- Decision: watch `packages/post/**` rather than enumerating existing post hook files.
  Rationale: the release image executes post hooks by directory glob. The build gate should mirror that execution model so future hooks trigger validation and publishing without another classifier update.
  Date/Author: 2026-04-21 / Codex
- Decision: replace shell-hard-coded classifier rule sets with a single TOML fact file under `hack/`.
  Rationale: the path rules are now part of a durable maintainer-facing interface and should be reusable by CI and future harnesses without copying logic into multiple callers.
  Date/Author: 2026-04-12 / Codex
- Decision: express classifier composition with additive include semantics only; do not support excludes.
  Rationale: the desired relationships are nested and compositional. Exclusion rules would make the fact file harder to reason about and would invite hidden coupling between broad and narrow classifier definitions.
  Date/Author: 2026-04-12 / Codex
- Decision: keep the current manifest flat and classifier-first instead of normalizing every reusable fragment into its own `path_set`.
  Rationale: the repository currently has only three exported classifiers and a single meaningful extension relationship. Flattening the file makes the source of truth easier to read and update while still preserving additive include semantics for future growth.
  Date/Author: 2026-04-19 / Codex
- Decision: make each top-level TOML table a classifier and remove the `classifiers` namespace from both the manifest and parser.
  Rationale: the file has no purpose beyond expressing classifiers, so the extra root key was redundant and made maintenance slightly noisier.
  Date/Author: 2026-04-19 / Codex
- Decision: initially keep the three public wrapper scripts at the top level of `hack/`, but move the shared manifest/parser/helper implementation into `hack/change-detection/`.
  Rationale: this was an intermediate cleanup that grouped internal implementation under a subdirectory before the command surface was later consolidated into one Python CLI.
  Date/Author: 2026-04-19 / Codex
- Decision: replace the shell wrappers with one direct Python CLI, `python3 hack/change-detection/main.py --source <workspace|commit> <classifier>`.
  Rationale: the fact file already requires a Python TOML parser, and routing through shell added a second implementation layer without adding useful compatibility. `commit` is clearer than `head` because the mode classifies the checked-out commit diff rather than the mutable working tree.
  Date/Author: 2026-04-19 / Codex
- Decision: move the classifier fact source to the repository root as `file-classifier.toml`, while keeping `hack/change-detection/main.py` as the CLI implementation.
  Rationale: the watched-path classifications are global repository facts, not private implementation state. A root-level file is easier for maintainers to discover, and the singular `file-classifier.toml` name matches the changed-file classifier interface without implying a general repository layout description.
  Date/Author: 2026-04-20 / Codex
- Decision: include `file-classifier.toml` and `hack/change-detection/main.py` in the `dotfile_image_manifest` classifier.
  Rationale: changes to the release-image gating facts or the CLI that interprets them should make the image workflow exercise the build job rather than only the detection job.
  Date/Author: 2026-04-20 / Codex
- Decision: require Python 3.11+ directly and do not use `uv` for this automation.
  Rationale: `tomllib` is part of the Python 3.11 standard library, and the repository has no Python project dependency set that would justify introducing `uv run` into the CI classifier path.
  Date/Author: 2026-04-19 / Codex
- Decision: preserve `user_workflow_changed` as the broad "full user-workflow input changed" answer, add `user_workflow_container_changed` as the container-specific view, and rename `dotfile_image_inputs_changed` to `dotfile_image_manifest_changed`.
  Rationale: the repository now needs three distinct questions answered from one source of truth. Narrowing the meaning of `user_workflow_changed` would make existing docs and tooling ambiguous.
  Date/Author: 2026-04-12 / Codex

## Outcomes & Retrospective

The repository already has a working runtime image implementation and reusable change-detection automation. The classifier revision completed the next maintenance step those additions exposed: the classifier rules were too coarse, especially around `packages/`, and they lived in shell rather than in a durable, machine-readable fact source. The release workflow still publishes the same image artifact, but it now derives broad user-workflow, container-specific workflow, and image-manifest classifications from one additive TOML source of truth through a direct Python CLI. The fact source is now the root `file-classifier.toml`, while the CLI remains under `hack/change-detection/`. Validation after the move confirmed that current edits to the fact file and CLI trip only the image-manifest classifier. The 2026-04-21 trigger revision keeps pull request and manual image-build validation available, but stops automatic push builds and branch tag publishing outside `master`; local validation confirmed the workflow parses as YAML and contains the intended branch filter plus job guard. The follow-up range revision now makes direct multi-commit `master` pushes evaluate the complete pushed range by passing GitHub's `before` and `sha` values into the classifier. The review follow-up now ensures newly added `packages/post/` hooks are watched by the image classifier. The main lesson from validation is that "container image inputs" are not synonymous with "everything in user workflow"; the install list, Dotter package selection, Unix post hooks, and the classifier infrastructure itself each contribute part of the truth, and Git-backed classifier validation must account for the devcontainer's intentionally non-Git `/workspace` copy.

## Context and Orientation

The release artifact is centered in three places. `.github/workflows/ubuntu-dotfile.yml` is the publish workflow. `docs/release-image.md` and `ci/image/README.md` describe what the image is supposed to contain. The actual Unix user workflow lives in `bootstrap/bootstrap.sh`, `bootstrap-up.sh`, `script/install.sh`, `script/post.sh`, `justfile`, `.dotter/`, and `packages/`.

`Dotter` is the deployment tool used by the `stow` stage. In this repository it normally creates symbolic links from files under `packages/` into a user's home directory. A symbolic link is a filesystem entry that points to another path instead of storing its own data. That is acceptable on a normal checked-out machine, but it is wrong for a prebuilt runtime image if the final image deletes the repository tree.

The release image therefore needs one extra step after `just up` completes. That step scans the deployed files in the container home directory, finds the symbolic links that still point back into the build workspace, replaces them with ordinary copied files or directories, and only then removes the workspace. This happens only for the release-image build, not for the general `stow` implementation.

The release workflow also needs stable answers to three questions from repository state. The first is "did any maintained user-workflow implementation input change?" The second is "did any container-specific user-workflow input change?" The third is "did any release-image manifest input change?" Before this revision, the first and third questions were answered by shell case statements in `hack/user_workflow_changed.sh` and `hack/dotfile_image_inputs_changed.sh`. After this revision, all three answers come from `file-classifier.toml`, a machine-readable root fact file with additive include semantics, and `hack/change-detection/main.py`, a Python 3.11+ CLI that collects changed files and evaluates one named classifier. The fact file is intentionally flat: each top-level TOML table is one classifier, so a maintainer can update one classification rule set without any extra namespace or many one-use helper blocks.

In this repository, "container-specific user-workflow input" means the subset of user-workflow paths that can change the behavior or contents of the container run of `bootstrap -> install -> stow -> post`. That subset is not inferred from one file alone. `packages/container.list` controls which tools are installed. `.dotter/default/container.toml`, `.dotter/unix.toml`, and `.dotter/global.toml` control which config packages are deployed. `script/post.sh` and the Unix post hooks under `packages/post/` control post-install side effects. The fact file must describe all of those pieces.

## Plan of Work

Start by replacing the old hard-coded classifier rule sets with a single root fact file, `file-classifier.toml`. The file must be organized as top-level classifier tables, with additive includes used only where one classifier truly extends another. A classifier is a named answer with repository-relative path patterns and optional includes of other classifiers. The file supports additive composition only: one classifier includes another, and their patterns are unioned together. It does not support subtracting one set from another.

Implement the classifier in a single Python script under `hack/change-detection/`, using Python 3.11 standard library `tomllib` so the repository does not depend on an external TOML parser. The CLI must load the TOML file, resolve additive includes recursively, detect missing references and include cycles, collect changed files from Git, and answer whether any changed path matches the fully resolved pattern set for a requested classifier.

Expose the normal command as `python3 hack/change-detection/main.py --source <workspace|commit> <classifier>`. `workspace` compares the working tree against `HEAD` and includes untracked files. `commit` compares the checked-out `HEAD` commit against `HEAD^1`, falling back to the complete `HEAD` file tree when no parent exists. When callers provide `--base <sha>` and `--head <sha>` with `--source commit`, the CLI compares that explicit range instead. Do not add a debug pattern-inspection command unless a future task needs it.

Update the fact file so it contains the real container workflow inputs, not a blanket `packages/**` rule. The broad `user_workflow` classifier should still cover all maintained user-workflow inputs, but the `user_workflow_container` classifier must only include the Unix bootstrap scripts, the command surface, the container install scripts and list, the Dotter files used by container bootstrap and deploy, the config package directories enabled by the container Dotter profile, and the Unix post hooks that run in the container image build. The `dotfile_image_manifest` classifier must include the `user_workflow_container` classifier plus image-specific inputs such as `file-classifier.toml`, `hack/change-detection/main.py`, `.dockerignore`, `ci/image/**`, and `.github/workflows/ubuntu-dotfile.yml`.

Finally, update `.github/workflows/ubuntu-dotfile.yml`, `docs/release-image.md`, and `docs/maintainer-workflow.md` so they refer to the TOML fact file and Python CLI as the source of truth, mention the new `user_workflow_container_changed` output where relevant, and rename `dotfile_image_inputs_changed` to `dotfile_image_manifest_changed`.

For the 2026-04-21 trigger correction, keep the change-detection job available for pull requests and explicit manual dispatch, but limit automatic `push` workflow events to `master`. The image job condition should say the same thing explicitly: manual dispatch always builds without publishing, pull requests build only when `dotfile_image_manifest_changed=true`, and push events build only when the pushed ref is `refs/heads/master` and `dotfile_image_manifest_changed=true`.

For push change detection, extend `hack/change-detection/main.py` so `--source commit` can accept optional `--base <sha>` and `--head <sha>` arguments. When both are provided, the classifier compares `base..head`; when they are omitted, it keeps the existing `HEAD^1..HEAD` fallback for pull request merge commits and local checks. If GitHub reports an all-zero base SHA or the base object cannot be found, classify the complete file tree of `head` so the workflow fails open by building rather than silently skipping a possibly relevant image change.

## Concrete Steps

From the repository root:

1. Update this ExecPlan so it describes the TOML fact-file design, the additive include semantics, the new classifier names, and the new validation expectations.
2. Add `file-classifier.toml`.
3. Add `hack/change-detection/main.py`, implemented in Python 3.11+ and using standard library `tomllib`.
4. Remove the shell wrapper layer and call the Python CLI directly from the workflow and docs.
5. Update `.github/workflows/ubuntu-dotfile.yml` to publish `user_workflow_container_changed` and `dotfile_image_manifest_changed`.
6. Update `docs/release-image.md` and `docs/maintainer-workflow.md`.
7. Run static validation:

       python3 -m py_compile hack/change-detection/main.py

8. Run classifier checks from the repository root. Use `workspace` first in a clean tree and then with temporary edits:

       python3 hack/change-detection/main.py --source workspace user_workflow
       python3 hack/change-detection/main.py --source workspace user_workflow_container
       python3 hack/change-detection/main.py --source workspace dotfile_image_manifest

    Then create temporary edits one at a time, rerun the same commands, and confirm these behaviors:

       packages/alacritty/... -> only user_workflow changes
       packages/zsh/... -> all three change
       .dotter/windows.toml -> only user_workflow changes
       ci/image/Dockerfile -> only dotfile_image_manifest changes
       file-classifier.toml -> only dotfile_image_manifest changes
       hack/change-detection/main.py -> only dotfile_image_manifest changes

9. Validate workflow syntax if `actionlint` is available:

       actionlint .github/workflows/ubuntu-dotfile.yml

10. For the 2026-04-21 trigger correction, update `.github/workflows/ubuntu-dotfile.yml` so `on.push.branches` contains only `master`, and update the image job `if` expression so non-`master` push events cannot run the image build job even if the trigger is expanded later. Update `docs/release-image.md` and `ci/image/README.md` so they describe only the `master` publish tag plus `latest` when `master` is the default branch.
11. For the push range correction, update `hack/change-detection/main.py` with optional `--base` and `--head` arguments for `--source commit`, then update `.github/workflows/ubuntu-dotfile.yml` so push events pass `${{ github.event.before }}` and `${{ github.sha }}`. Add Python bytecode cache entries to `.gitignore`, remove any generated `__pycache__` file from the working tree, and update `docs/release-image.md` plus `plans/file-classifier.md` to describe the new command surface.

## Validation and Acceptance

Acceptance for the release image remains behavioral. A successful local build of `ci/image/Dockerfile` must complete `bootstrap-up.sh` during `docker build`, and a container started from that image must contain deployed dotfiles under `/root` as ordinary files and directories rather than symlinks into `/workspace`. The final image must not retain `/workspace`.

Acceptance for the workflow trigger model is now tripartite. Running the Python CLI in `workspace` mode for the three classifiers in a clean tree must print `false`. Editing a broad user-workflow path such as `packages/alacritty/...` must make only the `user_workflow` classifier print `true`. Editing a container-relevant config package such as `packages/zsh/...` must make all three classifiers print `true`. Editing an image-only input such as `ci/image/Dockerfile`, `file-classifier.toml`, or `hack/change-detection/main.py` must make only the `dotfile_image_manifest` classifier print `true`. Running the same classifiers in `commit` mode must classify the checked-out commit with the same path rules, and `commit` mode with explicit `--base` and `--head` must classify the complete range between those two revisions. `.github/workflows/ubuntu-dotfile.yml` must start for pull requests, `master` pushes, and manual dispatch. The image build job should run only when manual dispatch is used, when a pull request has `dotfile_image_manifest_changed=true`, or when a `master` push has `dotfile_image_manifest_changed=true`. Pushes to branches other than `master` must not start the release workflow automatically.

Acceptance for the wider repository contract is that the usual Unix workflow still works when exercised through the disposable devcontainer environment described by `test/devcontainer/devcontainer.json`. The release-image finalization logic must not be required for normal `just up` execution in that validation surface.

## Idempotence and Recovery

The new fact file and Python CLI are safe to edit repeatedly. The classifier command does not write repository state; it only inspects the current diff source. If a TOML or include-resolution mistake breaks classification, fix the fact file or CLI and rerun the same command. The image build and devcontainer validation remain retryable from scratch as before.

If validation fails because local Git rejects the repository as an unsafe directory in this environment, rerun the validation commands with temporary Git config injection rather than mutating the repository. The checked-in scripts must continue to use plain `git` so CI remains simple. Python bytecode compilation may create `hack/change-detection/__pycache__/`; remove that generated directory after validation and keep `.gitignore` broad enough to prevent accidental `*.pyc` commits.

## Artifacts and Notes

The important new artifact in this revision is `file-classifier.toml`, which becomes the single source of truth for watched paths. The other important artifact is `hack/change-detection/main.py`, which collects Git changes, resolves additive includes, and evaluates classifiers without a shell wrapper layer. The final fact-file shape is intentionally flat so maintainers can read it top to bottom without reconstructing classifier membership from many one-use fragments.

Expected classification examples after implementation:

    edit: packages/alacritty/alacritty.toml.tmpl
    user_workflow_changed=true
    user_workflow_container_changed=false
    dotfile_image_manifest_changed=false

    edit: packages/zsh/conf.d/05-utils.zsh
    user_workflow_changed=true
    user_workflow_container_changed=true
    dotfile_image_manifest_changed=true

    edit: ci/image/Dockerfile
    user_workflow_changed=false
    user_workflow_container_changed=false
    dotfile_image_manifest_changed=true

Expected workflow trigger excerpt after the 2026-04-21 correction:

    on:
      push:
        branches:
          - master

    ubuntu-dotfile:
      if: manual dispatch, or pull request with dotfile_image_manifest_changed=true, or master push with dotfile_image_manifest_changed=true

## Interfaces and Dependencies

The public image artifact remains `ghcr.io/petejohn6/ubuntu-dotfile`. The release workflow in `.github/workflows/ubuntu-dotfile.yml` continues to build from repository root context with `ci/image/Dockerfile`. Automatic push-triggered publishing is limited to `master`, which publishes `ghcr.io/petejohn6/ubuntu-dotfile:master` and, when `master` is the default branch, `ghcr.io/petejohn6/ubuntu-dotfile:latest`.

The implementation depends on the existing Unix workflow interfaces that must remain unchanged:

- `bootstrap-up.sh` must continue to run `bootstrap/bootstrap.sh` followed by `just up`.
- `justfile` must continue to expose `install`, `stow`, `post`, and `up` without a release-image-specific branch.
- `ci/image/finalize-image.sh` is a release-image-only helper and must not be treated as part of generic `stow`.

The new classifier interface consists of:

- `file-classifier.toml` as the only source of watched-path facts
- `hack/change-detection/main.py` as the only change-detection CLI, invoked as `python3 hack/change-detection/main.py --source <workspace|commit> [--base <sha> --head <sha>] <classifier>`

The CLI must print exactly one line: `true` or `false`.

Ongoing maintenance of `file-classifier.toml` is tracked in `plans/file-classifier.md`. Do not expand this release-image plan for classifier fact-file work unless the change also alters the published image or its release workflow contract.

Revision note: initial checked-in version created to bring the missing release-image implementation in line with the already documented repository contract.
Revision note: updated on 2026-04-10 to replace the workflow's hard-coded `paths` trigger with reusable `hack/` classifiers for `workspace` and `head` diff modes, keeping the release-image input rules in one shared automation surface.
Revision note: updated on 2026-04-12 to replace shell-hard-coded classifier rules with a TOML fact file that supports additive includes, to add a container-specific classifier, and to rename the image classifier to `dotfile_image_manifest_changed`.
Revision note: updated on 2026-04-19 to flatten the TOML manifest so the current repository keeps only three main classifier blocks and a single additive include relationship, reducing maintenance overhead without changing external behavior.
Revision note: updated on 2026-04-19 again to remove the redundant `classifiers` namespace so each top-level TOML table is directly a classifier.
Revision note: updated on 2026-04-19 again to replace the shell wrapper layer with a direct Python 3.11+ CLI and rename the CI source mode from `head` to `commit`.
Revision note: updated on 2026-04-20 to move the watched-path fact source to root `file-classifier.toml`, keep the CLI under `hack/change-detection/`, and classify both files as release-image manifest inputs.
Revision note: updated on 2026-04-20 to split classifier fact-file maintenance into `plans/file-classifier.md`.
Revision note: updated on 2026-04-20 to merge release-image change-detection docs into `docs/release-image.md`.
Revision note: updated on 2026-04-21 to limit automatic push-triggered release-image builds and publishing to `master`, while preserving pull request and manual dispatch validation builds.
Revision note: updated on 2026-04-21 again to classify push events across the full GitHub `before..sha` range and to keep Python bytecode cache output out of the worktree.
