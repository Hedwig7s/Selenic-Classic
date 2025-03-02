local require = require("customrequire")
local class = require("middleclass")

ClientReceiver = {}

Packet = {}

PacketSenders = {}

Protocol = {}

local packetNameCache = {}

local protocolImpl = class("Protocol")
function protocolImpl:initialize() end
protocolImpl.Packets = {}

function protocolImpl:PacketFromName(name)
	if not packetNameCache[self.Meta.Version] then
		packetNameCache[self.Meta.Version] = {}
	end
	local cache = packetNameCache[self.Meta.Version]
	if cache[name] then
		return cache[name]
	end
	for _, packet in pairs(self.Packets) do
		if packet.name == name then
			cache[name] = packet
			return packet
		end
	end
	return nil
end

return protocolImpl
