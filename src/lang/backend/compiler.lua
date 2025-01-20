local Lexer = require("src.lang.frontend.lexer")
local Parser = require("src.lang.frontend.parser")
local Interpreter = require("src.lang.backend.interpreter")
local Errors = require("src.lang.common.errors")
local Values = require("src.lang.backend.values")

local Compiler = {}
Compiler.__index = Compiler

function Compiler:new()
    local instance = { global_symbol_table = Values("SymbolTable") }
    instance.global_symbol_table["nil"] = Values("Number", 0)
    setmetatable(instance, Compiler); return instance
end
function Compiler:run(fn, source)
    local lexer = Lexer:new(fn, source)
    local tokens, error = lexer:tokenize()
    if error then return nil, error end
    print(table.unpack(tokens))

    local parser = Parser:new(tokens)
    local ast = parser:parse()
    if ast.error then return nil, ast.error end

    local interpreter = Interpreter:new()
    local context = Values("Context", "<program>")
    context.symbol_table = self.global_symbol_table

    local result = interpreter:visit(ast.node, context)
    return result.value, result.error
end

return Compiler