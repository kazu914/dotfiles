require("toggleterm").setup {
  size = vim.o.columns * 0.4,
  direction = 'vertical',
  start_in_insert = true,
}

function _G.set_terminal_keymaps()
  local opts = {noremap = true}
  vim.api.nvim_buf_set_keymap(0, 't', '<C-h>', [[<C-\><C-n><C-W>h]], opts)
end

vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')
vim.keymap.set('n', '<C-o>', ':ToggleTerm<CR>', { noremap = true })
vim.keymap.set('n', '<C-o>', ':ToggleTerm<CR>', { noremap = true })

-- for lazygit
local Terminal  = require('toggleterm.terminal').Terminal
local lazygit = Terminal:new({
  cmd = "lazygit",
  hidden = true,
  direction = "float",
  on_open = function(term)
    vim.cmd("startinsert!")
    vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
  end,
})

function LazygitToggle()
  lazygit:toggle()
end

vim.api.nvim_set_keymap("n", "<leader>g", "<cmd>lua LazygitToggle()<CR>", {noremap = true, silent = true})
