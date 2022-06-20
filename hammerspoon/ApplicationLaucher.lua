local FuzzyMatcher = require("FuzzyMatcher")

local function getAppsInPath(path)
    local apps = {}
    local list = hs.execute('ls ' .. path)
    for token in string.gmatch(list, "[^\r\n]+") do
        table.insert(apps, {
            text = hs.styledtext.new(token),
            subText = hs.styledtext.new(path .. token)
        })
    end
    return apps
end

local function getApps()
    local apps = {}
    for _, path in pairs({"/Applications", "~/Applications"}) do
        for _, app in pairs(getAppsInPath(path)) do
            table.insert(apps, app)
        end
    end
    return apps
end

local function sorter(a, b)
    return (string.len(a.text:getString()) < string.len(b.text:getString()))
end

-- [[
-- choose and open an Application
-- ]]
hs.hotkey.bind({"cmd", "shift"}, "d", function()
    local apps = getApps()

    local chooser = hs.chooser.new(function(app)
        hs.application.launchOrFocus(app.text:getString())
    end)

    FuzzyMatcher.setChoices(apps, chooser, true, sorter)
    chooser:queryChangedCallback(function()
        FuzzyMatcher.setChoices(apps, chooser, true, sorter)
    end)
    chooser:show()
end)

-- [[
-- choose and focus an existing window
-- ]]
hs.hotkey.bind({"cmd"}, "d", function()
    local choices = {}
    for _, window in ipairs(hs.window.allWindows()) do
        table.insert(choices,
                     {text = hs.styledtext.new(window:title()), subText = hs.styledtext.new(window:application():name())})
    end

    local chooser = hs.chooser.new(function(choice)
        hs.window.get(choice.text:getString()):focus()
    end)

    FuzzyMatcher.setChoices(choices, chooser, false, nil)
    chooser:queryChangedCallback(function()
        FuzzyMatcher.setChoices(choices, chooser, false, nil)
    end)
    chooser:show()
end)
