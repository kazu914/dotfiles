-- [[
-- move focused window to previous mointor
-- ]]
hs.hotkey.bind({'shift', 'cmd'}, 'h', function()
    local win = hs.window.focusedWindow()
    local screens = hs.screen.allScreens()
    if #screens ~= 1 then
        local screen = win:screen()
        win:move(win:frame():toUnitRect(screen:frame()), screen:previous(),
                 true, 0)
    else
        win:moveToUnit(hs.layout.left50)
    end
end)

-- [[
-- move focused window to next mointor
-- ]]
hs.hotkey.bind({'shift', 'cmd'}, 'l', function()
    local win = hs.window.focusedWindow()
    local screens = hs.screen.allScreens()
    if #screens ~= 1 then
        local screen = win:screen()
        win:move(win:frame():toUnitRect(screen:frame()), screen:next(), true, 0)
    else
        win:moveToUnit(hs.layout.right50)
    end
end)

-- [[
-- focuse next window
-- ]]
hs.hotkey.bind({'cmd'}, 'l', function()
    local allWindows = hs.window.allWindows()
    local focusedWindow = hs.window.focusedWindow()
    for k, v in pairs(allWindows) do
        if v == focusedWindow then
            if k == #allWindows then
                allWindows[1]:focus()
            else
                allWindows[k + 1]:focus()
            end
        end
    end
end)

-- [[
-- focuse previous window
-- ]]
hs.hotkey.bind({'cmd'}, 'h', function()
    local allWindows = hs.window.allWindows()
    local focusedWindow = hs.window.focusedWindow()
    for k, v in pairs(allWindows) do
        if v == focusedWindow then
            if k == 1 then
                allWindows[#allWindows]:focus()
            else
                allWindows[k - 1]:focus()
            end
        end
    end
end)

-- [[
-- maximize focused window
-- ]]
hs.hotkey.bind({'shift', 'cmd'}, 'f', function()
    local win = hs.window.focusedWindow()
    win:moveToUnit(hs.layout.maximized)
end)

-- [[
-- centerize focused window
-- ]]
hs.hotkey.bind({'shift', 'cmd'}, 'c', function()
    local win = hs.window.focusedWindow()
    win:moveToUnit(hs.geometry(0.25, 0, 0.5, 1))
end)
