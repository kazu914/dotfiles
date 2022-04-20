require 'packer'.startup(function(use)
  -- packer itself
  use { 'wbthomason/packer.nvim' }

  -- colorscheme
  use { 'folke/tokyonight.nvim', config = 'vim.cmd[[colorscheme tokyonight]]' }

  use { 'tpope/vim-surround' }

  use { 'tpope/vim-commentary' }

  use { 'jiangmiao/auto-pairs' }

  use { 'thinca/vim-quickrun' }

  use { 'simeji/winresizer' }

  use { 'mbbill/undotree', config = function()
    vim.g.undotree_WindowLayout = 2
    vim.g.undotree_ShortIndicators = 1
    vim.g.undotree_SplitWidth = 30
    vim.g.undotree_SetFocusWhenToggle = 1
    vim.keymap.set('n', '<leader>u', ':UndotreeToggle<CR>', { noremap = true })
  end }

  use { 'machakann/vim-highlightedyank', event = 'TextYankPost', config = function()
    vim.g.highlightedyank_highlight_duration = -1
  end }

  use { "lukas-reineke/indent-blankline.nvim", config = function()
    require("indent_blankline").setup {
      space_char_blankline = " ",
      show_current_context = true,
      show_current_context_start = true,
    }
  end }

  use { 'jose-elias-alvarez/buftabline.nvim',
    config = function() require("buftabline").setup {} end
  }

  use { 'mhinz/vim-sayonara',
    config = function()
      vim.keymap.set('n', '<leader>q', ':Sayonara<CR>')
    end
  }

  use { 'yuki-yano/fuzzy-motion.vim', config = function()
    vim.keymap.set('n', '<leader>s', ':FuzzyMotion<CR>')
  end }

  use { 'luochen1990/rainbow', config = function()
    vim.g.rainbow_active = 1
  end }

  use { 'ntpeters/vim-better-whitespace' }

  use { 'phaazon/hop.nvim', config = function()
    vim.keymap.set('n', "<Leader>l", ':HopWord<CR>')
    vim.keymap.set('n', "<Leader>j", ':HopLine<CR>')
    require 'hop'.setup()
  end }

  use { 'mvllow/modes.nvim', config = function()
    vim.opt.cursorline = true
    require('modes').setup()
  end }

  use { 'j-hui/fidget.nvim', config = function()
    require('fidget').setup {}
  end }

  -- treesitter
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate', config = function()
    require 'nvim-treesitter.configs'.setup({
      highlight = {
        enable = true,
      },
      indent = {
        enable = true,
      }
    })
  end }

  use { 'romgrk/nvim-treesitter-context' }

  use { 'petertriho/nvim-scrollbar',
    config = function()
      local colors = require("tokyonight.colors").setup()
      require("scrollbar").setup({
        handle = { color = colors.bg_highlight },
        marks = {
          Search = { color = colors.orange },
          Error = { color = colors.error },
          Warn = { color = colors.warning },
          Info = { color = colors.info },
          Hint = { color = colors.hint },
          Misc = { color = colors.purple }
        }
      })
      require("scrollbar.handlers.search").setup()
    end
  }

  use { 'rcarriga/nvim-notify',
    config = function() vim.notify = require('notify') end
  }

  use { 'kevinhwang91/nvim-hlslens',
    config = function()
      local kopts = { noremap = true, silent = true }
      vim.api.nvim_set_keymap('n', 'n',
        [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
        kopts)
      vim.api.nvim_set_keymap('n', 'N',
        [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
        kopts)
      vim.api.nvim_set_keymap('n', '*',
        [[*<Cmd>lua require('hlslens').start()<CR>]],
        kopts)
      vim.api.nvim_set_keymap('n', '#',
        [[#<Cmd>lua require('hlslens').start()<CR>]],
        kopts)
      vim.api.nvim_set_keymap('n', 'g*',
        [[g*<Cmd>lua require('hlslens').start()<CR>]],
        kopts)
      vim.api.nvim_set_keymap('n', 'g#',
        [[g#<Cmd>lua require('hlslens').start()<CR>]],
        kopts)
      vim.api.nvim_set_keymap('n', '<Leader>l', ':noh<CR>', kopts)
    end
  }

  use { 'vim-denops/denops.vim' }

  use { 'nvim-lua/plenary.nvim' }

  use { 'neovim/nvim-lspconfig' }

  use { 'folke/lsp-colors.nvim' }

  use { 'williamboman/nvim-lsp-installer' }

  use { 'onsails/lspkind-nvim' }

  use { 'jose-elias-alvarez/null-ls.nvim' }

  use { 'tami5/lspsaga.nvim' }

  use { 'hrsh7th/cmp-nvim-lsp' }

  use { 'hrsh7th/vim-vsnip' }

  use { 'hrsh7th/vim-vsnip-integ' }

  use { 'hrsh7th/cmp-buffer' }

  use { 'hrsh7th/cmp-cmdline' }

  use { 'hrsh7th/cmp-path' }

  use { 'hrsh7th/cmp-vsnip' }

  use { 'hrsh7th/nvim-cmp',
    config = function()
      vim.api.nvim_command('set completeopt=menu,menuone,noselect')
      -- Setup nvim-cmp.
      local cmp = require 'cmp'
      local mapping = {
        ['<Tab>'] = cmp.mapping.select_next_item({
          behavior = cmp.SelectBehavior.Insert
        }),
        ['<S-Tab>'] = cmp.mapping.select_prev_item({
          behavior = cmp.SelectBehavior.Insert
        }),
        ['<Down>'] = cmp.mapping.select_next_item({
          behavior = cmp.SelectBehavior.Select
        }),
        ['<Up>'] = cmp.mapping.select_prev_item({
          behavior = cmp.SelectBehavior.Select
        }),
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.close(),
        ['<CR>'] = cmp.mapping.confirm({
          behavior = cmp.ConfirmBehavior.Replace,
          select = true
        })
      }
      cmp.setup({
        snippet = {
          expand = function(args)
            vim.fn["vsnip#anonymous"](args.body)
          end
        },
        mapping = mapping,
        sources = cmp.config.sources({
          { name = 'vsnip' }, { name = 'buffer' }, { name = 'nvim_lsp' },
          { name = 'path' }
        })
      })
      -- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline('/', { sources = { { name = 'buffer' } } })
      -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline(':', {
        sources = cmp.config
            .sources({ { name = 'path' } }, { { name = 'cmdline' } })
      })
      local lspkind = require('lspkind')
      cmp.setup {
        formatting = {
          format = lspkind.cmp_format({
            with_text = true,
            maxwidth = 50
          })
        }
      }

    end
  }

  use { 'ray-x/lsp_signature.nvim', config = function()
    require "lsp_signature".setup({
      floating_window = true,
      use_lspsaga = false,
      hint_prefix = "🐰 ",
      transpancy = nil,
      zindex = 49,
      handler_opts = {
        border = "rounded"
      }
    })
  end }

  use { 'nvim-telescope/telescope.nvim',
    requires = { { 'nvim-lua/plenary.nvim' } },
    config = function()

      vim.keymap.set('n', ',f', require('telescope.builtin').find_files)
      vim.keymap.set('n', ',g', require('telescope.builtin').git_files)
      vim.keymap.set('n', ',b', require('telescope.builtin').buffers)
      vim.keymap.set('n', ',r', require('telescope.builtin').live_grep)
      vim.keymap.set('n', '<leader>ca',
        require('telescope.builtin').lsp_code_actions)
      vim.keymap.set('n', '<leader>tr',
        require('telescope.builtin').diagnostics)

      local actions = require "telescope.actions"
      require('telescope').setup {
        defaults = {
          sorting_strategy = "ascending",
          selection_caret = "> ",
          layout_config = { prompt_position = "top" },
          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<Tab>"] = actions.move_selection_next,
              ["<S-Tab>"] = actions.move_selection_previous,
              ["<esc>"] = actions.close,
            }
          }
        },
        extensions = {
          fzf = {
            fuzzy = true, -- false will only do exact matching
            override_generic_sorter = false, -- override the generic sorter
            override_file_sorter = true, -- override the file sorter
            case_mode = "smart_case" -- or "ignore_case" or "respect_case"
            -- the default case_mode is "smart_case"
          }
        }
      }
    end
  }

  use { 'nvim-lualine/lualine.nvim',
    config = function()
      local options = { theme = 'codedark' }
      require('lualine').setup { options = options }
    end
  }

  use { "lewis6991/gitsigns.nvim", config = function()
    require('gitsigns').setup()
  end }

  use { 'kyazdani42/nvim-web-devicons' }

  use { 'ryanoasis/vim-devicons' }

  use { 'Shougo/vimproc.vim', run = 'make' }

  -- For Language
  use { 'posva/vim-vue', ft = { 'vue' } }

  use { 'mattn/emmet-vim', ft = { 'vue' } }

  use { "jose-elias-alvarez/nvim-lsp-ts-utils" }

  use { 'airblade/vim-rooter', config = function ()
    vim.g.rooter_change_directory_for_non_project_files = 'current'
  end }
end)
