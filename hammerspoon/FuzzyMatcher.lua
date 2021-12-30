local function fuzzy_match(target, query)

    if string.len(query) == 0 then return true end
    if string.len(query) > string.len(target) then return false end
    if not string.match(query, "%u") then target = string.lower(target) end

    local query_idx = 1
    local target_idx = 1
    while query_idx <= #query and target_idx <= #target do
        local query_char = string.sub(query, query_idx, query_idx)
        local target_char = string.sub(target, target_idx, target_idx)
        if query_char == target_char then query_idx = query_idx + 1 end
        target_idx = target_idx + 1
    end
    return query_idx == #query + 1
end

return {fuzzy_match = fuzzy_match}
