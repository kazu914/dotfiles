dofile("WindowManager.lua")
dofile("ApplicationLaucher.lua")
dofile("BookmarkOpener.lua")
dofile("TodoManager.lua")

local function openApp(app, path)
    local application = hs.application.find(app)
    if application ~= nil and application:isFrontmost() then
        application:hide()
    else
        hs.application.launchOrFocus(path)
    end
end

-- [[
-- open alacritty
-- ]]
hs.hotkey.bind({"cmd"}, "space", function()
    openApp('kitty', '/Applications/Kitty.app')
end)

-- [[
-- open teams
-- ]]
hs.hotkey.bind({"cmd"}, "t", function()
    openApp('teams', '/Applications/Microsoft Teams.app')
end)

-- [[
-- open google chrome
-- ]]
hs.hotkey.bind({"cmd"}, "g", function()
    openApp("chrome", "/Applications/Sidekick.app")
end)
