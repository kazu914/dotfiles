local wezterm = require 'wezterm'
local key_bindings = require 'key_bindings'
local mouse_bindings = require 'mouse_bindings'
local ui_components = require 'ui_components'

ui_components.setup()

local config = {
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
  keys = key_bindings.key_bindings,
  mouse_bindings = mouse_bindings.mouse_bindings,
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

-- OSごとの設定分岐
if wezterm.target_triple == "x86_64-pc-windows-msvc" then
  -- Windowsの場合: WSLをデフォルトで起動
  config.default_prog = { "wsl.exe", "--distribution", "Ubuntu" }
end

return config
