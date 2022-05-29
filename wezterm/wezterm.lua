local wezterm = require 'wezterm'
local utils = require 'utils'

wezterm.on("update-right-status", function(window, pane)
    if pane:get_user_vars().color_scheme ~= nil then
        window:set_config_overrides({
            value = {color_scheme = pane:get_user_vars().color_scheme}
        })
    end

    local cells = {}

    -- divider
    local divider = {{Foreground = {AnsiColor = "White"}}, {Text = " | "}}

    -- Get Clipboard
    local success, stdout = wezterm.run_child_process({"pbpaste"})

    if (success) then
        local line = wezterm.split_by_newlines(stdout)
        local text = utils.concat_first_and_last_line(line)
        text = wezterm.truncate_right(text, 50)
        if #text == 50 then text = text .. " .." end

        local clipboard = {
            {Foreground = {AnsiColor = "Red"}},
            {Text = wezterm.nerdfonts.mdi_clipboard_outline .. " " .. text}
        }
        table.insert(cells, clipboard)
    end

    -- Date
    local date = {
        {Foreground = {AnsiColor = "Red"}}, {
            Text = wezterm.nerdfonts.mdi_clock .. " " ..
                wezterm.strftime("%Y-%m-%d (%a) %H:%M:%S")
        }
    }

    table.insert(cells, date)

    local elements = {}
    for index, cell in ipairs(cells) do
        for _, cell_item in ipairs(cell) do
            table.insert(elements, cell_item)
        end

        if index ~= #cells then
            for _, cell_item in ipairs(divider) do
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
        action = wezterm.action {SpawnTab = "CurrentPaneDomain"}
    }, {
        key = "x",
        mods = "LEADER",
        action = wezterm.action {CloseCurrentTab = {confirm = true}}
    }, {key = "[", mods = "LEADER", action = "ActivateCopyMode"},
    {key = "l", mods = "ALT", action = wezterm.action {ActivateTabRelative = 1}},
    {
        key = "h",
        mods = "ALT",
        action = wezterm.action {ActivateTabRelative = -1}
    },
    {key = "c", mods = "SUPER", action = wezterm.action {CopyTo = "Clipboard"}},
    {
        key = "v",
        mods = "SUPER",
        action = wezterm.action {PasteFrom = "Clipboard"}
    }
}

local mouse_bindings = {
    {
        event = {Down = {streak = 1, button = "Left"}},
        mods = "NONE",
        action = wezterm.action {SelectTextAtMouseCursor = "Cell"}
    }, {
        event = {Down = {streak = 2, button = "Left"}},
        mods = "NONE",
        action = wezterm.action {SelectTextAtMouseCursor = "Word"}
    }, {
        event = {Down = {streak = 3, button = "Left"}},
        mods = "NONE",
        action = wezterm.action {SelectTextAtMouseCursor = "Line"}
    }, {
        event = {Drag = {streak = 1, button = "Left"}},
        mods = "NONE",
        action = wezterm.action {ExtendSelectionToMouseCursor = "Cell"}
    }, {
        event = {Drag = {streak = 2, button = "Left"}},
        mods = "NONE",
        action = wezterm.action {ExtendSelectionToMouseCursor = "Word"}
    }, {
        event = {Drag = {streak = 3, button = "Left"}},
        mods = "NONE",
        action = wezterm.action {ExtendSelectionToMouseCursor = "Line"}
    }, {
        event = {Up = {streak = 1, button = "Left"}},
        mods = "NONE",
        action = wezterm.action {
            CompleteSelection = "ClipboardAndPrimarySelection"
        }
    }, {
        event = {Up = {streak = 2, button = "Left"}},
        mods = "NONE",
        action = wezterm.action {CompleteSelection = "PrimarySelection"}
    }, {
        event = {Up = {streak = 3, button = "Left"}},
        mods = "NONE",
        action = wezterm.action {CompleteSelection = "PrimarySelection"}
    }, {
        event = {Up = {streak = 1, button = "Left"}},
        mods = "SUPER",
        action = wezterm.action {
            CompleteSelectionOrOpenLinkAtMouseCursor = "ClipboardAndPrimarySelection"
        }
    }
}

return {
    -- UI
    font_size = 13.0,
    font = wezterm.font("HackGen35Nerd Console", {
        style = "Normal"
    }),
    font_rules = {
        -- Disable Italic
        {
            italic = true,
            font = wezterm.font("HackGen35Nerd Console", {
                italic = false
            })
        }
    },
    adjust_window_size_when_changing_font_size = false,
    tab_bar_at_bottom = true,
    color_scheme = "Andromeda",
    window_frame = {
        font_size = 13.0,
        font = wezterm.font("HackGen35Nerd Console", {
            weight = "Bold",
            stretch = "Normal",
            style = "Normal"
        })
    },
    window_padding = {left = 0, right = 0, top = 0, bottom = 0},
    -- Bindings
    disable_default_key_bindings = true,
    disable_default_mouse_bindings = true,
    leader = {key = "s", mods = "CTRL", timeout_milliseconds = 1000},
    keys = key_bindings,
    mouse_bindings = mouse_bindings,
    -- Others
    use_ime = true,
    skip_close_confirmation_for_processes_named = {''},
    exit_behavior = 'Close'
}
