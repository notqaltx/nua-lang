local Results = require("src.lang.common.results")
local Nodes = require("src.lang.common.nodes")
local Errors = require("src.lang.common.errors")

local Tokens = require("src.lang.frontend.tokens")
local Token, TokenType = Tokens.Token, Tokens.TokenType

local Parser = {}
local parse_methods = {
    advance = function(self)
        self.token_idx = self.token_idx + 1
        self:update_current_token()
        return self.current_token
    end,
    reverse = function(self, amount)
        amount = (amount and amount) or 1
        self.token_idx = self.token_idx - amount
        self:update_current_token()
        return self.current_token
    end,
    update_current_token = function(self)
        if self.token_idx >= 0 and self.token_idx < #self.tokens then
            self.current_token = self.tokens[self.token_idx + 1]
        else self.current_token = nil end
    end,
    consume = function(self, type, value, res)
        if self.current_token.type ~= type and self.current_token.value ~= value then
            return res:failure(Errors("InvalidSyntaxError",
                self.current_token.pos_start, self.current_token.pos_end,
                "Expected \""..value.."\" after \""..type.."\""
            ))
        end
    end,
    parse = function(self)
        local res = self:expr()
        if res.error then return res end
        if self.current_token and self.current_token.type ~= TokenType.EOF then
            print("parse error")
            return res:failure(Errors("InvalidSyntaxError",
                self.current_token.pos_start, self.current_token.pos_end,
                "Expected identifier, keyword, or expression."
            ))
        end
        return res
    end,
    if_expr = function(self)
        local res = Results("Parse")
        local cases, else_case = {}, nil
        local cases_count = 0

        if not self.current_token(TokenType.KEYWORD, "if") then
            return res:failure(Errors("InvalidSyntaxError",
                self.current_token.pos_start, self.current_token.pos_end,
                "Expected \"if\"."
            ))
        end
        res:register_advancement(); self:advance()
        self:consume(TokenType.LPAREN, "(", res)

        res:register_advancement(); self:advance()
        local condition = res:register(self:expr())
        if res.error then return res end

        self:consume(TokenType.RPAREN, ")", res)
        res:register_advancement(); self:advance()

        if self.current_token.type ~= TokenType.LBRACKET then
            return res:failure(Errors("InvalidSyntaxError",
                self.current_token.pos_start, self.current_token.pos_end,
                "Expected \"{\" after if condition."
            ))
        end
        res:register_advancement(); self:advance()
        local then_body = res:register(self:expr())
        if res.error then return res end

        cases[cases_count + 1] = {[1] = condition, [2] = then_body}
        cases_count = cases_count + 1
        self:consume(TokenType.RBRACKET, "}", res)
        res:register_advancement(); self:advance()

        while self.current_token(TokenType.KEYWORD, "elif") do
            res:register_advancement(); self:advance()
            self:consume(TokenType.LPAREN, "(", res)
            res:register_advancement(); self:advance()

            local condition = res:register(self:expr())
            if res.error then return res end
            self:consume(TokenType.RPAREN, ")", res)
            res:register_advancement(); self:advance()

            if self.current_token.type ~= TokenType.LBRACKET then
                return res:failure(Errors("InvalidSyntaxError",
                    self.current_token.pos_start, self.current_token.pos_end,
                    "Expected \"{\" after elif condition."
                ))
            end
            res:register_advancement(); self:advance()
            local then_body = res:register(self:expr())
            if res.error then return res end

            cases[cases_count + 1] = {[1] = condition, [2] = then_body}
            cases_count = cases_count + 1

            self:consume(TokenType.RBRACKET, "}", res)
            res:register_advancement(); self:advance()
        end
        if self.current_token(TokenType.KEYWORD, "else") then
            res:register_advancement(); self:advance()
            if self.current_token.type ~= TokenType.LBRACKET then
                return res:failure(Errors("InvalidSyntaxError",
                    self.current_token.pos_start, self.current_token.pos_end,
                    "Expected \"{\" after else."
                ))
            end
            res:register_advancement(); self:advance()
            local else_body = res:register(self:expr())
            if res.error then return res end
            else_case = else_body

            self:consume(TokenType.RBRACKET, "}", res)
            res:register_advancement(); self:advance()
        end
        return res:success(Nodes("IfNode", cases, else_case))
    end,
    for_expr = function(self)
        local res = Results("Parse")
        if not self.current_token(TokenType.KEYWORD, "for") then
            return res:failure(Errors("InvalidSyntaxError",
                self.current_token.pos_start, self.current_token.pos_end,
                "Expected \"for\"."
            ))
        end
        res:register_advancement(); self:advance()
        if self.current_token.type ~= TokenType.IDENTIFIER then
            print("for_expr error")
            return res:failure(Errors("InvalidSyntaxError",
                self.current_token.pos_start, self.current_token.pos_end,
                "Expected identifier after \"for\"."
            ))
        end
        local var_name_token = self.current_token
        res:register_advancement(); self:advance()

        if self.current_token.type ~= TokenType.EQ then
            return res:failure(Errors("InvalidSyntaxError",
                self.current_token.pos_start, self.current_token.pos_end,
                "Expected \"=\" after identifier."
            ))
        end
        res:register_advancement(); self:advance()
        local start_node = res:register(self:expr())
        if res.error then return res end

        local inclusive = false
        if self.current_token.type == TokenType.DD then inclusive = false
        elseif self.current_token.type == TokenType.DDE then inclusive = true
        else
            return res:failure(Errors("InvalidSyntaxError",
                self.current_token.pos_start, self.current_token.pos_end,
                "Expected \"..\" or \"..=\" after start value in for loop."
            ))
        end
        res:register_advancement(); self:advance()
        local end_node = res:register(self:expr())
        if res.error then return res end

        local step_node = nil
        if self.current_token(TokenType.KEYWORD, "step") then
            res:register_advancement(); self:advance()
            step_node = res:register(self:expr())
            if res.error then return res end
        end
        if self.current_token.type ~= TokenType.LBRACKET then
            return res:failure(Errors("InvalidSyntaxError",
                self.current_token.pos_start, self.current_token.pos_end,
                "Expected \"{\" after for loop."
            ))
        end
        res:register_advancement(); self:advance()
        local body_node = res:register(self:expr())
        if res.error then return res end

        self:consume(TokenType.RBRACKET, "}", res)
        res:register_advancement(); self:advance()

        return res:success(Nodes("ForNode", var_name_token, start_node,
            end_node, step_node, body_node, inclusive))
    end,
    while_expr = function(self)
        local res = Results("Parse")
        if not self.current_token(TokenType.KEYWORD, "while") then
            return res:failure(Errors("InvalidSyntaxError",
                self.current_token.pos_start, self.current_token.pos_end,
                "Expected \"while\"."
            ))
        end
        res:register_advancement(); self:advance()
        if self.current_token.type ~= TokenType.LPAREN then
            return res:failure(Errors("InvalidSyntaxError",
                self.current_token.pos_start, self.current_token.pos_end,
                "Expected \"(\" after \"while\"."
            ))
        end
        res:register_advancement(); self:advance()
        local condition_node = res:register(self:expr())
        if res.error then return res end

        if self.current_token.type ~= TokenType.RPAREN then
            return res:failure(Errors("InvalidSyntaxError",
                self.current_token.pos_start, self.current_token.pos_end,
                "Expected \")\" after condition body."
            ))
        end
        res:register_advancement(); self:advance()
        if self.current_token.type ~= TokenType.LBRACKET then
            return res:failure(Errors("InvalidSyntaxError",
                self.current_token.pos_start, self.current_token.pos_end,
                "Expected \"{\" after while condition."
            ))
        end
        res:register_advancement(); self:advance()
        local body_node = res:register(self:expr())
        if res.error then return res end

        self:consume(TokenType.RBRACKET, "}", res)
        res:register_advancement(); self:advance()
        return res:success(Nodes("WhileNode", condition_node, body_node))
    end,
    atom = function(self)
        local res, token = Results("Parse"), self.current_token
        if token.type == TokenType.INT or token.type == TokenType.FLOAT then
            res:register_advancement(); self:advance()
            return res:success(Nodes("NumberNode", token))

        -- elseif token.type == TokenType.PLUS or token.type == TokenType.MINUS then
        --     res:register_advancement(); self:advance()
        --     local factor = res:register(self:factor())
        --     if res.error then return res end
        --     return res:success(Nodes("UnaryOpNode", token, factor))

        elseif token.type == TokenType.IDENTIFIER then
            res:register_advancement(); self:advance()
            return res:success(Nodes("VarAccessNode", token))

        elseif token.type == TokenType.LPAREN then
            res:register_advancement(); self:advance()
            local expr = res:register(self:expr())
            if res.error then return res end

            if self.current_token == TokenType.RPAREN then
                res:register_advancement(); self:advance()
                return res:success(expr)
            else
                return res:failure(Errors("InvalidSyntaxError",
                    self.current_token.pos_start, self.current_token.pos_end
                    "Expected \")\" after expression."
                ))
            end
        elseif token(TokenType.KEYWORD, "if") then
            local if_expr = res:register(self:if_expr())
            if res.error then return res end
            return res:success(if_expr)

        elseif token(TokenType.KEYWORD, "for") then
            local for_expr = res:register(self:for_expr())
            if res.error then return res end
            return res:success(for_expr)

        elseif token(TokenType.KEYWORD, "while") then
            local while_expr = res:register(self:while_expr())
            if res.error then return res end
            return res:success(while_expr)
        end
        print("atom error")
        return res:failure(Errors("InvalidSyntaxError",
            token.pos_start, token.pos_end,
            "Expected identifier, keyword or expression."
        ))
    end,
    power = function(self)
        return self:bin_op(self.atom, {TokenType.POW, }, self.factor)
    end,
    factor = function(self)
        local res, token = Results("Parse"), self.current_token
        if not token then
            return res:failure(Errors("InvalidSyntaxError",
                nil, nil, "Unexpected end of input."
            ))
        end
        local valid_tokens = {[TokenType.PLUS] = true, [TokenType.MINUS] = true}
        if valid_tokens[token.type] then
            res:register_advancement(); self:advance()
            local factor = res:register(self:factor())
            if res.error then
                print("Error in factor:", res.error)
                return res
            end
            return res:success(Nodes("UnaryOpNode", token, factor))
        end
        -- if token.type == TokenType.PLUS or token.type == TokenType.MINUS then
        --     res:register_advancement(); self:advance()
        --     if self.current_token.type == TokenType.INT 
        --     or self.current_token.type == TokenType.FLOAT then
        --         local num_token = self.current_token
        --         res:register_advancement(); self:advance()
        --         return res:success(Nodes("UnaryOpNode", token, Nodes("NumberNode", num_token)))
        --     else
        --         return res:failure(Errors("InvalidSyntaxError",
        --             self.current_token.pos_start, self.current_token.pos_end,
        --             "Expected number after unary operator."
        --         ))
        --     end
        -- end
        return self:power()
    end,
    term = function(self)
        return self:bin_op(self.factor, {TokenType.MUL, TokenType.DIV})
    end,
    arith_expr = function(self)
        return self:bin_op(self.term, {TokenType.PLUS, TokenType.MINUS})
    end,
    comp_expr = function(self)
        local res = Results("Parse")
        if self.current_token(TokenType.KEYWORD, "not") then
            local op_token = self.current_token
            res:register_advancement(); self:advance()
            local expr = res:register(self:comp_expr())
            if res.error then return res end
            return res:success(Nodes("UnaryOpNode", op_token, expr))
        end
        local node = res:register(self:bin_op(self.arith_expr, {
            TokenType.EE, TokenType.NE, TokenType.LT,
            TokenType.GT, TokenType.LTE, TokenType.GTE
        }))
        if res.error then
            print("comp_expr error")
            return res:failure(Errors("InvalidSyntaxError",
                self.current_token.pos_start, self.current_token.pos_end,
                "Expected identifier, keyword or expression."
            ))
        end
        return res:success(node)
    end,
    expr = function(self)
        local res = Results("Parse")
        if self.current_token(TokenType.KEYWORD, "var") then
            res:register_advancement(); self:advance()
            if self.current_token.type ~= TokenType.IDENTIFIER then
                return res:failure(Errors("InvalidSyntaxError",
                    self.current_token.pos_start, self.current_token.pos_end,
                    "Expected identifier after \"var\"."
                ))
            end
            local var_name = self.current_token
            res:register_advancement(); self:advance()

            if self.current_token.type ~= TokenType.EQ then
                return res:failure(Errors("InvalidSyntaxError",
                    self.current_token.pos_start, self.current_token.pos_end,
                    "Expected \"=\" after variable identifier."
                ))
            end
            res:register_advancement(); self:advance()
            local expr = res:register(self:expr())
            if res.error then return res end
            return res:success(Nodes("VarAssignNode", var_name, expr))
        end
        local node = res:register(self:bin_op(self.comp_expr, {TokenType.AND, TokenType.OR}))
        if res.error then
            print("expr error")
            return res:failure(Errors("InvalidSyntaxError",
                self.current_token.pos_start, self.current_token.pos_end,
                "Expected identifier, keyword or expression."
            ))
        end
        return res:success(node)
    end,
    bin_op = function(self, a, ops, b)
        if b == nil then b = a end
        local res = Results("Parse")
        local left = res:register(a(self))
        if res.error then return res end

        while true do
            local found, op_token = false, nil
            for _, op in ipairs(ops) do
                if type(op) == "table" then
                    if self.current_token.type == op[1]
                    and self.current_token.type == op[2] then
                        found = true 
                        op_token = self.current_token
                        break
                    end
                else
                    if self.current_token.type == op then
                        found = true
                        op_token = self.current_token
                        break
                    end
                end
            end
            if not found then break end
            res:register_advancement(); self:advance()

            local right = res:register(b(self))
            if res.error then return res end
            left = Nodes("BinOpNode", left, op_token, right)
        end
        return res:success(left)
    end,
}
function Parser:new(tokens)
    local instance = { tokens = tokens, token_idx = -1 }
    setmetatable(instance, {__index = function(t, key)
        return parse_methods[key] or rawget(t, key)
    end}); instance:advance()
    return instance
end
return Parser