local Errors = require("src.lang.common.errors")

local Values = {}
local function is_instance(obj, class)
    return getmetatable(obj) == class
end
local Number = {}
local number_methods = {
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
            print(self.value, other.value)
            return Number:new(self.value + other.value)
                :set_context(self.context), nil
        end
    end,
    subbed = function(self, other)
        if is_instance(other, Number) then
            return Number:new(self.value - other.value)
                :set_context(self.context), nil
        end
    end,
    multed = function(self, other)
        if is_instance(other, Number) then
            return Number:new(self.value * other.value)
                :set_context(self.context), nil
        end
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
    end,
    powed = function(self, other)
        if is_instance(other, Number) then
            return Number:new(self.value ^ other.value)
                :set_context(self.context), nil
        end
    end,
    get_comparison_eq = function(self, other)
        if is_instance(other, Number) then
            return Number:new(self.value == other.value)
                :set_context(self.context), nil
        end
    end,
    get_comparison_ne = function(self, other)
        if is_instance(other, Number) then
            return Number:new(self.value ~= other.value)
                :set_context(self.context), nil
        end
    end,
    get_comparison_lt = function(self, other)
        if is_instance(other, Number) then
            return Number:new(self.value < other.value)
                :set_context(self.context), nil
        end
    end,
    get_comparison_gt = function(self, other)
        if is_instance(other, Number) then
            return Number:new(self.value > other.value)
                :set_context(self.context), nil
        end
    end,
    get_comparison_lte = function(self, other)
        if is_instance(other, Number) then
            return Number:new(self.value <= other.value)
                :set_context(self.context), nil
        end
    end,
    get_comparison_gte = function(self, other)
        if is_instance(other, Number) then
            return Number:new(self.value >= other.value)
                :set_context(self.context), nil
        end
    end,
    get_comparison_and = function(self, other)
        if is_instance(other, Number) then
            return Number:new(self.value and other.value)
                :set_context(self.context), nil
        end
    end,
    get_comparison_or = function(self, other)
        if is_instance(other, Number) then
            return Number:new(self.value or other.value)
                :set_context(self.context), nil
        end
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
        return self.value ~= 0
    end,
}
function Number:new(value)
    local instance = { value = value }
    setmetatable(instance, {
        __index = function(t, key)
            return number_methods[key] or rawget(t, key)
        end,
        __tostring = function(t)
             return tostring(t.value)
        end
    })
    instance:set_pos(); instance:set_context()
    return instance
end
Values.Number = Number

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