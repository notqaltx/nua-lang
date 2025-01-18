-- local Position = require("src.lang.position")
-- local Errors = require("src.lang.errors")
-- local token_module = require("src.lang.token")
-- local TokenType = token_module.TokenType
-- local Token = token_module.Token

-- local Lexer = {}
-- Lexer.__index = Lexer

-- function Lexer:new(fn, source)
--     local instance = {
--         source = source,
--         tokens = {},
--         pos = Position:new(fn, source),
--         current_char = source:sub(1, 1)
--     }
--     setmetatable(instance, Lexer)
--     return instance
-- end

-- function Lexer:advance()
--     self.pos:advance(self.current_char)
--     if self.pos.idx < #self.source then
--         self.current_char = self.source:sub(self.pos.idx + 1, self.pos.idx + 1)
--     else
--         self.current_char = nil
--     end
--     return self.current_char
-- end

-- function Lexer:char_match(expected)
--     if self:is_at_end() then return false end
--     if self.source:sub(self.pos.idx + 1, self.pos.idx + 1) ~= expected then return false end
--     self:advance()
--     return true
-- end

-- function Lexer:peek()
--     if self:is_at_end() then return '\0' end
--     return self.source:sub(self.pos.idx + 1, self.pos.idx + 1)
-- end

-- function Lexer:is_at_end()
--     return self.pos.idx >= #self.source
-- end

-- function Lexer:is_digit(c)
--     return c:match("%d") ~= nil
-- end

-- function Lexer:is_alpha(c)
--     return c:match("%a") ~= nil
-- end

-- function Lexer:add_token(type, value)
--     local token = Token:new(type, value, self.pos:copy(), self.pos:copy())
--     table.insert(self.tokens, token)
-- end

-- function Lexer:string()
--     local start = self.pos:copy()
--     while self.current_char ~= "\"" and not self:is_at_end() do
--         if self.current_char == "\n" then
--             self.pos.ln = self.pos.ln + 1
--         end
--         self:advance()
--     end

--     if self:is_at_end() then
--         return nil, Errors.IllegalCharError:new(start, self.pos, "Unterminated string")
--     end

--     self:advance() -- The closing "
--     local value = self.source:sub(start.idx + 1, self.pos.idx - 1)
--     self:add_token(TokenType.STRING, value)
--     return true
-- end

-- function Lexer:number()
--     local start = self.pos:copy()
--     while self:is_digit(self.current_char) do
--         self:advance()
--     end

--     if self.current_char == "." and self:is_digit(self:peek()) then
--         self:advance()
--         while self:is_digit(self.current_char) do
--             self:advance()
--         end
--         self:add_token(TokenType.FLOAT, tonumber(self.source:sub(start.idx + 1, self.pos.idx)))
--     else
--         self:add_token(TokenType.INT, tonumber(self.source:sub(start.idx + 1, self.pos.idx)))
--     end
--     return true
-- end

-- function Lexer:identifier()
--     local start = self.pos:copy()
--     while self:is_alpha(self.current_char) or self:is_digit(self.current_char) do
--         self:advance()
--     end

--     local value = self.source:sub(start.idx + 1, self.pos.idx)
--     local type = TokenType.IDENTIFIER
--     for _, keyword in ipairs(token_module.KEYWORDS) do
--         if value == keyword then
--             type = TokenType.KEYWORD
--         end
--     end
--     self:add_token(type, value)
--     return true
-- end

-- function Lexer:scan_token()
--     local c = self.current_char
--     self:advance()
    
