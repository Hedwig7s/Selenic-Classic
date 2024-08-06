
local module = {}

local coronet = require("coro-net")
local timer = require("timer")
local server = require("./server")
local config = require("./config")
local util = require("./util")
local worlds = require("./worlds")
local numberutil = require("./numberutil")

local connections = {}
local connectionCount = 0

local function disconnect(reason, write)
    write(string.char(0x0E)..reason)
end

local function serverIdent(write) 
    write(string.char(0x00)..server.info.Protocol..config:getValue("server.motd").."\32"..string.char(0x00))
end

local function ping(write)
    write(string.char(0x01))
end

local function levelInit(write)
    write(string.char(0x02))
end

local function levelDataChunk(write, length, data, percent)
    if length > 1024 then
        error("Chunk too large")
    end
    if #data < 1024 then
        data = data .. string.rep("\0", 1024-#data)
    end
    write(string.char(0x03)..numberutil:toshort(length)..data..string.char(percent))
end

local function LevelFinalize(write)
    write(string.char(0x04))
end

local ServerPackets = {
    ServerIdentification = serverIdent,
    Ping = ping,
    LevelInitialize = levelInit,
    LevelDataChunk = levelDataChunk,
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

module.ServerPackets = ServerPackets

local function playerIdent(data, write) 
    local protocolVersion = data:sub(2,2):byte()
    local splitdata = util.split(data:sub(3),"\32")
    local username = splitdata[1]
    local verificationKey = splitdata[2]
    print("Login packet received")
    print("Protocol version: " .. protocolVersion)
    print("Username: " .. username)
    print("Verification key: " .. verificationKey)
    ServerPackets.ServerIdentification(write)
    ServerPackets.LevelInitialize(write)
    local world = worlds.loadedWorlds[config:getValue("server.defaultworld")]
    local packed = world:Pack()
    local length = #packed
    local chunkSize = 1024
    local chunks = math.ceil(length/chunkSize)
    for i = 1, chunks do
        local chunk = packed:sub((i-1)*chunkSize+1, i*chunkSize)
        ServerPackets.LevelDataChunk(write, #chunk, chunk, math.floor(i/chunks*100))
    end
    ServerPackets.LevelFinalize(write)
end

local ClientPackets = {
    [0x00] = playerIdent,
    [0x05] = "SetBlock",
    [0x08] = "PositionAndOrientation",
    [0x0D] = "Message"
}

module.ClientPackets = ClientPackets

function module:HandleConnect(server, read, write, dsocket, updateDecoder, updateEncoder)
    local id = connectionCount
    connectionCount = connectionCount + 1
    print("Client connected with id ".. connectionCount)
    local connectionroutine = coroutine.create(function()
        while true do
            timer.sleep(0.05)
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