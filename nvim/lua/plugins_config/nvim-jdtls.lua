local M = {}
function M.setup()
  local jdtls = require("jdtls")

  -- Installation location of jdtls by nvim-lsp-installer
  local JDTLS_LOCATION = vim.fn.stdpath "data" .. "/mason/packages/jdtls"

  -- Data directory - change it to your liking
  local HOME = os.getenv "HOME"
  local WORKSPACE_PATH = HOME .. "/workspace/java/"

  -- Only for Linux and Mac
  local SYSTEM = "linux"
  if vim.fn.has "mac" == 1 then
    SYSTEM = "mac"
  end

  local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
  local workspace_dir = WORKSPACE_PATH .. project_name

  local root_markers = { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" }
  local root_dir = require("jdtls.setup").find_root(root_markers)
  if root_dir == "" then
    return
  end

  local extendedClientCapabilities = jdtls.extendedClientCapabilities
  extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

  local config = {
    cmd = {
      "java",
      "-Declipse.application=org.eclipse.jdt.ls.core.id1",
      "-Dosgi.bundles.defaultStartLevel=4",
      "-Declipse.product=org.eclipse.jdt.ls.core.product",
      "-Dlog.protocol=true",
      "-Dlog.level=ALL",
      '-javaagent:' .. JDTLS_LOCATION .. '/lombok.jar',
      "-Xms1g",
      "--add-modules=ALL-SYSTEM",
      "--add-opens",
      "java.base/java.util=ALL-UNNAMED",
      "--add-opens",
      "java.base/java.lang=ALL-UNNAMED",
      "-jar",
      vim.fn.glob(JDTLS_LOCATION .. "/plugins/org.eclipse.equinox.launcher_*.jar"),
      "-configuration",
      JDTLS_LOCATION .. "/config_" .. SYSTEM,
      "-data",
      workspace_dir,
    },

    on_attach = require("03_lsp_setting").on_attach,
    capabilities = require("03_lsp_setting").capabilities,
    root_dir = root_dir,
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
            url = root_dir .. "/formatter.xml",
            profile = "Style",
          },
        },
      },
      signatureHelp = { enabled = true },
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
      extendedClientCapabilities = extendedClientCapabilities,
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

    flags = {
      allow_incremental_sync = true,
    },
    init_options = {
      bundles = {},
    },
  }
  jdtls.start_or_attach(config)

  require("jdtls.setup").add_commands()

  vim.bo.shiftwidth = 2
  vim.bo.tabstop = 2
end

return M
