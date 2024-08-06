
local module = {}

local coronet = require("coro-net")
local os = require("os")

module.ClientPackets = {
    [0x00] = "PlayerIdentification",
    [0x05] = "SetBlock",
    [0x08] = "PositionAndOrientation",
    [0x0D] = "Message"
}
module.ServerPackets = {
    ServerIdentification = 0x00,
    Ping = 0x01,
    LevelInitialize = 0x02,
    LevelDataChunk = 0x03,
    LevelFinalize = 0x04,
    SetBlock = 0x06,
    SpawnPlayer = 0x07,
    SetPositionAndOrientation = 0x08,
    PositionAndOrientationUpdate = 0x09,
    PositionUpdate = 0x0A,
    OrientationUpdate = 0x0B,
    DespawnPlayer = 0x0C,
    Message = 0x0D,
    DisconnectPlayer = 0x0E,
    UpdateUserType = 0x0F,
}

function module:HandleConnect(server, read, write, dsocket, updateDecoder, updateEncoder)
   print("Client connected")
   while wait(1) do
    print(read())
   end
end

return module