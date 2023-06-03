if vim.g.vscode then
  return {}
end
return {
  {
    'akinsho/flutter-tools.nvim',
    ft = 'dart',
    dependencies = 'nvim-lua/plenary.nvim',
    config = true
  },
  {
    'posva/vim-vue',
    ft = 'vue'
  },
  {
    'mattn/emmet-vim',
    ft = 'vue'
  },
}
