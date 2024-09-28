local FuzzyMatcher = require("FuzzyMatcher")

function killVSCode()
    local vscode = hs.application.find("Code")
    if vscode then
        vscode:kill()
    end
end

-- [[
-- switch workspace
-- ]]
hs.hotkey.bind({ "cmd", "shift" }, "space", function()
    local task_list = hs.execute("find ~/.workspace -name '*.code-workspace'")
    if (task_list == "") then
        hs.alert.show("No Tasks!!!!")
        return
    end
    local tasks = {}

    for task in string.gmatch(task_list, "[^\n]+") do
        table.insert(tasks, { text = hs.styledtext.new(task), subText = "" })
    end

    local chooser = hs.chooser.new(function(task)
        if task == nil then return end
        killVSCode()
        hs.execute("/opt/homebrew/bin/code " .. task.text:getString())
    end)

    FuzzyMatcher.setChoices(tasks, chooser, true, nil)
    chooser:queryChangedCallback(function()
        FuzzyMatcher.setChoices(tasks, chooser, true, nil)
    end)
    chooser:show()
end)
