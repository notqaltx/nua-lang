-- src/lang/lexer.lua
local Lexer = {}
Lexer.__index = Lexer

function Lexer:new(source)
    local instance = {
        source = source,
        tokens = {},
        start = 1,
        current = 1,
        line = 1
    }
    setmetatable(instance, Lexer)
    return instance
end

function Lexer:advance()
    local char = self.source:sub(self.current, self.current)
    if char == "\n" then
        self.line = self.line + 1
    end
    self.current = self.current + 1
end

function Lexer:add_token(type, value)
    table.insert(self.tokens, { type = type, value = value or "", line = self.line })
end

function Lexer:scan_token()
    local char = self.source:sub(self.current, self.current)
    self:advance()
    if char == "(" then
        self:add_token("LEFT_PAREN")
    elseif char == ")" then
        self:add_token("RIGHT_PAREN")
    elseif char == "!" then
        self:add_token("EXCLAMATION")
    elseif char == ";" then
        self:add_token("SEMICOLON")
    elseif char == "\"" then
        self:scan_string()
    elseif char:match("%s") then
        -- Ignore whitespace
    else
        self:scan_identifier_or_keyword()
    end
end

function Lexer:scan_string()
    local start = self.current
    while self.source:sub(self.current, self.current) ~= "\"" and self.current <= #self.source do
        self:advance()
    end
    if self.current > #self.source then
        error("Unterminated string at line " .. self.line)
    end
    local value = self.source:sub(start, self.current - 1)
    self:advance()
    self:add_token("STRING", value)
end

function Lexer:scan_identifier_or_keyword()
    local start = self.current - 1
    while self.source:sub(self.current, self.current):match("[%w_]") do
        self:advance()
    end
    local value = self.source:sub(start, self.current - 1)
    if value == "print" then
        self:add_token("PRINT")
    else
        self:add_token("IDENTIFIER", value)
    end
end

function Lexer:scan_tokens()
    while self.current <= #self.source do
        self.start = self.current
        self:scan_token()
    end
    self:add_token("EOF")
    return self.tokens
end

return Lexer