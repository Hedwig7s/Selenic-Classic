local require = require("customrequire")
local Vector3 = require("datatypes.vector3")

local record EntityPosition
    position: Vector3
    pitch: number
    yaw: number
    new: function(x:number, y:number, z:number, pitch:number, yaw:number): EntityPosition
end

EntityPosition.new = function(x:number, y:number, z:number, pitch:number, yaw:number): EntityPosition
    return {
        position = Vector3.new(x, y, z),
        pitch = pitch,
        yaw = yaw
    }
end

return EntityPosition