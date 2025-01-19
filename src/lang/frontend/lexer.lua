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
        if self.pos.idx < #self.source then
            self.current_char = self.source:sub(self.pos.idx + 1, self.pos.idx + 1)
        else self.current_char = nil end
        return self.current_char
    end,
    char_match = function(self, expected)
        if self:is_at_end() then return false end
        if self.source:sub(self.pos.idx + 1, self.pos.idx + 1) ~= expected then
            return false
        end; self:advance()
        return true
    end,
    peek = function(self)
        if self:is_at_end() then return '\0' end
        return self.source:sub(self.pos.idx + 1, self.pos.idx + 1)
    end,
    token = function(self, type, value, start, _end)
        local token = Token:new(type, value, start, _end)
        table.insert(self.tokens, token)
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
            return nil, Errors.IllegalCharError:new(start, self.pos:copy(), "Unterminated string")
        end
        self:advance(); print(str)
        return self:token(TokenType.STRING, str, start, self.pos:copy())
    end,
    make_number = function(self)
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
        if dot_count == 0 then return self:token(TokenType.FLOAT, tonum, start, self.pos:copy())
        else return self:token(TokenType.INT, tonum, start, self.pos:copy()) end
    end,
    make_identifier = function(self)
        local id_str, start = "", self.pos:copy()
        local new_tokens = Tokens.LETTERS_DIGITS
        -- if not new_tokens then return end

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
        print(new_token, id_str)
        return self:token(new_token, id_str, start, self.pos:copy())
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
        if self.current_char == "(" then self:token(TokenType.LPAREN); self:advance()
        elseif self.current_char == ")" then self:token(TokenType.RPAREN); self:advance()
        elseif self.current_char == "{" then self:token(TokenType.LBRACKET); self:advance()
        elseif self.current_char == "}" then self:token(TokenType.RBRACKET); self:advance()
        elseif self.current_char == "," then self:token(TokenType.COMMA); self:advance()
        elseif self.current_char == "." then self:token(TokenType.DOT); self:advance()
        elseif self.current_char == "-" then self:token(TokenType.MINUS); self:advance()
        elseif self.current_char == "+" then self:token(TokenType.PLUS); self:advance()
        elseif self.current_char == ":" then self:token(TokenType.COLON); self:advance()
        elseif self.current_char == ";" then self:token(TokenType.SEMICOLON); self:advance()
        elseif self.current_char == "*" then self:token(TokenType.MUL); self:advance()
        elseif self.current_char == "!" then
            local token = self:char_match("=") and TokenType.NE or TokenType.BANG
            self:token(token); self:advance()
        elseif self.current_char == "=" then
            local token = self:char_match("=") and TokenType.EE or TokenType.EQ
            self:token(token); self:advance()
        elseif self.current_char == "<" then
            local token = self:char_match("=") and TokenType.LTE or (self:char_match("-") and TokenType.GETS or TokenType.LT)
            self:token(token); self:advance()
        elseif self.current_char == ">" then
            local token = self:char_match("=") and TokenType.GTE or (self:char_match("-") and TokenType.ARROW or TokenType.GT)
            self:token(token); self:advance()
        elseif self.current_char == "/" then
            if self:char_match("/") then
                while self:peek() ~= "\n" and not self:is_at_end() do
                    self:advance()
                end
            else
                self:token(TokenType.DIV)
                self:advance()
            end
        elseif self.current_char == "|" then
            if self:char_match(">") then
                self:token(TokenType.PIPE)
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
            self.pos.line = self.pos.line + 1
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
    end,
    tokenize = function(self)
        while self.current_char do
            self.pos.start = self.pos.idx
            local success, err = self:scan_token()
            if not success then return nil, err end
        end
        self:token(TokenType.EOF)
        return self.tokens
    end,
}
function Lexer:new(fn, source)
    local instance = {
        source = source, tokens = {},
        pos = Position:new(0, 0, -1, fn, source),
        current_char = source:sub(1, 1)
    }
    setmetatable(instance, {
        __index = function(t, key)
            return lexer_methods[key] or rawget(t, key)
        end
    })
    return instance
end

return Lexer