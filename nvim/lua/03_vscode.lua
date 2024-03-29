vim.keymap.set("n", "<Space>w", "<Cmd>call VSCodeNotify('workbench.action.files.save')<CR>")
vim.keymap.set("n", "<Space>q", "<Cmd>call VSCodeNotify('workbench.action.closeActiveEditor')<CR>")

-- カーソル下の単語ハイライト
vim.keymap.set('n', '<Space><Space>', '"zyiw:let @/ = @z <CR>:set hlsearch<CR>')


vim.keymap.set('i', '<C-j>', 'col(".") == col("$") ? \'<C-j>\' : \'<ESC>A\'',
    { noremap = true, silent = true, expr = true })

-- コピペのときに自動で対象の末尾に移動
vim.keymap.set('v', 'y', 'y`]')
vim.keymap.set({ 'n', 'v' }, 'p', 'p`]')

-- open referenceSearch
vim.keymap.set('n', "gh", "<Cmd>call VSCodeNotify('editor.action.referenceSearch.trigger')<CR>")

-- format
vim.keymap.set("n", "<Space>F", "<Cmd>call VSCodeNotify('editor.action.format')<CR>")

vim.keymap.set("n", "k",
    ":<C-u>call rpcrequest(g:vscode_channel, 'vscode-command', 'cursorMove', { 'to': 'up', 'by': 'wrappedLine', 'value': v:count ? v:count : 1 })<CR>")

vim.keymap.set("n", "j",
    ":<C-u>call rpcrequest(g:vscode_channel, 'vscode-command', 'cursorMove', { 'to': 'down', 'by': 'wrappedLine', 'value': v:count ? v:count : 1 })<CR>")

vim.keymap.set("n", "<Space>f", "<Cmd>call VSCodeNotify('workbench.action.toggleSidebarVisibility')<CR>")

vim.keymap.set("n", "[g", "<Cmd>call VSCodeNotify('editor.action.marker.prev')<CR>")

vim.keymap.set("n", "]g", "<Cmd>call VSCodeNotify('editor.action.marker.next')<CR>")


vim.keymap.set("n", "[c", "<Cmd>call VSCodeNotify('workbench.action.editor.previousChange')<CR>")

vim.keymap.set("n", "]c", "<Cmd>call VSCodeNotify('workbench.action.editor.nextChange')<CR>")

vim.keymap.set("n", "<Space>ca", "<Cmd>call VSCodeNotify('editor.action.quickFix')<CR>")

vim.keymap.set("n", "<Space>rn", "<Cmd>call VSCodeNotify('editor.action.rename')<CR>")
