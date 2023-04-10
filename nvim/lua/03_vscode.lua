vim.g.mapleader = ' '
vim.keymap.set("n", "<leader>w", "<Cmd>call VSCodeNotify('workbench.action.files.save')<CR>")
vim.keymap.set("n", "<leader>q", "<Cmd>call VSCodeNotify('workbench.action.closeActiveEditor')<CR>")

-- カーソル下の単語ハイライト
vim.keymap.set('n', '<Space><Space>', '"zyiw:let @/ = @z <CR>:set hlsearch<CR>')

-- open referenceSearch
vim.keymap.set('n',"gh","<Cmd>call VSCodeNotify('editor.action.referenceSearch.trigger')<CR>")
