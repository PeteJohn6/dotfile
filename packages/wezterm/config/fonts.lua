local wezterm = require("wezterm")
local platform = require("utils.platform")

local font_size = 13
local font_list = {
	{
		family = "SauceCodePro Nerd Font",
		weight = "Light",
	},
	{
		-- family = "Source Han Sans SC",
		family = "LXGW WenKai Mono",
		weight = "Light",
		freetype_load_target = "Normal",
		freetype_render_target = "HorizontalLcd",
	},
}

if platform.is_mac then
	font_size = 18
	font_list[#font_list + 1] = {
		family = "PingFang SC",
		weight = "Light",
	}
elseif platform.is_windows then
	font_list[#font_list + 1] = {
		family = "Microsoft YaHei UI",
		weight = "Light",
	}
else
	font_list[#font_list + 1] = {
		family = "Noto Sans CJK SC",
		weight = "Light",
	}
end

return {
	font = wezterm.font_with_fallback(font_list),
	font_size = font_size,
	use_cap_height_to_scale_fallback_fonts = true,
}
