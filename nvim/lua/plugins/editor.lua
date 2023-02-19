return {
  {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope-ui-select.nvim'
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
            fuzzy = true, -- false will only do exact matching
            override_generic_sorter = false, -- override the generic sorter
            override_file_sorter = true, -- override the file sorter
            case_mode = "smart_case" -- or "ignore_case" or "respect_case"
            -- the default case_mode is "smart_case"
          }
        }
      }

      require("telescope").load_extension("ui-select")
    end
  },
  {
    'lewis6991/gitsigns.nvim',
    dependencies = {
      'kyazdani42/nvim-web-devicons'
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
    'tamago324/lir.nvim',
    config = function()
      local actions = require 'lir.actions'
      local mark_actions = require 'lir.mark.actions'
      local clipboard_actions = require 'lir.clipboard.actions'
      local lir = require('lir')

      vim.keymap.set('n', '<leader>f',
        function() require('lir.float').init(vim.fn.getcwd()) end)
      lir.setup {
        show_hidden_files = false,
        devicons = { enable = true },
        mappings = {
          ['l'] = actions.edit,
          ['<CR>'] = actions.edit,
          ['<C-s>'] = actions.split,
          ['<C-v>'] = actions.vsplit,
          ['<C-t>'] = actions.tabedit,

          ['h'] = actions.up,
          ['q'] = actions.quit,

          ['K'] = actions.mkdir,
          ['N'] = actions.newfile,
          ['R'] = actions.rename,
          ['@'] = actions.cd,
          ['Y'] = actions.yank_path,
          ['.'] = actions.toggle_show_hidden,
          ['D'] = actions.delete,

          ['i'] = function()
            mark_actions.toggle_mark()
            vim.cmd('normal! j')
          end,
          ['c'] = clipboard_actions.copy,
          ['x'] = clipboard_actions.cut,
          ['p'] = clipboard_actions.paste
        },
        float = {
          winblend = 0,
          curdir_window = { enable = false, highlight_dirname = false }
        },
        hide_cursor = false
      }
      -- custom folder icon
      require 'nvim-web-devicons'.set_icon({
        lir_folder_icon = { icon = "", color = "#7ebae4", name = "LirFolderNode" }
      })

    end
  },
  {
    'mvllow/modes.nvim',
    event = 'InsertEnter',
    config = function()
      vim.opt.cursorline = true
      require('modes').setup()
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
    'yuki-yano/fuzzy-motion.vim',
    dependencies = {
      'vim-denops/denops.vim'
    },
    config = function()
      vim.keymap.set('n', '<leader>s', ':FuzzyMotion<CR>', {})
    end
  },
  {
    'phaazon/hop.nvim',
    config = function()
      vim.keymap.set('n', "<Leader>l", ':HopWord<CR>', {})
      vim.keymap.set('n', "<Leader>j", ':HopLine<CR>', {})
      require 'hop'.setup()
    end
  },
  {
    'airblade/vim-rooter', config = function()
      vim.cmd([[
      let g:rooter_change_directory_for_non_project_files = 'current'
      let g:rooter_patterns = ['.git', '_darcs', '.hg', '.bzr', '.svn', 'package.json']
      let g:rooter_silent_chdir = 1
      ]])
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
    'neoclide/coc.nvim',
    ft = 'java',
    dependencies = {
      'fannheyward/telescope-coc.nvim'
    },
    config = function()
      vim.api.nvim_create_augroup('java_coc', {})
      vim.api.nvim_create_autocmd('FileType java', { group = 'java_coc', callback = function()
        require('plugins_config/coc_settings').setup()
      end })
    end
  }
}
