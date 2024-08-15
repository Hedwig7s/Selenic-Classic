---@class PacketsModule
local module = {}

local timer = require("timer")
local util = require("./util")
local playerModule = require("./player")
local worlds = require("./worlds")
local criterias = require("./criterias")
local uv = require("uv")

require("compat53")

---@type table<number, Connection>
local connections = {}
module.connections = util.readOnlyTable(connections, false)

---@type table<number, Protocol>
local protocols = {}
setmetatable(protocols, {
    __index = function(self, key)
        if rawget(self, key) == nil then
            local success, proto = pcall(require,"./protocol/proto" .. key)
            rawset(self, key, success and proto or false)
        end
        if rawget(self, key) == false then
            return nil
        end
        return rawget(self, key)
    end
})

--------------------------------CLIENTBOUND PACKETS--------------------------------

---Gets protocol from connection
---@param connection Connection
---@return Protocol
local function getProtocol(connection)
    if not connection.player then
        print("No player associated with connection")
        protocols[7].ServerPackets.DisconnectPlayer(connection, "Player was not created successfully")
        return
    end
    return connection.player.protocol
end

---Basic wrapper for clientbound packets
---@param name string
---@return fun(connection: Connection, ...)
local function basicClientboundWrapper(name)
    return function(connection, ...)
        local protocol = getProtocol(connection)
        if not protocol then
            return false
        end
        return protocol.ServerPackets[name](connection, ...)
    end
end

---Wrapper for packets that need to be sent to multiple clients
---@param name string
---@param criteria criteria @Function to determine if a connection should receive the packet
---@param leaveId boolean? @Whether to leave the id unmodified rather than switch to -1 for matching player
---@return fun(connection: Connection, ...)
local function multiPlayerWrapper(name, criteria, leaveId)
    local base = basicClientboundWrapper(name)
    return function(connection, id, cr, ...)
        local args = {...}
        ---@type any|criteria
        local criteriaFunction = type(criteria) == "function" and criteria or cr
        local function dataProvider(id)
            local data = { id }
            if not criteria or type(criteria) == "function" then
                table.insert(data, cr)
            end
            for _, v in pairs(args) do
                table.insert(data, v)
            end
            return data
        end
        local data = dataProvider(id)
        local selfData = dataProvider(-1)
        if connection then
            return base(connection, unpack(data))
        end
        for _, connection in pairs(connections) do
            if ((type(criteria) == "function" or criteria == true) and criteriaFunction and criteriaFunction(connection, id)) or not criteria then
                local d if connection.player and connection.player.id == id and not leaveId then 
                    d = selfData
                else
                    d = data
                end

                base(connection, unpack(d))
            end
        end
    end
end


local function setBlock()
    local wrapper = basicClientboundWrapper("SetBlock")
    ---@type ServerPackets.SetBlock
    return function(connection, world, x, y, z, blockId)
        local function convert(player, blockId)
            if player and player.protocol then
                local replacements = worlds.replacements
                local protoReplacements = replacements[player.protocol.Version]
                if protoReplacements and blockId > protoReplacements.MAX then
                    blockId = replacements.REPLACEMENTS[blockId] or replacements.DEFAULT
                end
                return blockId
            end
        end
        if connection and connection.player then
            return wrapper(connection, world, x, y, z, convert(connection.player, blockId))
        end
        for _, connection in pairs(connections) do
            if connection.player and connection.player.world == world then
                wrapper(connection, world, x, y, z, convert(connection.player, blockId))
            end
        end
    end
end

---@type ServerPackets
local ServerPackets = {
    ServerIdentification = basicClientboundWrapper("ServerIdentification"),
    Ping = basicClientboundWrapper("Ping"),
    LevelInitialize = basicClientboundWrapper("LevelInitialize"),
    LevelDataChunk = basicClientboundWrapper("LevelDataChunk"),
    LevelFinalize = basicClientboundWrapper("LevelFinalize"),
    UpdateUserType = basicClientboundWrapper("UpdateUserType"),
    SetBlock = setBlock(),
    SpawnPlayer = multiPlayerWrapper("SpawnPlayer", criterias.matchWorld), -- If NPCs are added these will need to be changed
    SetPositionAndOrientation = multiPlayerWrapper("SetPositionAndOrientation", criterias.matchWorld),
    PositionAndOrientationUpdate = multiPlayerWrapper("PositionAndOrientationUpdate", criterias.matchWorld),
    PositionUpdate = multiPlayerWrapper("PositionUpdate", criterias.matchWorld),
    OrientationUpdate = multiPlayerWrapper("OrientationUpdate", criterias.matchWorld),
    DespawnPlayer = multiPlayerWrapper("DespawnPlayer", criterias.matchWorld),
    Message = multiPlayerWrapper("Message", true, true),
    DisconnectPlayer = basicClientboundWrapper("DisconnectPlayer"),
}
module.ServerPackets = ServerPackets

