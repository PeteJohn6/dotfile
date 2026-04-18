local backdrops = require("utils.backdrops")
local colors = require("colors.custom")

return {
	colors = colors,
	background = backdrops:initial_background(),
	underline_thickness = "1.5pt",
	animation_fps = 120,
	cell_width = 1.0,
	default_cursor_style = "BlinkingBlock",
	cursor_blink_ease_in = "EaseOut",
	cursor_blink_ease_out = "EaseOut",
	cursor_blink_rate = 650,
	enable_scroll_bar = false,
	enable_tab_bar = false,
	hide_tab_bar_if_only_one_tab = true,
	use_fancy_tab_bar = false,
	window_padding = {
		left = 0,
		right = 0,
		top = 0,
		bottom = 0,
	},
	adjust_window_size_when_changing_font_size = false,
	window_background_opacity = 1.0,
	window_close_confirmation = "NeverPrompt",
	inactive_pane_hsb = {
		saturation = 0.5,
		brightness = 0.5,
	},
	visual_bell = {
		fade_in_function = "EaseIn",
		fade_in_duration_ms = 250,
		fade_out_function = "EaseOut",
		fade_out_duration_ms = 250,
		target = "CursorColor",
	},
}
