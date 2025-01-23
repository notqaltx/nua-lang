local Strings = {}
Strings.__index = Strings

local colors = {
    red = "31",
    green = "32",
    yellow = "33",
    blue = "34"
}
function range(start, stop, step)
    local step = step or 1
    local i = start - step
    return function()
        i = i + step
        if i <= stop then
            return i
        end
    end
end
function rfind(s, pattern, start, end_)
    local start = start or 1
    local end_ = end_ or #s
    local last_pos = nil
    
    while true do
        local pos = string.find(s, pattern, start, true)
        if pos == nil or pos > end_ then break end
        last_pos = pos; start = pos + 1
    end
    return last_pos
end
function Strings.colored(color_code, message)
    local new_color = colors[color_code]
    return string.format("\27[%sm%s\27[0m", new_color, message)
end
function Strings.split(input, sep)
    if sep == nil then sep = "%s" end
    local t = {}
    for str in string.gmatch(input, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end
function Strings.add_arrows(text, pos_start, pos_end)
    if not text or not pos_start or not pos_end then
        return ""
    end
    local source = text
    local idx_start = math.max((source:find('\n', 0, pos_start.idx + 1) or 0), 0)
    local idx_end = source:find('\n', idx_start + 1) or #source
    
    local result_str = ""
    local line_count = pos_end.ln - pos_start.ln + 1
    for i = 1, line_count do
        local line = source:sub(idx_start + 1, idx_end)
        local col_start = (i == 1) and pos_start.col or 0
        local col_end = (i == line_count) and pos_end.col or #line

        result_str = result_str .. line .. '\n'
        result_str = result_str .. string.rep(" ", col_start) .. 
                    Strings.colored("red", string.rep("^", math.max(1, col_end - col_start))) .. '\n'
        idx_start = idx_end
        idx_end = source:find('\n', idx_start + 1) or #source
    end
    return result_str:gsub('\t', '')
end

return Strings