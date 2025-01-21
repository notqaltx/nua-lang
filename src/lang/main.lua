local Compiler = require("src.lang.backend.compiler")
local Errors = require("src.lang.common.errors")

-- Utility function for colored output
local function colored_print(color_code, message)
    io.write(string.format("\27[%sm%s\27[0m", color_code, message))
end

-- Color codes
local colors = {
    red = "31",
    green = "32",
    yellow = "33",
    blue = "34"
}

local function read_file(filename)
    local file, err = io.open(filename, "r")
    if not file then
        error("Could not open file: " .. filename .. " (" .. err .. ")")
    end
    local content = file:read("*all")
    file:close()
    return content
end

local function execute_file(filename)
    -- Append .nua extension if not present
    if not filename:match("%.nua$") then
        filename = filename .. ".nua"
    end
    local content
    local ok, err = pcall(function()
        content = read_file(filename)
    end)
    if not ok then
        colored_print(colors.red, tostring(err))
        return
    end
    local compiler = Compiler:new()
    local result, error = compiler:run(filename, content)
    if error then
        if type(err) == "table" and err.as_string then
            colored_print(colors.red, err:as_string())
        else
            colored_print(colors.red, tostring(err))
        end
    else
        print(result)
        colored_print(colors.green, "Script executed successfully.")
    end
end

local function main(args)
    if #args ~= 1 then
        colored_print(colors.yellow, "Usage: lua main.lua <filename>")
        return
    end
    local filename = args[1]
    execute_file(filename)
end

main(arg)