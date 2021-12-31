local function fuzzyMatch(target, query)
    local matched_idx = {}

    if string.len(query) > string.len(target) then return matched_idx end
    if not string.match(query, "%u") then target = string.lower(target) end

    local query_idx = 1
    local target_idx = 1
    while query_idx <= #query and target_idx <= #target do
        local query_char = string.sub(query, query_idx, query_idx)
        local target_char = string.sub(target, target_idx, target_idx)
        if query_char == target_char then
            table.insert(matched_idx, target_idx)
            query_idx = query_idx + 1
        end
        target_idx = target_idx + 1
    end
    return query_idx == #query + 1 and matched_idx or {}
end

local function highlightMatched(text, matched_idxs)
    local new_text = hs.styledtext.new(text)
    for _, idx in pairs(matched_idxs) do
        new_text = new_text:setStyle({color = hs.drawing.color.red}, idx, idx)
    end
    return new_text
end

local function filter(choices, query)
    if string.len(query) == 0 then return choices end
    local filtered_choices = {}
    for _, app in pairs(choices) do
        local matched_idxs = fuzzyMatch(app.text:getString(), query)
        if #matched_idxs ~= 0 then
            local new_app = {
                text = highlightMatched(app.text:getString(), matched_idxs),
                subText = app.subText
            }
            table.insert(filtered_choices, new_app)
        end
    end
    return filtered_choices
end

local function setChoices(choices, chooser)
    local filtered_choices = filter(choices, chooser:query())
    chooser:choices(filtered_choices)
    chooser:refreshChoicesCallback(true)
end

return {setChoices = setChoices}
