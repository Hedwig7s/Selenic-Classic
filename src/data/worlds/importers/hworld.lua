local require = require("customrequire")
local zlib = require("zlib")
local EntityPosition = require("datatypes.entityposition")
local Vector3 = require("datatypes.vector3")
local Buffer = require("buffer").Buffer

local sharedFunctions = {
	parseHeader = function(data)
		local _, sizeX, sizeY, sizeZ, spawnX, spawnY, spawnZ, spawnYaw, spawnPitch = string.unpack("<I4HHHHHHBB", data)
		local size = Vector3.new(sizeX, sizeY, sizeZ)
		local spawn = EntityPosition.new(spawnX, spawnY, spawnZ, spawnYaw, spawnPitch)
		return size, spawn
	end,
	parseBlockData = function(data, size)
		local blocks = Buffer:new(math.floor(size.X * size.Y * size.Z))
		local blockI = 1
		for i = 1, #data, 5 do
			local id, count = string.unpack("<BI4", data:sub(i, i + 4))
			for _ = 1, count do
				blocks:writeUInt8(blockI, id)
				blockI = blockI + 1
			end
		end

		return blocks
	end,
}

local ret = {
	versions = {
		[2] = function(name, data)
			local size, spawn = sharedFunctions.parseHeader(data:sub(1, 18))
			data = data:sub(19)
			local blocks = sharedFunctions.parseBlockData(data, size)
			return { name = name, size = size, spawn = spawn, blocks = blocks }
		end,
		[3] = function(name, data)
			local size, spawn = sharedFunctions.parseHeader(data:sub(1, 18))
			data = data:sub(19)
			local blockData = zlib.inflate()(data, "finish")
			local blocks = sharedFunctions.parseBlockData(blockData, size)
			return { name = name, size = size, spawn = spawn, blocks = blocks }
		end,
	},
	getVersion = function(_, data)
		return string.unpack("<I4", data:sub(1, 4))
	end,
}
return ret
