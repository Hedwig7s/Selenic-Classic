local require = require("customrequire")
local playerRegistry = require("entity.playerregistry")
local _ = require("networking.protocol.protocol")

local class = require("middleclass")

CriteriaData = {}

BroadcastCriteria = {}

PacketBroadcaster = {}

local packetBroadcasterClass = class("PacketBroadcaster")

function packetBroadcasterClass:initialize(packet, criteria, leaveId)
	self.packet = packet
	self.criteria = criteria
	self.changeId = not leaveId
end
function packetBroadcasterClass:sendTo(player, criteriaData, ...)
	local connection = player.connection
	if (self.criteria and self.criteria(player, criteriaData)) or not self.criteria then
		local p = connection.protocol:PacketFromName(self.packet)
		if not p then
			error("Couldn't find packet of name " .. self.packet)
		end
		local packet = p
		local id = (self.changeId and criteriaData.sourcePlayer and criteriaData.sourcePlayer.id == player.id and -1)
			or (criteriaData.sourcePlayer and criteriaData.sourcePlayer.id)
			or -1

		packet.sender(connection, id, ...)
	end
end
function packetBroadcasterClass:Broadcast(criteriaData, ...)
	for _, player in ipairs(playerRegistry:GetEntities()) do
		self:sendTo(player, criteriaData, ...)
	end
end

local criterias = {}

criterias.notSelf = function(player, data)
	if data.sourcePlayer and data.sourcePlayer.id == player.id then
		return false
	else
		return true
	end
end

criterias.sameWorld = function(player, data)
	if data.sourcePlayer and player and data.sourcePlayer.world ~= player.world then
		return false
	else
		return true
	end
end

local combineCriterias = function(...)
	local allCriterias = { ... }
	return function(player, data)
		for _, criteria in ipairs(allCriterias) do
			if not criteria(player, data) then
				return false
			end
		end
		return true
	end
end

return { packetBroadcaster = packetBroadcasterClass, criterias = criterias, combineCriterias = combineCriterias }
