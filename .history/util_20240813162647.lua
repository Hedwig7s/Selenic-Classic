---@class Util A collection of utility functions
local module = {}

---Deep copies a table
---@param obj table | any
---@return table | any
function module.deepCopy(obj)
    if type(obj) ~= "table" then
        return obj
    end
    local copy = {}
    for k, v in pairs(obj) do
        copy[module.deepCopy(k)] = module.deepCopy(v)
    end
    return copy
end

---Splits a string by a separator
---@param inputstr string
---@param sep string
---@return table<string>
function module.split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

---Converts a string to bytes
---@param str string
---@return number ...
function module.bytes(str)
    local t = {}
    for i = 1, #str do
        table.insert(t, str:sub(i, i):byte())
    end
    return unpack(t)
end

---Merges two tables where if t1 doesn't have a key from t2, it is added
---@param t1 table<any, any>
---@param t2 table<any, any>
function module.merge(t1, t2)
    t1 = module.deepCopy(t1)
    for k, v in pairs(t2) do
        if type(v) == "table" then
            if t1[k] then
                t1[k] = module.merge(t1[k], v)
            else
                t1[k] = module.deepCopy(v)
            end
        elseif not t1[k] then
            t1[k] = v
        end
    end
    return t1
end

---Pads a string with a character to a certain length
---@param str string
---@param len number
---@param char string
function module.pad(str, len, char)
    return str .. string.rep(char, len - #str)
end

---Checks if a table contains a value
---@param t table
---@param value any
---@return boolean
function module.contains(t, value)
    for _, v in pairs(t) do
        if v == value then
            return true
        end
    end
    return false
end

--- Makes a read-only table based on t
--- @param t table
--- @param recursive boolean?
--- @return table
function module.readOnlyTable(t, recursive)
    local subtables = {}
    if recursive then
        for k, v in pairs(t) do
            if type(v) == "table" then
                subtables[k] = module.readOnlyTable(v, true)
            end
        end
    end
    local proxy = newproxy(true)
    local meta = getmetatable(proxy)
    meta.__index = function(_, key)
        if subtables[key] then
            return subtables[key]
        end
        return t[key]
    end
    meta.__newindex = function()
        error("Cannot modify read-only table")
    end
    return proxy
end


return module