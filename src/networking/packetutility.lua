local module = {}
local require = require("customrequire")

function module.sendPacket(connection, format, ...)
	local data = { ... }
	for i, v in ipairs(data) do
		if type(v) == "string" then
			local str = v
			data[i] = str .. string.rep("\32", math.max(64 - #str, 0))
		end
	end
	return connection:write(string.pack(format, unpack(data)))
end

function module.parsePacket(format, data)
	local unpackedData = { string.unpack(format, data) }
	for i, v in ipairs(unpackedData) do
		if type(v) == "string" then
			local str = v
			for j = #v, 1, -1 do
				if str:sub(j, j) ~= "\32" then
					str = str:sub(1, j)
					break
				end
			end
			unpackedData[i] = str
		end
	end
	return unpack(unpackedData)
end
function module.toFixedPoint(...)
	local data = { ... }
	local fixedData = {}
	for _, v in ipairs(data) do
		table.insert(fixedData, math.floor(v * 32))
	end
	return unpack(fixedData)
end

function module.fromFixedPoint(...)
	local data = { ... }
	for i, v in ipairs(data) do
		data[i] = v / 32
	end
	return unpack(data)
end

function module.formatEntityPosition(position)
	local data = { module.toFixedPoint(position.X, position.Y, position.Z) }
	table.insert(data, position.yaw)
	table.insert(data, position.pitch)
	return unpack(data)
end

return module
