vim.g.mapleader = ' '
vim.keymap.set("n", "<leader>w", "<Cmd>call VSCodeNotify('workbench.action.files.save')<CR>")
vim.keymap.set("n", "<leader>q", "<Cmd>call VSCodeNotify('workbench.action.closeActiveEditor')<CR>")

-- カーソル下の単語ハイライト
vim.keymap.set('n', '<Space><Space>', '"zyiw:let @/ = @z <CR>:set hlsearch<CR>')

-- open referenceSearch
vim.keymap.set('n', "gh", "<Cmd>call VSCodeNotify('editor.action.referenceSearch.trigger')<CR>")

-- format
vim.keymap.set("n", "<Space>F", "<Cmd>call VSCodeNotify('editor.action.format')<CR>")

vim.keymap.set("n", "k",
    ":<C-u>call rpcrequest(g:vscode_channel, 'vscode-command', 'cursorMove', { 'to': 'up', 'by': 'wrappedLine', 'value': v:count ? v:count : 1 })<CR>")

vim.keymap.set("n", "j",
    ":<C-u>call rpcrequest(g:vscode_channel, 'vscode-command', 'cursorMove', { 'to': 'down', 'by': 'wrappedLine', 'value': v:count ? v:count : 1 })<CR>")
