local require = require("customrequire")
local Vector3 = require("datatypes.vector3")


local record EntityPosition
    position: Vector3
    X: number
    Y: number
    Z: number
    pitch: integer
    yaw: integer
    new: function(x:number, y:number, z:number, yaw:number, pitch:number): EntityPosition
    metamethod __index: EntityPosition
    metamethod __tostring: function(self:EntityPosition): string
end

local EntityPositionMT: metatable<EntityPosition>
EntityPositionMT = {
    __index = EntityPosition,
    __tostring = function(self:EntityPosition): string
        return string.format("EntityPosition(%f, %f, %f, %d, %d)",self.X, self.Y, self.Z, self.yaw, self.pitch)
    end
}

EntityPosition.new = function(x:number, y:number, z:number, yaw:integer, pitch:integer): EntityPosition
    return setmetatable({
        position = Vector3.new(x, y, z),
        X = x,
        Y = y,
        Z = z,
        pitch = pitch,
        yaw = yaw
    }, EntityPositionMT)
end

return EntityPosition