local require = require("customrequire")
local Vector3 = require("datatypes.vector3")

local record EntityPosition
    position: Vector3
    X: number
    Y: number
    Z: number
    pitch: number
    yaw: number
    new: function(x:number, y:number, z:number, pitch:number, yaw:number): EntityPosition
end

EntityPosition.new = function(x:number, y:number, z:number, pitch:number, yaw:number): EntityPosition
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