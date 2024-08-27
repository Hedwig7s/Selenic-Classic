local require = require("customrequire")
local class = require("utility.class")

global type Connection

global type ClientReceiver = function(protocol:Protocol, connection:Connection, data:string)

global record Packet
    id: integer
    name: string
    format: string
    size: integer
    receiver: ClientReceiver|nil
    sender: function(self:Protocol, connection:Connection, ...:any)
end

global record ServerPackets
    Identification: function(self:Protocol, connection:Connection, name:string, motd:string)
    Ping: function(self:Protocol, connection:Connection)
    LevelInitialize: function(self:Protocol, connection:Connection)
    LevelDataChunk: function(self:Protocol, connection:Connection, chunkX:integer, chunkY:integer, chunkZ:integer, sizeX:integer, sizeY:integer, sizeZ:integer, data:string)
    LevelFinalize: function(self:Protocol, connection:Connection, sizeX:integer, sizeY:integer, sizeZ:integer)
end

global record Protocol
    __class__: BaseClass
    Packets: {integer: Packet}
    record Meta
        Version: integer
    end
    PacketFromName: function(self:Protocol, name:string): Packet|nil
end

local protocolImpl = class("ProtocolImpl", {
    singleton = true,
    constructor = function()

    end,
    values = {
        Packets = {},
        Meta = {
            Version = -1
        },
        PacketFromName = function(): Packet|nil
            
        end
    }
})


return protocolImpl