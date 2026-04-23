# Git Package

This guide explains the repo-managed Git package under `packages/git/`. The package provides global Git behavior, global ignore rules, and cross-platform attributes.

## Design Intent

- Keep global Git defaults portable across Unix and Windows.
- Use Delta for readable diffs without changing Git's underlying diff data.
- Prefer history that stays easy to inspect: rebased pulls, pruned fetches, automatic rebase stashing, and histogram diffs.
- Keep line-ending normalization explicit through global attributes instead of relying only on host Git defaults.

## Structure

| Path | Role |
| --- | --- |
| `packages/git/.gitconfig` | Global Git config deployed to `~/.gitconfig` |
| `packages/git/.gitignore_global` | Global ignore patterns deployed under `~/.gitconfigdir/` |
| `packages/git/.gitattributes` | Global attributes and line-ending rules deployed under `~/.gitconfigdir/` |

## Configuration Model

`.gitconfig` points Git at the repo-managed ignore and attributes files:

- `core.excludesfile = ~/.gitconfigdir/.gitignore_global`
- `core.attributesfile = ~/.gitconfigdir/.gitattributes`

Diff display uses Delta through `core.pager = delta --color-only`. Delta is configured for decorated side-by-side diffs, navigation, line numbers, and the `Monokai Extended` syntax theme.

Repository defaults are intentionally conservative:

- new repositories use `init.defaultBranch = master`
- pulls rebase by default with `pull.rebase = true`
- pushes use `push.default = simple`
- fetches prune deleted remote branches
- rebases use `rebase.autoStash = true`
- merges use `merge.conflictStyle = diff3`
- diffs use `diff.algorithm = histogram` and copy/rename detection

Global aliases are minimal and avoid hiding Git subcommands: `st` for `status` and `s` for `status -sb`.

## Ignore And Attribute Model

`.gitignore_global` covers common operating-system files, editor state, language build output, package-manager directories, logs, and local environment directories. These rules are global by design, so they should stay focused on machine-local clutter rather than project-specific outputs.

`.gitattributes` starts with `* text=auto`, then pins file families to the line endings expected by their dominant runtime:

- Shell, zsh, config, Markdown, source, web, Dockerfile, and justfile patterns use LF.
- PowerShell, batch, and cmd scripts use CRLF.
- Images, fonts, archives, compiled binaries, documents, and multimedia are binary.
- Lockfiles are excluded from text diff output.
- Markdown and JSON files use named diff drivers when available.

`core.autocrlf = input` complements those attributes by normalizing CRLF to LF on commit without forcing CRLF checkout globally.

## Lifecycle Integration

| Stage | Current behavior |
| --- | --- |
| Install list | `packages/packages.list` installs `git`. `packages/container.list` also includes `git`. |
| Pre-install | No package-specific pre-install rule. |
| Dotter deployment | Global Dotter config deploys `.gitconfig` to `~/.gitconfig` and the ignore/attributes files under `~/.gitconfigdir/`. Default Unix, Windows, and container profiles include `git`. |
| Post hook | No post hook. |

Delta is installed by a separate `delta` entry in `packages/packages.list`. The Git package assumes `delta` may be absent on a partially provisioned machine; Git still runs, but pager startup can fail until Delta is installed or the pager setting is changed.

## Validation Notes

Validate Dotter deployment for `.gitconfig`, `.gitignore_global`, and `.gitattributes`. For runtime checks, inspect `git config --global --list --show-origin` and verify the deployed config is the origin for the managed keys.

## Common Failure Modes

- `~/.gitconfigdir/` files are not deployed, so global ignore or attributes paths point at missing files.
- Delta is missing while `core.pager` still points at it.
- A project needs repo-local line-ending rules that override the global attributes.
- The configured identity is not appropriate for a machine or account.
