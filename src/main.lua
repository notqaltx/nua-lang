-- src/main.lua
local compiler = require("src.lang.compiler")

local function read_file(filename)
    local file = io.open(filename, "r")
    if not file then
        error("Could not open file: " .. filename)
    end
    local content = file:read("*all")
    file:close()
    return content
end

local function execute_file(filename)
    if not filename:match("%.nua$") then
        error("Invalid file extension. Only .nua files are supported.")
    end

    local content = read_file(filename)
    compiler:run(content)
end

local function main(args)
    if #args ~= 1 then
        print("Usage: lua main.lua <filename>.nua")
        return
    end
    local filename = args[1]
    execute_file(filename)
end

main(arg)