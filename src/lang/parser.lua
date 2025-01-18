local Errors = require("src.lang.errors")
local Tokens = require("src.lang.tokens")

local TokenType = Tokens.TokenType
local Token = Tokens.Token

local Parser = {}
Parser.__index = Parser

function Parser:new(tokens)
    -- print(tokens[1].value)
    return setmetatable({ tokens = tokens, current = 1 }, Parser)
end
function Parser:advance()
    self.current = self.current + 1
    -- self:update_current_token()
    return self.current
end
function Parser:current_token() return self.tokens[self.current] end
function Parser:update_current_token()
    if self.current >= 1 and self.current < #self.tokens then
        self.current = self.tokens[self.current]
    end
end
function Parser:consume(expected_type, error_message)
    local token = self:current_token()
    -- print(token.type)

    if token and token.type == expected_type then
        self:advance() return token
    else
        error(Errors.InvalidSyntaxError:new(token.pos, token.pos, error_message))
    end
end
function Parser:parse()
    local statements = {}
    while self:current_token().type ~= TokenType.EOF do
        table.insert(statements, self:parse_statement())
    end
    return statements
end
function Parser:parse_statement()
    local token = self:current_token()
    if token.type == TokenType.KEYWORD then
        if token.value == "print" then
            return self:parse_print_statement()
        end
    else
        error(Errors.InvalidSyntaxError:new(token.pos_start, token.pos_end, "Unknown statement"))
    end
end
function Parser:parse_print_statement()
    self:consume(TokenType.KEYWORD, "Expected 'print'")
    self:consume(TokenType.BANG, "Expected '!' after 'print'")
    self:consume(TokenType.LPAREN, "Expected '(' after 'print!'")
    local value = self:parse_expression()
    self:consume(TokenType.RPAREN, "Expected ')' after expression")
    self:consume(TokenType.SEMICOLON, "Expected ';' after right paren.")
    return { type = "print", value = value }
end
function Parser:parse_expression()
    local token = self:current_token()
    if token.type == TokenType.STRING then self:advance()
        return { type = "string", value = token.value }
    else
        error(Errors.InvalidSyntaxError:new(token.pos_start, token.pos_end, "Unknown expression"))
    end
end

return Parser