--------------------------------SERVERBOUND PACKETS--------------------------------

---Basic wrapper for serverbound packets
---@param id number
---@return fun(data: string, connection: Connection)
local function basicServerboundWrapper(id)
    return function(data, connection)
        local protocol = getProtocol(connection)
        if not protocol then
            return false
        end
        return protocol.ClientPackets[id](data, connection)
    end
end

local function PlayerIdentification(data, connection)
    if connection.player then return end
    local protocol = connection.protocol
    if not protocol then
        return false
    end
    return protocol.ClientPackets[0x00](data, connection, protocol)
end

---@type ClientPackets
local ClientPackets = {
    [0x00] = PlayerIdentification,
    [0x05] = basicServerboundWrapper(0x05),
    [0x08] = basicServerboundWrapper(0x08),
    [0x0D] = basicServerboundWrapper(0x0D),
}

-----------------HANDLING-----------------

---Handles a new packet
---@param data string
---@param cooldown {last:number,amount:number, dropped:number}
---@param connection Connection
local function handlePacket(data, packetId, cooldown, connection)
    local dsocket = connection.dsocket
    local id = connection.id
    local time = os.clock()
    local limited = false
    if time - cooldown.last < 0.05 then
        cooldown.amount = cooldown.amount + 1
        if cooldown.amount > 150 then
            cooldown.dropped = cooldown.dropped + 1
            print("Dropped packet from connection " .. tostring(id) .. ": Rate limit exceeded")
            limited = true
        end
        if cooldown.dropped > 200 then
            print("Removing connection " .. tostring(id) .. " due to rate limit")
            pcall(dsocket.close, dsocket)
            return false
        end
    else
        cooldown.last = time
        cooldown.amount = 0
        cooldown.dropped = 0
    end
    if not limited then
        local co = coroutine.create(ClientPackets[packetId])
        local success, err1, err2 = pcall(coroutine.resume, co, data, connection)
        if not success or not err1 then
            local err = not success and err1 or err2
            print(
                "Error handling packet id " ..
                tostring(packetId) .. " from connection " .. tostring(connection.id) .. ":", err)
            print(debug.traceback(co))
        end
    end
    return true
end

function module.HandleConnect(server)
    return function(err)
        assert(not err, err)
        local socket = uv.new_tcp()
        server:accept(socket)
        local buffer = {}
        local closed = false
        local function read_buffer(bytes, leaveData)
            local data = table.concat(buffer)
            local size = #data
            bytes = bytes or size
        
            while bytes > size and not closed do
                timer.sleep(2)
                data = table.concat(buffer)
                size = #data
            end
        
            if bytes == size and not leaveData then
                buffer = {}
            elseif not leaveData then
                buffer = {data:sub(bytes + 1)}
            end
        
            return data:sub(1, bytes)
        end
        

        socket:read_start(function(err, data)
            if err or not data then
                print("Client disconnected")
                closed = true
            end
            if err then return end
            if not data then
                socket:shutdown()
                socket:close()
                return
            end
            if #data > 0 then
                table.insert(buffer, data)
            end
        end)
        local function write(data)
            return socket:write(data)
        end
        local id
        do
            local i = 1
            while connections[i] and i <= 1024 do
                i = i + 1
            end
            if i > 1024 then
                print("Too many connections")
                socket:close()
                return
            end
            id = i
        end
        print("Client connected with id "..id)
        ---@class Connection
        ---@field read fun():string?
        ---@field write fun(data:string): success:boolean, err:string?
        ---@field dsocket unknown
        ---@field id number
        ---@field routine thread
        ---@field player Player?
        ---@field protocol Protocol?
        ---@field cooldowns table<string, {last:number,amount:number, dropped:number}>
        local connection = {
            read = function()
                return read_buffer()
            end,
            write = write,
            dsocket = socket,
            id = id,
            cooldowns = {
                setblock = { last = 0, amount = 0, dropped = 0 },
                packet = { last = 0, amount = 0, dropped = 0 },
                chat = { last = 0, amount = 0, dropped = 0 },
            },
        }
        
        local co = coroutine.create(function()
            local loggedIn = false
            local identified = false
            local lastPingSuccess = true
            local dsocket = connection.dsocket
            local lastPing = os.time()
            local loginTime = os.time()
            while not closed do
                
                local data = read_buffer(1)
                if closed then break end
                local packetId = string.unpack(">B", data)
                if packetId == 0x00 and not identified then
                    local protocolByte = read_buffer(1, true)
                    local protocolVersion = string.unpack(">B", protocolByte)

                    if protocolVersion > 7 then -- It's probably the username
                        protocolVersion = 1
                    end
                    local protocol = protocols[protocolVersion]
                    if not protocol then
                        pcall(function()
                            -- Should work with most protocols
                            protocols[7].ServerPackets.DisconnectPlayer(connection,
                                string.sub("Unsupported protocol version: " .. protocolVersion, 1, 64))
                        end)
                        break
                    end
                    connection.protocol = protocol
                    identified = true
                end

                if not ClientPackets[packetId] then
                    print("Unknown packet received:", packetId)
                else
                    data = data..read_buffer(connection.protocol.PacketSizes[packetId]-1)
                    if not handlePacket(data, packetId, connection.cooldowns.packet, connection) then
                        break
                    end
                end
                if os.time() - lastPing > 0 then
                    local err
                    lastPingSuccess, err = ServerPackets.Ping(connection)
                    if not lastPingSuccess then
                        print("Error sending ping to client: " .. (err and err or "Unknown error"))
                        pcall(dsocket.close, dsocket) -- There isn't much I can do if this fails
                        break
                    end
                end
                loggedIn = connection.player and true or false
                if os.time() - loginTime > 10 and not loggedIn then
                    print("Client took too long to login")
                    pcall(protocols[7].ServerPackets.DisconnectPlayer, connection, "Login timeout")
                    pcall(dsocket.close, dsocket)
                    break
                end
                timer.sleep(2)
            end
            if connection.player then
                connection.player:Remove()
            end
            connections[connection.id] = nil
        end)
        connection.routine = co
        connections[id] = connection
        pcall(coroutine.resume,co)
    end
