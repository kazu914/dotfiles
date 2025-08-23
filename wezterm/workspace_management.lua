local wezterm = require 'wezterm'
local utils = require 'utils'
local M = {}
local function load_local_workspaces()
  if utils.file_exists("local_workspaces") then
    return require("local_workspaces")
  end
  return {}
end

M.create_or_switch_new = function(win, pane)
  -- 現在の作業ディレクトリを取得
  local cwd = pane:get_current_working_dir()
  local workspace_name = cwd.file_path

  win:perform_action(wezterm.action.SwitchToWorkspace { name = workspace_name,
    spawn = {
      cwd = workspace_name
    }
  }, pane)
end

M.switch_to_workspace = function(win, pane)
  local current_workspace = wezterm.mux.get_active_workspace()
  -- workspace のリストを作成
  local workspaces        = {}

  if current_workspace ~= "" then
    table.insert(workspaces, {
      id    = current_workspace,
      label = wezterm.format {
        { Background = { Color = "#80d4ff" } },
        { Foreground = { Color = '#383a42' } },
        { Text = "current: " },
        { Text = current_workspace }
      },
    })
  end

  if current_workspace ~= 'default' then
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
    if name == current_workspace or name == "default" then
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
        win:perform_action(wezterm.action.SwitchToWorkspace { name = id,
          spawn = { cwd = id }
        }, pane)
      end
    end),
    title = "Select workspace",
    choices = workspaces,
    fuzzy = true,
  }, pane)
end

return M
