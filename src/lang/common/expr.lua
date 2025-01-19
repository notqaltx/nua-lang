local Errors = require("src.lang.errors")
local token_module = require("src.lang.token")
local TokenType = token_module.TokenType

local Expr = {}
Expr.__index = Expr

function Expr:evaluate_binary(operator, left, right)
    if operator.type == TokenType.PLUS then
        if left.type == "number" and right.type == "number" then
            return { type = "number", value = left.value + right.value }
        elseif left.type == "string" and right.type == "string" then
            return { type = "string", value = left.value .. right.value }
        end
    elseif operator.type == TokenType.MINUS and left.type == "number" and right.type == "number" then
        return { type = "number", value = left.value - right.value }
    elseif operator.type == TokenType.MUL and left.type == "number" and right.type == "number" then
        return { type = "number", value = left.value * right.value }
    elseif operator.type == TokenType.DIV and left.type == "number" and right.type == "number" then
        return { type = "number", value = left.value / right.value }
    elseif operator.type == TokenType.EE then
        return { type = "boolean", value = left.value == right.value }
    elseif operator.type == TokenType.NE then
        return { type = "boolean", value = left.value ~= right.value }
    elseif operator.type == TokenType.GT and left.type == "number" and right.type == "number" then
        return { type = "boolean", value = left.value > right.value }
    elseif operator.type == TokenType.GTE and left.type == "number" and right.type == "number" then
        return { type = "boolean", value = left.value >= right.value }
    elseif operator.type == TokenType.LT and left.type == "number" and right.type == "number" then
        return { type = "boolean", value = left.value < right.value }
    elseif operator.type == TokenType.LTE and left.type == "number" and right.type == "number" then
        return { type = "boolean", value = left.value <= right.value }
    else
        return nil, Errors.RTError:new(operator.pos_start, operator.pos_end, "Invalid operation", nil)
    end
end

return Expr