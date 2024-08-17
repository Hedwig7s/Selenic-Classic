---@class Protocol6:Protocol
local module = {}

local proto7 = require("./proto7")
local packetUtil = require("./packetutil")

---@type ServerPackets
local ServerPackets = proto7.ServerPackets
module.ServerPackets = ServerPackets



local ClientPackets = proto7.ClientPackets
module.ClientPackets = ClientPackets

module.Version = 6

module.PacketSizes = proto7.PacketSizes

module.ClientVersions = "c0.0.20a-c0.0.23a"

return module
