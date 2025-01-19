local Results = require("src.lang.common.results")
local Values = require("src.lang.backend.values")
local Errors = require("src.lang.common.errors")

local Tokens = require("src.lang.frontend.tokens")
local Token, TokenType = Tokens.Token, Tokens.TokenType

local Interpreter = {}
local interpret_methods = {
    visit = function(self, node, context)
        local method_name = "visit_"..tostring(node.__name)
        local method = self[method_name] or self.no_visit_method
        return method(self, node)
    end,
    no_visit_method = function(self, node, context)
        error(string.format("No visit_%s method defined", node.__name or "Unknown"))
    end,
    visit_NumberNode = function(self, node, context)
        return Results:RT():success(
            Values:Number(node.token.value)
                :set_context(context)
                :set_pos(node.pos_start, node.pos_end)
        )
    end,
    visit_VarAccessNode = function(self, node, context)
        local res, var_name = Results:RT(), node.var_name_token.value
        local new_value = context.symbol_table[var_name]
        if not new_value then
            return res:failure(Errors:RTError(
                node.pos_start, node.pos_end,
                string.format("\"%s\" is not defined.", var_name),
                context
            ))
        end
        new_value = new_value:copy():set_pos(node.pos_start, node.pos_end)
        return res:success(new_value)
    end,
    visit_VarAssignNode = function(self, node, context)
        local res, var_name = Results:RT(), node.var_name_token.value
        local new_value = res:register(self:visit(node.value_node, context))
        if res.error then return res end
        context.symbol_table[var_name] = new_value
        return res:success(new_value)
    end,
    visit_BinOpNode = function(self, node, context)
        local res, result, error = Results:RT(), nil, nil
        local left = res:register(self:visit(node.left_node, context))
        if res.error then return res end
        local right = res:register(self:visit(node.right_node, context))
        if res.error then return res end
        
        if node.op_token.type == TokenType.PLUS then result, error = left:added(right)
        elseif node.op_token.type == TokenType.MINUS then result, error = left:subbed(right)
        elseif node.op_token.type == TokenType.MUL then result, error = left:multed(right)
        elseif node.op_token.type == TokenType.DIV then result, error = left:divided(right)
        elseif node.op_token.type == TokenType.POW then result, error = left:powed(right) end

        if error then return res:failure(error)
        else return res:success(result:set_pos(node.pos_start, node.pos_end)) end
    end,
    visit_UnaryOpNode = function(self, node, context)
        local res, error = Results:RT(), nil
        local number = res:register(self:visit(node.node, context))
        if res.error then return res end
        if node.op_token.type == TokenType.MINUS then
            number, error = number:multed(Values:Number(-1))
        end
        if error then return res:failure(error)
        else return res:success(number:set_pos(node.pos_start, node.pos_end)) end
    end,
}
function Interpreter:new()
    return setmetatable({}, {__index = function(t, key)
        return interpret_methods[key] or rawget(t, key)
    end})
end