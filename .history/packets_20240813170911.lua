
---@class PacketsModule
local module = {}

local timer = require("timer")
local util = require("./util")

require("compat53")

---@type table<number, Connection>
local connections = {}
module.connections = util.readOnlyTable(connections, false)

---@type table<number, Protocol>
local protocols = {}
setmetatable(protocols, {
    __index = function (self, key)
        if self[key] == nil then
            rawset(self, key, require("./protocol/proto"..key) or false)
        end
        if self[key] == false then
            error("Protocol "..key.." not found")
        end
        return self[key]
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
local function basicWrapper(name)
    return function(connection, ...)
        local protocol = getProtocol(connection)
        return protocol.ServerPackets[name](connection, ...)
    end
end

---Wrapper for packets that need to be sent to multiple clients
---@param name string
---@param leaveId boolean @Whether to leave the id unmodified rather than switch to -1 for matching player
---@returns fun(connection: Connection, ...)
local function multiPlayerWrapper(name, leaveId)
    return function(connection, id, ...)
        local base = basicWrapper(name)
        if connection.player and connection.player.id == id and not leaveId then
            id = -1
        end
        if connection then
            base(connection, id, ...)
        end
        for _, connection in pairs(connections) do
            base(...)
        end
    end
end

---@type ServerPackets
local ServerPackets = {
    ServerIdentification = basicWrapper("ServerIdentification"),
    Ping = basicWrapper("Ping"),
    LevelInitialize = basicWrapper("LevelInitialize"),
    LevelDataChunk = basicWrapper("LevelDataChunk"),
    LevelFinalize = basicWrapper("LevelFinalize"),
    UpdateUserType = basicWrapper("UpdateUserType"),
    SetBlock = multiPlayerWrapper("SetBlock"),
    SpawnPlayer = multiPlayerWrapper("SpawnPlayer"),
    SetPositionAndOrientation = multiPlayerWrapper("SetPositionAndOrientation"),
    PositionAndOrientationUpdate = multiPlayerWrapper("PositionAndOrientationUpdate"),
    PositionUpdate = multiPlayerWrapper("PositionUpdate"),
    OrientationUpdate = multiPlayerWrapper("OrientationUpdate"),
    DespawnPlayer = multiPlayerWrapper("DespawnPlayer"),
    Message = multiPlayerWrapper("Message"),
    DisconnectPlayer = basicWrapper("DisconnectPlayer"),
}
module.ServerPackets = ServerPackets


-----------------HANDLING-----------------

---Handles a new connection
---@param server unknown
---@param read fun():string?
---@param write fun(data:string)
---@param dsocket unknown
---@param updateDecoder unknown
---@param updateEncoder unknown
function module:HandleConnect(server, read, write, dsocket, updateDecoder, updateEncoder)
    local id do
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
    print("Client connected with id ".. id)
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
            setblock = {last = 0, amount = 0, dropped = 0},
            packet = {last = 0, amount = 0, dropped = 0},
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
                        print("Dropped packet from connection "..tostring(id)..": Rate limit exceeded")
                        limited = true
                    end
                    if cooldown.dropped > 30 then
                        print("Removing connection "..tostring(id).." due to rate limit")
                        pcall(dsocket.close, dsocket)
                        break
                    end
                else
                    cooldown.last = time
                    cooldown.amount = 0
                    cooldown.dropped = 0
                end
                if not limited then
                    local id = string.unpack(">B",data:sub(1,1))
                    if ClientPackets[id] then
                        local co = coroutine.create(ClientPackets[id])
                        local success, err = coroutine.resume(co, data, connection)
                        if not success then
                            print("Error handling packet id " .. tostring(id) .." from connection "..tostring(connection.id)..":", err)
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
                lastPingSuccess,err = ServerPackets.Ping(connection)
                if not lastPingSuccess then
                    print("Error sending ping to client: "..err)
                    pcall(dsocket.close, dsocket) -- There isn't much I can do if this fails 
                    break
                end
            end
            loggedIn = connection.player and true or false
            if os.time() - loginTime > 10 and not loggedIn then
                print("Client took too long to login")
                pcall(ServerPackets.DisconnectPlayer,connection, "Login timeout")
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
