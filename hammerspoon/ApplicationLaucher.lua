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
        local matched_idxs = FuzzyMatcher.fuzzyMatch(app.text:getString(),
                                                      query)
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

-- [[
-- choose and open an Application
-- ]]
hs.hotkey.bind({"cmd"}, "d", function()
    local choices = {}
    local list = hs.execute('ls /Applications')
    for token in string.gmatch(list, "[^\r\n]+") do
        table.insert(choices, {
            text = hs.styledtext.new(token),
            subText = "/Applications/" .. token
        })
    end

    local list = hs.execute('ls ~/Applications')
    for token in string.gmatch(list, "[^\r\n]+") do
        table.insert(choices, {
            text = hs.styledtext.new(token),
            subText = "~/Applications/" .. token
        })
    end

    local chooser = hs.chooser.new(function(choice)
        hs.application.launchOrFocus(choice.text:getString())
        hs.window.focusedWindow():maximize()
    end)

    local function generateChoices()
        local filtered_apps = filter(choices, chooser:query())
        chooser:choices(filtered_apps)
        chooser:refreshChoicesCallback(true)
    end

    chooser:choices(generateChoices)
    chooser:queryChangedCallback(generateChoices)
    chooser:show()
end)

