-- src/lang/parser.lua
local Parser = {}
Parser.__index = Parser

function Parser:new(tokens)
    return setmetatable({ tokens = tokens, current = 1 }, Parser)
end

function Parser:advance()
    self.current = self.current + 1
end

function Parser:current_token()
    return self.tokens[self.current]
end

function Parser:consume(expected_type, error_message)
    local token = self:current_token()
    if token and token.type == expected_type then
        self:advance()
        return token
    else
        error(error_message .. " Got: " .. (token and token.type or "nil") .. " at line " .. (token and token.line or "unknown"))
    end
end

function Parser:parse()
    local statements = {}
    while self:current_token().type ~= "EOF" do
        table.insert(statements, self:parse_statement())
    end
    return statements
end

function Parser:parse_statement()
    local token = self:current_token()
    if token.type == "PRINT" then
        return self:parse_print_statement()
    else
        error("Unknown statement at line " .. token.line)
    end
end

function Parser:parse_print_statement()
    self:consume("PRINT", "Expected 'print' keyword")
    self:consume("EXCLAMATION", "Expected '!' after 'print'")
    self:consume("LEFT_PAREN", "Expected '(' after 'print!'")
    local value = self:parse_expression()
    self:consume("RIGHT_PAREN", "Expected ')' after expression")
    self:consume("SEMICOLON", "Expected ';' after right paren")
    return { type = "print", value = value }
end

function Parser:parse_expression()
    local token = self:current_token()
    if token.type == "STRING" then
        self:advance()
        return { type = "string", value = token.value }
    else
        error("Unknown expression at line " .. token.line)
    end
end

return Parser