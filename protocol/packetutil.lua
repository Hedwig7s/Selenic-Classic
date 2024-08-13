local module = {}
local util = require("../util")
local packets = require("../packets")
local asserts = require("../asserts")
local config = require("../config")
local playerModule = require("../player")
local server = require("../server")
local md5 = require("md5")
local worlds = require("../worlds")

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
        asserts.assertCoordinates(x, y, z)
        x, y, z = module.toFixedPoint(x, y, z)
    end
    if yaw then
        asserts.angleAssert(yaw, "Invalid yaw")
        asserts.angleAssert(pitch, "Invalid pitch")
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
function module.handleNewPlayer(connection, protocol, username, verificationKey, disconnect)
    assert(username and type(username) == "string" and #username <= 64, "Invalid username")
    assert(verificationKey and type(verificationKey) == "string" and #verificationKey <= 64, "Invalid verification key")
    username = module.unformatString(username)
    verificationKey = module.unformatString(verificationKey)
    print("Login packet received")
    print("Protocol version: " .. protocol.Version)
    print("Username: " .. username)
    --print("Verification key: " .. verificationKey)
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

return module