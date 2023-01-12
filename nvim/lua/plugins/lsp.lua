return {
  'neovim/nvim-lspconfig',
  'glepnir/lspsaga.nvim',
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
    config = function ()
      require('nvim-navic').setup { separator = " > " }
    end
  },
  {
    'ray-x/lsp_signature.nvim',
    config = function ()
      require('lsp_signature').setup {
        floating_window = true,
        use_lspsaga = false,
        hint_prefix = "🐰 ",
        transpancy = nil,
        zindex = 49,
        handler_opts = {
          border = "rounded"
        }
      }
    end
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
