local require = require("customrequire")
local core = require("core")
local Object = core.Object
local type Vector3 = require("datatypes.vector3")

local type ServerModule = require("networking.servertypes")

global type ClientReceiver = function(connection:ServerModule.Connection, data:string)

global record Packet
    id: integer
    name: string
    format: string
    size: integer
    receiver: ClientReceiver|nil
    sender: function(connection:ServerModule.Connection, ...:any)
end

global record PacketSenders
    type Identification = function(connection:ServerModule.Connection, name:string, motd:string)
    type Ping = function(connection:ServerModule.Connection)
    type LevelInitialize = function(connection:ServerModule.Connection)
    type LevelDataChunk = function(connection:ServerModule.Connection, levelData:string, percentage:integer)
    type LevelFinalize = function(connection:ServerModule.Connection, size:Vector3)
    type ServerSetBlock = function(connection:ServerModule.Connection, position:Vector3, blockID:integer)
    type SpawnPlayer = function(connection:ServerModule.Connection, _:integer, position:Vector3, block:integer)
    type PositionAndOrientation = function(connection:ServerModule.Connection, _:integer, position:Vector3, orientation:Vector3)
    type PositionAndOrientationUpdate = function(connection:ServerModule.Connection, _:integer, position:Vector3, orientation:Vector3)
    type DespawnPlayer = function(connection:ServerModule.Connection, _:integer)
    type Message = function(connection:ServerModule.Connection, message:string)
    type DisconnectPlayer = function(connection:ServerModule.Connection, reason:string)
    type UpdateBlock = function(connection:ServerModule.Connection, position:Vector3, blockID:integer)
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
    PacketFromName: function(self:Protocol, name:string): Packet|nil
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