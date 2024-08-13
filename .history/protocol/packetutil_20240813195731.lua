local module = {}
local util = require("../util")
local packets = require("../packets")
local asserts = require("../asserts")
local connections = packets.connections

---Formats string to 64 characters with padding
---@param str string
---@return string
function module.formatString(str)
    return util.pad(str,64,"\32")
end

---Reverts packet padding on a string
---@param str string
---@return string
function module.unformatString(str)
    for i = #str,1,-1 do
        if str:sub(i,i) ~= "\32" then
            return str:sub(1,i)
        end
    end
    return ""
end

---Converts numbers to fixed point
---@param ... number
---@return number ...
function module.toFixedPoint(...)
    local values = {}
    for _,v in pairs({...}) do
        table.insert(values, math.floor(v * 32))
    end
    return unpack(values) 
end

---Converts fixed point to numbers
---@param ... number
---@return number ...
function module.fromFixedPoint(...)
    local values = {}
    for _,v in pairs({...}) do
        table.insert(values, v/32)
    end
    return unpack(values) 
end

---@param id number
---@param x number?
---@param y number?
---@param z number?
---@param yaw number?
---@param pitch number?
---@param connection Connection
---@param dataProvider fun(id:number, x:number?, y:number?, z:number?, yaw:number?, pitch:number?):string
---@param skipSelf boolean?
function module.baseMovementPacket(connection, id, x, y, z, yaw, pitch, dataProvider, skipSelf)
    if not connection.player then
        return
    elseif (connection.player.id == id or id < 0) and skipSelf then
        return true
    end
    asserts.assertId(id)
    if x then
        asserts.assertCoordinates(x, y, z)
        x, y, z = module.toFixedPoint(x, y, z)
    end
    if yaw then
        asserts.angleAssert(yaw, "Invalid yaw")
        asserts.angleAssert(pitch, "Invalid pitch")
    end

    return connection.write(dataProvider(id, x, y, z, yaw, pitch))
end

function module.dummyPacket(...)
    return true
end

return module