local wezterm = require 'wezterm'
local utils = require 'utils'
local is_linux = string.find(wezterm.target_triple, "linux") ~= nil

local function setup()
  wezterm.on("format-window-title", function(_, _)
    local active_ws = wezterm.mux.get_active_workspace()
    return "WezTerm - (" .. active_ws .. ")"
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
    local success
    local stdout
    if (is_linux) then
      -- pbpasteがないので何もしない
    else
      success, stdout = wezterm.run_child_process({ "pbpaste" })
    end

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
end
return {
  setup = setup
}
