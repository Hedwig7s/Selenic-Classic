local require = require("customrequire")
local playerRegistry = require("entity.playerregistry")
local type _ = require("networking.protocol.protocol")
local type ServerModule = require("networking.servertypes")
local type Connection = ServerModule.Connection
local type Entities = require("entity.types")
local type Player = Entities.Player
local class = require("middleclass")

global record CriteriaData
    sourcePlayer: Player -- The player related to the packet (e.g. movement), if any
end

global type BroadcastCriteria = function(player:Player, data:CriteriaData): boolean

global record PacketBroadcaster
    initialize: function(self:PacketBroadcaster, packet:string, criteria:BroadcastCriteria, leaveId:boolean|nil)
    new: function(self:PacketBroadcaster, packet:string, criteria:BroadcastCriteria, leaveId:boolean|nil): PacketBroadcaster
    static: table
    isSubclassOf: function(self: PacketBroadcaster, other:class.Class): boolean
    include: function(self: PacketBroadcaster, ...:table): PacketBroadcaster
    subclassed: function(self: PacketBroadcaster, other:class.Class)
    allocate: function(self: PacketBroadcaster): table
    isInstanceOf: function(self: PacketBroadcaster, class: class.Class): boolean
    subclass: function(self:PacketBroadcaster,name:string):  PacketBroadcaster
    packet: string
    changeId: boolean
    criteria: BroadcastCriteria
    sendTo: function(self:PacketBroadcaster, player:Player, criteriaData:CriteriaData, ...:any)
    Broadcast: function(self:PacketBroadcaster, criteriaData:CriteriaData, ...:any)
end

local packetBroadcasterClass = class("PacketBroadcaster") as PacketBroadcaster

function packetBroadcasterClass:initialize(packet:string, criteria:BroadcastCriteria, leaveId:boolean|nil)
    self.packet = packet
    self.criteria = criteria
    self.changeId = not leaveId
end
function packetBroadcasterClass:sendTo(player:Player, criteriaData:CriteriaData, ...:any)
    local connection = player.connection
    if (self.criteria and self.criteria(player, criteriaData)) or not self.criteria then
        local p = connection.protocol:PacketFromName(self.packet)
        if not p then
            error("Couldn't find packet of name "..self.packet)
        end
        local packet = p as Packet
        local id = (self.changeId and criteriaData.sourcePlayer and criteriaData.sourcePlayer.id == player.id and -1) or 
                    (criteriaData.sourcePlayer and criteriaData.sourcePlayer.id) or -1

        packet.sender(connection, id, ...)
    end
end
function packetBroadcasterClass:Broadcast(criteriaData:CriteriaData, ...:any)
    for _, player in ipairs(playerRegistry:GetEntities()) do
        self:sendTo(player as Player, criteriaData, ...)
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