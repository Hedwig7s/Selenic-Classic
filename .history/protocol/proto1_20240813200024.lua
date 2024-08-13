---@class Protocol1:Protocol
local module = {}

local proto7 = require("./proto7")
local packetutil = require("./packetutil")

local function disconnectPlayer(connection, id)
    connection.dsocket:close()
    return true
end

local ServerPackets = {
    ServerIdentification = proto7.ServerPackets.ServerIdentification,
    Ping = proto7.ServerPackets.Ping,
    LevelInitialize = proto7.ServerPackets.LevelInitialize,
    LevelDataChunk = proto7.ServerPackets.LevelDataChunk,
    LevelFinalize = proto7.ServerPackets.LevelFinalize,
    UpdateUserType = packetutil.dummyPacket,
    SetBlock = proto7.ServerPackets.SetBlock,
    SpawnPlayer = proto7.ServerPackets.SpawnPlayer,
    SetPositionAndOrientation = proto7.ServerPackets.SetPositionAndOrientation,
    PositionAndOrientationUpdate = proto7.ServerPackets.PositionAndOrientationUpdate,
    PositionUpdate = proto7.ServerPackets.PositionUpdate,
    OrientationUpdate = proto7.ServerPackets.OrientationUpdate,
    DespawnPlayer = proto7.ServerPackets.DespawnPlayer,
    Message = proto7.ServerPackets.Message,
    DisconnectPlayer = disconnectPlayer,
}

module.Version = 1

return module