--     if c == "(" then self:add_token(TokenType.LPAREN)
--     elseif c == ")" then self:add_token(TokenType.RPAREN)
--     elseif c == "{" then self:add_token(TokenType.LBRACKET)
--     elseif c == "}" then self:add_token(TokenType.RBRACKET)
--     elseif c == "," then self:add_token(TokenType.COMMA)
--     elseif c == "." then self:add_token(TokenType.DOT)
--     elseif c == "-" then self:add_token(TokenType.MINUS)
--     elseif c == "+" then self:add_token(TokenType.PLUS)
--     elseif c == ":" then self:add_token(TokenType.COLON)
--     elseif c == ";" then self:add_token(TokenType.SEMICOLON)
--     elseif c == "*" then self:add_token(TokenType.MUL)
--     elseif c == "!" then
--         local token = self:char_match("=") and TokenType.NE or TokenType.BANG
--         self:add_token(token)
--     elseif c == "=" then
--         local token = self:char_match("=") and TokenType.EE or TokenType.EQ
--         self:add_token(token)
--     elseif c == "<" then
--         local token = self:char_match("=") and TokenType.LTE or (self:char_match("-") and TokenType.GETS or TokenType.LT)
--         self:add_token(token)
--     elseif c == ">" then
--         local token = self:char_match("=") and TokenType.GTE or (self:char_match("-") and TokenType.ARROW or TokenType.GT)
--         self:add_token(token)
--     elseif c == "/" then
--         if self:char_match("/") then
--             while self:peek() ~= "\n" and not self:is_at_end() do
--                 self:advance()
--             end
--         else
--             self:add_token(TokenType.DIV)
--         end
--     elseif c == "|" then
--         if self:char_match(">") then
--             self:add_token(TokenType.PIPE)
--         else
--             return nil, string.format("Expected '>' at line %d", self.pos.ln)
--         end
--     elseif c == " " or c == "\r" or c == "\t" then
--         -- Ignore whitespace
--     elseif c == "\n" then
--         self.pos.ln = self.pos.ln + 1
--         self:advance()
--     elseif c == "\"" then
--         local success, err = self:string()
--         if not success then return nil, err end
--     else
--         if self:is_digit(c) then
--             local success, err = self:number()
--             if not success then return nil, err end
--         elseif self:is_alpha(c) then
--             self:identifier()
--         else
--             return nil, string.format("Unrecognized char at line %d: %s", self.pos.ln, c)
--         end
--     end
--     return true
-- end

-- function Lexer:scan_tokens()
--     while self.current_char do
--         self.pos.start = self.pos.idx
--         local success, err = self:scan_token()
--         if not success then
--             return nil, err
--         end
--     end
--     self:add_token(TokenType.EOF)
--     return self.tokens
-- end

-- return Lexer

local Position = require("src.lang.position")
local Errors = require("src.lang.errors")
local Tokens = require("src.lang.tokens")

local TokenType = Tokens.TokenType
local Token = Tokens.Token

local Lexer = {}
Lexer.__index = Lexer

function Lexer:new(fn, source)
    local instance = {
        source = source,
        tokens = {},
        pos = Position:new(fn, source),
        current_char = source:sub(1, 1)
    }
    setmetatable(instance, Lexer)
    return instance
end
function Lexer:advance()
    self.pos:advance(self.current_char)
    if self.pos.idx < #self.source then
        self.current_char = self.source:sub(self.pos.idx + 1, self.pos.idx + 1)
    else
        self.current_char = nil
    end
    return self.current_char
end
function Lexer:char_match(expected)
    if self:is_at_end() then return false end
    if self.source:sub(self.pos.idx + 1, self.pos.idx + 1) ~= expected then return false end
    self:advance()
    return true
end
function Lexer:peek()
    if self:is_at_end() then return '\0' end
    return self.source:sub(self.pos.idx + 1, self.pos.idx + 1)
end
function Lexer:is_at_end()
    return self.pos.idx >= #self.source
end
function Lexer:is_digit(c)
    return c:match("%d") ~= nil
end
function Lexer:is_alpha(c)
    return c:match("%a") ~= nil
end
function Lexer:add_token(type, value)
    local token = Token:new(type, value, self.pos:copy(), self.pos:copy())
    table.insert(self.tokens, token)
end
function Lexer:make_string()
    local str, start = "", self.pos:copy()
    local escape_character = false
    self:advance()

    local escape_characters = {['n'] = "\n", ['t'] = "\t", ['r'] = "\r"}
    while self.current_char ~= nil and (self.current_char ~= "\"" or escape_character) do
        if escape_character then
            str = str..(escape_characters[self.current_char]
                or tostring(self.current_char))
        else
            if self.current_char == "\\" then escape_character = true
            else str = str..tostring(self.current_char) end
        end
        self:advance()
        escape_character = false
    end
    if self:is_at_end() then
        return nil, Errors.IllegalCharError:new(start, self.pos:copy(), "Unterminated string")
    end
    self:advance(); print(str)
    return self:add_token(TokenType.STRING, str)
