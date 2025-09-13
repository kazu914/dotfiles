local wezterm = require 'wezterm'
local is_linux = string.find(wezterm.target_triple, "linux") ~= nil
local workspace_management = require("workspace_management")

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
    action = wezterm.action_callback(workspace_management.create_or_switch_new),
  },
  {
    mods = 'LEADER',
    key = 's',
    action = wezterm.action_callback(workspace_management.switch_to_workspace),
  },
}

if is_linux then
  table.insert(key_bindings,
    {
      key = 'V',
      mods = 'CTRL',
      action = wezterm.action.PasteFrom 'Clipboard'
    }
  )
end


return {
  key_bindings = key_bindings
}