end


--[[
---Handles a new connection
---@param server unknown
---@param read fun():string?
---@param write fun(data:string)
---@param dsocket unknown
---@param updateDecoder unknown
---@param updateEncoder unknown
function module:HandleConnect(server, read, write, dsocket, updateDecoder, updateEncoder)
    local id
    do
        local i = 1
        while connections[i] and i <= 1024 do
            i = i + 1
        end
        if i > 1024 then
            print("Too many connections")
            dsocket:close()
            return
        end
        id = i
    end
    
    print("Client connected with id " .. id)
    local lastPing = os.time()
    local loginTime = os.time()
    ---@class Connection
    ---@field read fun():string?
    ---@field write fun(data:string): success:boolean, err:string?
    ---@field dsocket unknown
    ---@field updateDecoder unknown
    ---@field updateEncoder unknown
    ---@field id number
    ---@field routine thread
    ---@field player Player?
    ---@field cooldowns table<string, {last:number,amount:number, dropped:number}>
    local connection = {
        read = read,
        write = write,
        dsocket = dsocket,
        updateDecoder = updateDecoder,
        updateEncoder = updateEncoder,
        id = id,
        cooldowns = {
            setblock = { last = 0, amount = 0, dropped = 0 },
            packet = { last = 0, amount = 0, dropped = 0 },
        },
    }
    local cooldown = connection.cooldowns.packet
    connections[id] = connection
    local firstPacket = true
    local connectionroutine = coroutine.create(function()
        local loggedIn = false
        local lastPingSuccess = true

        while true do
            timer.sleep(1)
            local data = read()
            if data and #data > 0 then
                if not handlePacket(data, cooldown, connection) then
                    break
                end
            elseif data == nil or not lastPingSuccess then
                print("Client lost connection")
                break
            end
            if os.time() - lastPing > 0 then
                local err
                lastPingSuccess, err = ServerPackets.Ping(connection)
                if not lastPingSuccess then
                    print("Error sending ping to client: " .. err)
                    pcall(dsocket.close, dsocket) -- There isn't much I can do if this fails
                    break
                end
            end
            loggedIn = connection.player and true or false
            if os.time() - loginTime > 10 and not loggedIn then
                print("Client took too long to login")
                pcall(protocols[7].ServerPackets.DisconnectPlayer, connection, "Login timeout")
                pcall(dsocket.close, dsocket)
                break
            end
        end
        if connection.player then
            connection.player:Remove()
        end
        connections[id] = nil
    end)
    coroutine.resume(connectionroutine)
    connection.routine = connectionroutine
end]]

return module
