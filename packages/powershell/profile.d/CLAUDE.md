# Module Development Guidelines

## When a shortcut command needs to be created

### Base Requirements

!import: Do not introduce dependencies outside of current dependencies unless necessary.

### Key Points

1. Use PowerShell functions (with comment-based help) to implement shortcut commands. Do NOT use `Set-Alias/New-Alias`. Aliases only provide static "name→command name" mapping and cannot carry parameters, pipeline input, default values, or combined logic.

   - Functions are complete command units that can receive parameters and pipeline input, support conditional branching and multi-step encapsulation, and provide readable usage documentation through `.SYNOPSIS/.DESCRIPTION/.EXAMPLE`.

   - See complete information at `https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions`

2. Use fzf to provide an interactive interface.

   - See detailed documentation at `https://junegunn.github.io/fzf/`

3. Use ripgrep (`rg`) as the find and search tool.

   - See detailed documentation at `https://github.com/BurntSushi/ripgrep`

### Things to Watch For

1. If you modify or add code related to "Use PowerShell functions (with comment-based help) to implement shortcut commands", you must also review and maintain the function's `.SYNOPSIS/.DESCRIPTION/.EXAMPLE` fields.

| Field | Required? | Purpose |
| --- | --- | --- |
| `.SYNOPSIS` | Yes | A one-sentence summary. It should let readers quickly understand what the function does (typically 1–2 lines). |
| `.DESCRIPTION` | Optional (recommended for complex functions) | Detailed behavior: defaults, edge cases, dependencies, outputs, and common caveats. It should be longer than the synopsis and explain how it works and when to use it. |
| `.EXAMPLE` | Optional (recommended for complex functions) | Examples of typical usage. Ideally include the command and the expected output/behavior. You can include multiple `.EXAMPLE` blocks; each should be copy-pastable. |


### Minimal Function Template

Use this shape for user-facing commands to keep behavior consistent:

```powershell
function Invoke-Thing {
<#
.SYNOPSIS
Does X for Y.

.DESCRIPTION
Longer explanation of behavior, defaults, and failure modes.

.EXAMPLE
Invoke-Thing -Name foo
#>
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    # Implementation here (validate inputs, call tools, handle errors)
}
```
