
local module = {}

local coronet = require("coro-net")
local timer = require("timer")
local server = require("./server")
local config = require("./config")
local util = require("./util")

local connections = {}
local connectionCount = 0

local function disconnect(reason, write)
    write(string.char(0x0E)..reason)
    print("Disconnecting client: "..reason)
end


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
    DisconnectPlayer = disconnect,
    UpdateUserType = 0x0F,
}

local function login(data, write) 
    local protocolVersion = data:sub(2,2):byte()
    local splitdata = util.split(data:sub(3),"\32")
    local username = splitdata[1]
    local verificationKey = splitdata[2]
    print("Login packet received")
    print("Protocol version: " .. protocolVersion)
    print("Username: " .. username)
    print("Verification key: " .. verificationKey)
    if protocolVersion ~= 6 then
        ServerPackets["DisconnectPlayer"]("Wrong protocol version", write)
        return
    end
end

local ClientPackets = {
    [0x00] = login,
    [0x05] = "SetBlock",
    [0x08] = "PositionAndOrientation",
    [0x0D] = "Message"
}


function module:HandleConnect(server, read, write, dsocket, updateDecoder, updateEncoder)
    local id = connectionCount
    connectionCount = connectionCount + 1
    print("Client connected with id ".. connectionCount)
    local connectionroutine = coroutine.create(function()
        while true do
            local data = read()
            if data and #data > 0 then
                local id = data:sub(1,1):byte()
                if ClientPackets[id] then
                    ClientPackets[id](data, write)
                else
                    print("Unknown packet received:", id)
                end
            elseif data == nil then
                print("Client disconnected")
                break
            end
        end
        connections[id] = nil
    end)
    coroutine.resume(connectionroutine) 
    connections[id] = {
        read = read,
        write = write,
        dsocket = dsocket,
        updateDecoder = updateDecoder,
        updateEncoder = updateEncoder,
        routine = connectionroutine,
    }
end

return module