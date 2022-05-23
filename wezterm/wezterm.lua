local wezterm = require 'wezterm'

wezterm.on("update-right-status", function(window, pane)
    local date = wezterm.strftime("%Y-%m-%d (%a) %H:%M:%S");
    local success, stdout, stderr = wezterm.run_child_process({
        "pbpaste", "|", "cut", "-c1-40"
    })
    window:set_right_status(wezterm.format({
        {Attribute = {Underline = "Single"}}, {Attribute = {Italic = true}},
        {Text = stdout .. " |  " .. date}
    }));
end)

return {
    use_ime = true,
    font = wezterm.font("HackGenNerd Console", {
        weight = "Regular",
        stretch = "Normal",
        italic = false
    }),
    font_size = 13,
    adjust_window_size_when_changing_font_size = false,
    disable_default_key_bindings = true,
    tab_bar_at_bottom = true
}
