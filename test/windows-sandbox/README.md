# Windows Sandbox Test Harness

This directory contains the Windows-only disposable test harness for this repository.

## Entry Points

Use the dedicated test justfile from the repository root:

```powershell
just --justfile test/justfile windows-runtime-prepare
just --justfile test/justfile windows-static
just --justfile test/justfile windows-sandbox-logon
just --justfile test/justfile windows-sandbox-stop
just --justfile test/justfile windows-sandbox-full
```

`windows-runtime-prepare` downloads the latest stable PowerShell ZIP into `test/windows-sandbox/assets/` on the host.

`windows-static` validates the generated `.wsb` config, PowerShell syntax, the local `wsb` CLI, and the presence of the host-side runtime ZIP without launching Sandbox.

`windows-sandbox-logon` launches Windows Sandbox through the `wsb` CLI, waits for `System` and `ExistingLogin` guest command readiness, then runs the stage-0 bootstrap under `powershell.exe` and waits for a terminal runtime-bootstrap state.

`windows-sandbox-stop` stops any currently running Windows Sandbox session and updates the host-side state file.

`windows-sandbox-full` launches a fresh Windows Sandbox instance, expands the staged PowerShell ZIP, copies the repository into `C:\workspace`, runs `bootstrap\bootstrap.ps1`, then runs `just up`, and waits for a terminal guest state.

## Requirements

- Windows Sandbox must be available and enabled on the host.
- Windows Sandbox CLI (`wsb`) must be available on the host.
- Host-side runtime ZIP must exist under `test/windows-sandbox/assets/`.
- PowerShell 7 is the only supported runtime for repo-owned test scripts inside the harness.
- `pwsh.exe` is treated as a side-loaded runtime asset, not as a system-installed dependency inside Sandbox.
- The harness assumes Windows Sandbox is single-instance. If a Sandbox session is already active, launch is blocked instead of silently starting a second run.
- Waited runs auto-close the disposable Sandbox session after a terminal success or failure.

## Outputs

Runtime logs and generated configuration are written under:

- `test/windows-sandbox/assets/`
- `test/windows-sandbox/logs/`
- `test/windows-sandbox/generated/`

Important state files under `test/windows-sandbox/logs/`:

- `host-state.json` - host-side state observer view of the current sandbox session
- `sandbox-state.json` - guest-reported machine-readable state transitions
- `summary.txt` - final human-readable result
- `system-exec-probe.txt` - host-visible proof that `wsb exec --run-as System` succeeded inside the guest
- `existing-login-probe.txt` - host-visible proof that `wsb exec --run-as ExistingLogin` succeeded inside the guest
- `bootstrap-probe.txt` - first probe written by `sandbox-bootstrap.ps1`
