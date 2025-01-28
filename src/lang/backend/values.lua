local Errors = require("src.lang.common.errors")
local Results = require("src.lang.common.results")

local Values = {}
local Value, value_methods = {}, {
    set_pos = function(self, start, _end)
        self.pos_start = start
        self.pos_end = _end
        return self
    end,
    set_context = function(self, context)
        self.context = context; return self
    end,
    added = function(self, other)
        return nil, Errors.RTError(
            self.pos_start, self.pos_end,
            "Cannot add non-number value", self.context
        )
    end,
    subbed = function(self, other)
        return nil, Errors.RTError(
            self.pos_start, self.pos_end,
            "Cannot subtract non-number value", self.context
        )
    end,
    multed = function(self, other)
        return nil, Errors.RTError(
            self.pos_start, self.pos_end,
            "Cannot multiply non-number value", self.context
        )
    end,
    divided = function(self, other)
        return nil, Errors.RTError(
            self.pos_start, self.pos_end,
            "Cannot divide non-number value", self.context
        )
    end,
    powed = function(self, other)
        return nil, Errors.RTError(
            self.pos_start, self.pos_end,
            "Cannot raise non-number value", self.context
        )
    end,
    get_comparison_eq = function(self, other)
        return nil, Errors.RTError(
            self.pos_start, self.pos_end,
            "Cannot compare non-number value", self.context
        )
    end,
    get_comparison_ne = function(self, other)
        return nil, Errors.RTError(
            self.pos_start, self.pos_end,
            "Cannot compare non-number value", self.context
        )
    end,
    get_comparison_lt = function(self, other)
        return nil, Errors.RTError(
            self.pos_start, self.pos_end,
            "Cannot compare non-number value", self.context
        )
    end,
    get_comparison_gt = function(self, other)
        return nil, Errors.RTError(
            self.pos_start, self.pos_end,
            "Cannot compare non-number value", self.context
        )
    end,
    get_comparison_lte = function(self, other)
        return nil, Errors.RTError(
            self.pos_start, self.pos_end,
            "Cannot compare non-number value", self.context
        )
    end,
    get_comparison_gte = function(self, other)
        return nil, Errors.RTError(
            self.pos_start, self.pos_end,
            "Cannot compare non-number value", self.context
        )
    end,
    get_comparison_and = function(self, other)
        return nil, Errors.RTError(
            self.pos_start, self.pos_end,
            "Cannot compare non-number value", self.context
        )
    end,
    get_comparison_or = function(self, other)
        return nil, Errors.RTError(
            self.pos_start, self.pos_end,
            "Cannot compare non-number value", self.context
        )
    end,
    get_comparison_not = function(self)
        return nil, Errors.RTError(
            self.pos_start, self.pos_end,
            "Cannot compare non-number value", self.context
        )
    end,
    execute = function(self)
        return Results("RT"):failure(self:illegal_operation())
    end,
    copy = function(self) return error("No copy method for this value") end,
    is_true = function(self) return false end,
    illegal_operation = function(self, other)
        if not other then other = self end
        return Errors.RTError(
            self.pos_start, self.pos_end,
            "Illegal operation", self.context
        )
    end,
}
function Value:new(table, tostring_fn)
    local instance = table or {}
    setmetatable(instance, {
        __index = value_methods,
        __tostring = tostring_fn
    })
    instance:set_pos(); instance:set_context()
    return instance
end
Values.Value = Value

local Number, number_methods = {}, {}
local function is_instance(obj, class)
    if type(obj) ~= "table" then return false end
    local obj_class = getmetatable(obj)
    if not obj_class then return false end
    if class == Number then return obj_class.__index == number_methods end
    return false
