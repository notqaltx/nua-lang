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
        if self.token_idx >= 0 and self.token_idx <= #self.tokens then
            self.current_token = self.tokens[self.token_idx]
        else self.current_token = nil end
    end,
    parse = function(self)
        local res = self:expr()
        if res.error then return res end
        if self.current_token.type ~= TokenType.EOF then
            print("WARNING: Token mismatch")
            -- Uncomment the error handling
            return res:failure(Errors("InvalidSyntaxError",
                self.current_token.pos_start, self.current_token.pos_end,
                "Expected identifier, keyword, or expression."
            ))
        end
        return res
    end,
    atom = function(self)
        local res, token = Results("Parse"), self.current_token
        if token.type == TokenType.INT or token.type == TokenType.FLOAT then
            res:register_advancement(); self:advance()
            return res:success(Nodes("NumberNode", token))

        elseif token.type == TokenType.IDENTIFIER then
            res:register_advancement(); self:advance()
            return res.success(Nodes("VarAccessNode", token))

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
                    "Expected \")\""
                ))
            end
        end
        return res:failure(Errors("InvalidSyntaxError",
            token.pos_start, token.pos_end,
            "Expected identifier, keyword or expression."
        ))
    end,
    power = function(self)
        return self:bin_op(self.atom, {TokenType.POW}, self.factor)
    end,
    factor = function(self)
        local res, token = Results("Parse"), self.current_token
        if not token then
            return res:failure(Errors("InvalidSyntaxError",
                nil, nil,
                "Unexpected end of input."
            ))
        end
        if token.type == TokenType.PLUS or token.type == TokenType.MINUS then
            res:register_advancement(); self:advance()
            local factor = res:register(self:factor())
            if res.error then return res end
            return res:success(Nodes("UnaryOpNode", token, factor))
        end
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
        local node = res:register(self:bin_op(self.comp_expr, {TokenType.PLUS, TokenType.MINUS}))
        if res.error then
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
        
        -- while table.find(ops, self.current_token.type)
        while ops[self.current_token.type]
        and self.current_token.type ~= TokenType.EOF do
            local op_token = self.current_token
            res:register_advancement(); self:advance()

            local right = res:register(b(self))
            if res.error then return res end
            left = Nodes("BinOpNode", left, op_token, right)
        end
        return res:success(left)
    end,
}
function Parser:new(tokens)
    local instance = { tokens = tokens, token_idx = 0 }
    setmetatable(instance, {__index = function(t, key)
        return parse_methods[key] or rawget(t, key)
    end}); instance:advance()
    return instance
end
return Parser