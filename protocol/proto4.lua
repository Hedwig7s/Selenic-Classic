---@class Protocol4:Protocol
local module = {}

local proto5 = require("./proto5")

---@type ServerPackets
local ServerPackets = proto5.ServerPackets
module.ServerPackets = ServerPackets
local ClientPackets = proto5.ClientPackets

module.ClientPackets = ClientPackets

module.Version = 4

module.PacketSizes = proto5.PacketSizes

return module
