local require = require("customrequire")
local Vector3 = require("datatypes.vector3")

local record EntityPosition
    position: Vector3
    X: number
    Y: number
    Z: number
    pitch: number
    yaw: number
    new: function(x:number, y:number, z:number, yaw:number, pitch:number): EntityPosition
    __tostring: function(self:EntityPosition): string
end

EntityPosition.__tostring = function(self:EntityPosition): string
    return string.format("EntityPosition(%3f, %3f, %3f, %3f, %3f)",self.X, self.Y, self.Z, self.yaw, self.pitch)
end

EntityPosition.new = function(x:number, y:number, z:number, yaw:number, pitch:number): EntityPosition
    return setmetatable({
        position = Vector3.new(x, y, z),
        X = x,
        Y = y,
        Z = z,
        pitch = pitch,
        yaw = yaw
    }, EntityPosition)
end

return EntityPosition