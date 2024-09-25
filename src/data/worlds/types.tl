local require = require("customrequire")
local type Vector3 = require("datatypes.vector3")
local type EntityPosition = require("datatypes.entityposition")
local type _ = require("data.blocks")
local type _ = require("networking.protocol.protocol")
local type Logger = require("utility.logging")
local type buffer = require("buffer")
local type class = require("middleclass")

global type Player

local record Worlds

    record WorldParams
        name: string
        size: Vector3
        spawn: EntityPosition
        blocks: buffer.Buffer | nil
        autosave: boolean | nil 
    end

    type WorldDataParser = function(name: string, data:string): WorldParams
        
    record WorldParser 
        versions: {integer: WorldDataParser}
        getVersion: function(self:WorldParser, data:string): integer
    end

    record World 
        initialize: function(self:World, params:WorldParams)
        new: function(self:World, params:WorldParams): World
        static: table
        isSubclassOf: function(self: World, other:class.Class): boolean
        include: function(self: World, ...:table): World
        subclassed: function(self: World, other:class.Class)
        allocate: function(self: World): table
        isInstanceOf: function(self: World, class: class.Class): boolean
        subclass: function(self:World,name:string):  World
        name: string
        size: Vector3
        spawn: EntityPosition
        autosave: boolean
        blocks: buffer.Buffer
        logger: Logger
        Pack: function(self:World, protocol:Protocol): string
        GetBlock: function(self:World, position:Vector3): Block
        SetBlock: function(self:World, position:Vector3, block:Block, dontReplicate: boolean | nil, player:Player|nil)
        GetIndex: function(self:World, position:Vector3): integer
        Save: function(self:World)
    end

    record WorldManager
        logger: Logger
        initialize: function(self:WorldManager)
        new: function(self:WorldManager): WorldManager
        static: table
        isSubclassOf: function(self: WorldManager, other:class.Class): boolean
        include: function(self: WorldManager, ...:table): WorldManager
        subclassed: function(self: WorldManager, other:class.Class)
        allocate: function(self: WorldManager): table
        isInstanceOf: function(self: WorldManager, class: class.Class): boolean
        subclass: function(self:WorldManager,name:string): WorldManager
        newWorld: function(self:WorldManager, name:string, size:Vector3): World
        load: function(self:WorldManager, path:string): World | nil
        loadOrCreate: function(self:WorldManager, name:string, filetype:string, size:Vector3): World
        getWorld: function(self:WorldManager, name:string): World | nil
        saveAll: function(self:WorldManager)
        registerParser: function(self:WorldManager,filetype:string, parser:WorldParser)
        registerWorld: function(self:WorldManager, world:World)
    end
end

return Worlds