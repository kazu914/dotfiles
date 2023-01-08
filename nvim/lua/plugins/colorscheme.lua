return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    build = ":CatppuccinCompile",
    config = function()
      require("catppuccin").setup({
        term_colors = false,
        custom_highlights = {
          Comment = { fg = "#E80F88" },
        },
        integrations = {
          fidget = true,
          cmp = true,
          fern = true,
          gitsigns = true,
          hop = true,
          lsp_saga = true,
          notify = true,
          treesitter = true,
          treesitter_context = true,
          telescope = true,
          native_lsp = {
            enabled = true,
            virtual_text = {
              errors = { "italic" },
              hints = { "italic" },
              warnings = { "italic" },
              information = { "italic" },
            },
            underlines = {
              errors = { "underline" },
              hints = { "underline" },
              warnings = { "underline" },
              information = { "underline" },
            },
          },
          navic = {
            enabled = true,
            custom_bg = "NONE",
          },

        }
      })
      vim.g.catppuccin_flavour = "macchiato" -- latte, frappe, macchiato, mocha
      vim.api.nvim_command "colorscheme catppuccin"
    end
  },
}
