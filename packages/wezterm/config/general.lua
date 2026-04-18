local wezterm = require("wezterm")
local platform = require("utils.platform")

local config = {}

--- macos setting
config.native_macos_fullscreen_mode = true
config.macos_fullscreen_extend_behind_notch = true

local default_prog = { "zsh", "-l" }
local launch_menu = {}
local wsl_domains = {}

if platform.is_win then
	default_prog = { "pwsh.exe", "-NoLogo" }
	wsl_domains = wezterm.default_wsl_domains()

	for _, domain in ipairs(wsl_domains) do
		if domain.distribution == "Ubuntu-24.04" or domain.name == "WSL:Ubuntu-24.04" then
			domain.username = "root"
			domain.default_prog = { "zsh", "-l" }
		end
	end

	launch_menu = {
		{
			label = "PowerShell",
			args = { "pwsh.exe", "-NoLogo" },
		},
		{
			label = "WSL Ubuntu 24.04",
			domain = { DomainName = "WSL:Ubuntu-24.04" },
		},
		{
			label = "WSL Ubuntu 24.04 (tmux)",
			domain = { DomainName = "WSL:Ubuntu-24.04" },
			args = { "tmux" },
		},
	}
end

return {
	automatically_reload_config = true,
	default_prog = default_prog,
	launch_menu = launch_menu,
	wsl_domains = wsl_domains,
	exit_behavior = "CloseOnCleanExit",
	exit_behavior_messaging = "Verbose",
	scrollback_lines = 20000,
	hide_mouse_cursor_when_typing = true,
	hyperlink_rules = {
		{
			regex = "\\((\\w+://\\S+)\\)",
			format = "$1",
			highlight = 1,
		},
		{
			regex = "\\[(\\w+://\\S+)\\]",
			format = "$1",
			highlight = 1,
		},
		{
			regex = "\\{(\\w+://\\S+)\\}",
			format = "$1",
			highlight = 1,
		},
		{
			regex = "<(\\w+://\\S+)>",
			format = "$1",
			highlight = 1,
		},
		{
			regex = "\\b\\w+://\\S+[)/a-zA-Z0-9-]+",
			format = "$0",
		},
		{
			regex = "\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b",
			format = "mailto:$0",
		},
	},
}
