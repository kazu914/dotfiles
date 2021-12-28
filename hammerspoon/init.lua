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
local switcher = hs.window.switcher.new()
switcher.ui.showSelectedThumbnail = false
switcher.ui.showThumbnails = false
hs.hotkey.bind('cmd','l',function()switcher:next()end,nil,function()switcher:next()end)
hs.hotkey.bind('cmd','h',function()switcher:previous()end,nil,function()switcher:previous()end)
