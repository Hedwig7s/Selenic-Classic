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

---Asserts a positional coordinate
---@param n number
---@param err string
function module.positionAssert(n, err)
    assert(n and type(n) == "number" and n < 65536 and n >= 0, err or "Invalid position")
end

---Asserts angle
---@param n number
---@param err string
function module.angleAssert(n, err)
    assert(n and type(n) == "number" and n <= 192 and n >= 0, err or "Invalid angle")
end

--- Asserts coordinates
--- @param x number
--- @param y number
--- @param z number
--- @param yaw number?
--- @param pitch number?
function module.assertCoordinates(x, y, z, yaw, pitch)
    local function positionAssert(n)
        return n < 65536 and n >= 0
    end
    module.positionAssert(x, "Invalid x coordinate")
    module.positionAssert(y, "Invalid y coordinate")
    module.positionAssert(z, "Invalid z coordinate")
    if yaw then
        module.angleAssert(yaw, "Invalid yaw")
        module.angleAssert(pitch, "Invalid pitch")
    end
end

return module