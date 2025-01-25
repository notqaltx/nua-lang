local Results = require("src.lang.common.results")
local Values = require("src.lang.backend.values")
local Errors = require("src.lang.common.errors")

local Tokens = require("src.lang.frontend.tokens")
local Token, TokenType = Tokens.Token, Tokens.TokenType

local Interpreter = {}
local interpret_methods = {
    visit = function(self, node, context)
        if not node then
            return Results("RT"):failure(Errors("RTError",
                node.pos_start, node.pos_end,
                "No node to visit",
                context
            ))
        end
        local method_name = "visit_"..tostring(node.__name)
        local method = self[method_name] or self.no_visit_method
        return method(self, node, context)
    end,
    no_visit_method = function(self, node, context)
        error(string.format("No visit_%s method defined", node.__name or "Unknown"))
    end,
    visit_NumberNode = function(self, node, context)
        return Results("RT"):success(
            Values("Number", node.token.value)
                :set_context(context)
                :set_pos(node.pos_start, node.pos_end)
        )
    end,
    visit_VarAccessNode = function(self, node, context)
        local res, var_name = Results("RT"), node.var_name_token.value
        local new_value = context.symbol_table[var_name]
        if not new_value then
            return res:failure(Errors("RTError",
                node.pos_start, node.pos_end,
                string.format("\"%s\" is not defined.", var_name),
                context
            ))
        end
        new_value = new_value:copy():set_pos(node.pos_start, node.pos_end)
        return res:success(new_value)
    end,
    visit_VarAssignNode = function(self, node, context)
        local res, var_name = Results("RT"), node.var_name_token.value
        local new_value = res:register(self:visit(node.value_node, context))
        if res.error then return res end
        context.symbol_table[var_name] = new_value
        return res:success(new_value)
    end,
    visit_BinOpNode = function(self, node, context)
        local res, result, error = Results("RT"), nil, nil
        local left = res:register(self:visit(node.left_node, context))
        if res.error then return res end
        local right = res:register(self:visit(node.right_node, context))
        if res.error then return res end

        if node.op_token.type == TokenType.PLUS then result, error = left:added(right)
        elseif node.op_token.type == TokenType.MINUS then result, error = left:subbed(right)
        elseif node.op_token.type == TokenType.MUL then result, error = left:multed(right)
        elseif node.op_token.type == TokenType.DIV then result, error = left:divided(right)
        elseif node.op_token.type == TokenType.POW then result, error = left:powed(right)
        elseif node.op_token.type == TokenType.EE then result, error = left:get_comparison_eq(right)
        elseif node.op_token.type == TokenType.NE then result, error = left:get_comparison_ne(right)
        elseif node.op_token.type == TokenType.LT then result, error = left:get_comparison_lt(right)
        elseif node.op_token.type == TokenType.GT then result, error = left:get_comparison_gt(right)
        elseif node.op_token.type == TokenType.LTE then result, error = left:get_comparison_lte(right)
        elseif node.op_token.type == TokenType.GTE then result, error = left:get_comparison_gte(right)
        elseif node.op_token.type == TokenType.AND then result, error = left:get_comparison_and(right)
        elseif node.op_token.type == TokenType.OR then result, error = left:get_comparison_or(right) end

        if error then return res:failure(error) end
        if result then
            result = result:set_pos(node.pos_start, node.pos_end)
            return res:success(result)
        else
            return res:failure(Errors("RTError",
                node.pos_start, node.pos_end,
                "Operation not supported",
                context
            ))
        end
    end,
    visit_UnaryOpNode = function(self, node, context)
        local res, error = Results("RT"), nil
        print(node.op_token.type)
        local number = res:register(self:visit(node.node, context))
        if res.error then return res end

        if node.op_token.type == TokenType.MINUS then
            number, error = number:multed(Values("Number", -1))
        elseif node.op_token.type == TokenType.NOT then
            number, error = number:get_comparison_not()
        end
        if error then return res:failure(error)
        else return res:success(number:set_pos(node.pos_start, node.pos_end)) end
    end,
    visit_IfNode = function(self, node, context)
        local res = Results("RT")
        for _, case in ipairs(node.cases) do
            local condition, expr = case[1], case[2]
            local condition_value = res:register(self:visit(condition, context))
            if res.error then return res end

            local is_true = condition_value:is_true()
            if is_true then
                local expr_value = res:register(self:visit(expr, context))
                if res.error then return res end
                return res:success(expr_value)
            end
        end
        if node.else_case then
            local else_expr = res:register(self:visit(node.else_case, context))
            if res.error then return res end
            return res:success(else_expr)
        end
        return res:success(Values("Number", 0))
    end,
    visit_ForNode = function(self, node, context)
        local res = Results("RT")
        local start_value = res:register(self:visit(node.start_node, context))
        if res.error then return res end
        local end_value = res:register(self:visit(node.end_node, context))
        if res.error then return res end

        local step_value
        if node.step_node then
            step_value = res:register(self:visit(node.step_node, context))
            if res.error then return res end
        else step_value = Values("Number", 1) end

        local condition
        local i = start_value.value
        if step_value.value > 0 then
            condition = function()
                if node.inclusive then return i <= end_value.value
                else return i < end_value.value end
            end
        else
            condition = function()
                if node.inclusive then return i >= end_value.value
                else return i > end_value.value end
            end
        end
        while condition() do
            context.symbol_table[node.var_name_token.value] = Values("Number", i)
            i = i + step_value.value
            res:register(self:visit(node.body_node, context))
            if res.error then return res end
        end
        context.symbol_table[node.var_name_token.value] = nil
        return res:success(Values("Number", 0))
    end,
    visit_WhileNode = function(self, node, context)
        local res = Results("RT")
        while true do
            local condition = res:register(self:visit(node.condition_node, context))
            if res.error then return res end
            if not condition:is_true() then break end
            res:register(self:visit(node.body_node, context))
            if res.error then return res end
        end
        return res:success(Values("Number", 0))
    end,
}
function Interpreter:new()
    return setmetatable({}, {__index = function(t, key)
        return interpret_methods[key] or rawget(t, key)
    end})
end
return Interpreter