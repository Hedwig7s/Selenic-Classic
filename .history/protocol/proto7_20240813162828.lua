
---@class Protocol7: Protocol
local module = {}


local md5 = require("md5")
local server = require("../server")
local config = require("../config")
local util = require("../util")
local asserts = require("../asserts")
local worlds = require("../worlds")
local playerModule = require("../player")
local packets = require("../packets")
local connections = packets.connections

local packetUtil = require("./packetutil")
local formatString = packetUtil.formatString
local unformatString = packetUtil.unformatString
local toFixedPoint = packetUtil.toFixedPoint
local fromFixedPoint = packetUtil.fromFixedPoint
local perPlayerPacket = packetUtil.perPlayerPacket

-----------------SERVER PACKETS-----------------

---Disconnects a player with a reason
---@param reason string
---@param connection Connection
local function disconnect(connection, reason)
    assert(reason and type(reason) == "string" and #reason <= 64, "Invalid reason")
    local success, err = connection.write(string.pack(">Bc64",0x0E,formatString(reason)))
    connection.dsocket:close()
    return success, err
end

---Identifies server to client
---@param connection Connection
local function serverIdent(connection) 
    return connection.write(string.pack(">BBc64c64B",
                        0x00,
                        server.info.Protocol,
                        formatString(config:getValue("server.serverName")),
                        formatString(config:getValue("server.motd")),
                        0x00))
end

---Pings the client
---@param connection Connection
local function ping(connection)
    return connection.write(string.pack(">B",0x01))
end

---Indicates to client that level data is about to be sent
---@param connection Connection
local function levelInit(connection)
    return connection.write(string.pack(">B",0x02))
end

---Sends a chunk of level data to the client
---@param connection Connection
---@param length number
---@param data string
---@param percent number
local function levelDataChunk(connection, length, data, percent)
    assert(length and length <= 1024, "Data chunk too large")
    assert(data and type(data) == "string", "Invalid data")
    assert(percent and type(percent) == "number" and percent <= 100 and percent >= 0, "Invalid percent")
    data = util.pad(data,1024,"\0")
    return connection.write(string.pack(">BHc1024B",0x03,length,data,percent))
end

---Indicates to client that level has been fully sent, also sends size
---@param connection Connection
---@param size Vector3
local function levelFinalize(connection, size)
    asserts.assertCoordinates(size.x,size.y,size.z)
    return connection.write(string.pack(">BHHH",0x04,size.x,size.y,size.z))
end

---Updates client(s) of a block update
---@param connection Connection
---@param x number
---@param y number
---@param z number
---@param block BlockIDs
---@param connection Connection?
local function serverSetBlock(x, y, z, block, connection)
    asserts.assertCoordinates(x,y,z)
    assert(block and type(block) == "number" and block < 256 and block >= 0, "Invalid block")
    local data = string.pack(">BHHHB",0x06,x,y,z,block)
    if connection then
        return connection.write(data)
    end
    for _, connection in pairs(connections) do
        local success, err = pcall(connection.write, data)
        if not success then
            print("Error sending packet to client: "..err)
        end 
    end
end

local baseMovementPacket = packetUtil.baseMovementPacket

---Tells clients to spawn player with specified positional information
---@param id number
---@param name string
---@param x number
---@param y number
---@param z number
---@param yaw number
---@param pitch number
---@param criteria? fun(connection:Connection):boolean
---@param connection Connection?
local function spawnPlayer(id, name, x, y, z, yaw, pitch, criteria, connection)
    asserts.assertCoordinates(x,y,z,yaw,pitch)
    asserts.assertPacketString(name)
    name = formatString(name)

    local function getData(id2, x, y, z, yaw, pitch)
        return string.pack(">Bbc64hhhBB", 0x07, id2, name, x, y, z, yaw, pitch)
    end

    baseMovementPacket(id, x, y, z, yaw, pitch, "SpawnPlayer", getData, criteria, false, connection)
end

---Tells clients to move player to specified location
---@param id number
---@param x number
---@param y number
---@param z number
---@param yaw number
---@param pitch number
---@param criteria? fun(connection:Connection):boolean
---@param skipSelf? boolean
---@param connection Connection?
local function setPositionAndOrientation(id, x, y, z, yaw, pitch, criteria, skipSelf, connection)
    asserts.assertCoordinates(x,y,z,yaw,pitch)
    local function getData(id2, x, y, z, yaw, pitch)
        return string.pack(">BbhhhBB", 0x08, id2, x, y, z, yaw, pitch)
    end

    baseMovementPacket(id, x, y, z, yaw, pitch, "SetPositionAndOrientation", getData, criteria, skipSelf, connection)
end

---Tells clients to move player relative to current (client-side) location and orientation
---@param id number
---@param x number
---@param y number
---@param z number
---@param yaw number
---@param pitch number
---@param criteria? fun(connection:Connection):boolean
---@param connection Connection?
local function positionAndOrientationUpdate(id, x, y, z, yaw, pitch, criteria, connection)
    asserts.assertFByte("Invalid coordinate", x, y, z)
    asserts.angleAssert(yaw, "Invalid yaw")
    asserts.angleAssert(pitch, "Invalid pitch")
    local function getData(id2, x, y, z, yaw, pitch)
        return string.pack(">BbbbbBB", 0x09, id2, x, y, z, yaw, pitch)
    end
    baseMovementPacket(id, x, y, z, yaw, pitch, "SetPositionAndOrientation", getData, criteria, true, connection)
end

---Tells clients to move player relative to current (client-side) location
---@param id number
---@param x number
---@param y number
---@param z number
---@param criteria? fun(connection:Connection):boolean
---@param connection Connection?
local function positionUpdate(id, x, y, z, criteria, connection)
    asserts.assertFByte("Invalid coordinate", x, y, z)
    local function getData(id2, x, y, z, _, _)
        return string.pack(">Bbbbb", 0x0A, id2, x, y, z)
    end
    baseMovementPacket(id, x, y, z, nil, nil, "PositionUpdate", getData, criteria, true, connection)
end

---Tells client to rotate player relative to current (client-side) orientation
---@param id number
---@param yaw number
---@param pitch number
---@param criteria? fun(connection:Connection):boolean
---@param connection Connection?
local function orientationUpdate(id, yaw, pitch, criteria, connection)
    asserts.angleAssert(yaw, "Invalid yaw")
    asserts.angleAssert(pitch, "Invalid pitch")
    local function getData(id2, _, _, _, yaw, pitch)
        return string.pack(">BbBB", 0x0B, id2, yaw, pitch)
    end
    baseMovementPacket(id, nil, nil, nil, yaw, pitch, "OrientationUpdate", getData, criteria, true, connection)
end

---Despawns a player from the world
---@param id number
---@param connection Connection?
---@return boolean?, string?
local function despawnPlayer(id, connection)
    local data = string.pack(">Bb",0x0C,id)
    if connection then
        return connection.write(data)
    end
    local player = playerModule:GetPlayerById(id)
    if not player then
        error("Player not found")
    end
    for _,connection in pairs(connections) do
        if connection.player and connection.player.id ~= id and connection.player.world == player.world then
            connection.write(data)
        end
    end
end

---Sends a message to client(s)
---@param message string
---@param criteria? fun(connection:Connection):boolean
---@param connection Connection?
---@return boolean?, string?
local function serverMessage(message, id, criteria, connection)
    asserts.assertId(id)
    if message:sub(-1,-1) == "&" then
        message = message:sub(1,-2)
    end
    message = formatString(message)
    local messages = {}

    local current = {}
    local color = ""
    local i = 1
    while i <= #message do
        local char = message:sub(i,i)
        if char == "&" and message:sub(i+1,i+1) ~= "" and message:sub(i+1,i+1) ~= " " then
            color = message:sub(i,i+1)
        end
        table.insert(current, char)
        if #current >= 64 then
            table.insert(messages, formatString(table.concat(current)))
            current = {"> "..color}
        end
        i = i + 1
    end
    table.insert(messages, formatString(table.concat(current)))
    local data = {}
    for _,msg in pairs(messages) do
        table.insert(data, string.pack(">Bbc64",0x0D, id or -2,msg))
    end
    local function write(connection)
        for _,packet in pairs(data) do
            print(packet)
            connection.write(packet)
        end
    end
    if connection then
        write(connection)
    end
    for _, connection in pairs(connections) do
        if (criteria and criteria(connection)) or not criteria then
            write(connection)
        end
    end
end

---Changes the user type of a player
---@param connection Connection?
---@param id number
---@param type number
local function updateUserType(connection, id, type)
    asserts.assertId(id)
    assert(type and type == 0 or type == 0x64, "Invalid type")
    local data = string.pack(">BB",0x0F,id,type)
    if connection then
        return connection.write(data)
    end
    connection.write(data)
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
    SetPositionAndOrientation = setPositionAndOrientation,
    PositionAndOrientationUpdate = positionAndOrientationUpdate,
    PositionUpdate = positionUpdate,
    OrientationUpdate = orientationUpdate,
    DespawnPlayer = despawnPlayer,
    Message = serverMessage,
    DisconnectPlayer = disconnect,
    UpdateUserType = updateUserType,
}

