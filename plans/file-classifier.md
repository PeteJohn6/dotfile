# Maintain the Repository File Classifier

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This document is maintained in accordance with `PLANS.md` at the repository root.

## Trigger / Why This Needs an ExecPlan

`file-classifier.toml` is a repository-root fact file that influences the `ubuntu-dotfile` image workflow. It tells supporting automation which changed repository paths affect the broad user workflow, the container-specific user workflow, and the release-image manifest. Because those answers can decide whether the image build runs, the file is part of the durable release workflow contract and needs its own checked-in plan.

This plan is deliberately narrower than a linter implementation plan. Linting is an expected future capability for this fact file, but `hack/change-detection/main.py` must remain the change-classification CLI and must not gain a lint-specific mode as part of the current image-build work. The current scope is to maintain `file-classifier.toml`, keep its image-build semantics documented, and preserve the existing classifier command surface.

## Purpose / Big Picture

After this change, maintainers can find the global changed-file classification facts at the repository root in `file-classifier.toml` instead of under the `hack/` implementation directory. The release-image workflow still calls `python3 hack/change-detection/main.py --source commit <classifier>` for pull request merge commits, and for push events it passes an explicit base and head revision to the same command surface. The path facts it interprets are maintained separately from the Python CLI.

The observable behavior is that the classifier command still prints only `true` or `false` for a selected Git diff source:

    python3 hack/change-detection/main.py --source workspace dotfile_image_manifest
    python3 hack/change-detection/main.py --source commit --base <sha> --head <sha> dotfile_image_manifest

When the selected diff source touches `file-classifier.toml`, `hack/change-detection/main.py`, `.dockerignore`, `ci/image/**`, or `.github/workflows/ubuntu-dotfile.yml`, the `dotfile_image_manifest` classifier must print `true`.

## Progress

- [x] (2026-04-20T02:30:09+08:00) Moved the watched-path facts to repository-root `file-classifier.toml` and updated `hack/change-detection/main.py` to read it by default.
- [x] (2026-04-20T02:32:00+08:00) Updated release-image and maintainer docs so they describe the root fact file and the existing classifier CLI.
- [x] (2026-04-20T02:32:00+08:00) Updated `dotfile_image_manifest` so edits to `file-classifier.toml` or `hack/change-detection/main.py` are image-manifest inputs.
- [x] (2026-04-20T02:47:29+08:00) Created an initial separate plan for future linting.
- [x] (2026-04-20T03:00:00+08:00) Revised that plan into this maintenance plan because linting is expected later, but not as a `main.py` responsibility in the current image-build work.
- [x] (2026-04-20T04:03:38+08:00) Merged the separate release-image change-detection document into `docs/release-image.md` so image build gating is documented with the image workflow it controls.
- [x] (2026-04-20T04:14:17+08:00) Reduced `docs/maintainer-workflow.md` to change-detection ownership and routing guidance, leaving classifier details and examples in `docs/release-image.md`.
- [x] (2026-04-21T00:47:00+08:00) Extended `commit` source classification with optional explicit `--base` and `--head` revisions for GitHub push events.
- [x] (2026-04-21T00:56:52+08:00) Validated the updated classifier with Python bytecode compilation, workspace classification, explicit empty-range commit classification returning `false`, null-base commit classification returning `true`, and post-validation `__pycache__` cleanup.
- [x] (2026-04-21T01:24:12+08:00) Replaced exact `packages/post/*.sh` entries in the container classifier with a directory-wide post hook pattern so newly added Unix post hooks trigger release-image builds.
- [x] (2026-04-21T01:26:39+08:00) Validated the post-hook classifier fix with a temporary untracked `packages/post/review-classifier-temp.sh` file that made all three workspace classifiers print `true`, then removed the temporary file and reran static checks.

## Surprises & Discoveries

- Observation: the existing classifier CLI already performs the minimum validation needed for current image-build classification.
  Evidence: `hack/change-detection/main.py` parses TOML with `tomllib`, validates top-level table shape, rejects unsupported keys, checks `includes` and `patterns` types, detects unknown classifiers, and detects include cycles during include resolution.
- Observation: once wrapper scripts were removed, the facts became more important than the directory that contains the Python interpreter.
  Evidence: `file-classifier.toml` is now the root source of watched-path truth, while `hack/change-detection/main.py` is the executable reader for that source.
- Observation: classifier infrastructure changes can affect image workflow behavior even when no bootstrap, install, stow, or post path changed.
  Evidence: `[dotfile_image_manifest]` now includes `file-classifier.toml` and `hack/change-detection/main.py`.
- Observation: a push event can contain more than one commit, while the previous `commit` source fallback only compared `HEAD^1..HEAD`.
  Evidence: `hack/change-detection/main.py` collected commit changes with `git diff --name-only HEAD^1 HEAD --`, so a direct multi-commit `master` push could miss image-manifest changes outside the final commit.
