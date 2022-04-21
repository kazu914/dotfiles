vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost 02_plugins.lua
    \ execute 'lua vim.notify("Compiling...")' |
    \ source <afile> |
    \ PackerCompile
  augroup end
]])
require'00_settings'
require'01_mappings'
require'02_plugins'
require'03_lsp_setting'
