local wezterm = require 'wezterm'
local is_linux = string.find(wezterm.target_triple, "linux") ~= nil

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
      action = wezterm.action_callback(function(window, _, line)
        if line then
          window:active_tab():set_title(line)
        end
      end),
    },
  },
  {
    key = "n",
    mods = "LEADER",
    action = wezterm.action_callback(function(_, pane)
      -- 現在の作業ディレクトリを取得
      local cwd = pane:get_current_working_dir()
      local cwd_path = nil
      if cwd then
        cwd_path = cwd.file_path or cwd.windows_path
      end

      -- ワークスペース名を決定（unknown なら "cwd-unknown"）
      local workspace = cwd_path or "cwd-unknown"

      local mux = wezterm.mux

      -- 既に同名のワークスペースがあるか確認
      local exists = false
      for _, name in ipairs(mux.get_workspace_names()) do
        if name == workspace then
          exists = true
          break
        end
      end

      if exists then
        -- 既存ワークスペースへ切り替え
        mux.set_active_workspace(workspace)
      else
        -- ワークスペースを作成し、ウィンドウを起動
        mux.spawn_window { workspace = workspace, cwd = cwd_path }
        mux.set_active_workspace(workspace)
      end
    end),
  },
  {
    mods = 'LEADER',
    key = 's',
    action = wezterm.action_callback(function(win, pane)
      local active_ws  = wezterm.mux.get_active_workspace()
      -- workspace のリストを作成
      local workspaces = {}

      if active_ws ~= "" then
        table.insert(workspaces, {
          id    = active_ws,
          label = wezterm.format {
            { Background = { Color = "#80d4ff" } },
            { Foreground = { Color = '#383a42' } },
            { Text = "current: " },
            { Text = active_ws }
          },
        })
      end

      if active_ws ~= 'default' then
        table.insert(workspaces, {
          id = "default",
          label = wezterm.format {
            { Background = { Color = "#ffff99" } },
            { Foreground = { Color = '#383a42' } },
            { Text = "default: " },
            { Text = wezterm.home_dir }
          },
        })
      end

      local count = 1;
      local workspace_names = wezterm.mux.get_workspace_names()
      for _, name in pairs(workspace_names) do
        if name == active_ws or name == "default" then
          goto continue
        end
        table.insert(workspaces, {
          id = name,
          label = string.format("%7d: %s", count, name),
        })
        count = count + 1
        ::continue::
      end

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

if is_linux then
  table.insert(key_bindings,
    { key = 'v', mods = 'CTRL', action = wezterm.action.PasteFrom 'Clipboard' }
  )
end


return {
  key_bindings = key_bindings
}
