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
hs.hotkey.bind({"cmd"}, "space",
               function() openApp('alacritty', '/Applications/Alacritty.app') end)

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
    openApp("chrome", "/Applications/Google Chrome.app")
end)

hs.hotkey.bind({"ctrl"}, "m", function()
    hs.eventtap.keyStroke(nil, hs.keycodes.map["return"], 0)
end)

local function file_exists(name)
  local f = io.open(name, "r")
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

if file_exists("local.lua") then
  dofile("local.lua")
end
