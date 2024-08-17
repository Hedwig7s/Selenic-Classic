---@class Protocol4:Protocol
local module = {}

local proto5 = require("./proto5")
local packetutil = require("./packetutil")
require("compat53")

---@type ServerPackets.SetPositionAndOrientation
local function setPositionAndOrientation(connection, id, x, y, z, yaw, pitch, skipSelf)
    local function getData(id2, x, y, z, yaw, pitch)
        if id2 == -1 then -- More nonsense
            return module.ServerPackets.SpawnPlayer(connection, id, connection.player.name, x, y, z, yaw, pitch)
        end
        return string.pack(">BbhhhBB", 0x08, id2, x, y, z, yaw, pitch)
    end

    packetutil.baseMovementPacket(connection, id, x, y, z, yaw, pitch, getData, skipSelf)
end

---@type ServerPackets
local ServerPackets = {
    Ping = proto5.ServerPackets.Ping,
    LevelInitialize = proto5.ServerPackets.LevelInitialize,
    LevelDataChunk = proto5.ServerPackets.LevelDataChunk,
    LevelFinalize = proto5.ServerPackets.LevelFinalize,
    SetBlock = proto5.ServerPackets.SetBlock,
    SpawnPlayer = proto5.ServerPackets.SpawnPlayer,
    SetPositionAndOrientation = setPositionAndOrientation,
    PositionAndOrientationUpdate = proto5.ServerPackets.PositionAndOrientationUpdate,
    PositionUpdate = proto5.ServerPackets.PositionUpdate,
    OrientationUpdate = proto5.ServerPackets.OrientationUpdate,
    DespawnPlayer = proto5.ServerPackets.DespawnPlayer,
    Message = proto5.ServerPackets.Message,
    DisconnectPlayer = proto5.ServerPackets.DisconnectPlayer,
    UpdateUserType = proto5.ServerPackets.UpdateUserType,
    ServerIdentification = proto5.ServerPackets.ServerIdentification,
}
module.ServerPackets = ServerPackets
local ClientPackets = proto5.ClientPackets

module.ClientPackets = ClientPackets

module.Version = 4

module.PacketSizes = proto5.PacketSizes

module.ClientVersions = "c0.0.17a-c0.0.18a"

return module
