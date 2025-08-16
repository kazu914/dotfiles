-- =====================================
-- LSP LspAttach 設定
-- =====================================
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("my.lsp", {}),
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    local bufnr = args.buf

    -- =====================================
    -- keymap 設定
    -- =====================================
    local bufopts = { buffer = bufnr, silent = true }
    vim.keymap.set("n", "<leader>F", function()
      vim.lsp.buf.format({ bufnr = bufnr, async = true })
    end, bufopts)
  end,
})

-- =====================================
-- Diagnostics 設定
-- =====================================
local diag_icons = {
  [vim.diagnostic.severity.ERROR] = "😡",
  [vim.diagnostic.severity.WARN]  = "😵‍💫",
  [vim.diagnostic.severity.INFO]  = "🤖",
  [vim.diagnostic.severity.HINT]  = "💬",
}

vim.diagnostic.config({
  signs = {
    text = diag_icons,
    numhl = {
      [vim.diagnostic.severity.ERROR] = "ErrorMsg",
      [vim.diagnostic.severity.WARN]  = "WarningMsg",
      [vim.diagnostic.severity.INFO]  = "DiagnosticInfo",
      [vim.diagnostic.severity.HINT]  = "DiagnosticHint",
    },
  },

  virtual_text = {
    prefix = "",
    spacing = 0,
    format = function(d)
      return string.format("%s %s [%s]",
        diag_icons[d.severity] or "●",
        d.message,
        d.source or "LSP"
      )
    end,
  },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-- ---------------------------
-- Keymaps
-- ---------------------------
local lsp = vim.lsp.buf
local builtin = require("telescope.builtin")
local opts = { silent = true, noremap = true }

-- Diagnostics jump
vim.keymap.set("n", "[g", vim.diagnostic.goto_prev, opts)
vim.keymap.set("n", "]g", vim.diagnostic.goto_next, opts)

-- Code navigation (Telescope integration)
vim.keymap.set("n", "gh", builtin.lsp_definitions, opts)
vim.keymap.set("n", "gy", builtin.lsp_type_definitions, opts)
vim.keymap.set("n", "gi", builtin.lsp_implementations, opts)
vim.keymap.set("n", "gr", builtin.lsp_references, opts)

-- Hover / signature
vim.keymap.set("n", "K", lsp.hover, opts)
vim.keymap.set("n", "<C-k>", lsp.signature_help, opts)

-- Code actions / rename
vim.keymap.set("n", "<leader>ca", lsp.code_action, opts)
vim.keymap.set("n", "<leader>rn", lsp.rename, opts)

-- =====================================
-- 依存 設定
-- =====================================
return {
  {
    "mason-org/mason.nvim",
    build = ":MasonUpdate",
    cmd = { "Mason", "MasonUpdate", "MasonLog", "MasonInstall", "MasonUninstall", "MasonUninstallAll" },
    config = true,
  },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      { "mason-org/mason.nvim" },
      { "neovim/nvim-lspconfig" },
    },
    event = { "BufReadPre", "BufNewFile" },
    config = true,
  },
  {
    'saghen/blink.cmp',
    dependencies = { 'rafamadriz/friendly-snippets' },
    version = '1.*',
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = {
        preset = "none",
        ["<CR>"] = { "accept", "fallback" },
        ["<Tab>"] = {
          function(cmp)
            if cmp.snippet_active() then
              return cmp.snippet_forward()
            else
              return cmp.select_next()
            end
          end,
          "snippet_forward",
          "fallback"
        },
        ["<S-Tab>"] = {
          function(cmp)
            if cmp.snippet_active() then
              return cmp.snippet_backward()
            else
              return cmp.select_prev()
            end
          end,
          "snippet_backward",
          "fallback"
        },
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
        ["<S-C-j>"] = { "scroll_documentation_down", "fallback" },
        ["<S-C-k>"] = { "scroll_documentation_up", "fallback" },
      },

      appearance = {
        nerd_font_variant = 'mono'
      },

      completion = { documentation = { auto_show = true } },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" }
    },
    opts_extend = { "sources.default" }
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true
  }
}
