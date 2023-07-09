return {
    {
        'phaazon/hop.nvim',
        config = function()
            vim.keymap.set('n', "<Leader>l", ':HopWord<CR>', {})
            vim.keymap.set('n', "<Leader>j", ':HopLine<CR>', {})
            require 'hop'.setup()
        end
    },
}
