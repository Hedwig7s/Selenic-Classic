local require = require("customrequire")
local class = require("class")

global type Connection

global type ClientReceiver = function(protocol:Protocol, connection:Connection, data:string)

global record Packet
    id: integer
    name: string
    format: string
    size: integer
    receiver: ClientReceiver|nil
    sender: function(self:Protocol, connection:Connection, data:string)
end

global type Packets = {integer: Packet}

global record Protocol
    __class__: BaseClass
    Packets: Packets
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