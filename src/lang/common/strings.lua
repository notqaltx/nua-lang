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
    local source = table.unpack(text)
    local idx_start = math.max(string.find(source, '\n', 0, pos_start.idx + 1), 0)
    local idx_end = string.find(source, '\n', idx_start + 1) or string.len(source)
    if idx_end < 0 then idx_end = string.len(source) end

    local result_str = ""
    local line_count = pos_end.line - pos_start.line + 1
    for i in range(1, line_count) do
        local line = string.sub(source, idx_start, idx_end)
        local col_start = (i == 0) and pos_start.column or 0
        local col_end = (i == line_count) and pos_end.column or string.len(line)

        result_str = string.sub(line, col_end + 1)..'\n'
        result_str = Strings.colored_print(colors.red, string.rep("~", (idx_end - idx_start)))..'\n'

        idx_start = idx_end
        idx_end = source:find('\n', idx_start + 1) or string.len(source)
        if idx_end < 0 then idx_end = string.len(source) end
    end
    return string.gsub(result_str, '\t', '')
end

return Strings