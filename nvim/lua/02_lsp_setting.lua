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
  vim.keymap.set('n', ']g', ':Lspsaga diagnostic_jump_next<CR>', opts)
  vim.keymap.set('n', '[g', ':Lspsaga diagnostic_jump_prev<CR>', opts)
  vim.keymap.set('v', '<space>ca', ':<C-U>Lspsaga code_action<CR>', opts)
  vim.keymap.set('n', 'gh', ':Lspsaga lsp_finder<CR>', opts)
  vim.keymap.set('n', '<leader>o', '<cmd>LSoutlineToggle<CR>', opts)
end

M.on_attach = on_attach

local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp
  .protocol
  .make_client_capabilities())
capabilities.textDocument.completion.completionItem.snippetSupport = true
M.capabilities = capabilities

local lspconfig = require("lspconfig")

-- for rust
lspconfig.rust_analyzer.setup {
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

-- for vue
local TYPESCRIPT_PATH = vim.fn.stdpath "data" .. "/mason/packages/vue-language-server/node_modules/typescript/lib"
lspconfig.volar.setup {
  capabilities = capabilities,
  on_attach = on_attach,
  init_options = {
    typescript = {
      tsdk = TYPESCRIPT_PATH
    }
  }
}

local function has_value(tab, val)
  for _, value in ipairs(tab) do
    if value == val then
      return true
    end
  end
  return false
end

local configured_server = { 'rust_analyzer', 'volar' }

require('mason-lspconfig').setup_handlers({ function(server)
  if not has_value(configured_server, server) then
    lspconfig[server].setup { capabilities = capabilities, on_attach = on_attach }
  end
end })

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

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
  update_in_insert = false,
  virtual_text = {
    format = function(diagnostic)
      return string.format("%s 【%s: %s】", diagnostic.message, diagnostic.source, diagnostic.code)
    end,
  },
})

return M
