local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
require '00_settings'
require("lazy").setup("plugins")

if not vim.g.vscode then
  require '01_mappings'
  require '02_lsp_setting'
else
  require '03_vscode'
end
