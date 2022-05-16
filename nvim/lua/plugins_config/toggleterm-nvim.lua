require("toggleterm").setup {
  size = vim.o.columns * 0.4,
  direction = 'vertical',
  start_in_insert = false,
}
vim.keymap.set('n', '<C-o>', ':ToggleTerm<CR>', { noremap = true })
vim.keymap.set('n', '<C-o>', ':ToggleTerm<CR>', { noremap = true })
