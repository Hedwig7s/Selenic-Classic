local require = require("customrequire")
local class = require("utility.class")
local protocolImpl = require("networking.protocol.protocol")
local packetUtility = require("networking.packetutility")
local serverConfig = require("data.config.serverconfig")
local playerClass = require("entity.player")
local worlds = require("data.worlds.worlds")
local type _ = require("networking.servertypes")

local packetNameCache: {string: Packet} = {}

local protocolClass = class("Protocol7", {
    singleton = true,
    implements = protocolImpl,
    constructor = function(self:Instance)
        protocolImpl.__constructor__(self)
    end,
    values = {
        Packets = {
            [0x00] = {
                format = ">BBc64c64B",
                size = 131,
                id = 0x00,
                name = "Identification",
                sender = function(protocol:Protocol, connection:Connection, name:string, motd:string)
                    local packet = protocol:PacketFromName("Identification") as Packet
                    packetUtility.sendPacket(connection,packet.format, packet.id, protocol.Meta.Version, name, motd, 0x00)
                end,
                receiver = function(protocol:Protocol, connection:Connection, data:string)
                    local packet = protocol:PacketFromName("Identification") as Packet
                    local _, protVersion, name, verkey, CPEcode = packetUtility.parsePacket(packet.format, data)
                    local verificationKey = tostring(verkey)
                    local username = tostring(name)
                    local CPE = CPEcode == 0x42
                    connection.logger:Debug("Received identification packet")
                    connection.logger:Debug("Username: "..username)
                    connection.logger:Debug("Protocol: "..tostring(protVersion))
                    connection.logger:Debug("Supports CPE: "..tostring(CPE))
                    packet.sender(protocol, connection, serverConfig:get("server.serverName"), serverConfig:get("server.motd"))
                    connection.logger:Debug("Creating player")
                    local player:Player = playerClass(connection, name) as Player
                    connection.player = player
                    connection.logger:Debug("Player created, loading world")
                    local worldName = serverConfig:get("server.defaultWorld")
                    if not (worldName is string) then
                        connection.logger:Error("Default world not set")
                        return
                    end
                    local world = worlds:getWorld(worldName)
                    if not (world is World) then
                        connection.logger:Error("World not found")
                        return
                    end
                    player:LoadWorld(world as World)
                end
            },
            [0x01] = {
                format = ">B",
                size = 1,
                id = 0x01,
                name = "Ping",
                sender = function(self:Protocol, connection:Connection)
                    local packet = self:PacketFromName("Ping") as Packet
                    packetUtility.sendPacket(connection,packet.format, packet.id)
                end,
            },
            [0x02] = {
                format = ">B",
                size = 1,
                id = 0x02,
                name = "LevelInitialize",
                sender = function(self:Protocol, connection:Connection)
                    local packet = self:PacketFromName("LevelInitialize") as Packet
                    packetUtility.sendPacket(connection,packet.format, packet.id)
                end,
            },
            [0x03] = {
                format = ">BHc1024B",
                size = 1028,
                id = 0x03,
                name = "LevelDataChunk",
                sender = function(self:Protocol, connection:Connection, levelData:string, percentage:integer)
                    assert(#levelData <= 1024, "Level data chunk too large")
                    local packet = self:PacketFromName("LevelDataChunk") as Packet
                    packetUtility.sendPacket(connection,packet.format, packet.id, #levelData, levelData..string.rep("\0", 1024-#levelData), percentage)
                end,
            },
            [0x04] = {
                format = ">BHHH",
                size = 7,
                id = 0x04,
                name = "LevelFinalize",
                sender = function(self:Protocol, connection:Connection, sizeX:integer, sizeY:integer, sizeZ:integer)
                    local packet = self:PacketFromName("LevelFinalize") as Packet
                    packetUtility.sendPacket(connection,packet.format, packet.id, sizeX, sizeY, sizeZ)
                end,
            }
            
        },
        Meta = {
            Version = 7
        },
        PacketFromName = function(self:Protocol, name:string): Packet|nil
            if packetNameCache[name] then
                return packetNameCache[name]
            end
            for _, packet in pairs(self.Packets) do
                if packet.name == name then
                    packetNameCache[name] = packet
                    return packet
                end
            end
            return nil
        end
    }
})

return protocolClass()