local Position = require("src.lang.common.position")
local Errors = require("src.lang.common.errors")
local Tokens = require("src.lang.frontend.tokens")

local TokenType = Tokens.TokenType
local Token = Tokens.Token

local Lexer = {}
Lexer.__index = Lexer

local lexer_methods = {
    advance = function(self)
        self.pos:advance(self.current_char)
        self.current_char = self.pos.idx < string.len(self.source)
            and self.source:sub(self.pos.idx + 1, self.pos.idx + 1) or nil
        return self.current_char
    end,
    reverse = function(self)
        self.pos.idx = self.pos.idx - 1
        self.current_char = self.source:sub(self.pos.idx + 1, self.pos.idx + 1)
        return self.current_char
    end,
    char_match = function(self, expected)
        if self:is_at_end() then return false end
        local char = self.source:sub(self.pos.idx + 1, self.pos.idx + 1)
        if char ~= expected then return false end
        self:advance(); return true
    end,
    peek = function(self, ahead)
        ahead = ahead or 1
        local peek_idx = self.pos.idx + ahead
        if self:is_at_end() then return '\0' end
        return self.source:sub(peek_idx, peek_idx)
    end,
    token = function(self, type, value, start, _end)
        local token = Token:new(type, value, start, _end)
        table.insert(self.tokens, token); return token
    end,
    add_token = function(self, ...)
        local tbl = table.pack(...)
        tbl[2] = tbl[2] or self.pos; tbl[3] = tbl[3] or nil
        self:token(tbl[1], nil, tbl[2], tbl[3])
        return self:advance()
    end,
    make_not_equals = function(self)
        local start = self.pos:copy(); self:advance()
        if self.current_char == "=" then self:advance()
            return self:add_token(TokenType.NE, start, self.pos), nil
        end
        self:advance()
        return nil, Errors(
            "ExpectedCharError", start, 
            self.pos, "\"=\" (after \"!\")")
    end,
    make_equals = function(self)
        local token_type = TokenType.EQ
        local start = self.pos:copy(); self:advance()
        
        if self.current_char == "=" then self:advance(); token_type = TokenType.EE
        end return self:add_token(token_type, start, self.pos)
    end,
    make_less_than = function(self)
        local token_type = TokenType.LT
        local start = self.pos:copy(); self:advance()
        
        if self.current_char == "=" then self:advance(); token_type = TokenType.LTE
        end return self:add_token(token_type, start, self.pos)
    end,
    make_greater_than = function(self)
        local token_type = TokenType.GT
        local start = self.pos:copy(); self:advance()
        
        if self.current_char == "=" then self:advance(); token_type = TokenType.GTE
        end return self:add_token(token_type, start, self.pos)
    end,
    make_minus = function(self)
        local token_type = TokenType.MINUS
        local start = self.pos:copy(); self:advance()
        local next_token = self.current_char

        if next_token == ">" then self:advance(); token_type = TokenType.ARROW
        elseif self:is_digit(next_token) then
            local num_token, err = self:make_number()
            if err then return nil, err end
        end
        return self:add_token(token_type, start, self.pos)
    end,
    make_ampersand = function(self)
        local token_type = TokenType.AMPERSAND
        local start = self.pos:copy(); self:advance()

        if self.current_char == "&" then self:advance(); token_type = TokenType.AND
        end return self:add_token(token_type, start, self.pos)
    end,
    make_pipe = function(self)
        local token_type = TokenType.PIPE
        local start = self.pos:copy(); self:advance()

        if self.current_char == "|" then self:advance(); token_type = TokenType.OR
        elseif self.current_char == ">" then self:advance(); token_type = TokenType.PGT
        end return self:add_token(token_type, start, self.pos)
    end,
    make_dot = function(self)
        local token_type, new_token = nil, nil
        local start = self.pos:copy(); self:advance()

        if self.current_char == "." then self:advance()
            if self.current_char == "=" then self:advance();
                new_token = self:add_token(TokenType.DDE, start, self.pos)
            else new_token = self:add_token(TokenType.DD, start, self.pos) end
            self:reverse()

            if self:is_digit(self.current_char) then
                local num_token, err = self:make_number()
                if err then return nil, err end
            end
        else
            new_token = self:add_token(TokenType.DOT, start, self.pos)
        end 
        return new_token
    end,
    make_string = function(self)
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
            return nil, Errors("IllegalCharError", start, self.pos:copy(), "Unterminated string")
        end; self:advance()
        return self:token(TokenType.STRING, str, start), nil
    end,
    make_number = function(self)
        local start = self.pos:copy()
        local num_str, dot_count = "", 0

        if self:peek(2) == "." and self:peek(3) == "." then
            while self.current_char ~= nil and self:is_digit(self.current_char) do
                num_str = num_str..self.current_char
                self:advance()
            end
        else
            while self.current_char ~= nil and (self:is_digit(self.current_char) or self.current_char == ".") do
                if self.current_char == "." then
                    if dot_count == 1 then break end
                    dot_count = dot_count + 1
                    num_str = num_str.."."
                else
                    num_str = num_str..self.current_char
                end
                self:advance()
            end
        end
        local tonum = tonumber(num_str)
        if dot_count == 0 then return self:token(TokenType.INT, tonum, start), nil
        else return self:token(TokenType.FLOAT, tonum, start), nil end
    end,
    make_identifier = function(self)
        local id_str, start = "", self.pos:copy()
        local new_tokens = Tokens.LETTERS_DIGITS

        while self.current_char ~= nil and
            (string.find(new_tokens, self.current_char) or self.current_char == "_") do
            id_str = id_str..self.current_char; self:advance()
        end
        local function is_keyword(identifier)
            for _, keyword in ipairs(Tokens.KEYWORDS) do
                if keyword == identifier then return true end
            end return false
        end
        local new_token = is_keyword(id_str)
            and TokenType.KEYWORD or TokenType.IDENTIFIER
        return self:token(new_token, id_str, start)
    end,
    skip_comment = function(self)
        self:advance()
        while self.current_char ~= "\n" do
            self:advance()
        end; self:advance()
    end,
    is_at_end = function(self) return self.pos.idx >= #self.source end,
    is_digit = function(self, char) return char:match("%d") ~= nil end,
    is_alpha = function(self, char) return char:match("%a") ~= nil end,

    scan_token = function(self)
        if self.current_char == "(" then self:add_token(TokenType.LPAREN, self.pos)
        elseif self.current_char == ")" then self:add_token(TokenType.RPAREN, self.pos)
        elseif self.current_char == "{" then self:add_token(TokenType.LBRACKET, self.pos)
        elseif self.current_char == "}" then self:add_token(TokenType.RBRACKET, self.pos)
        elseif self.current_char == "," then self:add_token(TokenType.COMMA, self.pos)
        elseif self.current_char == "+" then self:add_token(TokenType.PLUS, self.pos)
        elseif self.current_char == "^" then self:add_token(TokenType.POW, self.pos)
        elseif self.current_char == ":" then self:add_token(TokenType.COLON, self.pos)
        elseif self.current_char == ";" then self:add_token(TokenType.SEMICOLON, self.pos)
        elseif self.current_char == "*" then self:add_token(TokenType.MUL, self.pos)
        elseif self.current_char == "." then self:make_dot()
        elseif self.current_char == "=" then self:make_equals()
        elseif self.current_char == "<" then self:make_less_than()
        elseif self.current_char == ">" then self:make_greater_than()
        elseif self.current_char == "-" then self:make_minus()
        elseif self.current_char == "&" then self:make_ampersand()
        elseif self.current_char == "|" then self:make_pipe()
        elseif self.current_char == "!" then
            local token, error = self:make_not_equals()
            if error then return {}, error end
        elseif self.current_char == "/" then
            self:advance()
            if self:char_match("/") then
                while self:peek() ~= "\n"
                and not self:is_at_end() do
                    self:advance()
                end
            else self:add_token(TokenType.DIV, self.pos) end
        elseif (self.current_char == "" or self.current_char == " ")
        or (self.current_char == "\r" or self.current_char == " \t") then
            self:advance() -- Ignore whitespace
        elseif self.current_char == "//" then
            self:skip_comment() -- Skip Comment
        elseif self.current_char == "\n" then self:add_token(TokenType.NEWLINE, self.pos)
        elseif self.current_char == "\"" or self.current_char == "'" then
            local success, err = self:make_string()
            if not success then return nil, err end
        else
            if self:is_digit(self.current_char) then
                local success, err = self:make_number()
                if not success then return nil, err end
            elseif self:is_alpha(self.current_char) then
                self:make_identifier()
            else
                local pos_start = self.pos:copy()
                local char = self.current_char; self:advance()
                return {}, Errors(
                    "IllegalCharError", pos_start, self.pos,
                    string.format("\"%s\"", char))
            end
        end
        return true
    end,
    tokenize = function(self)
        while self.current_char ~= nil do
            local success, err = self:scan_token()
            if not success then return {}, err end
        end
        self:token(TokenType.EOF, nil, self.pos)
        return self.tokens, nil
    end,
}
function Lexer:new(fn, source)
    local instance = {
        source = source, tokens = {},
        pos = Position:new(-1, 0, -1, fn, source),
        -- current_char = source:sub(1, 1)
        current_char = nil
    }
    setmetatable(instance, {__index = function(t, key)
        return lexer_methods[key] or rawget(t, key)
    end}); instance:advance()
    return instance
end

return Lexer