
local module = {}

local coronet = require("coro-net")
local timer = require("timer")
local server = require("./server")
local config = require("./config")
local util = require("./util")
local worlds = require("./worlds")
local playerModule = require(",/player")
require("compat53")

local connections = {}
local connectionCount = 0
-----------------UTIL-----------------
local function formatString(str)
    return util.pad(str,64,"\32")
end
function toFixedPoint(...)
    local values = {}
    for _,v in pairs({...}) do
        table.insert(values, math.floor(v * 32))
    end
    return unpack(values) 
end

function fromFixedPoint(...)
    local values = {}
    for _,v in pairs({...}) do
        table.insert(values, v/32)
    end
    return unpack(values) 
end
-----------------SERVER PACKETS-----------------

local function disconnect(reason, write)
    write(string.pack(">Bc64",0x0E,formatString(reason)))
end

local function serverIdent(write) 
    write(string.pack(">BBc64c64B",
                        0x00,
                        server.info.Protocol,
                        formatString(config:getValue("server.serverName")),
                        formatString(config:getValue("server.motd")),
                        0x00))
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
    write(string.pack(">BHI4"..string.rep("B",1024).."B",0x03,length,data,percent))
end

local function levelFinalize(write, size)
    write(string.pack(">BHHH",0x04,size.x,size.y,size.z))
end

local function serverSetBlock(x, y, z, block, write)
    local data = string.pack(">BHHHB",0x06,x,y,z,block)
    if write then
        write(data)
        return
    end
    for _, connection in pairs(connections) do
        local success, err = pcall(connection.write, data)
        if not success then
            print("Error sending packet to client: "..err)
        end 
    end
end
local function spawnPlayer(id, name, x, y, z, yaw, pitch)
    write(string.pack(">Bbc80HHHHH",0x07,id, formatString(name),toFixedPoint(x,y,z),yaw,pitch,0))
end
local ServerPackets = {
    ServerIdentification = serverIdent,
    Ping = ping,
    LevelInitialize = levelInit,
    LevelDataChunk = levelDataChunk,
    LevelFinalize = levelFinalize,
    SetBlock = serverSetBlock,
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

-----------------CLIENT PACKETS-----------------

local function playerIdent(data, write) 
    local _,protocolVersion, username, verificationKey, CPE = string.unpack(">BBc64c64B",data)
    username = username:sub(1,username:find("\32")-1)
    verificationKey = verificationKey:sub(1,verificationKey:find("\32")-1)
    print("Login packet received")
    print("Protocol version: " .. protocolVersion)
    print("Username: " .. username)
    print("Verification key: " .. verificationKey)
    if protocolVersion ~= server.info.Protocol then
        local err = "Protocol version mismatch. Expected "..server.info.Protocol..", got "..protocolVersion
        print(err)
        disconnect(err, write)
        return
    end
    ServerPackets.ServerIdentification(write)
    print("Identified")
    local player = 
end

function clientSetBlock(data, write) 
    local _, x, y, z, mode, block = string.unpack(">BHHHBB",data)
    local success, err = pcall(function()
        assert(mode == 0 or mode == 1, "Invalid mode")
        assert(block < 256, "Invalid block")
        assert(x < 65536 and y < 256 and z < 65536 and x >= 0 and y >= 0 and z >= 0, "Invalid coordinates")
    end)
    local world = worlds.loadedWorlds[config:getValue("server.defaultWorld")]
    if not success then
        print("Error handling SetBlock packet:", err)
        ServerPackets.SetBlock(x,y,z,world:getBlock(x,y,z,write))
        return
    end
    if mode == 1 and worlds.getBlockName(block) then
        world:setBlock(x,y,z,block)
    elseif mode == 0 then
        world:setBlock(x,y,z,worlds.BLOCK_IDS.AIR)
    end
end

local ClientPackets = {
    [0x00] = playerIdent,
    [0x05] = clientSetBlock,
    [0x08] = "PositionAndOrientation",
    [0x0D] = "Message"
}

module.ClientPackets = ClientPackets
-----------------HANDLING-----------------
function module:HandleConnect(server, read, write, dsocket, updateDecoder, updateEncoder)
    local id = connectionCount
    connectionCount = connectionCount + 1
    print("Client connected with id ".. connectionCount)
    local lastPing = os.time()
    local connectionroutine = coroutine.create(function()
        while true do
            timer.sleep(5)
            local data = read()
            if data and #data > 0 then
                local id = string.unpack(">B",data:sub(1,1))
                if ClientPackets[id] then
                    local success, err = pcall(ClientPackets[id],data, write)
                    if not success then
                        print("Error handling packet from connection"..tostring(id)..":", err)
                    end
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
        id = id,
    }
end

return module