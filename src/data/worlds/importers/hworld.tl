local require = require("customrequire")
local zlib = require("zlib")
local EntityPosition = require("datatypes.entityposition")
local Vector3 = require("datatypes.vector3")

local type _ = require("data.worlds.types")

local sharedFunctions = {
    parseHeader = function(data:string): Vector3, EntityPosition
        local _, sizeX, sizeY, sizeZ, spawnX, spawnY, spawnZ, spawnYaw, spawnPitch = string.unpack("<I4HHHHHHBB", data) 
        local size = Vector3.new(sizeX as integer, sizeY as integer, sizeZ as integer)
        local spawn = EntityPosition.new(spawnX as integer, spawnY as integer, spawnZ as integer, spawnYaw as integer, spawnPitch as integer)
        return size, spawn
    end,
    parseBlockData = function(data:string): {integer: Block}
        local blocks = {}
        for i = 1, #data, 5 do
            local id, count = string.unpack("<BI4", data:sub(i, i+4))
            for _ = i, i+(count as integer) do
                table.insert(blocks, id as integer)
            end
        end
        return blocks
    end
}

return {
    versions = {
        [2] = function(name:string, data:string): WorldParams
            local size, spawn = sharedFunctions.parseHeader(data:sub(1, 18))
            data = data:sub(19)
            local blocks = sharedFunctions.parseBlockData(data)
            return {name = name, size = size, spawn = spawn, blocks = blocks}
        end,
        [3] = function(name:string, data:string): WorldParams
            local size, spawn = sharedFunctions.parseHeader(data:sub(1, 18))
            data = data:sub(19)
            local blockData = zlib.inflate()(data, "finish")
            local blocks = sharedFunctions.parseBlockData(blockData)
            return {name = name, size = size, spawn = spawn, blocks = blocks}
        end
    },
    getVersion = function(_:WorldParser, data:string): integer
        return string.unpack("<I4", data:sub(1,4)) as integer
    end
}