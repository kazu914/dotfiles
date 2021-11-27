"dein Scripts-----------------------------
if &compatible
  set nocompatible               " Be iMproved
endif
set runtimepath+=~/.config/nvim/dein/repos/github.com/Shougo/dein.vim
if dein#load_state('~/.config/nvim/dein')
  call dein#begin('~/.config/nvim/dein')

  call dein#load_toml('~/.config/nvim/plugins/dein.toml', {'lazy': 0})
  call dein#load_toml('~/.config/nvim/plugins/nvim-cmp.toml', {'lazy': 0})
  call dein#load_toml('~/.config/nvim/plugins/lazy_dein.toml', {'lazy': 1})

  call dein#end()
  call dein#save_state()
endif
filetype plugin indent on
syntax enable

" If you want to install not installed plugins on startup.
if dein#check_install()
  call dein#install()
endif
"End dein Scripts-------------------------
"
source ~/.config/nvim/plugins/lsp_setting.lua
