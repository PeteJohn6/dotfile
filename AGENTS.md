# Contributor Guide

This guide helps new contributors get started with the Dotfile JS monorepo. It covers repo structure, how to test your work, available utilities, file locations, and guidelines for commits and PRs.

## Policies & Mandatory Rules

- Do not access or modify anything under `.tree/`.
- Do not modify files under repository test directories unless the task is explicitly about tests or validation infrastructure.
- Keep only the root `AGENTS.md`. Put durable knowledge, examples, and workflows in `docs/`.
- Treat `bootstrap -> install -> stow -> post` as the primary maintained model of the repo. Development should preserve or intentionally evolve that model.
- The maintenance target is the `user-workflow` model itself. Prefer preserving that model over optimizing for internal directory boundaries.
- `justfile` belongs to the command surface users run and generally should not change. Prefer changing `bootstrap/`, `script/`, `packages/`, `.dotter/`, and docs first.
- Keep `README.md` in sync when user-facing workflows, commands, package coverage, or maintained configs change.
- Do not treat repo-local runtime state as source of truth. `bin/`, machine-local state under `.dotter/`, and disposable `/workspace` copies are operational state.

### ExecPlans

When writing complex features or significant refactors, use an ExecPlan (as described in PLANS.md) from design to implementation. Store each ExecPlan file under plans/ with a descriptive name, and create the directory if it does not exist. Call out compatibility risk only when the plan changes behavior shipped in the latest release tag or a released/otherwise supported durable format. Do not treat branch-local interface churn or unreleased post-tag changes on main as breaking by default; prefer direct replacement over compatibility layers in those cases. Confirm the approach when changes could impact package consumers or durable external data that is already supported outside the current branch.

### Validation & Test

- End every change with static validation appropriate to the edited paths, including docs and other non-runtime checks. Prefer direct formatter, linter, and toolchain commands over repo-local wrapper scripts.
- Use `devcontainer-for-unix-work` to test that the full user-facing `bootstrap -> install -> stow -> post` model still holds.
- Add narrower stage-specific or harness-specific proof when the change needs more than the full workflow check to demonstrate correctness.

## Project Structure Guide

| Path | Relationship to user-workflow | Responsibility | Primary doc |
| --- | --- | --- | --- |
| `README.md` | Directly involved in user-workflow | Human quick-start and command guide | [docs/user-workflow.md](docs/user-workflow.md) |
| `justfile` | Directly involved in user-workflow | Stable command surface for install, deploy, preview, post-install, and teardown | [docs/user-workflow.md](docs/user-workflow.md) |
| `bootstrap/` | Directly involved in user-workflow | Bootstrap entrypoints behind the user-workflow model | [docs/user-workflow.md](docs/user-workflow.md) |
| `script/` | Directly involved in user-workflow | Install and post-install orchestration behind the user-workflow model | [docs/user-workflow.md](docs/user-workflow.md) |
| `packages/` | Directly involved in user-workflow | Package lists, hooks, and maintained configs used during install, stow, and post | [docs/maintainer-workflow.md](docs/maintainer-workflow.md) |
| `.dotter/` | Directly involved in user-workflow + local state | Deployment model, seeded defaults, and machine-local deployment state behind stow | [docs/maintainer-workflow.md](docs/maintainer-workflow.md) |
| `docs/` | Not directly involved in user-workflow | Durable architecture, reference, and package docs | [docs/maintainer-workflow.md](docs/maintainer-workflow.md) |
| `test/` | Not directly involved in user-workflow | Validation environments and test assets | [docs/maintainer-workflow.md](docs/maintainer-workflow.md) |
| `plans/` | Not directly involved in user-workflow | Execution plans and planning artifacts | [PLANS.md](PLANS.md) |
| `.agents/` | Not directly involved in user-workflow | Agent-side skills and supporting metadata | [docs/maintainer-workflow.md](docs/maintainer-workflow.md) |

## User Workflow

`bootstrap -> install -> stow -> post` is the user-facing logical interface of this repo and the primary maintained model behind repository changes. `bootstrap/` provides the platform bootstrap entrypoints, and `justfile` is the stable orchestration surface for the remaining stages. `install` runs the platform install script and is maintained as `pre-install -> install`, where pre-install handles preparation, manual paths, and exceptional cases before the package-manager install pass. `stow` deploys config from `packages/` through Dotter, and `post` runs post-deployment setup scripts. It is not the maintainer workflow.

Read [docs/user-workflow.md](docs/user-workflow.md) for the maintained contract, execution model, stage model, and user-facing guarantees.

## Maintainer Workflow

Maintainer workflow policy, change routing, validation depth, and runtime skill usage live in [docs/maintainer-workflow.md](docs/maintainer-workflow.md).

Use that document when changing repository behavior behind `bootstrap -> install -> stow -> post`.
