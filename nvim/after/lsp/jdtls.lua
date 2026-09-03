-- jdtls (Java) の LSP 設定
--
-- Neovim 0.11+ の lsp-config 仕様により、lsp/*.lua および after/lsp/*.lua は
-- 「設定テーブルを return」しなければならない (vim.lsp.config["jdtls"] への代入では
-- なく、vim.lsp.enable() 時の設定解決でこの戻り値が使われる)。
-- この設定は mason-lspconfig の automatic_enable から vim.lsp.enable("jdtls") される。
--
-- cmd には mason 同梱の公式ランチャー (bin/jdtls) を使う。
-- ランチャー側で equinox launcher jar の解決・config ディレクトリ (config_mac) の
-- 指定・共通 JVM 引数 (-Xms1G, --add-opens, --add-modules 等) が行われるため、
-- ここではプロジェクト毎の -data と lombok だけを指定する。

local workspace_root = vim.env.HOME .. "/workspace/java/"
local mason = vim.env.MASON or (vim.fn.stdpath "data" .. "/mason")
local jdtls_bin = mason .. "/bin/jdtls"
local lombok_jar = mason .. "/packages/jdtls/lombok.jar"

return {
  cmd = function(dispatchers, config)
    -- プロジェクト (root_dir) 毎に -data のワークスペースを分ける
    local project = config.root_dir and vim.fn.fnamemodify(config.root_dir, ":p:h:t")
      or vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")

    return vim.lsp.rpc.start({
      jdtls_bin,
      "-data",
      workspace_root .. project,
      "--jvm-arg=-javaagent:" .. lombok_jar,
    }, dispatchers, {
      cwd = config.cmd_cwd,
      env = config.cmd_env,
      detached = config.detached,
    })
  end,
  filetypes = { "java" },
  settings = {
    java = {
      eclipse = {
        downloadSources = true,
      },
      configuration = {
        updateBuildConfiguration = "interactive",
      },
      maven = {
        downloadSources = true,
      },
      implementationsCodeLens = {
        enabled = true,
      },
      referencesCodeLens = {
        enabled = true,
      },
      references = {
        includeDecompiledSources = true,
      },
      format = {
        enabled = true,
        settings = {
          -- url = root_dir .. "/formatter.xml",
          profile = "Style",
        },
      },
      signatureHelp = {
        enabled = true,
      },
      completion = {
        favoriteStaticMembers = {
          "org.hamcrest.MatcherAssert.assertThat",
          "org.hamcrest.Matchers.*",
          "org.hamcrest.CoreMatchers.*",
          "org.junit.jupiter.api.Assertions.*",
          "java.util.Objects.requireNonNull",
          "java.util.Objects.requireNonNullElse",
          "org.mockito.Mockito.*",
        },
      },
      contentProvider = { preferred = "fernflower" },
      sources = {
        organizeImports = {
          starThreshold = 9999,
          staticStarThreshold = 9999,
        },
      },
      codeGeneration = {
        toString = {
          template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
        },
        useBlocks = true,
      },
    },
  },

  flags = {
    allow_incremental_sync = true,
  },
  init_options = {
    bundles = {},
  },
}
