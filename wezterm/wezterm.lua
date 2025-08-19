local wezterm = require 'wezterm'
local utils = require 'utils'

wezterm.on("format-window-title", function(_, pane)
  local is_linux = string.find(wezterm.target_triple, "linux") ~= nil
  if is_linux then
    return "WezTerm"
  end

  local title = pane.title
  if pane.domain_name then
    title = title .. ' - (' .. pane.domain_name .. ')'
  end
  return title
end)

local function tab_title(tab_info)
  local title = tab_info.tab_title
  -- if the tab title is explicitly set, take that
  if title and #title > 0 then
    return title
  end
  -- Otherwise, use the title from the active pane
  -- in that tab
  return tab_info.active_pane.title
end

local color = {
  blue = '#32b9ff',
  black = '#383a42',
  white = '#f3f3f3',
  yellow = '#ffea00',
  red = '#D2042D',
  dark_purple = '#0b0022',
  green_blue = '#005c78',
  dark_green_blue = '#00394a',
  gray = '#909090'
}

local DIVIDER_LEFT = wezterm.nerdfonts.ple_pixelated_squares_big_mirrored .. ' '
local DIVIDER_RIGHT = wezterm.nerdfonts.ple_pixelated_squares_big
wezterm.on(
  'format-tab-title',
  function(tab, _, _, _, hover, max_width)
    local title = wezterm.truncate_right(tab_title(tab), max_width - 5)
    title = utils.padding_with_spaces(title, max_width - 5)
    local edge_background = color.dark_purple
    local background = color.dark_green_blue
    local foreground = color.white

    if tab.is_active then
      background = color.blue
      foreground = color.black
    elseif hover then
      background = color.green_blue
      foreground = color.gray
    end

    local edge_foreground = background
    return {
      { Background = { Color = edge_background } },
      { Foreground = { Color = edge_foreground } },
      { Text = DIVIDER_LEFT },
      { Background = { Color = background } },
      { Foreground = { Color = foreground } },
      { Text = ' ' .. title .. ' ' },
      { Background = { Color = edge_background } },
      { Foreground = { Color = edge_foreground } },
      { Text = DIVIDER_RIGHT },
    }
  end
)

