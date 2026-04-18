local wezterm = require("wezterm")

package.path = table.concat({
  wezterm.config_dir .. "/?.lua",
  wezterm.config_dir .. "/?/init.lua",
  package.path,
}, ";")

local backdrops = require("utils.backdrops")
backdrops:set_images()

local appearance = require("config.appearance")
local bindings = require("config.bindings")
local fonts = require("config.fonts")
local general = require("config.general")

local config = wezterm.config_builder()
local modules = {
  appearance,
  bindings,
  fonts,
  general,
}

for _, module in ipairs(modules) do
  for key, value in pairs(module) do
    config[key] = value
  end
end

return config
