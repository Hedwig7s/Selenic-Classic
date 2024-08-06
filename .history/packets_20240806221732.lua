
---@class PacketsModule
local module = {}

local coronet = require("coro-net")
local timer = require("timer")
local server = require("./server")
local config = require("./config")
local util = require("./util")
local worlds = require("./worlds")
local playerModule = require("./player")
require("compat53")

---@type table<number, Connection>
local connections = {}
local connectionCount = 0

-----------------UTIL-----------------

---Formats string to 64 characters with padding
---@param str string
---@return string
local function formatString(str)
    return util.pad(str,64,"\32")
end

---Converts numbers to fixed point
---@param ... number
---@return number ...
local function toFixedPoint(...)
    local values = {}
    for _,v in pairs({...}) do
        table.insert(values, math.floor(v * 32))
    end
    return unpack(values) 
end

---Converts fixed point to numbers
---@param ... number
---@return number ...
local function fromFixedPoint(...)
    local values = {}
    for _,v in pairs({...}) do
        table.insert(values, v/32)
    end
    return unpack(values) 
end
-----------------SERVER PACKETS-----------------

---Disconnects a player with a reason
---@param reason string
---@param connection Connection
local function disconnect(reason, connection)
    connection.write(string.pack(">Bc64",0x0E,formatString(reason)))
end

---Identifies server to client
---@param connection Connection
local function serverIdent(connection) 
    connection.write(string.pack(">BBc64c64B",
                        0x00,
                        server.info.Protocol,
                        formatString(config:getValue("server.serverName")),
                        formatString(config:getValue("server.motd")),
                        0x00))
end

---Pings the client
---@param connection Connection
local function ping(connection)
    connection.write(string.pack(">B",0x01))
end

---Indicates to client that level data is about to be sent
---@param connection Connection
local function levelInit(connection)
    connection.write(string.pack(">B",0x02))
end

---Sends a chunk of level data to the client
---@param connection Connection
---@param length number
---@param data string
---@param percent number
local function levelDataChunk(connection, length, data, percent)
    if length > 1024 then
        error("Chunk too large")
    end
    data = util.pad(data,1024,"\0")
    connection.write(string.pack(">BHI4c1024B",0x03,length,data,percent))
end

---Indicates to client that level has been fully sent, also sends size
---@param connection Connection
---@param size Vector3
local function levelFinalize(connection, size)
    connection.write(string.pack(">BHHH",0x04,size.x,size.y,size.z))
end

---Updates client(s) of a block update
---@param x number
---@param y number
---@param z number
---@param block BlockIDs
---@param connection Connection?
local function serverSetBlock(x, y, z, block, connection)
    local data = string.pack(">BHHHB",0x06,x,y,z,block)
    if connection then
        connection.write(data)
        return
    end
    for _, connection in pairs(connections) do
        local success, err = pcall(connection.write, data)
        if not success then
            print("Error sending packet to client: "..err)
        end 
    end
end

---Tells clients to spawn player with specified positional information
---@param id number
---@param name string
---@param x number
---@param y number
---@param z number
---@param yaw number
---@param pitch number
---@param connection Connection?
local function spawnPlayer(id, name, x, y, z, yaw, pitch, connection)
    local data = string.pack(">Bbc80HHHHH",0x07,id, formatString(name),toFixedPoint(x,y,z),yaw,pitch,0)
    if connection then
        connection.write(data)
        return
    end
    for _, connection in pairs(connections) do
        if connection.id ~= id then -- Don't send to the player that is being spawned
            local success, err = pcall(connection.write, data)
            if not success then
                print("Error sending packet to client: "..err)
            end 
        end
    end
end

---@class ServerPackets 
local ServerPackets = {
    ServerIdentification = serverIdent,
    Ping = ping,
    LevelInitialize = levelInit,
    LevelDataChunk = levelDataChunk,
    LevelFinalize = levelFinalize,
    SetBlock = serverSetBlock,
    SpawnPlayer = spawnPlayer,
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

---@alias ClientPacket fun(data:string, connection:Connection)

---Handles player identification
---@type ClientPacket
local function playerIdent(data, connection) 
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
        disconnect(err, connection)
        return
    end
    ServerPackets.ServerIdentification(connection)
    print("Identified")
    local player = playerModule.Player.new(connection, username)
    connection.player = player
    player:LoadWorld(worlds.loadedWorlds[config:getValue("server.defaultWorld")])
end

---Handles client trying to set block
---@type ClientPacket
function clientSetBlock(data, connection) 
    local _, x, y, z, mode, block = string.unpack(">BHHHBB",data)
    local success, err = pcall(function()
        assert(mode == 0 or mode == 1, "Invalid mode")
        assert(block < 256, "Invalid block")
        assert(x < 65536 and y < 65536 and z < 65536 and x >= 0 and y >= 0 and z >= 0, "Invalid coordinates")
    end)
    local world = worlds.loadedWorlds[config:getValue("server.defaultWorld")]
    if not success then
        print("Error handling SetBlock packet:", err)
        ServerPackets.SetBlock(x,y,z,world:getBlock(x,y,z), connection)
        return
    end
    if mode == 1 and worlds.getBlockName(block) then
        world:setBlock(x,y,z,block)
    elseif mode == 0 then
        world:setBlock(x,y,z,worlds.BLOCK_IDS.AIR)
    end
end

---@class ClientPackets
local ClientPackets = {
    [0x00] = playerIdent,
    [0x05] = clientSetBlock,
    [0x08] = "PositionAndOrientation",
    [0x0D] = "Message"
}

module.ClientPackets = ClientPackets
-----------------HANDLING-----------------

---Handles a new connection
---@param server unknown
---@param read fun():string?
---@param write fun(data:string)
---@param dsocket unknown
---@param updateDecoder unknown
---@param updateEncoder unknown
function module:HandleConnect(server, read, write, dsocket, updateDecoder, updateEncoder)
    local id = connectionCount
    connectionCount = connectionCount + 1
    print("Client connected with id ".. connectionCount)
    local lastPing = os.time()
    ---@class Connection
    ---@field read fun():string?
    ---@field write fun(data:string)
    ---@field dsocket unknown 
    ---@field updateDecoder unknown
    ---@field updateEncoder unknown
    ---@field id number
    ---@field routine thread
    ---@field player Player?
    local connection = {
        read = read,
        write = write,
        dsocket = dsocket,
        updateDecoder = updateDecoder,
        updateEncoder = updateEncoder,
        id = id,
    }
    connections[id] = connection
    local connectionroutine = coroutine.create(function()
        while true do
            timer.sleep(5)
            local data = read()
            if data and #data > 0 then
                local id = string.unpack(">B",data:sub(1,1))
                if ClientPackets[id] then
                    local success, err = pcall(ClientPackets[id],data, connection)
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
                ServerPackets.Ping(connection)
            end
        end
        connections[id] = nil
    end)
    coroutine.resume(connectionroutine) 
    connection.routine = connectionroutine
end

return module