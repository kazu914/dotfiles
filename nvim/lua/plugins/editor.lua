if vim.g.vscode then
  return {}
end

return {
  { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
  {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope-ui-select.nvim',
      'nvim-telescope/telescope-fzf-native.nvim'
    },
    config = function()
      vim.keymap.set('n', ',f', require('telescope.builtin').find_files)
      vim.keymap.set('n', ',g', require('telescope.builtin').git_files)
      vim.keymap.set('n', ',b', require('telescope.builtin').buffers)
      vim.keymap.set('n', ',r', require('telescope.builtin').live_grep)
      vim.keymap.set('n', '<leader>d', function() require('telescope.builtin').diagnostics { bufnr = 0 } end)
      vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action)

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
              ["<esc>"] = actions.close
            }
          }
        },
        extensions = {
          fzf = {
            fuzzy = true,                    -- false will only do exact matching
            override_generic_sorter = false, -- override the generic sorter
            override_file_sorter = true,     -- override the file sorter
            case_mode = "smart_case"         -- or "ignore_case" or "respect_case"
            -- the default case_mode is "smart_case"
          }
        }
      }

      require("telescope").load_extension("ui-select")
      require('telescope').load_extension('fzf')
    end
  },
  {
    'lewis6991/gitsigns.nvim',
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require('gitsigns').setup {
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- Navigation
          map('n', ']c', function()
            if vim.wo.diff then return ']c' end
            vim.schedule(function() gs.next_hunk() end)
            return '<Ignore>'
          end, { expr = true })

          map('n', '[c', function()
            if vim.wo.diff then return '[c' end
            vim.schedule(function() gs.prev_hunk() end)
            return '<Ignore>'
          end, { expr = true })

          -- Actions
          map({ 'n', 'v' }, '<leader>hs', ':Gitsigns stage_hunk<CR>')
          map({ 'n', 'v' }, '<leader>hr', ':Gitsigns reset_hunk<CR>')
          map('n', '<leader>hS', gs.stage_buffer)
          map('n', '<leader>hu', gs.undo_stage_hunk)
          map('n', '<leader>hR', gs.reset_buffer)
          map('n', '<leader>hp', gs.preview_hunk)
          map('n', '<leader>hb', function() gs.blame_line { full = true } end)
          map('n', '<leader>tb', gs.toggle_current_line_blame)
          map('n', '<leader>hd', gs.diffthis)
          map('n', '<leader>hD', function() gs.diffthis('~') end)
          map('n', '<leader>td', gs.toggle_deleted)

          -- Text object
          map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
        end
      }
    end
  },
  {
    'stevearc/oil.nvim',
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      vim.keymap.set('n', '<leader>f',
        function()
          require("oil").open(vim.fn.getcwd())
        end)
      require("oil").setup(
        {
          view_options = {
            show_hidden = true,
            is_always_hidden = function(name, _)
              return name == ".git"
            end,
          },
        }
      )
    end
  },
  {
    'mvllow/modes.nvim',
    event = 'InsertEnter',
    config = function()
      vim.opt.cursorline = true
      require('modes').setup({})
    end
  },
  {
    'jose-elias-alvarez/buftabline.nvim',
    config = true
  },
  {
    'mhinz/vim-sayonara',
    config = function()
      vim.keymap.set('n', '<leader>q', ':Sayonara<CR>', { noremap = true, silent = true })
    end
  },
  {
    'petertriho/nvim-scrollbar',
    dependencies = 'kevinhwang91/nvim-hlslens',
    config = function()
      require("scrollbar").setup({})
      require("scrollbar.handlers.search").setup()
    end
  },
  {
    'kevinhwang91/nvim-hlslens',
    config = function()
      local opts = { noremap = true, silent = true }
      vim.api.nvim_set_keymap('n', 'n',
        [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
        opts)
      vim.api.nvim_set_keymap('n', 'N',
        [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
        opts)
      vim.api.nvim_set_keymap('n', '*',
        [[*<Cmd>lua require('hlslens').start()<CR>]],
        opts)
      vim.api.nvim_set_keymap('n', '#',
        [[#<Cmd>lua require('hlslens').start()<CR>]],
        opts)
      vim.api.nvim_set_keymap('n', 'g*',
        [[g*<Cmd>lua require('hlslens').start()<CR>]],
        opts)
      vim.api.nvim_set_keymap('n', 'g#',
        [[g#<Cmd>lua require('hlslens').start()<CR>]],
        opts)
    end
  },
  {
    'rcarriga/nvim-notify',
    config = function()
      vim.notify = require("notify")
    end
  },
  {
    'nvim-lualine/lualine.nvim',
    dependencies = 'SmiteshP/nvim-navic',
    config = function()
      local navic = require("nvim-navic")
      local colors = {
        black = '#383a42',
        white = '#f3f3f3',
        blue = '#32b9ff',
        orange = '#ff7832',
        red = '#ca1243',
        green = '#8ec07c',
        yellow = '#ecff32',
        purple = '#c792ea',
      }
      local theme = {
        normal = {
          a = { fg = colors.black, bg = colors.blue },
          b = { fg = colors.black, bg = colors.orange },
          c = { fg = colors.white, bg = colors.black },
          x = { fg = colors.white, bg = colors.black },
          y = { fg = colors.white, bg = colors.red },
          z = { fg = colors.black, bg = colors.green },
        },
        insert = { z = { fg = colors.black, bg = colors.purple } },
        visual = { z = { fg = colors.black, bg = colors.yellow } },
        replace = { z = { fg = colors.black, bg = colors.green } },
      }
      local options = {
        theme = theme,
        component_separators = { left = ' ', right = ' ' },
        section_separators = { left = ' ', right = ' ' },
        globalstatus = true
      }
      local sections = {
        lualine_a = { { 'branch', colored = false } },
        lualine_b = { { 'diff', colored = false }, { 'diagnostics', colored = false, always_visible = true },
          { 'g:coc_status', colored = false, always_visible = true } },
        lualine_c = { { 'filename', path = 1 },
          { navic.get_location, cond = navic.is_available }
        },
        lualine_x = {},
        lualine_y = { 'filetype', 'encoding', 'fileformat' },
        lualine_z = { 'mode' }
      }
      local inactive_sections = {
        lualine_c = { { 'filename', path = 1 } }
      }

      require('lualine').setup { options = options, sections = sections, inactive_sections = inactive_sections }
    end
  },
  {
    'nvim-treesitter/nvim-treesitter',
    config = function()
      require('nvim-treesitter.configs').setup(
        {
          highlight = {
            enable = true
          }
        }
      )
    end
  },
  {
    "HampusHauffman/block.nvim",
    config = function()
      require("block").setup({})
    end
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash",
      },
    },
    config = function()
      require("flash").setup({
        modes = {
          search = {
            enabled = false
          }
        }
      })
    end
  },
  {
    'dinhhuy258/git.nvim',
    config = function()
      require('git').setup({
        default_mappings = false,
        keymaps = {
          -- Open blame window
          blame = "<Leader>gb",
        }
      })
    end
  },
  {
    'github/copilot.vim',
    config = function()
      vim.g.copilot_enabled = false
    end
  },
  {
    "nvim-zh/colorful-winsep.nvim",
    config = function()
      require('colorful-winsep').setup(
        {
          highlight = {
            fg = "#0E9CEF"
          }
        }
      )
    end,
    event = { "WinNew" },
  },
  {
    'stevearc/conform.nvim',
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          python = { "isort", "black" },
          json = { "jq" },
          markdown = { "mdformat" },
          toml = { "taplo" },
          ["*"] = { "trim_whitespace" }
        }

      })
    end
  },
  {
    "danymat/neogen",
    dependencies = "nvim-treesitter/nvim-treesitter",
    config = function()
      require("neogen").setup({})
      local opts = { noremap = true, silent = true }
      vim.api.nvim_set_keymap("n", "<Leader>ng", ":lua require('neogen').generate()<CR>", opts)
    end
  },
  {
    "shellRaining/hlchunk.nvim",
    event = { "UIEnter" },
    config = function()
      require("hlchunk").setup({
        chunk = {
          chars = {
            horizontal_line = "━",
            vertical_line = "┃",
            left_top = "┏",
            left_bottom = "┗",
            right_arrow = "▶",
          },
          style = {
            { fg = "#32b9ff", bold = true },
            { fg = "#c21f30" }, -- this fg is used to highlight wrong chunk
          },
        },
        line_num = {
          style = "#32b9ff",
        },
      })
    end
  },
}
