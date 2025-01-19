local Lexer = require("src.lang.frontend.lexer")
local Parser = require("src.lang.frontend.parser")
local Interpreter = require("src.lang.backend.interpreter")
local Errors = require("src.lang.common.errors")

local Compiler = {}
Compiler.__index = Compiler

function Compiler:new()
    local instance = {}
    setmetatable(instance, Compiler)
    return instance
end
function Compiler:run(filename, source)
    local lexer = Lexer:new(filename, source)
    local tokens, lexer_error = lexer:tokenize()
    if lexer_error then
        return nil, lexer_error
    end
    print(table.unpack(tokens))

    local parser = Parser:new(tokens)
    local ast, parser_error = parser:parse()
    if parser_error then
        return nil, parser_error
    end
    local interpreter = Interpreter:new()
    local result, runtime_error = interpreter:interpret(ast)
    if runtime_error then
        return nil, runtime_error
    end
    return result, nil
end

return Compiler