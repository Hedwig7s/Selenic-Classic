local require = require("customrequire")
local class = require("utility.class")
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

global record Protocol
    __class__: BaseClass
    Packets: {integer: Packet}
    record Meta
        Version: integer
    end
    PacketFromName: function(protocol:Protocol, name:string): Packet|nil
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