local require = require("customrequire")
local playerRegistry = require("entity.playerregistry")
local type _ = require("networking.protocol.protocol")
local type _ = require("networking.servertypes")
local type _ = require("entity.types")
local core = require("core")
local Object = core.Object

global record CriteriaData
    sourcePlayer: Player -- The player related to the packet (e.g. movement), if any
end

global type BroadcastCriteria = function(player:Player, data:CriteriaData): boolean

global record PacketBroadcaster
    initialize: function(self:PacketBroadcaster, packet:string, criteria:BroadcastCriteria)
    new: function(self:PacketBroadcaster, packet:string, criteria:BroadcastCriteria): PacketBroadcaster
    extend: function(self:PacketBroadcaster):  PacketBroadcaster
    packet: string
    criteria: BroadcastCriteria
    Broadcast: function(self:PacketBroadcaster, criteriaData:CriteriaData, ...:any)
end

local packetBroadcasterClass = Object:extend() as PacketBroadcaster

function packetBroadcasterClass:initialize(packet:string, criteria:BroadcastCriteria)
    self.packet = packet
    self.criteria = criteria
end
function packetBroadcasterClass:Broadcast(criteriaData:CriteriaData, ...:any)
    for _, player in ipairs(playerRegistry:GetEntities()) do
        local player = player as Player
        local connection = player.connection
        if (self.criteria and self.criteria(player, criteriaData)) or not self.criteria then
            local p = connection.protocol:PacketFromName(self.packet)
            if not p then
                error("Couldn't find packet of name "..self.packet)
            end
            local packet = p as Packet
            packet.sender(connection.protocol, connection, ...)
        end
    end
end

local record criterias
    notSelf: BroadcastCriteria
    sameWorld:BroadcastCriteria
end

criterias.notSelf = function(player:Player, data:CriteriaData): boolean
    if data.sourcePlayer and data.sourcePlayer.id == player.id then
        return false
    else
        return true
    end
end

criterias.sameWorld = function(player:Player, data:CriteriaData): boolean
    if data.sourcePlayer and player and data.sourcePlayer.world ~= player.world then
        return false
    else
        return true
    end
end

local combineCriterias = function(...:BroadcastCriteria): BroadcastCriteria
    local allCriterias = {...}
    return function(player:Player, data:CriteriaData):boolean
        for _, criteria in ipairs(allCriterias) do
            if not criteria(player, data) then
                return false
            end
        end
        return true
    end
end

return {packetBroadcaster = packetBroadcasterClass, criterias = criterias, combineCriterias = combineCriterias}