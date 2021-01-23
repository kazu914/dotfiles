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
set autochdir                     " カレントディレクトリを編集中のファイルのあるディレクトリにする
let mapleader = "\<Space>"
set clipboard=unnamedplus         " クリップボード連携

" タブ関連
" The prefix key.
nnoremap    [Tag]   <Nop>
nmap    t [Tag]
" Tab jump
for n in range(1, 9)
  execute 'nnoremap <silent> [Tag]'.n  ':<C-u>tabnext'.n.'<CR>'
endfor
" t1 で1番左のタブ、t2 で1番左から2番目のタブにジャンプ
map <silent> [Tag]c :tablast <bar> tabnew<CR>
" tc 新しいタブを一番右に作る
map <silent> [Tag]x :tabclose<CR>
" tx タブを閉じる
map <silent> [Tag]n :tabnext<CR>
" tn 次のタブ
map <silent> [Tag]p :tabprevious<CR>
" tp 前のタブ

" マークダウンの開き方
:autocmd BufEnter *.md nnoremap <silent> <C-p> :vs<CR><C-w>l:term typora "%"<CR><C-w>h

" PageUp,PageDownを無効化
noremap <PageUp> <Nop>
noremap <PageDown> <Nop>
inoremap <PageUp> <Nop>
inoremap <PageDown> <Nop>

" pythonをF6で自動実行
autocmd Filetype python nnoremap <buffer> <F6> :w<CR>:vs<CR><C-w>l:ter python3 "%"<CR>i

" 左にターミナルを開いて入る
nnoremap <Space>vt :vs<CR><C-w>l:term<CR>i

" カーソル下の単語ハイライト
nnoremap <silent> <Space><Space> "zyiw:let @/ = '\<' . @z . '\>'<CR>:set hlsearch<CR>

" カーソル下の単語を検索置換
nmap # <Space><Space>:%s/<C-r>///g<Left><Left>

" x,s ではヤンクしない
nnoremap x "_x
nnoremap s "_s

" コピペのときに自動で対象の末尾に移動
vnoremap <silent> y y`]
vnoremap <silent> p p`]
nnoremap <silent> p p`]

" visualモードで連続ペーストする
xnoremap <expr> p 'pgv"'.v:register.'y`>'

" jjでノーマルモードに戻って保存
inoremap jj <Esc>:w<CR>
tnoremap jj <C-\><C-n>

" Esc2回押しでハイライト削除
nnoremap <Esc><Esc> :nohlsearch<CR>

" 折り返し行移動
nnoremap j gj
nnoremap k gk
vnoremap j gj
vnoremap k gk

" 保存のマップ
nnoremap <Leader>w :w<CR>

" quit map
nnoremap <Leader>q :q<CR>

" ウィンドウ移動
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" terminalからノーマルモードに戻る
tnoremap <Esc> <C-\><C-n>

" <C-j> で文末にジャンプ，すでに文末なら改行
inoremap <expr> <C-j>  col(".") == col("$") ? '<C-j>' : '<ESC>A'

"
" htmlのマッチするタグに%でジャンプ
source $VIMRUNTIME/macros/matchit.vim

hi Comment ctermfg=gray

set mouse=

"dein Scripts-----------------------------
if &compatible
  set nocompatible               " Be iMproved
endif
set runtimepath+=~/.config/nvim/dein/repos/github.com/Shougo/dein.vim
if dein#load_state('~/.config/nvim/dein')
  call dein#begin('~/.config/nvim/dein')

  call dein#load_toml('~/.config/nvim/dein.toml', {'lazy': 0})
  call dein#load_toml('~/.config/nvim/lazy_dein.toml', {'lazy': 1})

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
