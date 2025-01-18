local Errors = {}
Errors.__index = Errors

-- Utility function for colored output
local function colored_print(color_code, message)
    return string.format("\27[%sm%s\27[0m", color_code, message)
end

-- Color codes
local colors = {
    red = "31",
    green = "32",
    yellow = "33",
    blue = "34"
}

local function string_with_arrows(text, pos_start, pos_end)
    -- Check if text is nil
    if not text then
        return "Error: source text is nil"
    end

    local result = ""

    -- Calculate indices
    local idx_start = text:sub(1, pos_start.idx):reverse():find("\n") or 0
    local idx_end = text:find("\n", pos_start.idx + 1) or #text

    idx_start = pos_start.idx - idx_start
    idx_end = idx_end - 1

    -- Extract lines
    local line = text:sub(idx_start, idx_end)

    -- Add line to result
    result = result .. line .. "\n"

    -- Add arrows
    local col_start = pos_start.col
    local col_end = pos_end and pos_end.col or col_start + 1

    for _ = 1, col_start - 1 do
        result = result .. " "
    end
    for _ = col_start, col_end - 1 do
        result = result .. "^"
    end

    return result
end

local Error = {}
Error.__index = Error

function Error:new(pos_start, pos_end, error_name, details)
    local instance = {
        pos_start = pos_start,
        pos_end = pos_end,
        error_name = error_name,
        details = details
    }
    setmetatable(instance, Error)
    return instance
end

function Error:as_string()
    local result = string.format(
        "%s: %s",
        self.error_name,
        self.details
    )
    if self.pos_start and self.pos_end then
        result = result .. string.format(
            "\nFile %s, line %d",
            self.pos_start.fn,
            self.pos_start.ln
        )
        result = result .. "\n\n" .. string_with_arrows(self.pos_start.source, self.pos_start, self.pos_end)
    else
        result = result .. "\n[Position information not available]"
    end
    return result
end

Errors.Error = Error

local IllegalCharError = setmetatable({}, { __index = Error })
IllegalCharError.__index = IllegalCharError

function IllegalCharError:new(pos_start, pos_end, details)
    local instance = Error.new(self, pos_start, pos_end, "Illegal Character", details)
    setmetatable(instance, IllegalCharError)
    return instance
end

Errors.IllegalCharError = IllegalCharError

local ExpectedCharError = setmetatable({}, { __index = Error })
ExpectedCharError.__index = ExpectedCharError

function ExpectedCharError:new(pos_start, pos_end, details)
    local instance = Error.new(self, pos_start, pos_end, "Expected Character", details)
    setmetatable(instance, ExpectedCharError)
    return instance
end

Errors.ExpectedCharError = ExpectedCharError

local InvalidSyntaxError = setmetatable({}, { __index = Error })
InvalidSyntaxError.__index = InvalidSyntaxError

function InvalidSyntaxError:new(pos_start, pos_end, details)
    local instance = Error.new(self, pos_start, pos_end, "Invalid Syntax", details)
    setmetatable(instance, InvalidSyntaxError)
    return instance
end

Errors.InvalidSyntaxError = InvalidSyntaxError

local RTError = setmetatable({}, { __index = Error })
RTError.__index = RTError

function RTError:new(pos_start, pos_end, details, context)
    local instance = Error.new(self, pos_start, pos_end, "Runtime Error", details)
    instance.context = context
    setmetatable(instance, RTError)
    return instance
end

function RTError:as_string()
    local result = self:generate_traceback()
    result = result .. colored_print(colors.red, self.error_name) .. ": " .. self.details .. "\n"
    result = result .. string_with_arrows(self.pos_start.source, self.pos_start, self.pos_end)
    return result
end

function RTError:generate_traceback()
    local result = ""
    local pos = self.pos_start
    local ctx = self.context

    while ctx do
        result = "   File " .. pos.fn .. ", line " .. (pos.ln + 1) .. ", in " .. ctx.display_name .. "\n" .. result
        pos = ctx.parent_entry_pos
        ctx = ctx.parent
    end

    return "Traceback (most recent call last):\n" .. result
end

Errors.RTError = RTError

return Errors