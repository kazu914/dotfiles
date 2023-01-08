return {
  {
    'folke/neodev.nvim',
    ft = 'lua',
    config = true
  },
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
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    config = function()
      vim.api.nvim_create_augroup('jdtls_lsp', {})
      vim.api.nvim_create_autocmd('FileType java', { group = 'jdtls_lsp', callback = function()
        require('plugins_config/nvim-jdtls').setup()
      end })
    end
  }
}
