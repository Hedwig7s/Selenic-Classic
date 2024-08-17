local module = {}

local server = require("../server")

local formatStrings = {
    ExtInfo = ">Bc64H",
    ExtEntry = ">Bc64I4",
}

local extensions = {}
module.Extensions = extensions
setmetatable(extensions, {
    __len = function(self)
        local count = 0
        for _ in pairs(self) do
            count = count + 1
        end
        return count
    end
})

---@param connection Connection
local function serverExtInfo(connection)
    return connection.write(string.pack(formatStrings.ExtInfo, 0x10, server.info.Software.." "..server.info.Version, #module.Extensions))
end

local function serverExtEntry(connection, name, version)
    return connection.write(string.pack(formatStrings.ExtEntry, 0x11, name, version))
end

local ServerPackets = {
    ExtInfo = serverExtInfo,
    ExtEntry = serverExtEntry,
}
module.ServerPackets = ServerPackets

local function clientExtInfo(data, connection)
    local _, client, extensionCount = string.unpack(formatStrings.ExtInfo, data)
    if not connection.player then
        error("Player not set")
    end
    local player = connection.player
    player.client = client 
    player.identifiedCPE = true
end

local function clientExtEntry(data, connection)
    local _, name, version = string.unpack(formatStrings.ExtEntry, data)
    local player = connection.player
    if not player then
        error("Player not set")
    end
    if extensions[name] and extensions[name].version == version then
        table.insert(player.CPE, name)
    end
end

local ClientPackets = {
    [0x10] = clientExtInfo,
    [0x11] = clientExtEntry,
}
module.ClientPackets = ClientPackets


return module