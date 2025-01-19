-- local Errors = require("src.lang.common.errors")
-- local Tokens = require("src.lang.frontend.tokens")

-- local TokenType = Tokens.TokenType
-- local Token = Tokens.Token

-- local Parser = {}
-- Parser.__index = Parser

-- function Parser:new(tokens)
--     -- print(tokens[1].value)
--     return setmetatable({ tokens = tokens, current = 1 }, Parser)
-- end
-- function Parser:advance()
--     self.current = self.current + 1
--     -- self:update_current_token()
--     return self.current
-- end
-- function Parser:current_token() return self.tokens[self.current] end
-- function Parser:update_current_token()
--     if self.current >= 1 and self.current < #self.tokens then
--         self.current = self.tokens[self.current]
--     end
-- end
-- function Parser:consume(expected_type, error_message)
--     local token = self:current_token()
--     -- print(token.type)

--     if token and token.type == expected_type then
--         self:advance() return token
--     else
--         print(token.pos_start, token.pos_end)
--         error(Errors.InvalidSyntaxError:new(token.pos_start, token.pos_end, error_message))
--     end
-- end
-- function Parser:parse()
--     local statements = {}
--     while self:current_token().type ~= TokenType.EOF do
--         table.insert(statements, self:parse_statement())
--     end
--     return statements
-- end
-- function Parser:parse_statement()
--     local token = self:current_token()
--     if token.type == TokenType.KEYWORD then
--         if token.value == "print" then
--             return self:parse_print_statement()
--         end
--     else
--         print(token.pos_start, token.pos_end)
--         error(Errors.InvalidSyntaxError:new(token.pos_start, token.pos_end, "Unknown statement"))
--     end
-- end
-- function Parser:parse_print_statement()
--     self:consume(TokenType.KEYWORD, "Expected 'print'")
--     self:consume(TokenType.BANG, "Expected '!' after 'print'")
--     self:consume(TokenType.LPAREN, "Expected '(' after 'print!'")
--     local value = self:parse_expression()
--     self:consume(TokenType.RPAREN, "Expected ')' after expression")
--     self:consume(TokenType.SEMICOLON, "Expected ';' after right paren.")
--     return { type = "print", value = value }
-- end
-- function Parser:parse_expression()
--     local token = self:current_token()
--     if token.type == TokenType.STRING then self:advance()
--         return { type = "string", value = token.value }
--     else
--         error(Errors.InvalidSyntaxError:new(token.pos_start, token.pos_end, "Unknown expression"))
--     end
-- end

-- return Parser

local Results = require("src.lang.common.results")
local Nodes = require("src.lang.common.nodes")
local Errors = require("src.lang.common.errors")
local Tokens = require("src.lang.frontend.tokens")
local Token, TokenType = Tokens.Token, Tokens.TokenType

local Parser = {}
Parser.__index = Parser

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
    -- update_current_token = function(self)
    --     if self.token_idx >= 0 and self.token_idx < #self.tokens then
    --         self.current_token = self.tokens[self.token_idx]
    --     end
    -- end,
    parse = function(self)
        local res = self:expr()
        if not res.error and self.current_token.type ~= TokenType.EOF then
            return res:failure(Errors:InvalidSyntaxError(
                self.current_token.pos_start, self.current_token.pos_end,
                "Expected identifier, keyword, or expression."
            ))
        end
        return res
    end,
    atom = function(self)
        local res = Results:Parse()
        local token = self.current_token
        if token == (TokenType.INT or TokenType.FLOAT) then
            res:register_advancement(); self:advance()
            return res:success(Nodes("NumberNode", token))

        elseif token == TokenType.KEYWORD then
            res:register_advancement(); self:advance()
            return res.success(Nodes("VarAccessNode", token))

        elseif token == TokenType.LPAREN then
            res:register_advancement(); self:advance()
            local expr = res:register(self:expr())
            if res.error then return res end

            if self.current_token == TokenType.RPAREN then
                res:register_advancement(); self:advance()
                return res:success(expr)
            else
                return res:failure(Errors:InvalidSyntaxError(
                    self.current_token.pos_start, self.current_token.pos_end
                    "Expected \")\""
                ))
            end
        end
        return res:failure(Errors:InvalidSyntaxError(
            token.pos_start, token.pos_end,
            "Expected identifier, keyword or expression."
        ))
    end,
    power = function(self)
        return self:bin_op(self.atom, {TokenType.POW}, self.factor)
    end,
    factor = function(self)
        local res, token = Results:Parse(), self.current_token
        if token.type == (TokenType.PLUS or TokenType.MINUS) then
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
    expr = function(self)
        local res = Results:Parse()
        if self.current_token:matches(TokenType.KEYWORD, "var") then
            res:register_advancement(); self:advance()
            if self.current_token.type ~= TokenType.IDENTIFIER then
                return res:failure(Errors:InvalidSyntaxError(
                    self.current_token.pos_start, self.current_token.pos_end,
                    "Expected identifier after \"var\"."
                ))
            end
            local var_name = self.current_token
            res:register_advancement(); self:advance()

            if self.current_token.type ~= TokenType.EQ then
                return res:failure(Errors:InvalidSyntaxError(
                    self.current_token.pos_start, self.current_token.pos_end,
                    "Expected \"=\" after variable identifier."
                ))
            end
            res:register_advancement(); self:advance()
            local expr = res:register(self:expr())
            if res.error then return res end
            return res:success(Nodes("VarAssignNode", var_name, expr))
        end
        local node = res:register(self:bin_op(self.term, {TokenType.PLUS, TokenType.MINUS}))
        if res.error then
            return res:failure(Errors:InvalidSyntaxError(
                self.current_token.pos_start, self.current_token.pos_end,
                "Expected identifier, keyword or expression."
            ))
        end
        return res:success(node)
    end,
    bin_op = function(self, a, ops, b)
        if b == nil then b = a end
        local res = Results:Parse()
        local left = res:register(a())
        if res.error then return res end
        
        while ops[self.current_token.type] do
            local op_token = self.current_token
            res:register_advancement(); self:advance()

            local right = res:register(b())
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