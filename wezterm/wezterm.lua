local wezterm = require 'wezterm'
local utils = require 'utils'

wezterm.on("update-right-status", function(window)
    -- Get Clipboard
    local success, stdout = wezterm.run_child_process({
        "pbpaste", "|", "cut", "-c1-40"
    })

    local clipboard = {
        {Attribute = {Underline = "Single"}}, {Attribute = {Italic = true}},
        {Text = stdout}
    }

    -- Date
    local date = {
        {Attribute = {Underline = "Single"}}, {Attribute = {Italic = true}},
        {Text = wezterm.strftime("%Y-%m-%d (%a) %H:%M:%S")}
    }

    local elements = utils.merge_tables(clipboard, date)

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
    },
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
    font_size = 13,
    font = wezterm.font("HackGen35Nerd Console", {
        weight = "Regular",
        stretch = "Normal",
        style = "Normal"
    }),
    adjust_window_size_when_changing_font_size = false,
    tab_bar_at_bottom = true,
    -- Bindings
    disable_default_key_bindings = true,
    disable_default_mouse_bindings = true,
    leader = {key = "s", mods = "CTRL", timeout_milliseconds = 1000},
    keys = key_bindings,
    mouse_bindings = mouse_bindings,
    -- Others
    use_ime = true,
    skip_close_confirmation_for_processes_named = {''}
}
