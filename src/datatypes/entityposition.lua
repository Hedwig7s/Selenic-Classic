local require = require("customrequire")
local Vector3 = require("datatypes.vector3")

local EntityPosition = {}

local EntityPositionMT
EntityPositionMT = {
	__index = EntityPosition,
	__tostring = function(self)
		return string.format("EntityPosition(%f, %f, %f, %d, %d)", self.X, self.Y, self.Z, self.yaw, self.pitch)
	end,
}

EntityPosition.new = function(x, y, z, yaw, pitch)
	return setmetatable({
		position = Vector3.new(x, y, z),
		X = x,
		Y = y,
		Z = z,
		pitch = pitch,
		yaw = yaw,
	}, EntityPositionMT)
end

return EntityPosition
