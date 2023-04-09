vim.g.mapleader = ' '
vim.keymap.set("n", "<leader>w", "<Cmd>call VSCodeNotify('workbench.action.files.save')<CR>")
vim.keymap.set("n", "<leader>q", "<Cmd>call VSCodeNotify('workbench.action.closeActiveEditor')<CR>")
