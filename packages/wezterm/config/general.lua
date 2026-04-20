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
	default_prog = { "wsl.exe", "--cd", "/home", "--user", "root", "--exec", "tmux" }
	wsl_domains = wezterm.default_wsl_domains()

	launch_menu = {
		{
			label = "PowerShell",
			args = { "pwsh.exe", "-NoLogo" },
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
