return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
        term_colors = false,
        custom_highlights = {
          Comment = { fg = "#E80F88" },
        },
        auto_integrations = true,
      })
      vim.cmd.colorscheme "catppuccin"
    end
  },
}
