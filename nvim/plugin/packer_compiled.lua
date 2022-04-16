-- Automatically generated packer.nvim plugin loader code

if vim.api.nvim_call_function('has', {'nvim-0.5'}) ~= 1 then
  vim.api.nvim_command('echohl WarningMsg | echom "Invalid Neovim version for packer.nvim! | echohl None"')
  return
end

vim.api.nvim_command('packadd packer.nvim')

local no_errors, error_msg = pcall(function()

  local time
  local profile_info
  local should_profile = false
  if should_profile then
    local hrtime = vim.loop.hrtime
    profile_info = {}
    time = function(chunk, start)
      if start then
        profile_info[chunk] = hrtime()
      else
        profile_info[chunk] = (hrtime() - profile_info[chunk]) / 1e6
      end
    end
  else
    time = function(chunk, start) end
  end
  
local function save_profiles(threshold)
  local sorted_times = {}
  for chunk_name, time_taken in pairs(profile_info) do
    sorted_times[#sorted_times + 1] = {chunk_name, time_taken}
  end
  table.sort(sorted_times, function(a, b) return a[2] > b[2] end)
  local results = {}
  for i, elem in ipairs(sorted_times) do
    if not threshold or threshold and elem[2] > threshold then
      results[i] = elem[1] .. ' took ' .. elem[2] .. 'ms'
    end
  end

  _G._packer = _G._packer or {}
  _G._packer.profile_output = results
end

time([[Luarocks path setup]], true)
local package_path_str = "/Users/nomura/.cache/nvim/packer_hererocks/2.1.0-beta3/share/lua/5.1/?.lua;/Users/nomura/.cache/nvim/packer_hererocks/2.1.0-beta3/share/lua/5.1/?/init.lua;/Users/nomura/.cache/nvim/packer_hererocks/2.1.0-beta3/lib/luarocks/rocks-5.1/?.lua;/Users/nomura/.cache/nvim/packer_hererocks/2.1.0-beta3/lib/luarocks/rocks-5.1/?/init.lua"
local install_cpath_pattern = "/Users/nomura/.cache/nvim/packer_hererocks/2.1.0-beta3/lib/lua/5.1/?.so"
if not string.find(package.path, package_path_str, 1, true) then
  package.path = package.path .. ';' .. package_path_str
end

if not string.find(package.cpath, install_cpath_pattern, 1, true) then
  package.cpath = package.cpath .. ';' .. install_cpath_pattern
end

time([[Luarocks path setup]], false)
time([[try_loadstring definition]], true)
local function try_loadstring(s, component, name)
  local success, result = pcall(loadstring(s), name, _G.packer_plugins[name])
  if not success then
    vim.schedule(function()
      vim.api.nvim_notify('packer.nvim: Error running ' .. component .. ' for ' .. name .. ': ' .. result, vim.log.levels.ERROR, {})
    end)
  end
  return result
end

time([[try_loadstring definition]], false)
time([[Defining packer_plugins]], true)
_G.packer_plugins = {
  ["auto-pairs"] = {
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/auto-pairs",
    url = "https://github.com/jiangmiao/auto-pairs"
  },
  ["buftabline.nvim"] = {
    config = { "\27LJ\2\n<\0\0\3\0\3\0\a6\0\0\0'\2\1\0B\0\2\0029\0\2\0004\2\0\0B\0\2\1K\0\1\0\nsetup\15buftabline\frequire\0" },
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/buftabline.nvim",
    url = "https://github.com/jose-elias-alvarez/buftabline.nvim"
  },
  ["cmp-buffer"] = {
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/cmp-buffer",
    url = "https://github.com/hrsh7th/cmp-buffer"
  },
  ["cmp-cmdline"] = {
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/cmp-cmdline",
    url = "https://github.com/hrsh7th/cmp-cmdline"
  },
  ["cmp-nvim-lsp"] = {
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/cmp-nvim-lsp",
    url = "https://github.com/hrsh7th/cmp-nvim-lsp"
  },
  ["cmp-path"] = {
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/cmp-path",
    url = "https://github.com/hrsh7th/cmp-path"
  },
  ["cmp-vsnip"] = {
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/cmp-vsnip",
    url = "https://github.com/hrsh7th/cmp-vsnip"
  },
  ["denops.vim"] = {
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/denops.vim",
    url = "https://github.com/vim-denops/denops.vim"
  },
  ["emmet-vim"] = {
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/opt/emmet-vim",
    url = "https://github.com/mattn/emmet-vim"
  },
  ["fidget.nvim"] = {
    config = { "\27LJ\2\n8\0\0\3\0\3\0\a6\0\0\0'\2\1\0B\0\2\0029\0\2\0004\2\0\0B\0\2\1K\0\1\0\nsetup\vfidget\frequire\0" },
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/fidget.nvim",
    url = "https://github.com/j-hui/fidget.nvim"
  },
  ["fuzzy-motion.vim"] = {
    config = { "\27LJ\2\nS\0\0\5\0\6\0\b6\0\0\0009\0\1\0009\0\2\0'\2\3\0'\3\4\0'\4\5\0B\0\4\1K\0\1\0\21:FuzzyMotion<CR>\14<leader>s\6n\bset\vkeymap\bvim\0" },
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/fuzzy-motion.vim",
    url = "https://github.com/yuki-yano/fuzzy-motion.vim"
  },
  ["gitsigns.nvim"] = {
    config = { "\27LJ\2\n6\0\0\3\0\3\0\0066\0\0\0'\2\1\0B\0\2\0029\0\2\0B\0\1\1K\0\1\0\nsetup\rgitsigns\frequire\0" },
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/gitsigns.nvim",
    url = "https://github.com/lewis6991/gitsigns.nvim"
  },
  ["hop.nvim"] = {
    config = { "\27LJ\2\n®\1\0\0\5\0\v\0\0206\0\0\0009\0\1\0009\0\2\0'\2\3\0'\3\4\0'\4\5\0B\0\4\0016\0\0\0009\0\1\0009\0\2\0'\2\3\0'\3\6\0'\4\a\0B\0\4\0016\0\b\0'\2\t\0B\0\2\0029\0\n\0B\0\1\1K\0\1\0\nsetup\bhop\frequire\17:HopLine<CR>\14<Leader>j\17:HopWord<CR>\14<Leader>l\6n\bset\vkeymap\bvim\0" },
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/hop.nvim",
    url = "https://github.com/phaazon/hop.nvim"
  },
  indentLine = {
    after_files = { "/Users/nomura/.local/share/nvim/site/pack/packer/opt/indentLine/after/plugin/indentLine.vim" },
    config = { "\27LJ\2\nZ\0\0\3\0\3\0\0056\0\0\0009\0\1\0'\2\2\0B\0\2\1K\0\1\0; autocmd FileType markdown let g:indentLine_enabled=0'\bcmd\bvim\0" },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/opt/indentLine",
    url = "https://github.com/Yggdroot/indentLine"
  },
  ["lsp_signature.nvim"] = {
    config = { "\27LJ\2\n¢\1\0\0\4\0\6\0\t6\0\0\0'\2\1\0B\0\2\0029\0\2\0005\2\3\0005\3\4\0=\3\5\2B\0\2\1K\0\1\0\17handler_opts\1\0\1\vborder\frounded\1\0\4\16hint_prefix\nüê∞ \16use_lspsaga\1\20floating_window\2\vzindex\0031\nsetup\18lsp_signature\frequire\0" },
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/lsp_signature.nvim",
    url = "https://github.com/ray-x/lsp_signature.nvim"
  },
  ["lspkind-nvim"] = {
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/lspkind-nvim",
    url = "https://github.com/onsails/lspkind-nvim"
  },
  ["lspsaga.nvim"] = {
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/lspsaga.nvim",
    url = "https://github.com/tami5/lspsaga.nvim"
  },
  ["lualine.nvim"] = {
    config = { "\27LJ\2\n^\0\0\4\0\6\0\t5\0\0\0006\1\1\0'\3\2\0B\1\2\0029\1\3\0015\3\4\0=\0\5\3B\1\2\1K\0\1\0\foptions\1\0\0\nsetup\flualine\frequire\1\0\1\ntheme\rcodedark\0" },
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/lualine.nvim",
    url = "https://github.com/nvim-lualine/lualine.nvim"
  },
  ["modes.nvim"] = {
    config = { "\27LJ\2\nV\0\0\3\0\6\0\n6\0\0\0009\0\1\0+\1\2\0=\1\2\0006\0\3\0'\2\4\0B\0\2\0029\0\5\0B\0\1\1K\0\1\0\nsetup\nmodes\frequire\15cursorline\bopt\bvim\0" },
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/modes.nvim",
    url = "https://github.com/mvllow/modes.nvim"
  },
  ["null-ls.nvim"] = {
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/null-ls.nvim",
    url = "https://github.com/jose-elias-alvarez/null-ls.nvim"
  },
  ["nvim-cmp"] = {
    config = { "\27LJ\2\n;\0\1\4\0\4\0\0066\1\0\0009\1\1\0019\1\2\0019\3\3\0B\1\2\1K\0\1\0\tbody\20vsnip#anonymous\afn\bvimä\b\1\0\v\0=\0}6\0\0\0009\0\1\0009\0\2\0'\2\3\0B\0\2\0016\0\4\0'\2\5\0B\0\2\0025\1\f\0009\2\6\0009\2\a\0025\4\n\0009\5\b\0009\5\t\5=\5\v\4B\2\2\2=\2\r\0019\2\6\0009\2\14\0025\4\15\0009\5\b\0009\5\t\5=\5\v\4B\2\2\2=\2\16\0019\2\6\0009\2\a\0025\4\18\0009\5\b\0009\5\17\5=\5\v\4B\2\2\2=\2\19\0019\2\6\0009\2\14\0025\4\20\0009\5\b\0009\5\17\5=\5\v\4B\2\2\2=\2\21\0019\2\6\0009\2\22\2)\4¸ˇB\2\2\2=\2\23\0019\2\6\0009\2\22\2)\4\4\0B\2\2\2=\2\24\0019\2\6\0009\2\25\2B\2\1\2=\2\26\0019\2\6\0009\2\27\2B\2\1\2=\2\28\0019\2\6\0009\2\29\0025\4 \0009\5\30\0009\5\31\5=\5\v\4B\2\2\2=\2!\0019\2\"\0005\4&\0005\5$\0003\6#\0=\6%\5=\5'\4=\1\6\0049\5(\0009\5)\0054\a\5\0005\b*\0>\b\1\a5\b+\0>\b\2\a5\b,\0>\b\3\a5\b-\0>\b\4\aB\5\2\2=\5)\4B\2\2\0019\2\"\0009\2.\2'\4/\0005\0051\0004\6\3\0005\a0\0>\a\1\6=\6)\5B\2\3\0019\2\"\0009\2.\2'\0042\0005\0055\0009\6(\0009\6)\0064\b\3\0005\t3\0>\t\1\b4\t\3\0005\n4\0>\n\1\tB\6\3\2=\6)\5B\2\3\0016\2\4\0'\0046\0B\2\2\0029\3\"\0005\5;\0005\0069\0009\a7\0025\t8\0B\a\2\2=\a:\6=\6<\5B\3\2\1K\0\1\0\15formatting\1\0\0\vformat\1\0\0\1\0\2\14with_text\2\rmaxwidth\0032\15cmp_format\flspkind\1\0\0\1\0\1\tname\fcmdline\1\0\1\tname\tpath\6:\1\0\0\1\0\1\tname\vbuffer\6/\fcmdline\1\0\1\tname\tpath\1\0\1\tname\rnvim_lsp\1\0\1\tname\vbuffer\1\0\1\tname\nvsnip\fsources\vconfig\fsnippet\1\0\0\vexpand\1\0\0\0\nsetup\t<CR>\1\0\1\vselect\2\fReplace\20ConfirmBehavior\fconfirm\n<C-e>\nclose\14<C-Space>\rcomplete\n<C-f>\n<C-b>\16scroll_docs\t<Up>\1\0\0\v<Down>\1\0\0\vSelect\f<S-Tab>\1\0\0\21select_prev_item\n<Tab>\1\0\0\rbehavior\1\0\0\vInsert\19SelectBehavior\21select_next_item\fmapping\bcmp\frequire*set completeopt=menu,menuone,noselect\17nvim_command\bapi\bvim\0" },
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/nvim-cmp",
    url = "https://github.com/hrsh7th/nvim-cmp"
  },
  ["nvim-hlslens"] = {
    config = { "\27LJ\2\nå\5\0\0\a\0\18\0:5\0\0\0006\1\1\0009\1\2\0019\1\3\1'\3\4\0'\4\4\0'\5\5\0\18\6\0\0B\1\5\0016\1\1\0009\1\2\0019\1\3\1'\3\4\0'\4\6\0'\5\a\0\18\6\0\0B\1\5\0016\1\1\0009\1\2\0019\1\3\1'\3\4\0'\4\b\0'\5\t\0\18\6\0\0B\1\5\0016\1\1\0009\1\2\0019\1\3\1'\3\4\0'\4\n\0'\5\v\0\18\6\0\0B\1\5\0016\1\1\0009\1\2\0019\1\3\1'\3\4\0'\4\f\0'\5\r\0\18\6\0\0B\1\5\0016\1\1\0009\1\2\0019\1\3\1'\3\4\0'\4\14\0'\5\15\0\18\6\0\0B\1\5\0016\1\1\0009\1\2\0019\1\3\1'\3\4\0'\4\16\0'\5\17\0\18\6\0\0B\1\5\1K\0\1\0\r:noh<CR>\14<Leader>l.g#<Cmd>lua require('hlslens').start()<CR>\ag#.g*<Cmd>lua require('hlslens').start()<CR>\ag*-#<Cmd>lua require('hlslens').start()<CR>\6#-*<Cmd>lua require('hlslens').start()<CR>\6*Y<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>\6NY<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>\6n\20nvim_set_keymap\bapi\bvim\1\0\2\fnoremap\2\vsilent\2\0" },
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/nvim-hlslens",
    url = "https://github.com/kevinhwang91/nvim-hlslens"
  },
  ["nvim-lsp-installer"] = {
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/nvim-lsp-installer",
    url = "https://github.com/williamboman/nvim-lsp-installer"
  },
  ["nvim-lsp-ts-utils"] = {
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/nvim-lsp-ts-utils",
    url = "https://github.com/jose-elias-alvarez/nvim-lsp-ts-utils"
  },
  ["nvim-lspconfig"] = {
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/nvim-lspconfig",
    url = "https://github.com/neovim/nvim-lspconfig"
  },
  ["nvim-notify"] = {
    config = { "\27LJ\2\n2\0\0\4\0\3\0\0066\0\0\0006\1\2\0'\3\1\0B\1\2\2=\1\1\0K\0\1\0\frequire\vnotify\bvim\0" },
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/nvim-notify",
    url = "https://github.com/rcarriga/nvim-notify"
  },
  ["nvim-scrollbar"] = {
    config = { "\27LJ\2\nâ\3\0\0\a\0\30\0/6\0\0\0'\2\1\0B\0\2\0029\0\2\0B\0\1\0026\1\0\0'\3\3\0B\1\2\0029\1\2\0015\3\a\0005\4\5\0009\5\4\0=\5\6\4=\4\b\0035\4\v\0005\5\n\0009\6\t\0=\6\6\5=\5\f\0045\5\14\0009\6\r\0=\6\6\5=\5\15\0045\5\17\0009\6\16\0=\6\6\5=\5\18\0045\5\20\0009\6\19\0=\6\6\5=\5\21\0045\5\23\0009\6\22\0=\6\6\5=\5\24\0045\5\26\0009\6\25\0=\6\6\5=\5\27\4=\4\28\3B\1\2\0016\1\0\0'\3\29\0B\1\2\0029\1\2\1B\1\1\1K\0\1\0\30scrollbar.handlers.search\nmarks\tMisc\1\0\0\vpurple\tHint\1\0\0\thint\tInfo\1\0\0\tinfo\tWarn\1\0\0\fwarning\nError\1\0\0\nerror\vSearch\1\0\0\1\0\0\vorange\vhandle\1\0\0\ncolor\1\0\0\17bg_highlight\14scrollbar\nsetup\22tokyonight.colors\frequire\0" },
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/nvim-scrollbar",
    url = "https://github.com/petertriho/nvim-scrollbar"
  },
  ["nvim-treesitter"] = {
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/nvim-treesitter",
    url = "https://github.com/nvim-treesitter/nvim-treesitter"
  },
  ["nvim-treesitter-context"] = {
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/nvim-treesitter-context",
    url = "https://github.com/romgrk/nvim-treesitter-context"
  },
  ["nvim-web-devicons"] = {
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/nvim-web-devicons",
    url = "https://github.com/kyazdani42/nvim-web-devicons"
  },
  ["packer.nvim"] = {
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/packer.nvim",
    url = "https://github.com/wbthomason/packer.nvim"
  },
  ["plenary.nvim"] = {
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/plenary.nvim",
    url = "https://github.com/nvim-lua/plenary.nvim"
  },
  rainbow = {
    config = { "\27LJ\2\n0\0\0\2\0\3\0\0056\0\0\0009\0\1\0)\1\1\0=\1\2\0K\0\1\0\19rainbow_active\6g\bvim\0" },
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/rainbow",
    url = "https://github.com/luochen1990/rainbow"
  },
  ["telescope.nvim"] = {
    config = { "\27LJ\2\nª\6\0\0\b\0(\0Z6\0\0\0009\0\1\0009\0\2\0'\2\3\0'\3\4\0006\4\5\0'\6\6\0B\4\2\0029\4\a\4B\0\4\0016\0\0\0009\0\1\0009\0\2\0'\2\3\0'\3\b\0006\4\5\0'\6\6\0B\4\2\0029\4\t\4B\0\4\0016\0\0\0009\0\1\0009\0\2\0'\2\3\0'\3\n\0006\4\5\0'\6\6\0B\4\2\0029\4\v\4B\0\4\0016\0\0\0009\0\1\0009\0\2\0'\2\3\0'\3\f\0006\4\5\0'\6\6\0B\4\2\0029\4\r\4B\0\4\0016\0\0\0009\0\1\0009\0\2\0'\2\3\0'\3\14\0006\4\5\0'\6\6\0B\4\2\0029\4\15\4B\0\4\0016\0\0\0009\0\1\0009\0\2\0'\2\3\0'\3\16\0006\4\5\0'\6\6\0B\4\2\0029\4\17\4B\0\4\0016\0\5\0'\2\18\0B\0\2\0026\1\5\0'\3\19\0B\1\2\0029\1\20\0015\3\"\0005\4\21\0005\5\22\0=\5\23\0045\5\31\0005\6\25\0009\a\24\0=\a\26\0069\a\27\0=\a\28\0069\a\24\0=\a\29\0069\a\27\0=\a\30\6=\6 \5=\5!\4=\4#\0035\4%\0005\5$\0=\5&\4=\4'\3B\1\2\1K\0\1\0\15extensions\bfzf\1\0\0\1\0\4\28override_generic_sorter\1\nfuzzy\2\14case_mode\15smart_case\25override_file_sorter\2\rdefaults\1\0\0\rmappings\6i\1\0\0\f<S-Tab>\n<Tab>\n<C-k>\28move_selection_previous\n<C-j>\1\0\0\24move_selection_next\18layout_config\1\0\1\20prompt_position\btop\1\0\2\20selection_caret\a> \21sorting_strategy\14ascending\nsetup\14telescope\22telescope.actions\16diagnostics\15<leader>tr\21lsp_code_actions\15<leader>ca\14live_grep\a,r\fbuffers\a,b\14git_files\a,g\15find_files\22telescope.builtin\frequire\a,f\6n\bset\vkeymap\bvim\0" },
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/telescope.nvim",
    url = "https://github.com/nvim-telescope/telescope.nvim"
  },
  ["tokyonight.nvim"] = {
    config = { "vim.cmd[[colorscheme tokyonight]]" },
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/tokyonight.nvim",
    url = "https://github.com/folke/tokyonight.nvim"
  },
  undotree = {
    config = { "\27LJ\2\ná\2\0\0\6\0\f\0\0256\0\0\0009\0\1\0)\1\2\0=\1\2\0006\0\0\0009\0\1\0)\1\1\0=\1\3\0006\0\0\0009\0\1\0)\1\30\0=\1\4\0006\0\0\0009\0\1\0)\1\1\0=\1\5\0006\0\0\0009\0\6\0009\0\a\0'\2\b\0'\3\t\0'\4\n\0005\5\v\0B\0\5\1K\0\1\0\1\0\1\fnoremap\2\24:UndotreeToggle<CR>\14<leader>u\6n\bset\vkeymap undotree_SetFocusWhenToggle\24undotree_SplitWidth\29undotree_ShortIndicators\26undotree_WindowLayout\6g\bvim\0" },
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/undotree",
    url = "https://github.com/mbbill/undotree"
  },
  ["vim-better-whitespace"] = {
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/vim-better-whitespace",
    url = "https://github.com/ntpeters/vim-better-whitespace"
  },
  ["vim-commentary"] = {
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/vim-commentary",
    url = "https://github.com/tpope/vim-commentary"
  },
  ["vim-devicons"] = {
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/vim-devicons",
    url = "https://github.com/ryanoasis/vim-devicons"
  },
  ["vim-highlightedyank"] = {
    config = { "\27LJ\2\nD\0\0\2\0\3\0\0056\0\0\0009\0\1\0)\1ˇˇ=\1\2\0K\0\1\0'highlightedyank_highlight_duration\6g\bvim\0" },
    loaded = false,
    needs_bufread = false,
    only_cond = false,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/opt/vim-highlightedyank",
    url = "https://github.com/machakann/vim-highlightedyank"
  },
  ["vim-quickrun"] = {
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/vim-quickrun",
    url = "https://github.com/thinca/vim-quickrun"
  },
  ["vim-sayonara"] = {
    config = { "\27LJ\2\nP\0\0\5\0\6\0\b6\0\0\0009\0\1\0009\0\2\0'\2\3\0'\3\4\0'\4\5\0B\0\4\1K\0\1\0\18:Sayonara<CR>\14<leader>q\6n\bset\vkeymap\bvim\0" },
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/vim-sayonara",
    url = "https://github.com/mhinz/vim-sayonara"
  },
  ["vim-surround"] = {
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/vim-surround",
    url = "https://github.com/tpope/vim-surround"
  },
  ["vim-vsnip"] = {
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/vim-vsnip",
    url = "https://github.com/hrsh7th/vim-vsnip"
  },
  ["vim-vsnip-integ"] = {
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/vim-vsnip-integ",
    url = "https://github.com/hrsh7th/vim-vsnip-integ"
  },
  ["vim-vue"] = {
    loaded = false,
    needs_bufread = true,
    only_cond = false,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/opt/vim-vue",
    url = "https://github.com/posva/vim-vue"
  },
  ["vimproc.vim"] = {
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/vimproc.vim",
    url = "https://github.com/Shougo/vimproc.vim"
  },
  winresizer = {
    loaded = true,
    path = "/Users/nomura/.local/share/nvim/site/pack/packer/start/winresizer",
    url = "https://github.com/simeji/winresizer"
  }
}

time([[Defining packer_plugins]], false)
-- Config for: undotree
time([[Config for undotree]], true)
try_loadstring("\27LJ\2\ná\2\0\0\6\0\f\0\0256\0\0\0009\0\1\0)\1\2\0=\1\2\0006\0\0\0009\0\1\0)\1\1\0=\1\3\0006\0\0\0009\0\1\0)\1\30\0=\1\4\0006\0\0\0009\0\1\0)\1\1\0=\1\5\0006\0\0\0009\0\6\0009\0\a\0'\2\b\0'\3\t\0'\4\n\0005\5\v\0B\0\5\1K\0\1\0\1\0\1\fnoremap\2\24:UndotreeToggle<CR>\14<leader>u\6n\bset\vkeymap undotree_SetFocusWhenToggle\24undotree_SplitWidth\29undotree_ShortIndicators\26undotree_WindowLayout\6g\bvim\0", "config", "undotree")
time([[Config for undotree]], false)
-- Config for: vim-sayonara
time([[Config for vim-sayonara]], true)
try_loadstring("\27LJ\2\nP\0\0\5\0\6\0\b6\0\0\0009\0\1\0009\0\2\0'\2\3\0'\3\4\0'\4\5\0B\0\4\1K\0\1\0\18:Sayonara<CR>\14<leader>q\6n\bset\vkeymap\bvim\0", "config", "vim-sayonara")
time([[Config for vim-sayonara]], false)
-- Config for: fidget.nvim
time([[Config for fidget.nvim]], true)
try_loadstring("\27LJ\2\n8\0\0\3\0\3\0\a6\0\0\0'\2\1\0B\0\2\0029\0\2\0004\2\0\0B\0\2\1K\0\1\0\nsetup\vfidget\frequire\0", "config", "fidget.nvim")
time([[Config for fidget.nvim]], false)
-- Config for: rainbow
time([[Config for rainbow]], true)
try_loadstring("\27LJ\2\n0\0\0\2\0\3\0\0056\0\0\0009\0\1\0)\1\1\0=\1\2\0K\0\1\0\19rainbow_active\6g\bvim\0", "config", "rainbow")
time([[Config for rainbow]], false)
-- Config for: modes.nvim
time([[Config for modes.nvim]], true)
try_loadstring("\27LJ\2\nV\0\0\3\0\6\0\n6\0\0\0009\0\1\0+\1\2\0=\1\2\0006\0\3\0'\2\4\0B\0\2\0029\0\5\0B\0\1\1K\0\1\0\nsetup\nmodes\frequire\15cursorline\bopt\bvim\0", "config", "modes.nvim")
time([[Config for modes.nvim]], false)
-- Config for: buftabline.nvim
time([[Config for buftabline.nvim]], true)
try_loadstring("\27LJ\2\n<\0\0\3\0\3\0\a6\0\0\0'\2\1\0B\0\2\0029\0\2\0004\2\0\0B\0\2\1K\0\1\0\nsetup\15buftabline\frequire\0", "config", "buftabline.nvim")
time([[Config for buftabline.nvim]], false)
-- Config for: gitsigns.nvim
time([[Config for gitsigns.nvim]], true)
try_loadstring("\27LJ\2\n6\0\0\3\0\3\0\0066\0\0\0'\2\1\0B\0\2\0029\0\2\0B\0\1\1K\0\1\0\nsetup\rgitsigns\frequire\0", "config", "gitsigns.nvim")
time([[Config for gitsigns.nvim]], false)
-- Config for: tokyonight.nvim
time([[Config for tokyonight.nvim]], true)
vim.cmd[[colorscheme tokyonight]]
time([[Config for tokyonight.nvim]], false)
-- Config for: nvim-cmp
time([[Config for nvim-cmp]], true)
try_loadstring("\27LJ\2\n;\0\1\4\0\4\0\0066\1\0\0009\1\1\0019\1\2\0019\3\3\0B\1\2\1K\0\1\0\tbody\20vsnip#anonymous\afn\bvimä\b\1\0\v\0=\0}6\0\0\0009\0\1\0009\0\2\0'\2\3\0B\0\2\0016\0\4\0'\2\5\0B\0\2\0025\1\f\0009\2\6\0009\2\a\0025\4\n\0009\5\b\0009\5\t\5=\5\v\4B\2\2\2=\2\r\0019\2\6\0009\2\14\0025\4\15\0009\5\b\0009\5\t\5=\5\v\4B\2\2\2=\2\16\0019\2\6\0009\2\a\0025\4\18\0009\5\b\0009\5\17\5=\5\v\4B\2\2\2=\2\19\0019\2\6\0009\2\14\0025\4\20\0009\5\b\0009\5\17\5=\5\v\4B\2\2\2=\2\21\0019\2\6\0009\2\22\2)\4¸ˇB\2\2\2=\2\23\0019\2\6\0009\2\22\2)\4\4\0B\2\2\2=\2\24\0019\2\6\0009\2\25\2B\2\1\2=\2\26\0019\2\6\0009\2\27\2B\2\1\2=\2\28\0019\2\6\0009\2\29\0025\4 \0009\5\30\0009\5\31\5=\5\v\4B\2\2\2=\2!\0019\2\"\0005\4&\0005\5$\0003\6#\0=\6%\5=\5'\4=\1\6\0049\5(\0009\5)\0054\a\5\0005\b*\0>\b\1\a5\b+\0>\b\2\a5\b,\0>\b\3\a5\b-\0>\b\4\aB\5\2\2=\5)\4B\2\2\0019\2\"\0009\2.\2'\4/\0005\0051\0004\6\3\0005\a0\0>\a\1\6=\6)\5B\2\3\0019\2\"\0009\2.\2'\0042\0005\0055\0009\6(\0009\6)\0064\b\3\0005\t3\0>\t\1\b4\t\3\0005\n4\0>\n\1\tB\6\3\2=\6)\5B\2\3\0016\2\4\0'\0046\0B\2\2\0029\3\"\0005\5;\0005\0069\0009\a7\0025\t8\0B\a\2\2=\a:\6=\6<\5B\3\2\1K\0\1\0\15formatting\1\0\0\vformat\1\0\0\1\0\2\14with_text\2\rmaxwidth\0032\15cmp_format\flspkind\1\0\0\1\0\1\tname\fcmdline\1\0\1\tname\tpath\6:\1\0\0\1\0\1\tname\vbuffer\6/\fcmdline\1\0\1\tname\tpath\1\0\1\tname\rnvim_lsp\1\0\1\tname\vbuffer\1\0\1\tname\nvsnip\fsources\vconfig\fsnippet\1\0\0\vexpand\1\0\0\0\nsetup\t<CR>\1\0\1\vselect\2\fReplace\20ConfirmBehavior\fconfirm\n<C-e>\nclose\14<C-Space>\rcomplete\n<C-f>\n<C-b>\16scroll_docs\t<Up>\1\0\0\v<Down>\1\0\0\vSelect\f<S-Tab>\1\0\0\21select_prev_item\n<Tab>\1\0\0\rbehavior\1\0\0\vInsert\19SelectBehavior\21select_next_item\fmapping\bcmp\frequire*set completeopt=menu,menuone,noselect\17nvim_command\bapi\bvim\0", "config", "nvim-cmp")
time([[Config for nvim-cmp]], false)
-- Config for: nvim-notify
time([[Config for nvim-notify]], true)
try_loadstring("\27LJ\2\n2\0\0\4\0\3\0\0066\0\0\0006\1\2\0'\3\1\0B\1\2\2=\1\1\0K\0\1\0\frequire\vnotify\bvim\0", "config", "nvim-notify")
time([[Config for nvim-notify]], false)
-- Config for: hop.nvim
time([[Config for hop.nvim]], true)
try_loadstring("\27LJ\2\n®\1\0\0\5\0\v\0\0206\0\0\0009\0\1\0009\0\2\0'\2\3\0'\3\4\0'\4\5\0B\0\4\0016\0\0\0009\0\1\0009\0\2\0'\2\3\0'\3\6\0'\4\a\0B\0\4\0016\0\b\0'\2\t\0B\0\2\0029\0\n\0B\0\1\1K\0\1\0\nsetup\bhop\frequire\17:HopLine<CR>\14<Leader>j\17:HopWord<CR>\14<Leader>l\6n\bset\vkeymap\bvim\0", "config", "hop.nvim")
time([[Config for hop.nvim]], false)
-- Config for: nvim-hlslens
time([[Config for nvim-hlslens]], true)
try_loadstring("\27LJ\2\nå\5\0\0\a\0\18\0:5\0\0\0006\1\1\0009\1\2\0019\1\3\1'\3\4\0'\4\4\0'\5\5\0\18\6\0\0B\1\5\0016\1\1\0009\1\2\0019\1\3\1'\3\4\0'\4\6\0'\5\a\0\18\6\0\0B\1\5\0016\1\1\0009\1\2\0019\1\3\1'\3\4\0'\4\b\0'\5\t\0\18\6\0\0B\1\5\0016\1\1\0009\1\2\0019\1\3\1'\3\4\0'\4\n\0'\5\v\0\18\6\0\0B\1\5\0016\1\1\0009\1\2\0019\1\3\1'\3\4\0'\4\f\0'\5\r\0\18\6\0\0B\1\5\0016\1\1\0009\1\2\0019\1\3\1'\3\4\0'\4\14\0'\5\15\0\18\6\0\0B\1\5\0016\1\1\0009\1\2\0019\1\3\1'\3\4\0'\4\16\0'\5\17\0\18\6\0\0B\1\5\1K\0\1\0\r:noh<CR>\14<Leader>l.g#<Cmd>lua require('hlslens').start()<CR>\ag#.g*<Cmd>lua require('hlslens').start()<CR>\ag*-#<Cmd>lua require('hlslens').start()<CR>\6#-*<Cmd>lua require('hlslens').start()<CR>\6*Y<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>\6NY<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>\6n\20nvim_set_keymap\bapi\bvim\1\0\2\fnoremap\2\vsilent\2\0", "config", "nvim-hlslens")
time([[Config for nvim-hlslens]], false)
-- Config for: nvim-scrollbar
time([[Config for nvim-scrollbar]], true)
try_loadstring("\27LJ\2\nâ\3\0\0\a\0\30\0/6\0\0\0'\2\1\0B\0\2\0029\0\2\0B\0\1\0026\1\0\0'\3\3\0B\1\2\0029\1\2\0015\3\a\0005\4\5\0009\5\4\0=\5\6\4=\4\b\0035\4\v\0005\5\n\0009\6\t\0=\6\6\5=\5\f\0045\5\14\0009\6\r\0=\6\6\5=\5\15\0045\5\17\0009\6\16\0=\6\6\5=\5\18\0045\5\20\0009\6\19\0=\6\6\5=\5\21\0045\5\23\0009\6\22\0=\6\6\5=\5\24\0045\5\26\0009\6\25\0=\6\6\5=\5\27\4=\4\28\3B\1\2\0016\1\0\0'\3\29\0B\1\2\0029\1\2\1B\1\1\1K\0\1\0\30scrollbar.handlers.search\nmarks\tMisc\1\0\0\vpurple\tHint\1\0\0\thint\tInfo\1\0\0\tinfo\tWarn\1\0\0\fwarning\nError\1\0\0\nerror\vSearch\1\0\0\1\0\0\vorange\vhandle\1\0\0\ncolor\1\0\0\17bg_highlight\14scrollbar\nsetup\22tokyonight.colors\frequire\0", "config", "nvim-scrollbar")
time([[Config for nvim-scrollbar]], false)
-- Config for: fuzzy-motion.vim
time([[Config for fuzzy-motion.vim]], true)
try_loadstring("\27LJ\2\nS\0\0\5\0\6\0\b6\0\0\0009\0\1\0009\0\2\0'\2\3\0'\3\4\0'\4\5\0B\0\4\1K\0\1\0\21:FuzzyMotion<CR>\14<leader>s\6n\bset\vkeymap\bvim\0", "config", "fuzzy-motion.vim")
time([[Config for fuzzy-motion.vim]], false)
-- Config for: lsp_signature.nvim
time([[Config for lsp_signature.nvim]], true)
try_loadstring("\27LJ\2\n¢\1\0\0\4\0\6\0\t6\0\0\0'\2\1\0B\0\2\0029\0\2\0005\2\3\0005\3\4\0=\3\5\2B\0\2\1K\0\1\0\17handler_opts\1\0\1\vborder\frounded\1\0\4\16hint_prefix\nüê∞ \16use_lspsaga\1\20floating_window\2\vzindex\0031\nsetup\18lsp_signature\frequire\0", "config", "lsp_signature.nvim")
time([[Config for lsp_signature.nvim]], false)
-- Config for: telescope.nvim
time([[Config for telescope.nvim]], true)
try_loadstring("\27LJ\2\nª\6\0\0\b\0(\0Z6\0\0\0009\0\1\0009\0\2\0'\2\3\0'\3\4\0006\4\5\0'\6\6\0B\4\2\0029\4\a\4B\0\4\0016\0\0\0009\0\1\0009\0\2\0'\2\3\0'\3\b\0006\4\5\0'\6\6\0B\4\2\0029\4\t\4B\0\4\0016\0\0\0009\0\1\0009\0\2\0'\2\3\0'\3\n\0006\4\5\0'\6\6\0B\4\2\0029\4\v\4B\0\4\0016\0\0\0009\0\1\0009\0\2\0'\2\3\0'\3\f\0006\4\5\0'\6\6\0B\4\2\0029\4\r\4B\0\4\0016\0\0\0009\0\1\0009\0\2\0'\2\3\0'\3\14\0006\4\5\0'\6\6\0B\4\2\0029\4\15\4B\0\4\0016\0\0\0009\0\1\0009\0\2\0'\2\3\0'\3\16\0006\4\5\0'\6\6\0B\4\2\0029\4\17\4B\0\4\0016\0\5\0'\2\18\0B\0\2\0026\1\5\0'\3\19\0B\1\2\0029\1\20\0015\3\"\0005\4\21\0005\5\22\0=\5\23\0045\5\31\0005\6\25\0009\a\24\0=\a\26\0069\a\27\0=\a\28\0069\a\24\0=\a\29\0069\a\27\0=\a\30\6=\6 \5=\5!\4=\4#\0035\4%\0005\5$\0=\5&\4=\4'\3B\1\2\1K\0\1\0\15extensions\bfzf\1\0\0\1\0\4\28override_generic_sorter\1\nfuzzy\2\14case_mode\15smart_case\25override_file_sorter\2\rdefaults\1\0\0\rmappings\6i\1\0\0\f<S-Tab>\n<Tab>\n<C-k>\28move_selection_previous\n<C-j>\1\0\0\24move_selection_next\18layout_config\1\0\1\20prompt_position\btop\1\0\2\20selection_caret\a> \21sorting_strategy\14ascending\nsetup\14telescope\22telescope.actions\16diagnostics\15<leader>tr\21lsp_code_actions\15<leader>ca\14live_grep\a,r\fbuffers\a,b\14git_files\a,g\15find_files\22telescope.builtin\frequire\a,f\6n\bset\vkeymap\bvim\0", "config", "telescope.nvim")
time([[Config for telescope.nvim]], false)
-- Config for: lualine.nvim
time([[Config for lualine.nvim]], true)
try_loadstring("\27LJ\2\n^\0\0\4\0\6\0\t5\0\0\0006\1\1\0'\3\2\0B\1\2\0029\1\3\0015\3\4\0=\0\5\3B\1\2\1K\0\1\0\foptions\1\0\0\nsetup\flualine\frequire\1\0\1\ntheme\rcodedark\0", "config", "lualine.nvim")
time([[Config for lualine.nvim]], false)
vim.cmd [[augroup packer_load_aucmds]]
vim.cmd [[au!]]
  -- Filetype lazy-loads
time([[Defining lazy-load filetype autocommands]], true)
vim.cmd [[au FileType vue ++once lua require("packer.load")({'emmet-vim', 'vim-vue'}, { ft = "vue" }, _G.packer_plugins)]]
time([[Defining lazy-load filetype autocommands]], false)
  -- Event lazy-loads
time([[Defining lazy-load event autocommands]], true)
vim.cmd [[au TextYankPost * ++once lua require("packer.load")({'vim-highlightedyank'}, { event = "TextYankPost *" }, _G.packer_plugins)]]
vim.cmd [[au InsertEnter * ++once lua require("packer.load")({'indentLine'}, { event = "InsertEnter *" }, _G.packer_plugins)]]
time([[Defining lazy-load event autocommands]], false)
vim.cmd("augroup END")
vim.cmd [[augroup filetypedetect]]
time([[Sourcing ftdetect script at: /Users/nomura/.local/share/nvim/site/pack/packer/opt/vim-vue/ftdetect/vue.vim]], true)
vim.cmd [[source /Users/nomura/.local/share/nvim/site/pack/packer/opt/vim-vue/ftdetect/vue.vim]]
time([[Sourcing ftdetect script at: /Users/nomura/.local/share/nvim/site/pack/packer/opt/vim-vue/ftdetect/vue.vim]], false)
vim.cmd("augroup END")
if should_profile then save_profiles() end

end)

if not no_errors then
  error_msg = error_msg:gsub('"', '\\"')
  vim.api.nvim_command('echohl ErrorMsg | echom "Error in packer_compiled: '..error_msg..'" | echom "Please check your config for correctness" | echohl None')
end
