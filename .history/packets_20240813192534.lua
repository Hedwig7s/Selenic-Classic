---@class PacketsModule
local module = {}

local timer = require("timer")
local util = require("./util")
local playerModule = require("./player")

require("compat53")

---@type table<number, Connection>
local connections = {}
module.connections = util.readOnlyTable(connections, false)

---@type table<number, Protocol>
local protocols = {}
setmetatable(protocols, {
    __index = function(self, key)
        if rawget(self, key) == nil then
            rawset(self, key, require("./protocol/proto" .. key) or false)
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
---@returns Protocol
local function getProtocol(connection)
    if not connection.player then
        error("No player associated with connection")
    end
    return connection.player.protocol
end

---Basic wrapper for clientbound packets
---@param name string
---@returns fun(connection: Connection, ...)
local function basicClientboundWrapper(name)
    return function(connection, ...)
        local protocol = getProtocol(connection)
        return protocol.ServerPackets[name](connection, ...)
    end
end

---Wrapper for packets that need to be sent to multiple clients
---@param name string
---@param criteria boolean|nil|fun(connection: Connection):boolean @Function to determine if a connection should receive the packet
---@param leaveId boolean? @Whether to leave the id unmodified rather than switch to -1 for matching player
---@return fun(connection: Connection, ...)
local function multiPlayerWrapper(name, criteria, leaveId)
    return function(connection, id, cr, ...)
        local args = {...}
        local base = basicClientboundWrapper(name)
        ---@type any|fun(connection: Connection, id:number):boolean
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
            base(connection, unpack(data))
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

---@param connection Connection
---@return boolean
local function matchWorld(connection, id)
    local player = playerModule:GetPlayerById(id)
    if not player then
        print("WARNING: Invalid id in matchWorld criteria", id)
    end
    return (connection.player and player and connection.player.world == player.world) and true or false
end

---@type ServerPackets
local ServerPackets = {
    ServerIdentification = basicClientboundWrapper("ServerIdentification"),
    Ping = basicClientboundWrapper("Ping"),
    LevelInitialize = basicClientboundWrapper("LevelInitialize"),
    LevelDataChunk = basicClientboundWrapper("LevelDataChunk"),
    LevelFinalize = basicClientboundWrapper("LevelFinalize"),
    UpdateUserType = basicClientboundWrapper("UpdateUserType"),
    SetBlock = multiPlayerWrapper("SetBlock", matchWorld),
    SpawnPlayer = multiPlayerWrapper("SpawnPlayer", matchWorld), -- If NPCs are added these will need to be changed
    SetPositionAndOrientation = multiPlayerWrapper("SetPositionAndOrientation", matchWorld),
    PositionAndOrientationUpdate = multiPlayerWrapper("PositionAndOrientationUpdate", matchWorld),
    PositionUpdate = multiPlayerWrapper("PositionUpdate", matchWorld),
    OrientationUpdate = multiPlayerWrapper("OrientationUpdate", matchWorld),
    DespawnPlayer = multiPlayerWrapper("DespawnPlayer", matchWorld),
    Message = multiPlayerWrapper("Message", true, true),
    DisconnectPlayer = basicClientboundWrapper("DisconnectPlayer"),
}
module.ServerPackets = ServerPackets

--------------------------------SERVERBOUND PACKETS--------------------------------

---Basic wrapper for serverbound packets
---@param id number
---@returns fun(data: string, connection: Connection)
local function basicServerboundWrapper(id)
    return function(data, connection)
        local protocol = getProtocol(connection)
        return protocol.ClientPackets[id](data, connection)
    end
end

local function PlayerIdentification(data, connection)
    if #data == 65 then
        -- Protocol version 1
        return
    end
    local protocolVersion = string.unpack(">B", data:sub(2, 2))
    local protocol = protocols[protocolVersion]
    if not protocol then
        pcall(function()
            -- Packet never changed should be fine
            protocols[7].ServerPackets.DisconnectPlayer(connection,
                string.sub("Unsupported protocol version: " .. protocolVersion, 1, 64))
        end)
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
    local connectionroutine = coroutine.create(function()
        local lastPingSuccess = true
        local loggedIn = false
        while true do
            timer.sleep(1)
            local data = read()
            if data and #data > 0 then
                local time = os.clock()
                local limited = false
                if time - cooldown.last < 0.001 then
                    cooldown.amount = cooldown.amount + 1
                    if cooldown.amount > 15 then
                        cooldown.dropped = cooldown.dropped + 1
                        print("Dropped packet from connection " .. tostring(id) .. ": Rate limit exceeded")
                        limited = true
                    end
                    if cooldown.dropped > 30 then
                        print("Removing connection " .. tostring(id) .. " due to rate limit")
                        pcall(dsocket.close, dsocket)
                        break
                    end
                else
                    cooldown.last = time
                    cooldown.amount = 0
                    cooldown.dropped = 0
                end
                if not limited then
                    local id = string.unpack(">B", data:sub(1, 1))
                    if ClientPackets[id] then
                        local co = coroutine.create(ClientPackets[id])
                        local success, err = coroutine.resume(co, data, connection)
                        if not success then
                            print(
                            "Error handling packet id " ..
                            tostring(id) .. " from connection " .. tostring(connection.id) .. ":", err)
                            print(debug.traceback(co))
                        end
                    else
                        print("Unknown packet received:", id)
                    end
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
end

return module
