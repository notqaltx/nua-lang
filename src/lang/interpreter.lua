-- src/lang/interpreter.lua
local Interpreter = {}
Interpreter.__index = Interpreter

function Interpreter:new()
    local instance = {}
    setmetatable(instance, Interpreter)
    return instance
end

function Interpreter:interpret(statements)
    for _, statement in ipairs(statements) do
        if statement.type == "print" then
            self:execute_print(statement)
        else
            error("Unknown statement type: " .. statement.type)
        end
    end
end

function Interpreter:execute_print(statement)
    if statement.value.type == "string" then
        print(statement.value.value)
    else
        error("Unknown value type in print statement")
    end
end

return Interpreter