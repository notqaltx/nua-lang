local Position = {}
Position.__index = Position

function Position:new(fn, source)
    local instance = {
        fn = fn,
        source = source,
        idx = 0,
        ln = 1,
        col = 1,
        start = 0,
        current = 0
    }
    setmetatable(instance, Position)
    return instance
end

function Position:advance(current_char)
    self.idx = self.idx + 1
    self.col = self.col + 1
    self.current = self.idx

    if current_char == "\n" then
        self.ln = self.ln + 1
        self.col = 1
    end
    print(string.format("Advanced to idx: %d, ln: %d, col: %d, char: %s", self.idx, self.ln, self.col, current_char))
end

function Position:copy()
    return setmetatable({
        fn = self.fn,
        source = self.source,
        idx = self.idx,
        ln = self.ln,
        col = self.col,
        start = self.start,
        current = self.current
    }, Position)
end

return Position