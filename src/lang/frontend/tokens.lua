local TokenType = {
    -- Define all token types here
    INT = 'INT',
    FLOAT = 'FLOAT',
    STRING = 'STRING',
    IDENTIFIER = 'IDENTIFIER',
    KEYWORD = 'KEYWORD',
    PLUS = 'PLUS',
    MINUS = 'MINUS',
    MUL = 'MUL',
    DIV = 'DIV',
    EQ = 'EQ',
    LPAREN = 'LPAREN',
    RPAREN = 'RPAREN',
    LBRACKET = 'LBRACKET',
    RBRACKET = 'RBRACKET',
    COMMA = 'COMMA',
    DOT = 'DOT',
    SEMICOLON = 'SEMICOLON',
    COLON = 'COLON',
    BANG = 'BANG',
    EE = 'EE',
    NE = 'NE',
    LT = 'LT',
    GT = 'GT',
    LTE = 'LTE',
    GTE = 'GTE',
    PIPE = 'PIPE',
    ARROW = 'ARROW',
    EOF = 'EOF'
}
local DIGITS = '0123456789'
local LETTERS = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
local LETTERS_DIGITS = LETTERS..DIGITS

local KEYWORDS = {
    'let', 'and', 'or', 'not',
    'if', 'then', 'elif', 'else',
    'for', 'to', 'step', 'while',
    'do', 'func', 'end', 'return',
    'break', 'continue', 'print'
}
local Token = {}
Token.__index = Token

function Token:new(type_, value, pos_start, pos_end)
    local instance = {
        type = type_, value = value,
        pos_start = pos_start and pos_start:copy() or nil,
        pos_end = pos_end and pos_end:copy() or nil
    }
    if pos_start then
        instance.pos_end = pos_start:copy()
        instance.pos_end:advance()
    end
    setmetatable(instance, {
        __tostring = function(t)
            if t.value then
                return string.format("%s:%s", t.type, t.value)
            end
            return t.type
        end,
        __call = function(self, _type, value)
            return self.type == _type and self.value == value
        end
    })
    return instance
end
return {
    DIGITS = DIGITS,
    LETTERS = LETTERS,
    LETTERS_DIGITS = LETTERS_DIGITS,
    KEYWORDS = KEYWORDS,
    TokenType = TokenType,
    Token = Token
}