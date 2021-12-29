-- [[
-- open alacritty
-- ]]
hs.hotkey.bind({"cmd"}, "space", function()
  local alacritty = hs.application.find('alacritty')
  if alacritty:isFrontmost() then
    alacritty:hide()
  else
    hs.application.launchOrFocus("/Applications/Alacritty.app")
  end
end)

-- [[
-- open teams
-- ]]
hs.hotkey.bind({"cmd"}, "t", function()
  local teams = hs.application.find('teams')
  if teams:isFrontmost() then
    teams:hide()
  else
    hs.application.launchOrFocus("/Applications/Microsoft Teams.app")
  end
end)

-- [[
-- open google chrome
-- ]]
hs.hotkey.bind({"cmd"}, "g", function()
  local chrome = hs.application.find('chrome')
  if chrome:isFrontmost() then
    chrome:hide()
  else
    hs.application.launchOrFocus("/Applications/Google Chrome.app")
  end
end)

-- [[
-- choose and open an Application
-- ]]
hs.hotkey.bind({"cmd"}, "d", function()
  local choices = {}
  local list = hs.execute('ls /Applications')
  for token in string.gmatch(list, "[^\r\n]+") do
    table.insert(choices,{
      text = token,
      subText = "/Applications/"..token,
    })
  end

  local list = hs.execute('ls ~/Applications')
  for token in string.gmatch(list, "[^\r\n]+") do
    table.insert(choices,{
      text = token,
      subText = "~/Applications/"..token,
    })
  end

  local chooser = hs.chooser.new(function (choice)
    hs.application.launchOrFocus(choice.text)
    hs.window.focusedWindow():maximize()
  end)
  chooser:choices(choices)
  chooser:show()
end)

-- [[
-- choose and open a bookmark
-- ]]
hs.hotkey.bind({"cmd"}, "b", function()
  local bookmarks = hs.json.read("~/Library/Application Support/Google/Chrome/Default/Bookmarks")
  local choices = extract_bookmarks(bookmarks["roots"]["bookmark_bar"]["children"], "")
  local chooser = hs.chooser.new(function (choice)
    hs.urlevent.openURL(choice.subText)
  end):searchSubText(true)
  chooser:choices(choices)
  chooser:show()
end)

function extract_bookmarks(items,path)
  if items == nil then
    return
  end
  local bookmarks = {}

  if items["children"] ~= nil then
    return extract_bookmarks(items["children"], path)
  elseif items["type"] == "url" then
    bookmarks.text = path
    bookmarks.subText = items["url"]
    return { bookmarks }
  else
    for _,v in pairs(items)do
      if type(v) == "table" then
        for _, item in pairs(extract_bookmarks(v, path.." / "..v["name"]))do
          table.insert(bookmarks,item)
        end
      end
    end
    return bookmarks
  end
end

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


