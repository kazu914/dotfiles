local on_attach = function(_, bufnr)
    local function buf_set_keymap(...)
        vim.api.nvim_buf_set_keymap(bufnr, ...)
    end
    local opts = {noremap = true, silent = true}
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
    buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    buf_set_keymap('n', '<space>D',
                   '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
    buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    buf_set_keymap('n', 'F', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)

    buf_set_keymap('n', '<space>rn', ':Lspsaga rename<CR>', opts)
    buf_set_keymap('n', '<C-k>', ':Lspsaga signature_help<CR>', opts)
    buf_set_keymap('n', 'K', ':Lspsaga hover_doc<CR>', opts)
    buf_set_keymap('n', '[g', ':Lspsaga diagnostic_jump_next<CR>', opts)
    buf_set_keymap('n', ']g', ':Lspsaga diagnostic_jump_prev<CR>', opts)
    buf_set_keymap('v', '<space>ca', ':<C-U>Lspsaga code_action<CR>', opts)
    buf_set_keymap('n', 'gh', ':Lspsaga lsp_finder<CR>', opts)
end

local lsp_installer = require("nvim-lsp-installer")
lsp_installer.on_server_ready(function(server)
    local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp
                                                                         .protocol
                                                                         .make_client_capabilities())
    capabilities.textDocument.completion.completionItem.snippetSupport = true

    local opts = {on_attach = on_attach, capabilities = capabilities}

    if server.name == "tsserver" then
        opts.on_attach = function(client, bufnr)
            client.resolved_capabilities.document_formatting = false
            client.resolved_capabilities.document_range_formatting = false

            local ts_utils = require("nvim-lsp-ts-utils")
            ts_utils.setup {
                enable_import_on_completion = true,
                eslint_enable_diagnostics = true,
                enable_formatting = true
            }

            ts_utils.setup_client(client)

            on_attach(client, bufnr)
        end
        opts.settings = {format = {enable = true}}
    end

    server:setup(opts)
    vim.cmd [[ do User LspAttachBuffers ]]
end)

-- for null-ls setting
require("null-ls").setup({
    sources = {
        require("null-ls").builtins.formatting.prettier,
        require("null-ls").builtins.formatting.eslint_d,
        require("null-ls").builtins.formatting.fixjson,
        require("null-ls").builtins.formatting.rustfmt,
        require("null-ls").builtins.formatting.lua_format,
        require("null-ls").builtins.diagnostics.write_good,
        require("null-ls").builtins.diagnostics.misspell
    }
})

-- for luasaga
local lspsaga = require 'lspsaga'
lspsaga.setup { -- defaults ...
    debug = false,
    use_saga_diagnostic_sign = true,
    -- diagnostic sign
    error_sign = "🤬",
    warn_sign = "🥺",
    hint_sign = "💡",
    infor_sign = "🤔",
    diagnostic_header_icon = "   ",
    -- code action title icon
    code_action_icon = " ",
    code_action_prompt = {
        enable = true,
        sign = true,
        sign_priority = 40,
        virtual_text = true
    },
    finder_definition_icon = "📝  ",
    finder_reference_icon = "🔍  ",
    max_preview_lines = 10,
    finder_action_keys = {
        open = "<CR>",
        vsplit = "v",
        quit = "q",
        scroll_down = "<C-f>",
        scroll_up = "<C-b>"
    },
    code_action_keys = {quit = "q", exec = "<CR>"},
    rename_action_keys = {quit = "<C-c>", exec = "<CR>"},
    definition_preview_icon = "  ",
    border_style = "single",
    rename_prompt_prefix = "➤",
    server_filetype_map = {}
}
