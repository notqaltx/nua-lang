local Position = {}
Position.__index = Position

function Position:new(index, line, column, filename, filetext)
    local instance = {
        idx = index or 0,
        line = line or 0,
        column = column or 0,
        filename = filename,
        filetext = filetext
    }
    setmetatable(instance, Position)
    return instance
end
function Position:advance(current_char)
    self.idx = self.idx + 1
    self.column = self.column + 1

    if current_char == "\n" then
        self.line = self.line + 1
        self.column = 0
    end
    return self
end
function Position:copy()
    return Position:new(self.idx, self.line, self.column, self.filename, self.filetext)
end
return Position