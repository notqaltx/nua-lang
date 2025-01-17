-- src/lang/compiler.lua

local Lexer = require("src.lang.lexer")
local Parser = require("src.lang.parser")
local Interpreter = require("src.lang.interpreter")

local Compiler = {}
Compiler.__index = Compiler

function Compiler:new()
    local instance = {}
    setmetatable(instance, Compiler)
    return instance
end

function Compiler:run(source)
    local lexer = Lexer:new(source)
    local tokens = lexer:scan_tokens()
    local parser = Parser:new(tokens)
    local ast = parser:parse()
    local interpreter = Interpreter:new()
    interpreter:interpret(ast)
end

return Compiler