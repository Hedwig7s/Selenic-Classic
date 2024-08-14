---@class Protocol5:Protocol
local module = {}

local proto7 = require("./proto7")
local proto6 = require("./proto6")
local packetutil = require("./packetutil")
local config = require("../config")

local function serverIdentification(connection)
    if not connection.player then
        error("No player associated with connection")
    end 
    return connection.write(string.pack(">BBc64c64",
                        0x00,
                        connection.player.protocol.Version,
                        packetutil.formatString(config:getValue("server.serverName")),
                        packetutil.formatString(config:getValue("server.motd"))
                    ))
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
    PositionAndOrientationUpdate = proto7.ServerPackets.PositionAndOrientationUpdate,
    PositionUpdate = proto7.ServerPackets.PositionUpdate,
    OrientationUpdate = proto7.ServerPackets.OrientationUpdate,
    DespawnPlayer = proto7.ServerPackets.DespawnPlayer,
    Message = proto6.ServerPackets.Message,
    DisconnectPlayer = proto7.ServerPackets.DisconnectPlayer,
}
module.ServerPackets = ServerPackets

---@type ClientPackets.PlayerIdentification
local function playerIdentification(data, connection, protocol)
    data = data.."\0"
    return proto7.ClientPackets[0x00](data, connection, protocol)
end

local ClientPackets = {
    [0x00] = playerIdentification,
    [0x05] = proto6.ClientPackets[0x05],
    [0x08] = proto6.ClientPackets[0x08],
    [0x0D] = proto6.ClientPackets[0x0D],
}

module.ClientPackets = ClientPackets

module.Version = 5

module.PacketSizes = {
    [0x00] = 130,
    [0x05] = 9,
    [0x08] = 10,
    [0x0D] = 66,
}

return module
