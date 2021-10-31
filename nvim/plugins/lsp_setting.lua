local on_attach = function (_, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local opts = { noremap=true, silent=false }
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '[g', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']g', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', 'F', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
end

local lsp_installer = require("nvim-lsp-installer")
lsp_installer.on_server_ready(function(server)
  local opts = {
    on_attach = on_attach
  }

  if server.name == "tsserver" then
    opts.on_attach = function (client, bufnr)
      client.resolved_capabilities.document_formatting = false
      client.resolved_capabilities.document_range_formatting = false

      local ts_utils = require("nvim-lsp-ts-utils")
      ts_utils.setup {
        enable_import_on_completion = true,
        eslint_enable_diagnostics = true,
        enable_formatting = true,
      }

      ts_utils.setup_client(client)

      on_attach(client, bufnr)
    end
    opts.settings = {
      format = { enable = true },
    }
  end

  server:setup(opts)
  vim.cmd [[ do User LspAttachBuffers ]]
end)

-- for null-ls setting

local nullls = require "null-ls"
local sources = {
  nullls.builtins.formatting.prettier,
  nullls.builtins.formatting.eslint_d,
  nullls.builtins.formatting.fixjson,
  nullls.builtins.formatting.rustfmt,
}

nullls.config({
  sources = sources,
  })
require("lspconfig")["null-ls"].setup({autostart = true})

-- for sign setting for LSP
vim.fn.sign_define({
    {name = "DiagnosticSignError", text = "🤬", linehl = "DiagnosticUnderlineError"},
    {name = "DiagnosticSignWarning",text = "🥺", linehl = "DiagnosticUnderlineWarning"},
    {name = "DiagnosticSignInformation",text = "🥺", linehl = "DiagnosticUnderlineInfomation"},
    {name = "DiagnosticSignHint",text = "🤔", linehl = "DiagnosticUnderlineHint"},
})
