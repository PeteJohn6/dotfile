local wezterm = require("wezterm")
local platform = require("utils.platform")
local backdrops = require("utils.backdrops")

local act = wezterm.action
local mod = {}
local leader = nil

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

local function show_domains(prefix, title, action_kind)
	return wezterm.action_callback(function(window, pane)
		local choices = {}

		for _, domain in ipairs(wezterm.mux.all_domains()) do
			local name = domain:name()
			if name:sub(1, #prefix) == prefix then
				table.insert(choices, {
					id = name,
					label = domain:label(),
				})
			end
		end

		table.sort(choices, function(left, right)
			return left.label < right.label
		end)

		if #choices == 0 then
			window:toast_notification("WezTerm", "No " .. title .. " available", nil, 3000)
			return
		end

		window:perform_action(
			act.InputSelector({
				title = title,
				choices = choices,
				fuzzy = true,
				fuzzy_description = title .. ": ",
				action = wezterm.action_callback(function(inner_window, inner_pane, id)
					if not id then
						return
					end

					if action_kind == "attach" then
						inner_window:perform_action(act.AttachDomain(id), inner_pane)
					else
						inner_window:perform_action(
							act.SpawnCommandInNewTab({
								domain = { DomainName = id },
							}),
							inner_pane
						)
					end
				end),
			}),
			pane
		)
	end)
end

local function show_domain_groups()
	return act.InputSelector({
		title = "Domains",
		choices = {
			{ id = "wsl", label = "w  WSL Domains" },
			{ id = "ssh", label = "s  SSH Domains" },
			{ id = "sshmux", label = "m  SSH Mux Domains" },
		},
		alphabet = "wsm",
		action = wezterm.action_callback(function(window, pane, id)
			if id == "wsl" then
				window:perform_action(show_domains("WSL:", "WSL Domains", "spawn"), pane)
			elseif id == "ssh" then
				window:perform_action(show_domains("SSH:", "SSH Domains", "spawn"), pane)
			elseif id == "sshmux" then
				window:perform_action(show_domains("SSHMUX:", "SSH Mux Domains", "attach"), pane)
			end
		end),
	})
end

if platform.is_win then
	leader = { key = "|", mods = "ALT|SHIFT", timeout_milliseconds = 3000 }

	table.insert(keys, {
		key = "p",
		mods = "LEADER",
		action = show_domain_groups(),
	})
end

local config = {
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

if leader then
	config.leader = leader
end

return config
