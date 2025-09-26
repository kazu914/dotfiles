vim.g.mapleader = ' '

local function map(mode, lhs, rhs, opts)
  local options = { noremap = true, silent = true }
  if opts then
    options = vim.tbl_extend('force', options, opts)
  end
  vim.keymap.set(mode, lhs, rhs, options)
end

-- PageUp,PageDownを無効化
map({ 'n', 'i' }, '<PageUp>', '<nop>')
map({ 'n', 'i' }, '<PageDown>', '<nop>')
-- カーソル下の単語ハイライト
map('n', '<Space><Space>', '"zyiw:let @/ = @z <CR>:set hlsearch<CR>')

-- x,s ではヤンクしない
map('n', 'x', '"_x')
map('n', 's', '"_s')

-- コピペのときに自動で対象の末尾に移動
map('v', 'y', 'y`]')
map({ 'n', 'v' }, 'p', 'p`]')

-- jjでノーマルモードに戻る
map('i', 'jj', '<Esc>')

-- Esc2回押しでハイライト削除
map('n', '<Esc><Esc>', ':nohlsearch<CR>')
-- 折り返し行移動
map({ 'n', 'v' }, 'j', 'gj')
map({ 'n', 'v' }, 'k', 'gk')

-- 保存のマップ
map('n', '<Leader>w', ':w<CR>')

-- 保存のマップ
map('n', '<Leader>q', ':q<CR>')


-- ウィンドウ移動
map('n', '<C-h>', '<C-w>h')
map('n', '<C-j>', '<C-w>j')
map('n', '<C-k>', '<C-w>k')
map('n', '<C-l>', '<C-w>l')

-- <C-j> で文末にジャンプ，すでに文末なら改行
map('i', '<C-j>', 'col(".") == col("$") ? \'<C-j>\' : \'<ESC>A\'', { noremap = true, silent = true, expr = true })

map('n', '<Space>bb', '<Cmd>BufferOrderByBufferNumber<CR>')
