return {
  'neovim/nvim-lspconfig',
  'glepnir/lspsaga.nvim',
  'jose-elias-alvarez/null-ls.nvim',
  {
    "williamboman/mason.nvim",
    config = true
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = true
  },
  {
    "SmiteshP/nvim-navic",
    dependencies = "neovim/nvim-lspconfig",
    config = { highlight = true, separator = "  " }
  },
  {
    'ray-x/lsp_signature.nvim',
    config = {
      floating_window = true,
      use_lspsaga = false,
      hint_prefix = "🐰 ",
      transpancy = nil,
      zindex = 49,
      handler_opts = {
        border = "rounded"
      }
    }
  },
  {
    'j-hui/fidget.nvim', config = function()
      require('fidget').setup {
        window = {
          blend = 0,
        },
      }
    end
  },
  {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    config = function()
      require 'nvim-treesitter.configs'.setup({
        highlight = {
          enable = true,
        },
        indent = {
          enable = true,
        }
      })
    end
  }
}
