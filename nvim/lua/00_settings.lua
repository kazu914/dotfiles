vim.cmd([[
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
set clipboard=unnamedplus         " クリップボード連携
set mouse=
set noswapfile
set pumblend=10
set winblend=10
set foldmethod=syntax
set nofoldenable
set signcolumn=yes:2

hi Comment ctermfg=gray

let g:netrw_liststyle=1
let g:netrw_banner=0
let g:netrw_sizestyle="H"
let g:netrw_timefmt="%Y/%m/%d(%a) %H:%M:%S"
let g:netrw_preview=1

if has('persistent_undo')
    set undodir=~/.config/nvim/undo
    set undofile
endif

]])
