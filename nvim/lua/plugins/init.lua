return {
  'jiangmiao/auto-pairs',
  'tpope/vim-commentary',
  'simeji/winresizer',
  'ntpeters/vim-better-whitespace',
  { 'kylechui/nvim-surround', config = true },
  {
    'machakann/vim-highlightedyank',
    event = 'TextYankPost',
    config = function()
      vim.g.highlightedyank_highlight_duration = -1
    end
  }
}
