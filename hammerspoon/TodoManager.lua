local FuzzyMatcher = require("FuzzyMatcher")
local todo_cli = "/usr/local/bin/todo";
-- [[
-- Create task
-- ]]
hs.hotkey.bind({"cmd"}, "/", function()
    hs.focus()
    local res, task = hs.dialog.textPrompt("Create new task", "Task: ", "",
                                           "OK", "Cancel")
    if res == "OK" then
        local output = hs.execute(todo_cli .. " add \"" .. task .. "\"")
        hs.alert.show("New Task " .. string.gsub(output, "\n", ""))
    end
end)

-- [[
-- complete task
-- ]]
hs.hotkey.bind({"cmd"}, ".", function()
    local task_list = hs.execute(todo_cli .. " list")
    if (task_list == "") then
        hs.alert.show("No Tasks!!!!")
        return
    end
    local tasks = {}

    for task in string.gmatch(task_list, "[^\n]+") do
        table.insert(tasks, {text = hs.styledtext.new(task), subText = ""})
    end

    local chooser = hs.chooser.new(function(task)
        if task == nil then return end
        local t = {}
        for token in string.gmatch(task.text:getString(), "([^:]+)") do
            table.insert(t, token)
        end
        local result = hs.execute(todo_cli .. " done " .. t[1])
        hs.alert.show(string.gsub(result, "\n", ""))
    end)

    FuzzyMatcher.setChoices(tasks, chooser, true, nil)
    chooser:queryChangedCallback(function()
        FuzzyMatcher.setChoices(tasks, chooser, true, nil)
    end)
    chooser:show()
end)
