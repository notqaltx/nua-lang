local Errors = require("src.lang.common.errors")

local pos_start = { fn = "test_file.lua", ln = 4, ft = "print('Hello World!')" }
local pos_end = { fn = "test_file.lua", ln = 4 }

-- Mock context for RTError
local context = {
    display_name = "main",
    parent_entry_pos = { fn = "test_file.lua", ln = 1 },
    parent = {
        display_name = "global",
        parent_entry_pos = { fn = "test_file.lua", ln = 0 },
        parent = nil
    }
}

-- Test IllegalCharError
local illegal_char_error = Errors("IllegalCharError", pos_start, pos_end, "Unexpected character '$'")
print(illegal_char_error)

-- Test ExpectedCharError
local expected_char_error = Errors("ExpectedCharError", pos_start, pos_end, "Expected ';' but found ','")
print(expected_char_error)

-- Test InvalidSyntaxError
local invalid_syntax_error = Errors("InvalidSyntaxError", pos_start, pos_end, "Invalid function call")
print(invalid_syntax_error)

-- Test RTError with context
local runtime_error_with_context = Errors.RTError:new(pos_start, pos_end, "Variable 'x' is undefined", context)
print(runtime_error_with_context)

-- Test RTError without context
local runtime_error_no_context = Errors.RTError:new(pos_start, pos_end, "Division by zero", nil)
print(runtime_error_no_context)

-- Invalid subclass (should throw an error)
local status, err = pcall(function()
    local invalid_error = Errors("NonExistentError", pos_start, pos_end, "This should fail")
end)

if not status then
    print("Caught expected error: " .. err)
end