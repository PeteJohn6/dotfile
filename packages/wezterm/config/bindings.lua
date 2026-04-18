local wezterm = require("wezterm")
local platform = require("utils.platform")
local backdrops = require("utils.backdrops")

local act = wezterm.action
local mod = {}

if platform.is_mac then
	mod.primary = "SUPER"
	mod.secondary = "SUPER|CTRL"
else
	mod.primary = "ALT"
	mod.secondary = "ALT|CTRL"
end

local keys = {
	{ key = "F11", mods = "NONE", action = act.ToggleFullScreen },
	{ key = "c", mods = "ALT", action = act.CopyTo("Clipboard") },
	{ key = "v", mods = "ALT", action = act.PasteFrom("Clipboard") },
	{ key = "n", mods = "CTRL", action = act.SpawnWindow },
	{
		key = "/",
		mods = mod.primary,
		action = wezterm.action_callback(function(window, _pane)
			backdrops:toggle_image(window)
		end),
	},
	{
		key = "/",
		mods = mod.secondary,
		action = act.InputSelector({
			title = "Select Background",
			choices = backdrops:set_image_list(),
			fuzzy = true,
			fuzzy_description = "Background: ",
			action = wezterm.action_callback(function(window, _pane, id)
				if not id then
					return
				end
				backdrops:set_image(window, tonumber(id))
			end),
		}),
	},
	{
		key = "b",
		mods = mod.primary,
		action = wezterm.action_callback(function(window, _pane)
			backdrops:toggle_backdrop_mode(window)
		end),
	},
}

if platform.is_win then
	table.insert(keys, {
		key = "P",
		mods = "CTRL|SHIFT",
		action = act.ShowLauncherArgs({
			flags = "FUZZY|LAUNCH_MENU_ITEMS",
			title = "Launch",
		}),
	})
end

return {
	disable_default_key_bindings = true,
	keys = keys,
	mouse_bindings = {
		{
			event = { Up = { streak = 1, button = "Right" } },
			mods = "NONE",
			action = act.PasteFrom("Clipboard"),
		},
		{
			event = { Down = { streak = 1, button = "Middle" } },
			mods = "NONE",
			action = act.SelectTextAtMouseCursor("SemanticZone"),
		},
	},
}
