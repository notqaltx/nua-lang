local Nodes = {}
local function create_node(name, constructor)
    local class = setmetatable({ __name = name }, {})
    class.__index = class
    class.new = constructor or function(_, ...)
        return setmetatable({}, class)
    end
    setmetatable(class, {__index = function(_, key)
        if key == "__name" then return name end
    end}); Nodes[name] = class
    return class
end
local Number = create_node("NumberNode", function(_, token)
    return setmetatable({
        __name = "NumberNode", token = token,
        pos_start = token.pos_start,
        pos_end = token.pos_end
    }, {
        __index = Number,
        __tostring = function(t)
            return tostring(t.token)
        end
    })
end)
local String = create_node("StringNode", function(_, token)
    return setmetatable({
        __name = "StringNode", token = token,
        pos_start = token.pos_start,
        pos_end = token.pos_end
    }, {
        __index = String,
        __tostring = function(t)
            return tostring(t.token)
        end
    })
end)
local List = create_node("ListNode", function(_, elements, pos_start, pos_end)
    return setmetatable({
        __name = "ListNode",
        element_nodes = elements,
        pos_start = pos_start,
        pos_end = pos_end
    }, { __index = List })
end)
local VarAccess = create_node("VarAccessNode", function(_, var_name_token)
    return setmetatable({
        __name = "VarAccessNode",
        var_name_token = var_name_token,
        pos_start = var_name_token.pos_start,
        pos_end = var_name_token.pos_end
    }, { __index = VarAccess })
end)
local VarAssign = create_node("VarAssignNode", function(_, var_name_token, value_node)
    return setmetatable({
        __name = "VarAssignNode",
        var_name_token = var_name_token,
        value_node = value_node,
        pos_start = var_name_token.pos_start,
        pos_end = value_node.pos_end
    }, { __index = VarAssign })
end)
local BinOp = create_node("BinOpNode", function(_, left, op_token, right)
    return setmetatable({
        __name = "BinOpNode",
        left_node = left,
        op_token = op_token,
        right_node = right,
        pos_start = left.pos_start,
        pos_end = right.pos_end
    }, {
        __index = BinOp,
        __tostring = function(t)
            return string.format(
                "(%s, %s, %s)", t.left_node,
                t.op_token, t.right_node
            )
        end
    })
end)
local UnaryOp = create_node("UnaryOpNode", function(_, op_token, node)
    return setmetatable({
        __name = "UnaryOpNode",
        op_token = op_token,
        node = node,
        pos_start = op_token.pos_start,
        pos_end = node.pos_end
    }, {
        __index = UnaryOp,
        __tostring = function(t)
            return string.format("(%s, %s)", t.op_token, t.node)
        end
    })
end)
return setmetatable(Nodes, {
    __call = function(_, subclass_name, ...)
        local subclass = Nodes[tostring(subclass_name)]
        if subclass and subclass.new then return subclass:new(...)
        elseif subclass then return subclass
        else error("Invalid node subclass: "..tostring(subclass_name)) end
    end
})