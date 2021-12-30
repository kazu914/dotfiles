local FuzzyMatcher = require("FuzzyMatcher")

-- [[
-- choose and open an Application
-- ]]
hs.hotkey.bind({"cmd"}, "d", function()
    local choices = {}
    local list = hs.execute('ls /Applications')
    for token in string.gmatch(list, "[^\r\n]+") do
        table.insert(choices,
                     {text = token, subText = "~/Applications/" .. token})
    end

    local list = hs.execute('ls ~/Applications')
    for token in string.gmatch(list, "[^\r\n]+") do
        table.insert(choices,
                     {text = token, subText = "~/Applications/" .. token})
    end

    local chooser = hs.chooser.new(function(choice)
        hs.application.launchOrFocus(choice.text)
        hs.window.focusedWindow():maximize()
    end)

    local function fillter(query)
        local results = {}
        for k, v in pairs(choices) do
            if FuzzyMatcher.fuzzy_match(v.text, query) then
                table.insert(results, v)
            end
        end
        return results
    end

    local function queryChangedCallback()
        local query = chooser:query()
        for _, v in pairs(choices) do
            for t, y in pairs(v) do print(t, y) end
        end
        local results = fillter(query)
        for _, v in pairs(results) do
            for t, y in pairs(v) do print(t, y) end
        end
        chooser:choices(results)
        chooser:refreshChoicesCallback(true)
    end

    chooser:choices(choices)
    chooser:queryChangedCallback(queryChangedCallback)
    chooser:show()
end)

