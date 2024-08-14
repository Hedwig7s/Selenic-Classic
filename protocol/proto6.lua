---@class Protocol6:Protocol
local module = {}

local proto7 = require("./proto7")
local packetUtil = require("./packetutil")

---@type ServerPackets.Message
local function serverMessage(connection, id, message)
    local messages = packetUtil.formatChatMessage(message,id)
    for _,msg in pairs(messages) do
        local packet = string.pack(">Bbc64",0x0D, id,msg:gsub("&.",""))
        connection.write(packet)
    end
    return true
end
---@type ServerPackets
local ServerPackets = {
    ServerIdentification = proto7.ServerPackets.ServerIdentification,
    Ping = proto7.ServerPackets.Ping,
    LevelInitialize = proto7.ServerPackets.LevelInitialize,
    LevelDataChunk = proto7.ServerPackets.LevelDataChunk,
    LevelFinalize = proto7.ServerPackets.LevelFinalize,
    UpdateUserType = packetUtil.dummyPacket,
    SetBlock = proto7.ServerPackets.SetBlock,
    SpawnPlayer = proto7.ServerPackets.SpawnPlayer,
    SetPositionAndOrientation = proto7.ServerPackets.SetPositionAndOrientation,
    PositionAndOrientationUpdate = proto7.ServerPackets.PositionAndOrientationUpdate,
    PositionUpdate = proto7.ServerPackets.PositionUpdate,
    OrientationUpdate = proto7.ServerPackets.OrientationUpdate,
    DespawnPlayer = proto7.ServerPackets.DespawnPlayer,
    Message = serverMessage,
    DisconnectPlayer = proto7.ServerPackets.DisconnectPlayer,
}
module.ServerPackets = ServerPackets



local ClientPackets = proto7.ClientPackets
module.ClientPackets = ClientPackets

module.Version = 6

module.PacketSizes = proto7.PacketSizes

return module
