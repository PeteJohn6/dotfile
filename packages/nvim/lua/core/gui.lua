if vim.g.neovide then
	-- Put anything you want to happen only in Neovide here
	vim.g.neovide_theme = "dark"
	vim.g.neovide_remember_window_size = false

	vim.api.nvim_set_keymap("n", "<F11>", ":lua ToggleFullscreen()<CR>", { noremap = true, silent = true })

	-- switch of Fullscreen mode
	function ToggleFullscreen()
		vim.g.neovide_fullscreen = not vim.g.neovide_fullscreen
		if vim.g.neovide_fullscreen then
			print("Fullscreen enabled")
		else
			print("Fullscreen disabled")
		end
	end

	vim.g.neovide_profiler = false
	vim.g.neovide_refresh_rate = 60

	vim.g.neovide_cursor_vfx_mode = ""
	vim.g.neovide_position_animation_length = 0

	vim.g.neovide_floating_shadow = true
	vim.g.neovide_floating_z_height = 10

	vim.g.neovide_light_angle_degrees = 45
	vim.g.neovide_light_radius = 5

	vim.g.neovide_transparency = 0.8

	vim.g.neovide_remember_window_size = true

	vim.g.neovide_fullscreen = true
end

-- vim.o.guifont = "Source Code Pro:h14:W200" -- text below applies for VimScript
vim.opt.guifont = "SauceCodePro_Nerd_Font:h14:W200" -- text below applies for VimScript
