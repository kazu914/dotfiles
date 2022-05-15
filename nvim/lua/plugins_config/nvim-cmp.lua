vim.api.nvim_command('set completeopt=menu,menuone,noselect')
-- Setup nvim-cmp.
local cmp = require 'cmp'
local mapping = {
  ['<Tab>'] = cmp.mapping.select_next_item({
    behavior = cmp.SelectBehavior.Insert
  }),
  ['<S-Tab>'] = cmp.mapping.select_prev_item({
    behavior = cmp.SelectBehavior.Insert
  }),
  ['<Down>'] = cmp.mapping.select_next_item({
    behavior = cmp.SelectBehavior.Select
  }),
  ['<Up>'] = cmp.mapping.select_prev_item({
    behavior = cmp.SelectBehavior.Select
  }),
  ['<C-b>'] = cmp.mapping.scroll_docs(-4),
  ['<C-f>'] = cmp.mapping.scroll_docs(4),
  ['<C-Space>'] = cmp.mapping.complete(),
  ['<C-e>'] = cmp.mapping.close(),
  ['<CR>'] = cmp.mapping.confirm({
    behavior = cmp.ConfirmBehavior.Replace,
    select = true
  })
}
cmp.setup({
  snippet = { expand = function(args) vim.fn["vsnip#anonymous"](args.body) end },
  mapping = mapping,
  sources = cmp.config.sources({
    { name = 'vsnip' }, { name = 'buffer' }, { name = 'nvim_lsp' },
    { name = 'path' }
  })
})
-- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline('/', {
  sources = { { name = 'buffer' } },
  mapping = cmp.mapping.preset.cmdline({}),
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
  sources = cmp.config.sources({ { name = 'path' } }, { { name = 'cmdline' } }),
  mapping = cmp.mapping.preset.cmdline({}),
})

local lspkind = require('lspkind')
cmp.setup {
  formatting = {
    format = lspkind.cmp_format({ with_text = true, maxwidth = 50 })
  }
}
