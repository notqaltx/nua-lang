local Lexer = require("src.lang.lexer")
local Parser = require("src.lang.parser")
local Interpreter = require("src.lang.interpreter")
local Errors = require("src.lang.errors")

local Compiler = {}
Compiler.__index = Compiler

function Compiler:new()
    local instance = {}
    setmetatable(instance, Compiler)
    return instance
end

function Compiler:run(filename, source)
    -- Lexical analysis
    local lexer = Lexer:new(filename, source)
    local tokens, lexer_error = lexer:scan_tokens()
    if lexer_error then
        return nil, lexer_error
    end
    print(table.unpack(tokens))

    -- Parsing
    local parser = Parser:new(tokens)
    local ast, parser_error = parser:parse()
    if parser_error then
        return nil, parser_error
    end

    -- Interpretation
    local interpreter = Interpreter:new()
    local result, runtime_error = interpreter:interpret(ast)
    if runtime_error then
        return nil, runtime_error
    end

    return result, nil
end

return Compiler