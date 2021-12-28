hs.hotkey.bind({"cmd"}, "space", function()
  local alacritty = hs.application.find('alacritty')
  if alacritty:isFrontmost() then
    alacritty:hide()
  else
    hs.application.launchOrFocus("/Applications/Alacritty.app")
  end
end)

hs.hotkey.bind({"cmd"}, "t", function()
  local teams = hs.application.find('teams')
  if teams:isFrontmost() then
    teams:hide()
  else
    hs.application.launchOrFocus("/Applications/Microsoft Teams.app")
  end
end)

hs.hotkey.bind({"cmd"}, "g", function()
  local chrome = hs.application.find('chrome')
  if chrome:isFrontmost() then
    chrome:hide()
  else
    hs.application.launchOrFocus("/Applications/Google Chrome.app")
  end
end)


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
  end)
  chooser:choices(choices)
  chooser:show()
end)

-- Window Switcher
local switcher = hs.window.switcher.new(hs.window.filter.new():setSortOrder(hs.window.filter.sortByCreated):setDefaultFilter{})
switcher.ui.showSelectedThumbnail = false
switcher.ui.showThumbnails = false
hs.hotkey.bind('cmd','l',function()switcher:next()end,nil,function()switcher:next()end)
hs.hotkey.bind('cmd','h',function()switcher:previous()end,nil,function()switcher:previous()end)


-- Bookmark Opener
hs.hotkey.bind({"cmd"}, "b", function()
  local bookmarks = hs.json.read("~/Library/Application Support/Google/Chrome/Default/Bookmarks")
  local choices = extract_bookmarks(bookmarks["roots"]["bookmark_bar"]["children"])
  local chooser = hs.chooser.new(function (choice)
    hs.urlevent.openURL(choice.subText)
  end)
  chooser:choices(choices)
  chooser:show()
end)

function extract_bookmarks(items)
  if items == nil then
    return
  end
  local bookmarks = {}

  if items["children"] ~= nil then
    return extract_bookmarks(items["children"])
  elseif items["type"] == "url" then
    bookmarks.text = items["name"]
    bookmarks.subText = items["url"]
    return { bookmarks }
  else
    for _,v in pairs(items)do
      if type(v) == "table" then
        for _, item in pairs(extract_bookmarks(v))do
          table.insert(bookmarks,item)
        end
      end
    end
    return bookmarks
  end
end
