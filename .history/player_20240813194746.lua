---@class PlayerModule
local module = {}

---@class PlayerSubscriptions
---@field chat table<fun(player:Player, message:string)>
local subscriptions = {
    chat = {},
}

module.subscriptions = subscriptions

local util = require("./util")
local asserts = require("./asserts")
local config = require("./config")
local criterias = require("./criterias")
local lazyModules = {}

local function lazyLoad(moduleName)
    if not lazyModules[moduleName] then
        lazyModules[moduleName] = require(moduleName)
    end
    return lazyModules[moduleName]
end

---@class Player
---@field connection Connection
---@field position Position
---@field world World
---@field name string
---@field id number
---@field removed boolean
---@field movements number
---@field protocol Protocol
local Player = {}
Player.__index = Player

---@type table<string, Player>
local playersByName = {}
---@type table<number, Player>
local players = {}

setmetatable(players, {
    __newindex = function(self, key, value)
        rawset(self, key, value)
        if value and type(value) == "table" and value.name then
            playersByName[value.name] = value
        end
    end
})

---Spawns the player in a world. Should only be called on the player's first spawn in the world
---@param player Player?
function Player:Spawn(player)
    local packets = lazyLoad("./packets")
    if player and (self.world ~= player.world or player.id == self.id) then
        return
    end
    local position = self.position

    packets.ServerPackets.SpawnPlayer(nil,self.id, self.name, position.x, position.y, position.z, position.yaw,
        position.pitch, player and player.connection or nil)
end

