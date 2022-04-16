vim.cmd([[
let mapleader = "\<Space>"
" タブ関連
" The prefix key.
nnoremap    [Tag]   <Nop>
nmap    t [Tag]
" Tab jump
" t1 で1番左のタブ、t2 で1番左から2番目のタブにジャンプ
for n in range(1, 9)
  execute 'nnoremap <silent> [Tag]'.n  ':<C-u>tabnext'.n.'<CR>'
endfor
" tc 新しいタブを一番右に作る
map <silent> [Tag]c :tablast <bar> tabnew<CR>
" tx タブを閉じる
map <silent> [Tag]x :tabclose<CR>
" tn 次のタブ
map <silent> [Tag]n :tabnext<CR>
" tp 前のタブ
map <silent> [Tag]p :tabprevious<CR>

" PageUp,PageDownを無効化
noremap <PageUp> <Nop>
noremap <PageDown> <Nop>
inoremap <PageUp> <Nop>
inoremap <PageDown> <Nop>

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


nnoremap <leader>f :Ntree<CR>
]])