end
number_methods = {
    set_pos = function(self, start, _end)
        self.pos_start = start
        self.pos_end = _end
        return self
    end,
    set_context = function(self, context)
        self.context = context; return self
    end,
    added = function(self, other)
        if is_instance(other, Number) then
            return Number:new(self.value + other.value)
                :set_context(self.context), nil
        end
        return self:added(other)
    end,
    subbed = function(self, other)
        if is_instance(other, Number) then
            return Number:new(self.value - other.value)
                :set_context(self.context), nil
        end
        return self:subbed(other)
    end,
    multed = function(self, other)
        if is_instance(other, Number) then
            return Number:new(self.value * other.value)
                :set_context(self.context), nil
        end
        return self:multed(other)
    end,
    divided = function(self, other)
        if is_instance(other, Number) then
            if other.value == 0 then
                return nil, Errors.RTError(
                    other.pos_start, other.pos_end,
                    "Cannot divide by zero.", self.context
                )
            end
            return Number:new(self.value / other.value)
                :set_context(self.context), nil
        end
        return self:divided(other)
    end,
    powed = function(self, other)
        if is_instance(other, Number) then
            return Number:new(self.value ^ other.value)
                :set_context(self.context), nil
        end
        return self:powed(other)
    end,
    get_comparison_eq = function(self, other)
        if is_instance(other, Number) then
            return Number:new(self.value == other.value)
                :set_context(self.context), nil
        end
        return self:get_comparison_eq(other)
    end,
    get_comparison_ne = function(self, other)
        if is_instance(other, Number) then
            return Number:new(self.value ~= other.value)
                :set_context(self.context), nil
        end
        return self:get_comparison_ne(other)
    end,
    get_comparison_lt = function(self, other)
        if is_instance(other, Number) then
            return Number:new(self.value < other.value)
                :set_context(self.context), nil
        end
        return self:get_comparison_lt(other)
    end,
    get_comparison_gt = function(self, other)
        if is_instance(other, Number) then
            return Number:new(self.value > other.value)
                :set_context(self.context), nil
        end
        return self:get_comparison_gt(other)
    end,
    get_comparison_lte = function(self, other)
        if is_instance(other, Number) then
            return Number:new(self.value <= other.value)
                :set_context(self.context), nil
        end
        return self:get_comparison_lte(other)
    end,
    get_comparison_gte = function(self, other)
        if is_instance(other, Number) then
            return Number:new(self.value >= other.value)
                :set_context(self.context), nil
        end
        return self:get_comparison_gte(other)
    end,
    get_comparison_and = function(self, other)
        if is_instance(other, Number) then
            return Number:new(self.value and other.value)
                :set_context(self.context), nil
        end
        return self:get_comparison_and(other)
    end,
    get_comparison_or = function(self, other)
        if is_instance(other, Number) then
            return Number:new(self.value or other.value)
                :set_context(self.context), nil
        end
        return self:get_comparison_or(other)
    end,
    get_comparison_not = function(self)
        return Number:new(not self.value)
            :set_context(self.context), nil
    end,
    copy = function(self)
        local copy = Number:new(self.value)
        copy:set_pos(self.pos_start, self.pos_end)
        copy:set_context(self.context)
        return copy
    end,
    is_true = function(self)
        if type(self.value) == "number" then
            if self.value == 1 then return true
            else return false end
        end
        if type(self.value) == "boolean" then return self.value end
        print("Unexpected value type:", type(self.value))
        return false
    end,
}
function Number:new(value)
    local instance = Value:new({ value = value },
        function(t) return tostring(t.value) end
    ); setmetatable(instance, {__index = number_methods})
    return instance
end
Values.Number = Number

local Function, function_methods = {}, {
    execute = function(self, args)
        local res, interpreter = Results("RT"), Interpreter:new()
        local context = Values("Context", self.name, self.context, self.pos_start)
        context.symbol_table = SymbolTable:new(context.parent.symbol_table)

        if #args > #self.arg_names then
            return res:failure(Errors.RTError(
                self.pos_start, self.pos_end,
                "Too many arguments passed into "..self.name,
                self.context
            ))
        end
        if #args < #self.arg_names then
            return res:failure(Errors.RTError(
                self.pos_start, self.pos_end,
                "Too few arguments passed into "..self.name,
                self.context
            ))
        end
        for i, arg in ipairs(args) do
            local arg_name, arg_value = self.arg_names[i], args[i]
            arg_value = res:set_context(context)
            context.symbol_table[arg_name] = arg_value
        end
        local result = res:register(interpreter:visit(self.body_node, context))
        if res.error then return res end
        return res:success(result)
    end,
    copy = function(self)
        local copy = Function:new(self.name, self.body_node, self.arg_names)
        copy:set_pos(self.pos_start, self.pos_end)
        copy:set_context(self.context)
        return copy
    end,
}
function Function:new(name, body_node, arg_names)
    local instance = Value:new({
        name = name or "<anonymous>",
        body_node = body_node, arg_names = arg_names
    }, function(t) return "<function> "..t.name end)
    setmetatable(instance, {__index = function_methods})
    return instance
end
Values.Function = Function

local Context = {}
function Context:new(display_name, parent, parent_entry_pos)
    return setmetatable({
        display_name = display_name, parent = parent,
        parent_entry_pos = parent_entry_pos, symbol_table = nil
    }, {})
end
Values.Context = Context

local SymbolTable = {}
local symbol_methods = {
    get = function(self, name)
        local value = self.symbols:get(name, nil)
        if value == nil and self.parent then
            return self.parent:get(name)
        end
        return value
    end,
    set = function(self, name, value) self.symbols[name] = value end,
    remove = function(self, name) self.symbols[name] = nil end,
}
function SymbolTable:new()
    return setmetatable({symbols = {}, parent = nil},
    {__index = function(t, key)
        return symbol_methods[key] or rawget(t, key)
    end})
end
Values.SymbolTable = SymbolTable

return setmetatable(Values, {
    __call = function(_, subclass_name, ...)
        local subclass = Values[tostring(subclass_name)]
        if subclass then return subclass:new(...)
        else error("Invalid value subclass: "..tostring(subclass_name)) end
    end
})