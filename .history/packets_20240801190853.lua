
local module = {}

local coronet = require("coro-net")
local timer = require("timer")
local server = require("./server")
local config = require("./config")
local util = require("./util")
local worlds = require("./worlds")
require("compat53")

local connections = {}
local connectionCount = 0

local function formatString(str)
    return util.pad(str,64,"\32")
end

local function disconnect(reason, write)
    write(string.pack(">B",0x0E)..reason)
end

local function serverIdent(write) 
    write(string.pack(">B",0x00)..string.pack(">B",server.info.Protocol)..formatString(config:getValue("server.serverName"))..formatString(config:getValue("server.motd"))..string.pack(">B",0x00))
end

local function ping(write)
    write(string.pack(">B",0x01))
end

local function levelInit(write)
    write(string.pack(">B",0x02))
end

local function levelDataChunk(write, length, data, percent)
    if length > 1024 then
        error("Chunk too large")
    end
    data = util.pad(data,1024,"\0")
    write(string.pack(">B",0x03)..string.pack(">H",length)..data..string.pack(">B",percent))
end

local function levelFinalize(write, size)
    write(string.pack(">B",0x04)..string.pack(">H>H>H",size.x,size.y,size.z))
end

local ServerPackets = {
    ServerIdentification = serverIdent,
    Ping = ping,
    LevelInitialize = levelInit,
    LevelDataChunk = levelDataChunk,
    LevelFinalize = levelFinalize,
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
    local _,protocolVersion, username, verificationKey, CPE = string.unpack(">B>Bc64c64>B",data)
    username = username:sub(1,username:find("\32")-1)
    verificationKey = verificationKey:sub(1,verificationKey:find("\32")-1)
    print("Login packet received")
    print("Protocol version: " .. protocolVersion)
    print("Username: " .. username)
    print("Verification key: " .. verificationKey)
    if protocolVersion ~= server.info.Protocol then
        print("Protocol version mismatch")
        disconnect("Protocol version mismatch", write)
        return
    end
    ServerPackets.ServerIdentification(write)
    print("Identified")
    print("Packing world")
    local world = worlds.loadedWorlds[config:getValue("server.defaultWorld")]
    local packed = world:Pack()
    ServerPackets.LevelInitialize(write)
    print("Initialising level")
    local length = #packed
    local chunkSize = 1024
    local chunks = math.ceil(length/chunkSize)
    print("Sending level data")
    for i = 1, chunks do
        local chunk = packed:sub((i-1)*chunkSize+1, i*chunkSize)
        ServerPackets.LevelDataChunk(write, #chunk, chunk, math.floor(i/chunks*100))
    end
    print("Finalising level")
    ServerPackets.LevelFinalize(write, world.size)
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
    local lastPing = os.time()
    local connectionroutine = coroutine.create(function()
        while true do
            timer.sleep(0.05)
            local data = read()
            if data and #data > 0 then
                local id = string.unpack(">B",data:sub(1,1))
                if ClientPackets[id] then
                    ClientPackets[id](data, write)
                else
                    print("Unknown packet received:", id)
                end
            elseif data == nil then
                print("Client disconnected")
                break
            end
            if os.time() - lastPing > 0 then
                ServerPackets.Ping(write)
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