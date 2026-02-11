# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This is a Neovim configuration organized with a modular structure using Lazy.nvim as the plugin manager. The configuration follows a clear separation of concerns:

### Core Structure
- **`init.lua`** - Entry point that loads core and plugin configuration
- **`lua/core/`** - Core Neovim configuration (options, keymaps, GUI settings, utilities)
- **`lua/lazyconf.lua`** - Lazy.nvim plugin manager setup and configuration
- **`lua/plugins/`** - Modular plugin configurations organized by functionality

### Plugin Organization Pattern
Each plugin file in `lua/plugins/` returns a Lua table or array of tables with Lazy.nvim plugin specifications. Key plugin categories:

- **Language Support** (`language.lua`) - Comprehensive language tool configuration using a unified pattern
- **Appearance** (`appearance.lua`) - Theme and UI customization (Cyberdream theme)  
- **Completion** (`completion.lua`) - Autocompletion with nvim-cmp
- **Editor** (`editor.lua`) - Core editing enhancements
- **Explorer** (`explorer.lua`) - File navigation tools
- **Terminal** (`terminal.lua`) - Terminal integration
- **Git** (`git.lua`) - Git workflow tools
- **Telescope** (`telescope.lua`) - Fuzzy finder and search
- **AI Assistant** (`ai-assistant.lua`) - AI-powered coding assistance

### Language Configuration System
The `language.lua` file implements a sophisticated configuration-driven approach for language tools:

- **Unified Configuration**: Uses `languagePluginConfig` table to define LSP servers, formatters, linters, and Treesitter parsers per language
- **Mason Integration**: Automatically installs and configures LSP servers via Mason
- **Dynamic Setup**: LSP servers are configured dynamically based on the configuration table
- **Keymapping System**: Centralized LSP keymaps applied via autocmd on LspAttach

Example language configuration structure:
```lua
languagePluginConfig = {
    javascript = {
        treesitter = { "javascript", "typescript" },
        formatter = { "prettier" },
        linter = { "eslint" },
        lsp = {
            ["typescript-language-server"] = {
                mason_lspconfig_name = "ts_ls"
            }
        }
    }
}
```

### Key Architectural Decisions
- **Lazy Loading**: Most plugins are configured for lazy loading to optimize startup time
- **Modular Design**: Each functional area is isolated in its own plugin file
- **Configuration Tables**: Language tools use declarative configuration for maintainability
- **Dynamic Line Numbers**: Custom autocmds show line numbers only in active windows
- **Windows Shell**: Configured to use PowerShell on Windows systems

## Development Commands

### Plugin Management
- Install/update plugins: `:Lazy` (opens Lazy.nvim UI)
- Plugin status: `:Lazy health`
- Clear plugin cache: `:Lazy clear`

### Language Server Management  
- Install LSP server: `:MasonInstall <server-name>`
- LSP server status: `:Mason` 
- Restart LSP: `<leader>rs` or `:LspRestart`
- LSP information: `:LspInfo`

### Formatting and Linting
- Format buffer: Uses conform.nvim (check `language.lua` for specific formatters)
- Lint status: Uses nvim-lint (integrated with LSP diagnostics)

### Key Diagnostic Commands
- Show diagnostics: `<leader>D` (buffer) or `<leader>d` (line)
- Navigate diagnostics: `[d` (previous), `]d` (next)
- Code actions: `<leader>ca`
- Rename symbol: `<leader>rn`

## Adding New Language Support

To add support for a new language, modify the `languagePluginConfig` table in `lua/plugins/language.lua`:

1. Add language entry with required tools
2. Specify LSP server name and any custom configuration
3. Define formatters and linters as needed
4. Add Treesitter parser for syntax highlighting
5. The system will automatically install and configure tools via Mason

## File Location Patterns

- Core Neovim settings: `lua/core/options.lua`
- Keymaps: `lua/core/keymaps.lua`
- GUI-specific settings: `lua/core/gui.lua`
- Plugin specifications: Individual files in `lua/plugins/`
- Plugin lock file: `lazy-lock.json` (commit this for reproducible installs)