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

return {fuzzyMatch = fuzzyMatch}
