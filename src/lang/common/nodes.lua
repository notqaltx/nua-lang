local Nodes = {}

local Number = {}
function Number:new(token)
    return setmetatable({
        token = token,
        pos_start = token.pos_start,
        pos_end = token.pos_end
    }, {
        __tostring = function(t)
            return tostring(t.token)
        end
    })
end
local String = {}
function String:new(token)
    return setmetatable({
        token = token,
        pos_start = token.pos_start,
        pos_end = token.pos_end
    }, {
        __tostring = function(t)
            return tostring(t.token)
        end
    })
end
local List = {}
function List:new(elements, start, _end)
    return setmetatable({
        element_nodes = elements,
        pos_start = start, pos_end = _end
    }, {})
end
local VarAccess = {}
function VarAccess:new(var_name_token)
    return setmetatable({
        var_name_token = var_name_token,
        pos_start = var_name_token.pos_start,
        pos_end = var_name_token.pos_end
    }, {})
end
local VarAssign = {}
function VarAssign:new(var_name_token, value_node)
    return setmetatable({
        var_name_token = var_name_token,
        value_node = value_node,
        pos_start = var_name_token.pos_start,
        pos_end = value_node.pos_end
    }, {})
end
local BinOp = {}
function BinOp:new(left, op_token, right)
    return setmetatable({
        left_node = left,
        op_token = op_token,
        right_node = right,

        pos_start = left.pos_start,
        pos_end = right.pos_end
    }, {
        __tostring = function(t)
            return string.format(
                "(%s, %s, %s)", t.left_node,
                t.op_token, t.right_node
            )
        end
    })
end
local UnaryOp = {}
function UnaryOp:new(op_token, node)
    return setmetatable({
        op_token = op_token, node = node,
        pos_start = op_token.pos_start,
        pos_end = node.pos_end
    }, {
        __tostring = function(t)
            return string.format("(%s, %s)", t.op_token, t.node)
        end
    })
end
return setmetatable(Nodes, {
    __call = function(_, subclass_name)
        local subclass = Nodes[tostring(subclass_name)]
        if subclass then return subclass:new()
        else error("Invalid node subclass: "..tostring(subclass_name)) end
    end
})