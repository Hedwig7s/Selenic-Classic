local require = require("customrequire")
local class = require("class")
local protocolImpl = require("networking.protocol.protocol")
local packetUtility = require("networking.packetutility")
local type _ = require("networking.servertypes")

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
                sender = function(self:Protocol, connection:Connection, name:string, motd:string)
                    local packet = self:PacketFromName("Identification") as Packet
                    packetUtility.sendPacket(connection,packet.format, packet.id, self.Meta.Version, name, motd, 0x00)
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
                    packet.sender(protocol, connection)
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
            }
            
        },
        Meta = {
            Version = 7
        },
        PacketFromName = function(self:Protocol, name:string): Packet|nil
            for _, packet in pairs(self.Packets) do
                if packet.name == name then
                    return packet
                end
            end
            return nil
        end
    }
})

return protocolClass()