end
function Lexer:make_number()
    local start = self.pos:copy()
    local num_str, dot_count = "", 0

    local match = string.match(Tokens.DIGITS, self.current_char)
    while self.current_char ~= nil and match.."." do
        if self.current_char == "." then
            if dot_count == 1 then break end
            dot_count = dot_count + 1
            num_str = num_str.."."
        else num_str = num_str..self.current_char end
        self:advance()
    end
    local tonum = tonumber(num_str)
    if dot_count == 0 then return self:add_token(TokenType.FLOAT, tonum)
    else return self:add_token(TokenType.INT, tonum) end
end
function Lexer:make_identifier()
    local id_str, start = "", self.pos:copy()
    while self.current_char ~= nil and
        (Tokens.LETTERS_DIGITS:find(self.current_char) or self.current_char == "_") do
        id_str = id_str..self.current_char; self:advance()
    end
    local function is_keyword(identifier)
        for _, keyword in ipairs(Tokens.KEYWORDS) do
            if keyword == identifier then return true end
        end return false
    end
    local new_token = is_keyword(id_str)
        and TokenType.KEYWORD or TokenType.IDENTIFIER
    print(new_token, id_str)
    return self:add_token(new_token, id_str)
end
function Lexer:skip_comment()
    self:advance()
    while self.current_char ~= "\n" do
        self:advance()
    end; self:advance()
end

function Lexer:scan_token()
    if self.current_char == "(" then self:add_token(TokenType.LPAREN); self:advance()
    elseif self.current_char == ")" then self:add_token(TokenType.RPAREN); self:advance()
    elseif self.current_char == "{" then self:add_token(TokenType.LBRACKET); self:advance()
    elseif self.current_char == "}" then self:add_token(TokenType.RBRACKET); self:advance()
    elseif self.current_char == "," then self:add_token(TokenType.COMMA); self:advance()
    elseif self.current_char == "." then self:add_token(TokenType.DOT); self:advance()
    elseif self.current_char == "-" then self:add_token(TokenType.MINUS); self:advance()
    elseif self.current_char == "+" then self:add_token(TokenType.PLUS); self:advance()
    elseif self.current_char == ":" then self:add_token(TokenType.COLON); self:advance()
    elseif self.current_char == ";" then self:add_token(TokenType.SEMICOLON); self:advance()
    elseif self.current_char == "*" then self:add_token(TokenType.MUL); self:advance()
    elseif self.current_char == "!" then
        local token = self:char_match("=") and TokenType.NE or TokenType.BANG
        self:add_token(token); self:advance()
    elseif self.current_char == "=" then
        local token = self:char_match("=") and TokenType.EE or TokenType.EQ
        self:add_token(token); self:advance()
    elseif self.current_char == "<" then
        local token = self:char_match("=") and TokenType.LTE or (self:char_match("-") and TokenType.GETS or TokenType.LT)
        self:add_token(token); self:advance()
    elseif self.current_char == ">" then
        local token = self:char_match("=") and TokenType.GTE or (self:char_match("-") and TokenType.ARROW or TokenType.GT)
        self:add_token(token); self:advance()
    elseif self.current_char == "/" then
        if self:char_match("/") then
            while self:peek() ~= "\n" and not self:is_at_end() do
                self:advance()
            end
        else
            self:add_token(TokenType.DIV)
            self:advance()
        end
    elseif self.current_char == "|" then
        if self:char_match(">") then
            self:add_token(TokenType.PIPE)
            self:advance()
        else
            return nil, string.format("Expected '>' at line %d", self.pos.ln)
        end
    elseif (self.current_char == "" or self.current_char == " ")
    or (self.current_char == "\r" or self.current_char == "\t") then
        self:advance() -- Ignore whitespace
    elseif self.current_char == "//" then
        self:skip_comment() -- Skip Comment
    elseif self.current_char == "\n" then
        self.pos.ln = self.pos.ln + 1
        self:advance()
    elseif self.current_char == "\"" or self.current_char == "'" then
        self:make_string()
        -- local success, err = self:string()
        -- if not success then return nil, err end
    else
        if self:is_digit(self.current_char) then
            local success, err = self:make_number()
            if not success then return nil, err end
        elseif self:is_alpha(self.current_char) then
            self:make_identifier()
        else
            return nil, string.format("Unrecognized char at line %d: %s", self.pos.ln, self.current_char)
        end
    end
    return true
end

function Lexer:scan_tokens()
    while self.current_char do
        self.pos.start = self.pos.idx
        local success, err = self:scan_token()
        if not success then
            return nil, err
        end
    end
    self:add_token(TokenType.EOF)
    return self.tokens
end

return Lexer