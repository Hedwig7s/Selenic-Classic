local require = require("customrequire")
local core = require("core")
local Object = core.Object
local type Vector3 = require("datatypes.vector3")

local type ServerModule = require("networking.servertypes")

global type ClientReceiver = function(protocol:Protocol, connection:ServerModule.Connection, data:string)

global record Packet
    id: integer
    name: string
    format: string
    size: integer
    receiver: ClientReceiver|nil
    sender: function(protocol:Protocol, connection:ServerModule.Connection, ...:any)
end

global record PacketSenders
    type Identification = function(protocol:Protocol, connection:ServerModule.Connection, name:string, motd:string)
    type Ping = function(protocol:Protocol, connection:ServerModule.Connection)
    type LevelInitialize = function(protocol:Protocol, connection:ServerModule.Connection)
    type LevelDataChunk = function(protocol:Protocol, connection:ServerModule.Connection, levelData:string, percentage:integer)
    type LevelFinalize = function(protocol:Protocol, connection:ServerModule.Connection, size:Vector3)
    type ServerSetBlock = function(protocol:Protocol, connection:ServerModule.Connection, position:Vector3, blockID:integer)
    type SpawnPlayer = function(protocol:Protocol, connection:ServerModule.Connection, _:integer, position:Vector3, block:integer)
    type PositionAndOrientation = function(protocol:Protocol, connection:ServerModule.Connection, _:integer, position:Vector3, orientation:Vector3)
    type PositionAndOrientationUpdate = function(protocol:Protocol, connection:ServerModule.Connection, _:integer, position:Vector3, orientation:Vector3)
    type DespawnPlayer = function(protocol:Protocol, connection:ServerModule.Connection, _:integer)
    type Message = function(protocol:Protocol, connection:ServerModule.Connection, message:string)
    type DisconnectPlayer = function(protocol:Protocol, connection:ServerModule.Connection, reason:string)
    type UpdateBlock = function(protocol:Protocol, connection:ServerModule.Connection, position:Vector3, blockID:integer)
end

local record Meta
    Version: integer
end

global record Protocol
    initialize: function(self:Protocol)
    new: function(self:Protocol): Protocol
    extend: function(self:Protocol): Protocol
    Packets: {integer: Packet}
    Meta: Meta
    PacketFromName: function(protocol:Protocol, name:string): Packet|nil
end

local packetNameCache:{integer:{string:Packet}} = {}

local protocolImpl = Object:extend() as Protocol
function protocolImpl:initialize()

end
protocolImpl.Packets = {}

function protocolImpl:PacketFromName(name:string): Packet|nil
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