- Observation: the post stage automatically executes every shell hook under `packages/post/`, not only the hook files that exist today.
  Evidence: `script/post.sh` loops over `"$POST_DIR"/*.sh`, so a future `packages/post/foo.sh` can affect the release image even before the classifier fact file is updated for that specific filename.

## Decision Log

- Decision: keep `file-classifier.toml` at the repository root.
  Rationale: these are global watched-path facts, not private implementation details of `hack/change-detection/`. A root-level file is easier to discover and signals that the contents are important to repository automation.
  Date/Author: 2026-04-20 / Codex
- Decision: keep `hack/change-detection/main.py` focused on changed-file classification only.
  Rationale: the existing workflow needs `python3 hack/change-detection/main.py --source <workspace|commit> <classifier>` to produce `true` or `false`. Debug pattern inspection and linting are future capabilities for the fact file, but neither should be added to `main.py` in the current image-build scope.
  Date/Author: 2026-04-20 / Codex
- Decision: track future linting as an expected capability without choosing its command shape now.
  Rationale: the current problem is location and maintenance of the fact file. Prematurely assigning linting to a specific CLI would constrain a later design before the desired checks and integration point are clear.
  Date/Author: 2026-04-20 / Codex
- Decision: include classifier infrastructure in `dotfile_image_manifest`.
  Rationale: if the facts or interpreter that decide image build eligibility change, the release-image workflow should exercise the image build job rather than only the detection job.
  Date/Author: 2026-04-20 / Codex
- Decision: add optional `--base` and `--head` arguments to `--source commit` instead of creating a separate source mode.
  Rationale: the selected diff is still a commit-based classification; the only difference is whether the caller lets the CLI infer `HEAD^1..HEAD` or supplies the exact range from a GitHub push event.
  Date/Author: 2026-04-21 / Codex
- Decision: classify `packages/post/**` as a container-specific user-workflow input.
  Rationale: the image build runs `script/post.sh`, and that script executes every current or future `*.sh` hook in `packages/post/`. Directory-wide matching prevents newly added hooks from being skipped by the image build gate.
  Date/Author: 2026-04-21 / Codex

## Outcomes & Retrospective

The current outcome is a separate plan for `file-classifier.toml` maintenance, with linting recorded as future work rather than an immediate `main.py` feature. Release-image documentation now owns the classifier meanings and image build gating examples, while maintainer workflow documentation only routes contributors to the right ownership boundary. The push-range follow-up is complete, so the same CLI can classify an explicit GitHub push range without duplicating path facts in workflow YAML. The post-hook review fix is complete, so future `packages/post/` hooks are classified without adding one filename at a time.

## Context and Orientation

`file-classifier.toml` is a TOML file in the repository root. TOML is a structured configuration format with tables such as `[user_workflow]` and arrays such as `patterns = [...]`. In this repository, each top-level table is one classifier. A classifier is a named answer to a changed-file question.

The supported fields are:

- `patterns`: an array of repository-relative path patterns.
- `includes`: an optional array of other classifier names to include additively.

The supported pattern language is intentionally small. A pattern is either an exact repository-relative path such as `justfile` or `.github/workflows/ubuntu-dotfile.yml`, or a recursive directory prefix ending in `/**` such as `packages/zsh/**`. There are no excludes or negative patterns.

The current required classifiers are:

- `user_workflow`: broad maintained user-workflow implementation inputs.
- `user_workflow_container`: the container-specific subset of user-workflow inputs.
- `dotfile_image_manifest`: release-image manifest inputs; it includes `user_workflow_container` and adds image-specific plus classifier-infrastructure paths.

`packages/post/**` belongs in `user_workflow_container` because the `post` stage executes hooks from that directory during the release-image build. The classifier intentionally watches the directory rather than the currently existing filenames.

`hack/change-detection/main.py` is the current reader for this file. It must continue to support:

    python3 hack/change-detection/main.py --source <workspace|commit> <classifier>
    python3 hack/change-detection/main.py --source commit --base <sha> --head <sha> <classifier>

It must not gain debug pattern-inspection or lint-specific options as part of this plan.

## Plan of Work

Maintain `file-classifier.toml` as the single source of watched-path facts. Keep the file flat and classifier-first unless the number of classifiers or repeated path sets grows enough that duplication becomes a real maintenance problem.

Preserve the Python CLI as a changed-file classifier. It should load `file-classifier.toml` by default and classify workspace or commit changes for a named classifier. For `commit` source, allow callers to provide both `--base` and `--head` when they need to classify a full pushed range; otherwise keep the inferred `HEAD^1..HEAD` behavior. Do not add debug pattern-inspection flags, lint-specific flags, or new responsibilities to `hack/change-detection/main.py` under this plan.

