local require = require("customrequire")
local core = require("core")
local Object = core.Object
local type Vector3 = require("datatypes.vector3")

global type Connection

global type ClientReceiver = function(protocol:Protocol, connection:Connection, data:string)

global record Packet
    id: integer
    name: string
    format: string
    size: integer
    receiver: ClientReceiver|nil
    sender: function(protocol:Protocol, connection:Connection, ...:any)
end

global record PacketSenders
    type Identification = function(protocol:Protocol, connection:Connection, name:string, motd:string)
    type Ping = function(protocol:Protocol, connection:Connection)
    type LevelInitialize = function(protocol:Protocol, connection:Connection)
    type LevelDataChunk = function(protocol:Protocol, connection:Connection, levelData:string, percentage:integer)
    type LevelFinalize = function(protocol:Protocol, connection:Connection, size:Vector3)
    type ServerSetBlock = function(protocol:Protocol, connection:Connection, position:Vector3, blockID:integer)
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