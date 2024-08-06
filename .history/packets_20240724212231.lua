
local module = {}

local coronet = require("coro-net")
local timer = require("timer")

local function login(data) 
    print("Login packet received")
    print("Protocol version: " .. data[2]:byte())
    print("Username: " .. data:sub(3):split("\32")[1])
end

local ClientPackets = {
    [0x00] = login,
    [0x05] = "SetBlock",
    [0x08] = "PositionAndOrientation",
    [0x0D] = "Message"
}
local ServerPackets = {
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
    local connectionroutine
    connectionroutine = coroutine.create(function()
        while true do
            local data = read()
            if data and #data > 0 then

                local id = data:sub(1,1):byte()
                if ClientPackets[id] then
                    ClientPackets[id](data)
                else
                    print("Unknown packet received:", id)
                end
            end
        end
    end)
    coroutine.resume(connectionroutine) 
end

return module