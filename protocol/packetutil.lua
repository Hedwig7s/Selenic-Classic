local module = {}
local util = require("../util")
local asserts = require("../asserts")
local config = require("../config")
local playerModule = require("../player")
local server = require("../server")
local md5 = require("md5")
local timer = require("timer")
local worlds = require("../worlds")
local commands = require("../commands")

local lazyLoaded = {}
local function lazyLoad(module)
    if not lazyLoaded[module] then
        lazyLoaded[module] = require(module)
    end
    return lazyLoaded[module]
end

---Formats string to 64 characters with padding
---@param str string
---@return string
function module.formatString(str)
    return util.pad(str,64,"\32")
end

---Reverts packet padding on a string
---@param str string
---@return string
function module.unformatString(str)
    for i = #str,1,-1 do
        if str:sub(i,i) ~= "\32" then
            return str:sub(1,i)
        end
    end
    return ""
end

---Converts numbers to fixed point
---@param ... number
---@return number ...
function module.toFixedPoint(...)
    local values = {}
    for _,v in pairs({...}) do
        table.insert(values, math.floor(v * 32))
    end
    return unpack(values) 
end

---Converts fixed point to numbers
---@param ... number
---@return number ...
function module.fromFixedPoint(...)
    local values = {}
    for _,v in pairs({...}) do
        table.insert(values, v/32)
    end
    return unpack(values) 
end

---@param id number
---@param x number?
---@param y number?
---@param z number?
---@param yaw number?
---@param pitch number?
---@param connection Connection
---@param dataProvider fun(id:number, x:number?, y:number?, z:number?, yaw:number?, pitch:number?):string
---@param skipSelf boolean?
function module.baseMovementPacket(connection, id, x, y, z, yaw, pitch, dataProvider, skipSelf)
    if not connection.player then
        return
    elseif (connection.player.id == id or id < 0) and skipSelf then
        return true
    end
    asserts.assertId(id)
    if x then
        x, y, z = module.toFixedPoint(x, y, z)
    end

    return connection.write(dataProvider(id, x, y, z, yaw, pitch))
end

function module.dummyPacket(...)
    return true
end

---@param connection Connection
---@param protocol Protocol
---@param username string
---@param verificationKey string
---@param disconnect fun(connection: Connection, reason: string)
function module.handleNewPlayer(connection, protocol, username, verificationKey, disconnect, CPE)
    CPE = CPE or false
    assert(username and type(username) == "string" and #username <= 64, "Invalid username")
    assert(verificationKey and type(verificationKey) == "string" and #verificationKey <= 64, "Invalid verification key")
    username = module.unformatString(username)
    verificationKey = module.unformatString(verificationKey)
    print("Login packet received")
    print("Protocol version: " .. protocol.Version)
    print("Username: " .. username)
    print("Supports CPE: " .. tostring(CPE))
    --print("Verification key: " .. verificationKey)
    if config:getValue("protocol.enabled."..(CPE and "CPE" or protocol.Version)) == false then
        protocol.ServerPackets.DisconnectPlayer(connection, "Protocol version " .. CPE and "CPE" or protocol.Version .. " is disabled")
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
    local player, err = playerModule.Player.new(connection, username, protocol, CPE)
    if not player then
        print("Error creating player: "..err)
        disconnect(connection, err:sub(1,64))
        return
    end
    connection.player = player
    local packets = lazyLoad("../packets")
    if CPE then
        packets.ExtensionPackets.ExtInfo(connection)
        player.client = "Unknown CPE"
        local waited = 0
        while not player.identifiedCPE do
            if waited > 1000 then
                print("CPE identification timed out")
                disconnect(connection, "CPE identification timed out")
                return
            end
            waited = waited + 1
            timer.sleep(1)
        end
    end
    print("Client: "..player.client)
    packets.ServerPackets.Message(nil,-2,nil,player.name.." joined the server!")
    player:SendMessage(string.format([[
&aWelcome to %s!
&aType /help for a list of commands
&bServer Software: %s
&aClient Software: &e%s]], config:getValue("server.serverName"), server.info.FancySoftware, player.client))
    protocol.ServerPackets.ServerIdentification(connection)
    print("Identified")
    player:LoadWorld(worlds.loadedWorlds[config:getValue("server.defaultWorld")])
    return true
end

function module.convertPositionUpdate(connection,id,...)
    local player = playerModule:GetPlayerById(id)
    if not player then return end
    module.ServerPackets.SetPositionAndOrientation(connection,id,player.position.x,player.position.y,player.position.z,player.position.yaw,player.position.pitch, true)
end

function module.formatChatMessage(message, id)
    asserts.assertId(id)
    id = id and id >= 0 and id or 127

    local newline = false

    local messages, current, word, color = {}, {}, {}, nil
    if id == 127 then
        word = {"&", "e"}
    end
    local function addCurrent()
        if #current > 0 then
            table.insert(messages, module.formatString(table.concat(current):gsub("&$", "")))
        end
        current = newline and {} or {">", " ", color}
        newline = false
    end

    local function checkSize()
        if #current + #word > 64 then
            addCurrent()
        end
    end
    local function addWord()
        checkSize()
        for _, c in pairs(word) do
            table.insert(current, c)
        end
        if #current < 64 then
            table.insert(current, " ")
        end
        word = {}
    end

    for i = 1, #message do
        local char = message:sub(i,i)
        if #word >= 61 then
            local cached = table.concat(word)
            for i = 1, #cached, 61 do
                word = {}
                for j = 1, 61 do
                    table.insert(word, cached:sub(i+j,i+j))
                end
                addWord()
            end
        end
        if char == "&" and i < #message and message:sub(i+1,i+1):match("[%a%d]") then
            color = "&"..message:sub(i+1,i+1)
        end
        if char == " " then
            addWord()
        elseif char == "\n" then
            addWord()
            newline = true
            addCurrent()
            current = {}
        else
            table.insert(word, char)
        end
    end
    addWord()
    addCurrent()

    return id, messages
end



function module.handleIncomingChat(connection, id, message)
    message = module.unformatString(message)
    local player = connection.player
    if not player then
        print("Player not found")
        return
    end
    if message:sub(1,1) == "/" then
        local success, err = commands:ParseCommand(player, message:sub(2))
        if not success and err then
            player:SendMessage("&c"..err)
        end
        return
    end

    local cooldown = connection.cooldowns.chat
    local time = os.clock()
    if time - cooldown.last < 0.5 then
        cooldown.amount = cooldown.amount + 1
        if cooldown.amount > 5 then
            cooldown.dropped = cooldown.dropped + 1
            error("Too many chat messages")
        end
    else
        cooldown.last = time
        cooldown.amount = math.max(cooldown.amount - 2, 0)
        cooldown.dropped = 0
    end
    player:Chat(message)
end

return module