module.ServerPackets = ServerPackets

-----------------CLIENT PACKETS-----------------


---Handles player identification
---@type ClientPacket
local function playerIdent(data, connection) 
    local _,protocolVersion, username, verificationKey, CPE = string.unpack(">BBc64c64B",data)
    assert(protocolVersion and type(protocolVersion) == "number", "Invalid protocol version")
    assert(username and type(username) == "string" and #username <= 64, "Invalid username")
    assert(verificationKey and type(verificationKey) == "string" and #verificationKey <= 64, "Invalid verification key")
    assert(CPE and type(CPE) == "number" and (CPE == 0x00 or CPE == 0x42), "Invalid CPE")
    username = unformatString(username)
    verificationKey = unformatString(verificationKey)
    print("Login packet received")
    print("Protocol version: " .. protocolVersion)
    print("Username: " .. username)
    print("Verification key: " .. verificationKey)
    if protocolVersion ~= server.info.Protocol then
        local err = "Protocol version mismatch. Expected "..server.info.Protocol..", got "..protocolVersion
        print(err)
        disconnect(connection, err)
        return
    end
    local localIPs = {
        "127.0.0.1",
        "localhost",
        config:getValue("server.host")
    }
    local ip = connection.dsocket:getpeername().ip
    local bypass = config:getValue("server.localBypassVerification") and util.contains(localIPs, ip)
    if config:getValue("server.verifyNames") and verificationKey ~= md5.sumhexa(server.info.Salt..username) and not bypass then 
        local err = "Invalid verification key"
        print(err)
        disconnect(connection, err)
        return
    end

    ServerPackets.ServerIdentification(connection)
    print("Identified")
    local player, err = playerModule.Player.new(connection, username)
    if not player then
        print("Error creating player: "..err)
        disconnect(connection, err:sub(1,64))
        return
    end
    connection.player = player
    player:LoadWorld(worlds.loadedWorlds[config:getValue("server.defaultWorld")])
end

---Handles client trying to set block
---@type ClientPacket
function clientSetBlock(data, connection) 
    local _, x, y, z, mode, block = string.unpack(">BHHHBB",data)
    local world
    local success, err = pcall(function()
        local player = connection.player
        if not player then
            error("Player not found")
        end
        world = player.world
        if not world then
            error("Player " .. tostring(player.id) .. " not in a world")
        end
        assert(mode == 0 or mode == 1, "Invalid mode")
        assert(block and block < 256, "Invalid block")
        asserts.assertCoordinates(x,y,z)
        assert(x < world.size.x and y < world.size.y and z < world.size.z and x >= 0 and y >= 0 and z >= 0, "Invalid coordinates")
        local cooldown = connection.cooldowns.setblock
        local time = os.clock()
        if time - cooldown.last < 0.015 then
            cooldown.amount = cooldown.amount + 1
            if cooldown.amount > 10 then
                cooldown.dropped = cooldown.dropped + 1
                error("Too many blocks")
            end
        else
            cooldown.last = time
            cooldown.amount = 0
            cooldown.dropped = 0
        end
    end)
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

---Handles client trying to move
---@type ClientPacket
local function positionAndOrientation(data, connection)
    local _, id, x, y, z, yaw, pitch = string.unpack(">BbhhhBB",data)
    x, y, z = fromFixedPoint(x, y, z)
    assert(id == -1, "Invalid id")
    asserts.assertCoordinates(x,y,z,yaw,pitch)
    local player = connection.player
    if not player then
        print("Player not found")
        return
    end
    player:MoveTo({x = x, y = y, z = z, yaw = yaw, pitch = pitch}, true, false)
end

---Handles chat messages from client
---@type ClientPacket
local function clientMessage(data, connection)
    local _, id, message = string.unpack(">Bbc64",data)
    if id ~= -1 then
        print("Invalid message id")
        return
    end
    message = unformatString(message)
    local player = connection.player
    if not player then
        print("Player not found")
        return
    end
    player:Chat(message)
end

---@type ClientPackets
local ClientPackets = {
    [0x00] = playerIdent,
    [0x05] = clientSetBlock,
    [0x08] = positionAndOrientation,
    [0x0D] = clientMessage,
}

module.ClientPackets = ClientPackets

return module