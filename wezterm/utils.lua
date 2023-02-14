local M = {}

M.merge_tables = function(table_a, table_b)
    local result = {}
    for _, v in pairs(table_a) do table.insert(result, v) end
    for _, v in pairs(table_b) do table.insert(result, v) end
    return result
end

M.trim_whitespace = function(s)
    if s == nil then return "" end
    return s:match '^%s*(.*%S)' or ''
end

M.concat_first_and_last_line = function(lists)
    if #lists == 1 then return M.trim_whitespace(lists[1]) end

    local first = lists[1]
    local last = lists[#lists]

    return M.trim_whitespace(first) .. " .. " .. M.trim_whitespace(last)
end

M.padding_with_spaces = function (target_str, max_width)
  while target_str:len() < max_width - 2 do target_str = " " .. target_str .. " " end
  return target_str
end

return M