Keep release-image documentation aligned with the fact file. When `dotfile_image_manifest` changes, update `docs/release-image.md`, `docs/maintainer-workflow.md`, and the release-image plan if the change affects the image workflow contract.

When future linting is designed, start from this plan's context but write or revise a dedicated plan for the linter command shape. That future plan must choose where linting lives, how it reports diagnostics, whether it runs in CI, and how it validates examples. This plan does not make those decisions.

## Concrete Steps

For the current image-build change, from the repository root:

1. Keep `file-classifier.toml` at the repository root.
2. Keep `hack/change-detection/main.py` reading `file-classifier.toml` by default.
3. Keep `[dotfile_image_manifest]` including:

       file-classifier.toml
       hack/change-detection/main.py
       .dockerignore
       ci/image/**
       .github/workflows/ubuntu-dotfile.yml

4. Run static validation:

       python3 -m py_compile hack/change-detection/main.py

5. Run workspace classification with temporary Git safe-directory injection if this Windows sandbox rejects the worktree owner:

       $env:GIT_CONFIG_COUNT='1'
       $env:GIT_CONFIG_KEY_0='safe.directory'
       $env:GIT_CONFIG_VALUE_0='C:/Users/night/code/dotfile-1/.tree/feature/hack'
       python3 hack/change-detection/main.py --source workspace user_workflow
       python3 hack/change-detection/main.py --source workspace user_workflow_container
       python3 hack/change-detection/main.py --source workspace dotfile_image_manifest

6. Run commit-range validation:

       python3 hack/change-detection/main.py --source commit --base HEAD --head HEAD dotfile_image_manifest
       python3 hack/change-detection/main.py --source commit --base 0000000000000000000000000000000000000000 --head HEAD dotfile_image_manifest

7. When changing post-hook classification, create a temporary untracked file such as `packages/post/review-classifier-temp.sh`, run the three workspace classifiers, and expect all three to print `true`. Remove the temporary file before finishing.

## Validation and Acceptance

The current file-classifier maintenance work is accepted when:

- `python3 -m py_compile hack/change-detection/main.py` exits zero.
- current edits to `file-classifier.toml` or `hack/change-detection/main.py` make only `dotfile_image_manifest` classify as changed, not `user_workflow` or `user_workflow_container`.
- `--source commit --base HEAD --head HEAD dotfile_image_manifest` prints `false`, proving explicit empty ranges are accepted.
- `--source commit --base 0000000000000000000000000000000000000000 --head HEAD dotfile_image_manifest` prints `true` in this repository, proving the GitHub null-base fallback classifies the complete file tree of the selected head.
- a newly added untracked `packages/post/*.sh` file makes `user_workflow`, `user_workflow_container`, and `dotfile_image_manifest` all print `true`.
- the CLI does not expose a debug pattern-inspection or lint-specific option.
- docs and plans consistently describe `file-classifier.toml` as the active fact source.

Future linting acceptance criteria are intentionally not defined here. They belong in the future linter plan once its command surface is chosen.

## Idempotence and Recovery

Editing `file-classifier.toml` is safe to repeat. If the CLI reports invalid TOML, bad field shapes, unknown includes, or include cycles, fix the fact file and rerun the same classification command.

The classifier commands should not write repository state. Python bytecode compilation may create `__pycache__`; remove that generated directory after validation if it appears. If local Git rejects this worktree as unsafe, use temporary `GIT_CONFIG_COUNT` environment variables for validation rather than mutating global Git configuration.

## Artifacts and Notes

The main artifact is `file-classifier.toml`. Its current release-image classifier must resolve to this image-manifest surface:

    justfile
    bootstrap/bootstrap.sh
    bootstrap-up.sh
    script/install.sh
    script/misc.sh
    script/post.sh
    packages/container.list
    packages/pre-install-unix.sh
    .dotter/global.toml
    .dotter/unix.toml
    .dotter/default/container.toml
    packages/git/**
    packages/nvim/**
    packages/starship/**
    packages/tmux/**
    packages/zsh/**
    packages/post/**
    file-classifier.toml
    hack/change-detection/main.py
    .dockerignore
    ci/image/**
    .github/workflows/ubuntu-dotfile.yml

## Interfaces and Dependencies

The maintained fact-file interface is:

    file-classifier.toml

The maintained classifier CLI interfaces are:

    python3 hack/change-detection/main.py --source <workspace|commit> <classifier>
    python3 hack/change-detection/main.py --source commit --base <sha> --head <sha> <classifier>

The implementation depends only on Python 3.11+ standard-library `tomllib` for TOML parsing. Do not introduce `uv`, `pip`, `pytest`, `tomli`, or any other dependency for the current image-build classifier work.
