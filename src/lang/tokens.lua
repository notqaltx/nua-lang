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

-- Token class definition
local Token = {}
Token.__index = Token

function Token:new(type_, value, pos_start, pos_end)
    local instance = {
        type = type_,
        value = value,
        pos_start = pos_start and pos_start:copy() or nil,
        pos_end = pos_end and pos_end:copy() or nil
    }
    if pos_start then
        instance.pos_end = pos_start:copy()
        instance.pos_end:advance()
    end
    setmetatable(instance, Token)
    return instance
end
function Token:matches(type_, value)
    return self.type == type_ and self.value == value
end
function Token:__tostring()
    if self.value then
        return string.format('%s:%s', self.type, self.value)
    end
    return self.type
end
return {
    TokenType = TokenType,
    DIGITS = DIGITS,
    LETTERS = LETTERS,
    LETTERS_DIGITS = LETTERS_DIGITS,
    KEYWORDS = KEYWORDS,
    Token = Token
}