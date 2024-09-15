local require = require("customrequire")
local type Vector3 = require("datatypes.vector3")
local type EntityPosition = require("datatypes.entityposition")
local type _ = require("data.blocks")
local type _ = require("networking.protocol.protocol")
local type Logger = require("utility.logging")
local type buffer = require("buffer")

global type Player

local record Worlds

    record WorldParams
        name: string
        size: Vector3
        spawn: EntityPosition
        blocks: buffer.Buffer | nil
    end

    type WorldDataParser = function(name: string, data:string): WorldParams
        
    record WorldParser 
        versions: {integer: WorldDataParser}
        getVersion: function(self:WorldParser, data:string): integer
    end

    record World 
        initialize: function(self:World, params:WorldParams)
        new: function(self:World, params:WorldParams): World
        extend: function(self:World):  World
        name: string
        size: Vector3
        spawn: EntityPosition
        blocks: buffer.Buffer
        logger: Logger
        Pack: function(self:World, protocol:Protocol): string
        GetBlock: function(self:World, position:Vector3): Block
        SetBlock: function(self:World, position:Vector3, block:Block, dontReplicate: boolean | nil, player:Player|nil)
        GetIndex: function(self:World, position:Vector3): integer
        Save: function(self:World)
    end

    record WorldModule
        logger: Logger
        initialize: function(self:WorldModule)
        new: function(self:WorldModule): WorldModule
        extend: function(self:WorldModule): WorldModule
        newWorld: function(self:WorldModule, name:string, size:Vector3): World
        load: function(self:WorldModule, path:string): World | nil
        loadOrCreate: function(self:WorldModule, name:string, filetype:string, size:Vector3): World
        getWorld: function(self:WorldModule, name:string): World | nil
        saveAll: function(self:WorldModule)
    end
end

return Worlds