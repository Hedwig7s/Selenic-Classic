---@class AssertsModule
local module = {}

---Asserts a positional coordinate
---@param n number?
---@param err string
function module.positionAssert(n, err)
    assert(n and type(n) == "number" and n < 65536 and n >= 0, err or "Invalid position")
end

---Asserts angle
---@param n number?
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
    module.positionAssert(x, "Invalid x coordinate")
    module.positionAssert(y, "Invalid y coordinate")
    module.positionAssert(z, "Invalid z coordinate")
    if yaw then
        module.angleAssert(yaw, "Invalid yaw")
        module.angleAssert(pitch, "Invalid pitch")
    end
end

function module.assertId(id)
    assert(id and type(id) == "number" and id < 256 and id >= 0, "Invalid id")
end

function module.assertPacketString(str)
    assert(str and type(str) == "string" and #string <= 64, "Invalid string")
end

return module