---Loads player into a world
---@param world World
function Player:LoadWorld(world)
    self:Despawn()
    self.world = world
    local packets = lazyLoad("./packets")

    print("Initialising level")
    packets.ServerPackets.LevelInitialize(self.connection)
    print("Packing world")
    local packed = world:Pack()
    local length = #packed
    local chunkSize = 1024
    local chunks = math.ceil(length / chunkSize)
    print("Sending level data")
    for i = 1, chunks do
        local chunk = packed:sub((i - 1) * chunkSize + 1, i * chunkSize)
        packets.ServerPackets.LevelDataChunk(self.connection, #chunk, chunk, math.floor(i / chunks * 100))
    end
    print("Finalising level")
    packets.ServerPackets.LevelFinalize(self.connection, world.size)
    self:MoveTo(world.spawn, false, true)
    self:Spawn()
    for _, player in pairs(players) do
        coroutine.wrap(player.Spawn)(player, self)
    end
    packets.ServerPackets.Message(nil,-2,criterias.matchWorld,self.name.." joined this world")
end

---Moves the player to a specified position
---@param position Position
---@param skipReplication boolean?
---@param playerMovement boolean?
function Player:MoveTo(position, playerMovement, skipReplication)
    asserts.assertCoordinates(position.x, position.y, position.z, position.yaw, position.pitch)
    skipReplication = skipReplication or false
    playerMovement = playerMovement or false
    local oldpos = util.deepCopy(self.position)
    self.position.x = position.x or self.position.x
    self.position.y = position.y or self.position.y
    self.position.z = position.z or self.position.z
    self.position.yaw = position.yaw or self.position.yaw
    self.position.pitch = position.pitch or self.position.pitch
    if not skipReplication then
        ---@type PacketsModule
        local packets = lazyLoad("./packets")
        local difference = {
            x = self.position.x - oldpos.x,
            y = self.position.y - oldpos.y,
            z = self.position.z - oldpos.z,
            yaw = self.position.yaw - oldpos.yaw,
            pitch = self.position.pitch - oldpos.pitch
        }
        local function cap(...)
            for _, x in pairs({ ... }) do
                if x < -4 or x > 3.96875 then
                    return false
                end
            end
            return true
        end
        local orientationChanged = difference.yaw ~= 0 or difference.pitch ~= 0
        local positionChanged = difference.x ~= 0 or difference.y ~= 0 or difference.z ~= 0
        local overflowed = not cap(difference.x, difference.y, difference.z)

        if not config:getValue("server.useRelativeMovement") or (not playerMovement or self.movements >= 100 or (overflowed and positionChanged)) then -- Teleportation, desync prevention or overflow
            packets.ServerPackets.SetPositionAndOrientation(nil,self.id, self.position.x, self.position.y, self.position.z,
                self.position.yaw, self.position.pitch, playerMovement)
            self.movements = 0
            return
        elseif orientationChanged and positionChanged then
            packets.ServerPackets.PositionAndOrientationUpdate(nil, self.id, difference.x, difference.y, difference.z,
                position.yaw, position.pitch)
        elseif orientationChanged then
            packets.ServerPackets.OrientationUpdate(nil, self.id, self.position.yaw, self.position.pitch)
        elseif positionChanged then
            packets.ServerPackets.PositionUpdate(nil, self.id, difference.x, difference.y, difference.z)
        end
        self.movements = self.movements + 1
    end
end

---Sends a chat message as the player
---@param message string
function Player:Chat(message)
    --asserts.assertPacketString(message)
    local packets = lazyLoad("./packets")
    -- TODO: Add muting
    -- TODO: Add color code permissions
    -- TODO: Add filter
    for _, sub in pairs(subscriptions.chat) do
        coroutine.wrap(sub)(self, message)
    end
    message = message:gsub("%%(.)", function(char)
        return "&" .. char
    end)
    message = self.name .. ": " .. message
    packets.ServerPackets.Message(nil,self.id,criterias.matchWorld,message)
end

---Despawns the player from the world
---@param player Player?
function Player:Despawn(player)
    local packets = lazyLoad("./packets")
    if not self.world then return end
    packets.ServerPackets.Message(nil,-2,criterias.matchWorld,self.name.." left this world")
    local success, err = pcall(packets.ServerPackets.DespawnPlayer, nil, self.id, player and player.connection or nil)
    if not success then
        print(err)
    end
    self.world = nil
end

function Player:Remove()
    self:Despawn()
    players[self.id] = nil
    playersByName[self.name] = nil
    self.removed = true
end

function Player:Kick(reason)
    local packets = lazyLoad("./packets")
    pcall(packets.ServerPackets.DisconnectPlayer, self.connection, reason)
    self:Remove()
end

---Creates new player
---@param connection Connection
---@param name string
---@param protocol Protocol
---@return Player?, string?
function Player.new(connection, name, protocol)
    if module:GetPlayerByName(name) then
        local err = "Player with name " .. name .. " already exists"
        print(err)
        return nil, err
    end
    local self = setmetatable({}, Player)
    self.connection = connection
    self.position = {
        x = 0,
        y = 0,
        z = 0,
        yaw = 0,
        pitch = 0
    }
    self.world = nil
    self.name = name
    self.removed = false
    self.movements = 0
    self.protocol = protocol
    local id = -1
    repeat id = id + 1 until not players[id] or id > 255
    if id > 255 or #module:GetPlayers() >= config:getValue("server.maxPlayers") then
        local err = "Too many players!"
        print(err)
        return nil, err
    end
    self.id = id
    players[self.id] = self
    return self
end

module.Player = Player

---Get player by id
---@param id number
---@return Player?
function module:GetPlayerById(id)
    return players[id]
end

---Get player by username
---@param name string
---@return Player?
function module:GetPlayerByName(name)
    return playersByName[name]
end

---Get all players
---@return table<number|string, Player>
function module:GetPlayers()
    local proxy = newproxy(true)
    local meta = getmetatable(proxy)

    meta.__index = function(self, key)
        return type(key) == "string" and playersByName[string] or players[key]
    end
    meta.__newindex = function(self, key, value)
        error("Cannot set player externally")
    end
    meta.__len = function()
        local i = 0
        for _ in pairs(players) do
            i = i + 1
        end
        return i
    end

    return proxy
end

return module
