local require = require("customrequire")
local class = require("class")
local ProtocolClass = require("networking.protocol.protocol")
local type server = require("networking.server")

local protocolClass = class("Protocol7", {
    implements = ProtocolClass,
    constructor = function(self:Instance)
        
    end,
    singleton = true,
    values = {
        ServerPackets = {
            
        },
        ClientPackets = {},
        PacketFormats = {},
    }
})
