  -- [[
  -- move focused window to previous mointor
  -- ]]
  hs.hotkey.bind({'shift', 'cmd'}, 'h', function()
    local win = hs.window.focusedWindow()
    local screen = win:screen()
    win:move(win:frame():toUnitRect(screen:frame()), screen:previous(), true, 0)
  end)

  -- [[
  -- move focused window to next mointor
  -- ]]
  hs.hotkey.bind({'shift', 'cmd'}, 'l', function()
    local win = hs.window.focusedWindow()
    local screen = win:screen()
    win:move(win:frame():toUnitRect(screen:frame()), screen:next(), true, 0)
  end)

  -- [[
  -- focuse next window
  -- ]]
  hs.hotkey.bind({'cmd'}, 'l', function()
    local allWindows = hs.window.allWindows()
    local focusedWindow = hs.window.focusedWindow()
    for k,v in pairs(allWindows)do
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
    for k,v in pairs(allWindows)do
      if v == focusedWindow then
        if k == 1 then
          allWindows[#allWindows]:focus()
        else
          allWindows[k-1]:focus()
        end
      end
    end
  end)

