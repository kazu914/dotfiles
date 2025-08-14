-- THIS IS POC
-- 目的: フロントアプリごとのマクロをchooserで選び, そのキー入力を送信する

-- short aliases
local app   = hs.application
local et    = hs.eventtap
local timer = hs.timer
local alert = hs.alert

-- key helpers
local function ks(mods, key) et.keyStroke(mods or {}, key, 0) end
local function typeText(s) et.keyStrokes(s) end
local function sendSequence(seq, interval)
    interval = interval or 0.04
    for _, s in ipairs(seq) do
        if s.delay then
            timer.usleep(s.delay * 1e6)
        elseif s.text then
            typeText(s.text)
        elseif s.keys then
            ks(s.keys.mods or {}, s.keys.key)
        elseif s.mods and s.key then
            ks(s.mods, s.key)
        end
        timer.usleep(interval * 1e6)
    end
end

-- アプリ別マクロ定義, 優先順は bundleID > app名 > _default
local macros = {
    ["com.microsoft.VSCodeInsiders"] = {
        { title = "保存", hint = "Ctrl+S", keys = { mods = { "ctrl" }, key = "s" } },
        { title = "コマンドパレット", hint = "Shift+Cmd+P", keys = { mods = { "shift", "cmd" }, key = "p" } },
        { title = "整形", hint = "Shift+Alt+F", keys = { mods = { "shift", "alt" }, key = "f" } },
        {
            title = "検索置換例",
            hint = "Cmd+F 入力 Alt+Enter 入力",
            sequence = {
                { mods = { "cmd" }, key = "f" }, { text = "foo" }, { mods = { "alt" }, key = "return" }, { text = "bar" }
            }
        },
    },
    ["Safari"] = {
        { title = "アドレスバー", hint = "Cmd+L", keys = { mods = { "cmd" }, key = "l" } },
        { title = "新規タブ", hint = "Cmd+T", keys = { mods = { "cmd" }, key = "t" } },
    },
    _default = {
        { title = "コピー", hint = "Cmd+C", keys = { mods = { "cmd" }, key = "c" } },
        { title = "ペースト", hint = "Cmd+V", keys = { mods = { "cmd" }, key = "v" } },
    },
}

-- chooser本体
local lastApp = nil
local chooser = hs.chooser.new(function(choice)
    if not choice then return end
    local m = choice._macro
    if lastApp then lastApp:activate(true) end
    timer.doAfter(0.06, function()
        if m.action then
            m.action(lastApp)
        elseif m.sequence then
            sendSequence(m.sequence, m.interval)
        elseif m.keys then
            ks(m.keys.mods, m.keys.key)
        elseif m.text then
            typeText(m.text)
        else
            alert.show("no action")
        end
    end)
end)

chooser:width(30)

local function showMacroChooser()
    lastApp = app.frontmostApplication()
    if not lastApp then
        alert.show("front app not found")
        return
    end
    local id = lastApp:bundleID()
    print(id)
    local name = lastApp:name()
    local list = macros[id] or macros[name] or macros._default or {}
    if #list == 0 then
        alert.show("no macro for " .. (id or name or "?"))
        return
    end
    local choices = {}
    for i, m in ipairs(list) do
        choices[i] = { text = m.title or "macro", subText = m.hint or "", _macro = m }
    end
    chooser:choices(choices)
    chooser:show()
end

-- 任意ショートカットでchooserを開く
hs.hotkey.bind({ "ctrl", "alt" }, "m", showMacroChooser)

-- 初回ロード通知
hs.alert.show("macro chooser ready, Ctrl+Alt+M")
