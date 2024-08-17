---@class Protocol3:Protocol
local module = {}

local proto4 = require("./proto4")
local asserts = require("../asserts")
local packetutil = require("./packetutil")
require("compat53")

local function spawnPlayer(connection, id, name, x, y, z, yaw, pitch)
    asserts.assertPacketString(name)
    name = packetutil.formatString(name)

    local function getData(id2, x, y, z, yaw, pitch)
        if id2 == -1 then -- Nonsense
            local temp = yaw
            yaw = pitch
            pitch = (256-temp)
        end
        return string.pack(">Bbc64hhhBB", 0x07, id2, name, x, y, z, yaw, pitch)
    end
    return packetutil.baseMovementPacket(connection, id, x, y, z, yaw, pitch, getData, false)
end


---@type ServerPackets
local ServerPackets = {
    Ping = proto4.ServerPackets.Ping,
    LevelInitialize = proto4.ServerPackets.LevelInitialize,
    LevelDataChunk = proto4.ServerPackets.LevelDataChunk,
    LevelFinalize = proto4.ServerPackets.LevelFinalize,
    SetBlock = proto4.ServerPackets.SetBlock,
    SpawnPlayer = spawnPlayer,
    SetPositionAndOrientation = proto4.ServerPackets.SetPositionAndOrientation,
    PositionAndOrientationUpdate = proto4.ServerPackets.PositionAndOrientationUpdate,
    PositionUpdate = proto4.ServerPackets.PositionUpdate,
    OrientationUpdate = proto4.ServerPackets.OrientationUpdate,
    DespawnPlayer = proto4.ServerPackets.DespawnPlayer,
    Message = proto4.ServerPackets.Message,
    DisconnectPlayer = proto4.ServerPackets.DisconnectPlayer,
    UpdateUserType = proto4.ServerPackets.UpdateUserType,
    ServerIdentification = proto4.ServerPackets.ServerIdentification,
}
module.ServerPackets = ServerPackets

local ClientPackets = proto4.ClientPackets

module.ClientPackets = ClientPackets

module.Version = 3

module.PacketSizes = proto4.PacketSizes

module.ClientVersions = "c0.0.16a"

return module
