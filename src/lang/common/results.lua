local Results = {}
local Parse, RT = {}, {}

local parse_methods = {
    register_advancement = function(self)
        local last = self.last_registered_advance
        local count = self.advance_count
        last = last + 1; count = count + 1
    end,
    register = function(self, res)
        local count = self.advance_count
        self.last_registered_advance = count
        count = count + res.advance_count
        if res.error then self.error = res.error end
        return res.node
    end,
    try_regiser = function(self, res)
        if res.error then
            self.to_reverse = res.advance_count
            return nil
        end
        return self:register(res)
    end,
    success = function(self, node)
        self.node = node
        return self
    end,
    failure = function(self, error)
        local last = self.last_registered_advance
        if not self.error or last == 0 then
            self.error = error
        end
        return self
    end,
}
function Parse:new()
    return setmetatable({
        error = nil, node = nil,
        last_registered_advance = 0,
        advance_count = 0, to_reverse = 0
    }, {__index = function(t, key)
        return parse_methods[key] or rawget(t, key)
    end})
end
Results.Parse = Parse

local rt_methods = {
    reset = function(self)
        self.value = nil; self.error = nil; self.func_return = nil
        self.loop_should_continue = false; self.loop_should_break = false
    end,
    register = function(self, res)
        self.error = res.error; self.func_return = res.func_return
        self.loop_should_continue = res.loop_should_continue
        self.loop_should_break = res.loop_should_break
        return res.value
    end,
    success = function(self, value)
        self:reset(); self.value = value
        return self
    end,
    success_return = function(self, value)
        self:reset()
        self.func_return = value
        return self
    end,
    success_continue = function(self)
        self:reset()
        self.loop_should_continue = true
        return self
    end,
    success_break = function(self)
        self:reset()
        self.loop_should_break = true
        return self
    end,
    failure = function(self, error)
        self:reset(); self.error = error
        return self
    end,
    should_return = function(self)
        return (
            self.error or self.func_return or
            self.loop_should_continue or
            self.loop_should_break
        )
    end,
}
function RT:new()
    local instance = {
        value = nil, error = nil, func_return = nil,
        loop_should_continue = false,
        loop_should_break = false
    }
    setmetatable(instance, {__index = function(t, key)
        return rt_methods[key] or rawget(t, key)
    end}); self:reset()
    return instance
end
Results.RT = RT

return setmetatable(Results, {
    __call = function(_, subclass_name)
        local subclass = Results[tostring(subclass_name)]
        if subclass then return subclass:new()
        else error("Invalid error subclass: "..tostring(subclass_name)) end
    end
})