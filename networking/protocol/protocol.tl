--local require = require("deps.customrequire")
local class = require("deps.class")

global type Connection

global type ServerPacket

global record ClientPacket
    name: string
    size: integer
    handle: function(connection:Connection, data:string)
end


global record Protocol
    __class__: BaseClass
    ServerPackets: {string:ServerPacket}
    ClientPackets: {integer:ClientPacket}
    PacketFormats: {string:string}
end

local protocol = class("Protocol", {
    singleton = true,
    constructor = function(self:Instance): Protocol
        local self = self as Protocol
        return self
    end,
    values = {
        ServerPackets = {},
        ClientPackets = {},
        PacketFormats = {},
    }
})

return protocol