local Position = {}
Position.__index = Position

function Position:new(index, line, column, filename, filetext)
    local instance = {
        idx = index or 0, ln = line or 0,
        column = column or 0, start = nil,
        fn = filename, ft = filetext
    }
    setmetatable(instance, Position)
    return instance
end
function Position:advance(current_char)
    self.idx = self.idx + 1
    self.column = self.column + 1
    if current_char == "\n" then
        self.ln = self.ln + 1
        self.column = 0
    end
    return self
end
function Position:copy()
    return Position:new(self.idx, self.ln, self.column, self.fn, self.ft)
end
return Position