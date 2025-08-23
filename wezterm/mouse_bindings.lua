local wezterm = require 'wezterm'

local mouse_bindings = {
  {
    event = { Down = { streak = 1, button = "Left" } },
    mods = "NONE",
    action = wezterm.action { SelectTextAtMouseCursor = "Cell" }
  },
  {
    event = { Down = { streak = 2, button = "Left" } },
    mods = "NONE",
    action = wezterm.action { SelectTextAtMouseCursor = "Word" }
  },
  {
    event = { Down = { streak = 3, button = "Left" } },
    mods = "NONE",
    action = wezterm.action { SelectTextAtMouseCursor = "Line" }
  },
  {
    event = { Drag = { streak = 1, button = "Left" } },
    mods = "NONE",
    action = wezterm.action { ExtendSelectionToMouseCursor = "Cell" }
  },
  {
    event = { Drag = { streak = 2, button = "Left" } },
    mods = "NONE",
    action = wezterm.action { ExtendSelectionToMouseCursor = "Word" }
  },
  {
    event = { Drag = { streak = 3, button = "Left" } },
    mods = "NONE",
    action = wezterm.action { ExtendSelectionToMouseCursor = "Line" }
  },
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "NONE",
    action = wezterm.action {
      CompleteSelection = "ClipboardAndPrimarySelection"
    }
  },
  {
    event = { Up = { streak = 2, button = "Left" } },
    mods = "NONE",
    action = wezterm.action { CompleteSelection = "PrimarySelection" }
  },
  {
    event = { Up = { streak = 3, button = "Left" } },
    mods = "NONE",
    action = wezterm.action { CompleteSelection = "PrimarySelection" }
  },
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "SUPER",
    action = wezterm.action {
      CompleteSelectionOrOpenLinkAtMouseCursor = "ClipboardAndPrimarySelection"
    }
  }
}

return {
  mouse_bindings = mouse_bindings
}
