
---@class PacketsModule
local module = {}

local timer = require("timer")
local util = require("./util")

require("compat53")

---@type table<number, Connection>
local connections = {}
module.connections = util.readOnlyTable(connections)

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
