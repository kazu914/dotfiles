return {
  'neovim/nvim-lspconfig',
  {
    'glepnir/lspsaga.nvim',
    event = 'BufRead',
    config = function()
      require('lspsaga').setup({
        finder = {
          edit = "<CR>",
          vsplit = "s",
          split = "i",
          tabe = "t",
          quit = {"q", '<ESC>'},
        },
        ui = {
          border = 'rounded'
        }
      })
    end
  },
  {
    "williamboman/mason.nvim",
    config = true
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = true
  },
  {
    'ray-x/lsp_signature.nvim',
    config = function()
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
