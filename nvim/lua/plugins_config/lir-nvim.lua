local actions = require 'lir.actions'
local mark_actions = require 'lir.mark.actions'
local clipboard_actions = require 'lir.clipboard.actions'
local lir = require('lir')

vim.keymap.set('n', '<leader>f',
               function() require('lir.float').init(vim.fn.getcwd()) end)
lir.setup {
    show_hidden_files = false,
    devicons_enable = true,
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
        curdir_window = {enable = false, highlight_dirname = false}
    },
    hide_cursor = false
}

-- custom folder icon
require'nvim-web-devicons'.set_icon({
    lir_folder_icon = {icon = "", color = "#7ebae4", name = "LirFolderNode"}
})
