local wezterm = require("wezterm")
local colors = require("colors.custom")
local platform = require("utils.platform")

local GLOB_PATTERN = "*.{jpg,jpeg,png,gif,bmp,ico,tiff,pnm,dds,tga}"

local MODE_ORIGIN = 0
local MODE_ACRYLIC = 1
local MODE_FOCUS = 2
local MODE_BACKDROP = 3
local DEFAULT_MODE = MODE_ORIGIN

local modes = {
	[MODE_ORIGIN] = {
		background = "origin_image",
		blur_backdrop = false,
	},
	[MODE_ACRYLIC] = {
		background = "acrylic_image",
		blur_backdrop = false,
	},
	[MODE_FOCUS] = {
		background = "focus",
		blur_backdrop = false,
	},
	[MODE_BACKDROP] = {
		background = nil,
		blur_backdrop = true,
	},
}

local Backdrops = {}
Backdrops.__index = Backdrops

local function normalize_dir(path)
	if path:match("[/\\]$") then
		return path
	end
	return path .. "/"
end

local function basename(path)
	return path:match("([^/\\]+)$") or path
end

local function focus_background()
	return {
		{
			source = { Color = colors.background },
			height = "120%",
			width = "120%",
			vertical_offset = "-10%",
			horizontal_offset = "-10%",
			opacity = 1,
		},
	}
end

local function origin_image_background(backdrops)
	local images = backdrops:_activate_images_for_mode(MODE_ORIGIN)
	if #images == 0 then
		return focus_background()
	end

	return {
		{
			source = { File = images[backdrops.current_idx] },
			horizontal_align = "Center",
		},
		{
			source = { Color = colors.background },
			height = "120%",
			width = "120%",
			vertical_offset = "-10%",
			horizontal_offset = "-10%",
			opacity = 0.85,
		},
	}
end

local function acrylic_image_background(backdrops)
	local images = backdrops:_activate_images_for_mode(MODE_ACRYLIC)
	if #images == 0 then
		return focus_background()
	end

	return {
		{
			source = { File = images[backdrops.current_idx] },
			horizontal_align = "Center",
		},
	}
end

local background_by_name = {
	origin_image = origin_image_background,
	acrylic_image = acrylic_image_background,
	focus = focus_background,
}

local function background_config(name, backdrops)
	local get_background = background_by_name[name] or focus_background
	return get_background(backdrops)
end

local blur_backdrop_enabled_by_platform = {
	windows = {
		win32_acrylic_accent_color = colors.background,
		window_background_opacity = 0.8,
		win32_system_backdrop = "Acrylic",
	},
	mac = {
		window_background_opacity = 0.3,
		macos_window_background_blur = 20,
	},
	linux = {
		window_background_opacity = 0.4,
		kde_window_background_blur = true,
	},
}

local function blur_backdrop_config()
	return blur_backdrop_enabled_by_platform[platform.os] or {}
end

function Backdrops:init()
	return setmetatable({
		current_idx = 1,
		images = {},
		origin_images = {},
		acrylic_images = {},
		images_dir = wezterm.config_dir .. "/backdrops/",
		mode = DEFAULT_MODE,
	}, self)
end

function Backdrops:set_images_dir(path)
	self.images_dir = normalize_dir(path)
	return self
end

function Backdrops:set_images()
	local all_files = wezterm.glob(self.images_dir .. GLOB_PATTERN)
	table.sort(all_files)

	self.images = {}
	self.origin_images = {}
	self.acrylic_images = {}

	for _, file in ipairs(all_files) do
		if string.find(file, "%.acrylic[%.%-_]") then
			table.insert(self.acrylic_images, file)
		else
			table.insert(self.origin_images, file)
		end
	end

	self:_activate_images_for_mode(self.mode)
	return self
end

function Backdrops:_mode()
	return modes[self.mode] or modes[MODE_FOCUS]
end

function Backdrops:_images_for_mode(mode)
	if mode == MODE_ORIGIN then
		return self.origin_images
	end

	if mode == MODE_ACRYLIC then
		if #self.acrylic_images > 0 then
			return self.acrylic_images
		end
		return self.origin_images
	end

	return self.images
end

function Backdrops:_activate_images_for_mode(mode)
	local images = self:_images_for_mode(mode)

	if #images > 0 then
		self.images = images
		if self.current_idx > #self.images or self.current_idx < 1 then
			self.current_idx = 1
		end
	end

	return self.images
end

function Backdrops:_create_overrides()
	local mode = self:_mode()
	---@type table<string, any>
	local overrides = {}

	if mode.background ~= nil then
		overrides.background = background_config(mode.background, self)
	else
		overrides.background = {}
	end

	if mode.blur_backdrop then
		for key, value in pairs(blur_backdrop_config()) do
			overrides[key] = value
		end
	end

	return overrides
end

function Backdrops:_set_opt(window)
	window:set_config_overrides(self:_create_overrides())
end

function Backdrops:initial_background()
	local mode = self:_mode()
	if mode.background ~= nil then
		return background_config(mode.background, self)
	end

	return {}
end

function Backdrops:set_image_list()
	local choices = {}
	for idx, file in ipairs(self.images) do
		table.insert(choices, {
			id = tostring(idx),
			label = basename(file),
		})
	end
	return choices
end

function Backdrops:toggle_image(window)
	if #self.images == 0 then
		return
	end

	if self.current_idx == #self.images then
		self:set_image(window, 1)
	else
		self:set_image(window, self.current_idx + 1)
	end
end

function Backdrops:set_image(window, idx)
	idx = tonumber(idx)

	if idx == nil or idx > #self.images or idx < 1 then
		wezterm.log_error("Backdrop index out of range")
		return
	end

	self.current_idx = idx
	self:_set_opt(window)
end

function Backdrops:toggle_backdrop_mode(window)
	if self.mode == MODE_BACKDROP then
		self.mode = MODE_ORIGIN
	else
		self.mode = self.mode + 1
	end

	self:_set_opt(window)
end

return Backdrops:init()
