local wezterm = require 'wezterm'
local utils = require 'utils'
local M = {}
local function load_local_workspaces()
  if utils.file_exists("local_workspaces") then
    return require("local_workspaces")
  end
  return {}
end

M.create_or_switch_new = function(_, pane)
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
end

M.switch_to_workspace = function(win, pane)
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

  local local_workspaces = load_local_workspaces()
  wezterm.log_info(local_workspaces)

  for _, workspace in pairs(local_workspaces) do
    if not utils.table_contains(workspace_names, workspace) then
      table.insert(workspaces, {
        id = workspace,
        label = wezterm.format {
          { Background = { Color = "#79a6d2" } },
          { Foreground = { Color = '#383a42' } },
          { Text = string.format("%7d: %s", count, workspace) }
        },
      })
      count = count + 1
    end
  end

  -- 選択メニューを起動
  win:perform_action(wezterm.action.InputSelector {
    action = wezterm.action_callback(function(_, _, id, label)
      if not id and not label then
        wezterm.log_info "Workspace selection canceled" -- 入力が空ならキャンセル
      else
        if utils.table_contains(workspace_names, id) then
          -- すでに存在するworkspaceならそのまま移動
          win:perform_action(wezterm.action.SwitchToWorkspace { name = id }, pane) -- workspace を移動
        else
          -- ワークスペースを作成し、ウィンドウを起動
          wezterm.mux.spawn_window { workspace = id, cwd = id }
          win:perform_action(wezterm.action.SwitchToWorkspace { name = id }, pane) -- workspace を移動
        end
      end
    end),
    title = "Select workspace",
    choices = workspaces,
    fuzzy = true,
  }, pane)
end

return M
