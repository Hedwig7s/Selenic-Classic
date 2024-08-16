local module = {}
local util = require("../util")
local asserts = require("../asserts")
local config = require("../config")
local playerModule = require("../player")
local server = require("../server")
local md5 = require("md5")
local worlds = require("../worlds")
local commands = require("../commands")

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
    print("Verification key accepted")
    local player, err = playerModule.Player.new(connection, username, protocol)
    if not player then
        print("Error creating player: "..err)
        disconnect(connection, err:sub(1,64))
        return
    end
    connection.player = player
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
    message = message:gsub("&$", "")

    -- Set the character limit as a variable
    local charLimit = 61

    local messages, current, word = {}, {}, {}
    local color, newline = "", false

    -- Split a long word into segments that fit within the character limit
    local function splitLongWord(word)
        local segments = {}
        while #word > charLimit do
            table.insert(segments, word:sub(1, charLimit))
            word = word:sub(charLimit + 1)
        end
        if #word > 0 then
            table.insert(segments, word)
        end
        return segments
    end

    local function checkSize()
        if #current > charLimit then
            table.insert(messages, module.formatString(table.concat(current)))
            current = {">", " ", color}
        end
    end

    local function addWord()
        if #word > charLimit then
            -- If the word is too long, split it into smaller segments
            local segments = splitLongWord(table.concat(word))
            for i, segment in ipairs(segments) do
                if #current + #segment > charLimit then
                    table.insert(messages, module.formatString(table.concat(current)))
                    current = {">", " ", color}
                end
                table.insert(current, segment)
                if i < #segments then
                    table.insert(messages, module.formatString(table.concat(current)))
                    current = {">", " ", color}
                end
            end
        else
            checkSize()
            for _, v in ipairs(word) do
                table.insert(current, v)
            end
            if #current < charLimit then table.insert(current, " ") end
        end
        word = {}
    end

    if id == 127 and message:sub(1,1) ~= "&" then
        table.insert(current, "&")
        table.insert(current, "e")
    end

    for i = 1, #message do
        local char = message:sub(i,i)
        if char == "&" and message:sub(i+1,i+1):match("%S") then
            color = message:sub(i,i+1)
        end
        if char == "\n" then
            addWord()
            table.insert(messages, table.concat(current))
            current, newline = {}, true
        else
            if char == " " then
                addWord()
            else
                table.insert(word, char)
            end
        end
    end

    if #word > 0 then 
        addWord() 
    end
    if #current > 0 then
        table.insert(messages, module.formatString(table.concat(current)))
    end
    for i, message in pairs(messages) do
        messages[i] = module.formatString(message:gsub("^[/\\].*:%d+:", "")) -- Lets not dox ourselves, shall we? Note this is where the strings are padded
    end
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