wezterm.on("update-status", function(window, pane)
  if pane:get_user_vars().color_scheme ~= nil then
    window:set_config_overrides({
      value = { color_scheme = pane:get_user_vars().color_scheme }
    })
  end

  local cells = {}

  -- divider
  local divider = { { Foreground = { Color = color.white } },
    { Text = ' ' .. wezterm.nerdfonts.md_drag_vertical .. ' ' } }

  -- trailing space
  local ts = { { Foreground = { Color = color.blue } }, { Text = " " } }

  -- Get Clipboard
  local success, stdout = wezterm.run_child_process({ "pbpaste" })

  if (success) then
    local line = wezterm.split_by_newlines(stdout)
    local text = utils.concat_first_and_last_line(line)
    text = wezterm.truncate_right(text, 50)
    if #text == 50 then text = text .. " .." end

    local clipboard = {
      { Foreground = { Color = color.blue } },
      { Text = wezterm.nerdfonts.md_clipboard_outline .. " " .. text }
    }
    local lines = {
      { Foreground = { Color = #line == 1 and color.blue or color.yellow } },
      { Text = tostring(#line) }
    }
    table.insert(cells, clipboard)
    table.insert(cells, lines)
  end

  -- Date
  local date = {
    { Foreground = { Color = color.blue } }, {
    Text = wezterm.nerdfonts.md_clock .. " " ..
        wezterm.strftime("%Y-%m-%d (%A) %H:%M:%S")
  }
  }

  table.insert(cells, date)

  -- Leader
  if window:leader_is_active() then
    local leader = { { Foreground = { Color = color.red } }, { Text = "LEADER" } }
    table.insert(cells, leader)
  else
    local leader = { { Foreground = { Color = color.blue } }, { Text = "NORMAL" } }
    table.insert(cells, leader)
  end

  local elements = {}
  for index, cell in ipairs(cells) do
    for _, cell_item in ipairs(cell) do
      table.insert(elements, cell_item)
    end

    if index ~= #cells then
      for _, cell_item in ipairs(divider) do
        table.insert(elements, cell_item)
      end
    else
      for _, cell_item in ipairs(ts) do
        table.insert(elements, cell_item)
      end
    end
  end

  window:set_right_status(wezterm.format(elements));
end)

local key_bindings = {
  {
    key = "c",
    mods = "LEADER",
    action = wezterm.action { SpawnTab = "CurrentPaneDomain" }
  },
  {
    key = "|",
    mods = "LEADER",
    action = wezterm.action { SplitHorizontal = {} }
  },
  {
    key = "j",
    mods = "ALT",
    action = wezterm.action { ActivatePaneDirection = "Left" }
  },
  {
    key = "k",
    mods = "ALT",
    action = wezterm.action { ActivatePaneDirection = "Right" }
  },
  {
    key = "x",
    mods = "LEADER",
    action = wezterm.action { CloseCurrentTab = { confirm = true } }
  },
  {
    key = "[",
    mods = "LEADER",
    action = "ActivateCopyMode"
  },
  {
    key = "l",
    mods = "ALT",
    action = wezterm.action { ActivateTabRelative = 1 }
  },
  {
    key = "h",
    mods = "ALT",
    action = wezterm.action { ActivateTabRelative = -1 }
  },
  {
    key = "l",
    mods = "ALT | SHIFT",
    action = wezterm.action { MoveTabRelative = 1 }
  },
  {
    key = "h",
    mods = "ALT | SHIFT",
    action = wezterm.action { MoveTabRelative = -1 }
  },
  {
    key = "c",
    mods = "SUPER",
    action = wezterm.action { CopyTo = "Clipboard" }
  },
  {
    key = "v",
    mods = "SUPER",
    action = wezterm.action { PasteFrom = "Clipboard" }
  },
  {
    key = ',',
    mods = 'LEADER',
    action = wezterm.action.PromptInputLine {
      description = 'Enter new name for tab',
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          window:active_tab():set_title(line)
        end
      end),
    },
  },
  {
    key = "n",
    mods = "LEADER",
    action = wezterm.action_callback(function(window, pane)
      local cwd = pane:get_current_working_dir()
      local cwd_path = nil
      if cwd then
        cwd_path = cwd.file_path or cwd.windows_path
      end
      local workspace = cwd_path or "cwd-unknown"
      local mux = wezterm.mux
      mux.spawn_window { workspace = workspace, cwd = cwd }
      mux.set_active_workspace(workspace)
    end),
  },
  {
    mods = 'LEADER',
    key = 's',
    action = wezterm.action_callback(function(win, pane)
      -- workspace のリストを作成
      local workspaces = {}
      for i, name in ipairs(wezterm.mux.get_workspace_names()) do
        table.insert(workspaces, {
          id = name,
          label = string.format("%d. %s", i, name),
        })
      end
      local current = wezterm.mux.get_active_workspace()
      -- 選択メニューを起動
      win:perform_action(wezterm.action.InputSelector {
        action = wezterm.action_callback(function(_, _, id, label)
          if not id and not label then
            wezterm.log_info "Workspace selection canceled"                          -- 入力が空ならキャンセル
          else
            win:perform_action(wezterm.action.SwitchToWorkspace { name = id }, pane) -- workspace を移動
          end
        end),
        title = "Select workspace",
        choices = workspaces,
        fuzzy = true,
      }, pane)
    end),
  },
}

local mouse_bindings = {
  {
    event = { Down = { streak = 1, button = "Left" } },
    mods = "NONE",
    action = wezterm.action { SelectTextAtMouseCursor = "Cell" }
  }, {
  event = { Down = { streak = 2, button = "Left" } },
  mods = "NONE",
  action = wezterm.action { SelectTextAtMouseCursor = "Word" }
}, {
  event = { Down = { streak = 3, button = "Left" } },
  mods = "NONE",
  action = wezterm.action { SelectTextAtMouseCursor = "Line" }
}, {
  event = { Drag = { streak = 1, button = "Left" } },
  mods = "NONE",
  action = wezterm.action { ExtendSelectionToMouseCursor = "Cell" }
}, {
  event = { Drag = { streak = 2, button = "Left" } },
  mods = "NONE",
  action = wezterm.action { ExtendSelectionToMouseCursor = "Word" }
}, {
  event = { Drag = { streak = 3, button = "Left" } },
  mods = "NONE",
  action = wezterm.action { ExtendSelectionToMouseCursor = "Line" }
}, {
  event = { Up = { streak = 1, button = "Left" } },
  mods = "NONE",
  action = wezterm.action {
    CompleteSelection = "ClipboardAndPrimarySelection"
  }
}, {
  event = { Up = { streak = 2, button = "Left" } },
  mods = "NONE",
  action = wezterm.action { CompleteSelection = "PrimarySelection" }
}, {
  event = { Up = { streak = 3, button = "Left" } },
  mods = "NONE",
  action = wezterm.action { CompleteSelection = "PrimarySelection" }
}, {
  event = { Up = { streak = 1, button = "Left" } },
  mods = "SUPER",
  action = wezterm.action {
    CompleteSelectionOrOpenLinkAtMouseCursor = "ClipboardAndPrimarySelection"
  }
}
}

return {
  -- UI
  font_size = 13.0,
  font = wezterm.font("HackGen35 Console NF", { style = "Normal" }),
  font_rules = {
    -- Disable Italic
    {
      italic = true,
      font = wezterm.font("HackGen35 Console NF", { italic = false })
    }
  },
  adjust_window_size_when_changing_font_size = false,
  tab_bar_at_bottom = true,
  window_frame = {
    font_size = 13.0,
    font = wezterm.font("HackGen35 Console NF", {
      weight = "Bold",
      stretch = "Normal",
      style = "Normal"
    })
  },
  color_scheme = "Catppuccin Macchiato",
  window_padding = { left = 0, right = 0, top = 0, bottom = 0 },
  -- Bindings
  disable_default_key_bindings = true,
  disable_default_mouse_bindings = false,
  leader = { key = "s", mods = "CTRL", timeout_milliseconds = 1000 },
  keys = key_bindings,
  mouse_bindings = mouse_bindings,
  -- Others
  use_ime = true,
  skip_close_confirmation_for_processes_named = { '' },
  exit_behavior = 'Close',
  use_fancy_tab_bar = false,
  visual_bell = {
    fade_in_function = 'EaseIn',
    fade_in_duration_ms = 20,
    fade_out_function = 'EaseOut',
    fade_out_duration_ms = 20,
  },
}
