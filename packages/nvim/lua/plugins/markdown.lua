local renderMD = {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = { "markdown", "codecompanion", "Avante" },
	opts = {
		code = {
			-- A list of language names for which background highlighting will be disabled.
			-- Likely because that language has background highlights itself.
			-- Use a boolean to make behavior apply to all languages.
			-- Borders above & below blocks will continue to be rendered.
			disable_background = true,

			border = "thin",
			-- Used above code blocks for thin border.
			above = "-",
			-- Used below code blocks for thin border.
			below = "-",
		},
	},
}

return { renderMD }
