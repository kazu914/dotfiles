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
