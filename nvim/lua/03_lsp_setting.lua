local M = {}
local navic = require("nvim-navic")
local on_attach = function(client, bufnr)
  navic.attach(client, bufnr)

  local opts = { noremap = true, silent = true, buffer = bufnr }
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  vim.keymap.set('n', '<space>D',
    '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  vim.keymap.set('n', 'F', '<cmd>lua vim.lsp.buf.format()<CR>', opts)

  vim.keymap.set('n', '<space>rn', ':Lspsaga rename<CR>', opts)
  vim.keymap.set('n', '<C-k>', ':Lspsaga signature_help<CR>', opts)
  vim.keymap.set('n', 'K', ':Lspsaga hover_doc<CR>', opts)
  vim.keymap.set('n', '[g', ':Lspsaga diagnostic_jump_next<CR>', opts)
  vim.keymap.set('n', ']g', ':Lspsaga diagnostic_jump_prev<CR>', opts)
  vim.keymap.set('v', '<space>ca', ':<C-U>Lspsaga code_action<CR>', opts)
  vim.keymap.set('n', 'gh', ':Lspsaga lsp_finder<CR>', opts)
  vim.keymap.set('n', '<leader>o', '<cmd>LSoutlineToggle<CR>', opts)
end

M.on_attach = on_attach

local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp
  .protocol
  .make_client_capabilities())
capabilities.textDocument.completion.completionItem.snippetSupport = true
M.capabilities = capabilities

local lspconfig = require("lspconfig")

-- for lua
local luadev = require("lua-dev").setup({
  lspconfig = {
    capabilities = capabilities,
    on_attach = on_attach,
    settings = { Lua = { diagnostics = { globals = { 'vim', 'hs' } } } }
  }
})

lspconfig.sumneko_lua.setup(luadev)

-- for typescript
local ts_on_attach = function(client, bufnr)
  client.server_capabilities.documentFormattingProvider = false
  client.server_capabilities.documentRangeFormattingProvider = false

  local ts_utils = require("nvim-lsp-ts-utils")
  ts_utils.setup {
    enable_import_on_completion = true,
    eslint_enable_diagnostics = true,
    enable_formatting = true
  }

  ts_utils.setup_client(client)

  on_attach(client, bufnr)
end

lspconfig.tsserver.setup {
  capabilities = capabilities,
  on_attach = ts_on_attach,
  settings = { format = { enable = true } }
}

-- for rust
require('lspconfig').rust_analyzer.setup {
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    ['rust-analyzer'] = {
      checkOnSave = {
        allFeatures = true,
        overrideCommand = {
          'cargo', 'clippy', '--workspace', '--message-format=json',
          '--all-targets', '--all-features'
        }
      }
    }
  }
}

-- for other servers
for _, server in ipairs { "cssls", "eslint", "graphql" } do
  lspconfig[server].setup { capabilities = capabilities, on_attach = on_attach }
end

-- other lsp-related plugins settings

-- for null-ls setting
require("null-ls").setup({
  sources = {
    require("null-ls").builtins.formatting.prettier,
    require("null-ls").builtins.formatting.eslint_d,
    require("null-ls").builtins.formatting.fixjson,
    require("null-ls").builtins.diagnostics.write_good,
    require("null-ls").builtins.diagnostics.misspell
  }
})

-- for luasaga
local lspsaga = require 'lspsaga'
lspsaga.init_lsp_saga({
  border_style = "rounded",
  finder_action_keys = {
    open = "<CR>",
    vsplit = "s",
    split = "i",
    tabe = "t",
    quit = "q",
  },
  diagnostic_header = { "🤬 ", "🥺", "💡", "🤔" },
})

-- Set icons for sidebar.
local diagnostic_icons = {
  Error = "🤬",
  Warn = "🥺",
  Hint = "💡",
  Info = "🤔",
}
for type, icon in pairs(diagnostic_icons) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl })
end
return M
