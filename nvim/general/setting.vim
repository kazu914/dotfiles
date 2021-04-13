syntax on
set t_Co=256

set autoindent                    " 改行時に自動でインデント
set smartindent
set expandtab                     " タブ入力を空白に置換
set tabstop=2                     " タブを何文字分の空白にするか
set shiftwidth=2                  " 自動インデント時に入力する空白の数
set cursorline                    " カーソルラインの表示
set number                        " 行番号の表示
set showtabline=2
set showmatch
set title
set backspace=indent,eol,start
set inccommand=split
set imdisable
set hidden
set nobackup
set nowritebackup
set termguicolors
set ignorecase
set smartcase
set conceallevel=0
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8,iso-2022-jp,euc-jp,ucs-2,cp932,sjis
let mapleader = "\<Space>"
set clipboard=unnamedplus         " クリップボード連携
set mouse=

hi Comment ctermfg=gray
