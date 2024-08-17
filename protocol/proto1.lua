---@class Protocol1:Protocol
local module = {}

local proto7 = require("./proto7")
local proto6 = require("./proto6")
local proto3 = require("./proto3")
local packetutil = require("./packetutil")
local config = require("../config")
local playerModule = require("../player")
local worlds = require("../worlds")
require("compat53")

---@type ServerPackets.DisconnectPlayer
local function disconnectPlayer(connection, id)
    connection.dsocket:close()
    return true
end

---@type ServerPackets.ServerIdentification
local function serverIdentification(connection)
    return connection.write(string.pack(">Bc64",0x00,packetutil.formatString("")))
end

---Despawns a player from the world
---@type ServerPackets.DespawnPlayer
local function despawnPlayer(connection, id)
    local data = string.pack(">Bb", 0x09, id)
    return connection.write(data)
end

---@type ServerPackets
local ServerPackets = {
    ServerIdentification = serverIdentification,
    Ping = proto7.ServerPackets.Ping,
    LevelInitialize = proto7.ServerPackets.LevelInitialize,
    LevelDataChunk = proto7.ServerPackets.LevelDataChunk,
    LevelFinalize = proto7.ServerPackets.LevelFinalize,
    UpdateUserType = packetutil.dummyPacket,
    SetBlock = proto7.ServerPackets.SetBlock,
    SpawnPlayer = proto7.ServerPackets.SpawnPlayer,
    SetPositionAndOrientation = proto7.ServerPackets.SetPositionAndOrientation,
    PositionAndOrientationUpdate = packetutil.convertPositionUpdate,
    PositionUpdate = packetutil.convertPositionUpdate,
    OrientationUpdate = packetutil.convertPositionUpdate,
    DespawnPlayer = despawnPlayer,
    Message = packetutil.dummyPacket,
    DisconnectPlayer = disconnectPlayer,
}
module.ServerPackets = ServerPackets

local function playerIdentification(data, connection, protocol)
    local _, name = string.unpack(">Bc64", data)
    packetutil.handleNewPlayer(connection, protocol, name, "(none)", disconnectPlayer)
    return true
end

local ClientPackets = {
    [0x00] = playerIdentification,
    [0x05] = proto6.ClientPackets[0x05],
    [0x08] = proto6.ClientPackets[0x08],
    [0x0D] = packetutil.dummyPacket,
}

module.ClientPackets = ClientPackets

module.Version = 1

module.PacketSizes = {
    [0x00] = 65,
    [0x05] = 9,
    [0x08] = 10,
    [0x0D] = 66,
}

module.ClientVersions = "c0.0.15a"

return module
