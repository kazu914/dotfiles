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
