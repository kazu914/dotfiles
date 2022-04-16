vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerCompile
  augroup end
]])
require'00_settings'
require'01_mappings'
require'02_plugins'
require'03_lsp_setting'
