local M = {}

M.merge_tables = function(table_a, table_b)
    local result = {}
    for _, v in pairs(table_a) do table.insert(result, v) end
    for _, v in pairs(table_b) do table.insert(result, v) end
    return result
end

return M
