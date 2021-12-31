local FuzzyMatcher = require("FuzzyMatcher")

local function extractBookmarks(items, path)
    if items == nil then return end
    local bookmarks = {}

    if items["children"] ~= nil then
        return extractBookmarks(items["children"], path)
    elseif items["type"] == "url" then
        bookmarks.text = hs.styledtext.new(path)
        bookmarks.subText = items["url"]
        return {bookmarks}
    else
        for _, v in pairs(items) do
            if type(v) == "table" then
                for _, item in pairs(extractBookmarks(v, path .. " / " ..
                                                          v["name"])) do
                    table.insert(bookmarks, item)
                end
            end
        end
        return bookmarks
    end
end

local function getBookmarks()
    local bookmarks = hs.json.read(
                          "~/Library/Application Support/Google/Chrome/Default/Bookmarks")
    return extractBookmarks(bookmarks["roots"]["bookmark_bar"]["children"], "")
end

-- [[
-- choose and open a bookmark
-- ]]
hs.hotkey.bind({"cmd"}, "b", function()
    local bookmarks = getBookmarks()
    local chooser = hs.chooser.new(function(choice)
        hs.urlevent.openURL(choice.subText)
    end):searchSubText(true)

    FuzzyMatcher.setChoices(bookmarks, chooser)
    chooser:queryChangedCallback(function()
        FuzzyMatcher.setChoices(bookmarks, chooser)
    end)
    chooser:show()
end)
