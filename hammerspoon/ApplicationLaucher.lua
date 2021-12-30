local FuzzyMatcher = require("FuzzyMatcher")

local function highlightMatched(text, matched_idxs)
    local new_text = hs.styledtext.new(text)
    for _, idx in pairs(matched_idxs) do
        new_text = new_text:setStyle({color = hs.drawing.color.red}, idx, idx)
    end
    return new_text
end

local function filter(choices, query)
    if string.len(query) == 0 then return choices end
    local filtered_apps = {}
    for _, app in pairs(choices) do
        local matched_idxs =
            FuzzyMatcher.fuzzyMatch(app.text:getString(), query)
        if #matched_idxs ~= 0 then
            local new_app = {
                text = highlightMatched(app.text:getString(), matched_idxs),
                subText = app.subText
            }
            table.insert(filtered_apps, new_app)
        end
    end
    return filtered_apps
end

local function getAppsInPath(path)
    local apps = {}
    local list = hs.execute('ls ' .. path)
    for token in string.gmatch(list, "[^\r\n]+") do
        table.insert(apps,
                     {text = hs.styledtext.new(token), subText = path .. token})
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

local function setChoices(apps, chooser)
    local filtered_apps = filter(apps, chooser:query())
    chooser:choices(filtered_apps)
    chooser:refreshChoicesCallback(true)
end

-- [[
-- choose and open an Application
-- ]]
hs.hotkey.bind({"cmd"}, "d", function()
    local apps = getApps()

    local chooser = hs.chooser.new(function(app)
        hs.application.launchOrFocus(app.text:getString())
        hs.window.focusedWindow():maximize()
    end)

    setChoices(apps, chooser)
    chooser:queryChangedCallback(function() setChoices(apps, chooser) end)
    chooser:show()
end)
