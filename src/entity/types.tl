local require = require("customrequire")
local type ServerModule = require("networking.servertypes")
local type Connection = ServerModule.Connection
local type EntityPosition = require("datatypes.entityposition")
local type Vector3 = require("datatypes.vector3")
local type Worlds = require("data.worlds.types")
local type World = Worlds.World
local type Logger = require("utility.logging")
local type _ = require("data.blocks")
local type _ = require("networking.protocol.protocol")
local type class = require("middleclass")

local record Entities 
    record Entity
        initialize: function(self:Entity, name:string)
        new: function(self:Entity, name:string): Entity
        static: table
        isSubclassOf: function(self: Entity, other:class.Class): boolean
        include: function(self: Entity, ...:table): Entity
        subclassed: function(self: Entity, other:class.Class)
        allocate: function(self: Entity): table
        isInstanceOf: function(self: Entity, class: class.Class): boolean
        subclass: function(self:Entity,name:string):  Entity
        id: integer
        worldId: integer
        logger: Logger
        world: World | nil
        name: string
        position: EntityPosition
        MoveTo: function(self:Entity, position:EntityPosition, dontReplicate?: boolean)
        Spawn: function(self:Entity)
        Despawn: function(self:Entity)
        SetBlock: function(self:Entity, position:Vector3, block:Block)
        LoadWorld: function(self:Entity, world:World)
        Remove: function(self:Entity)
        removed: boolean
    end
    
    record Player
        initialize: function(self:Player, name:string, connection:Connection)
        new: function(self:Player, name:string, connection:Connection): Player
        static: table
        isSubclassOf: function(self: Player, other:class.Class): boolean
        include: function(self: Player, ...:table): Player
        subclassed: function(self: Player, other:class.Class)
        allocate: function(self: Player): table
        isInstanceOf: function(self: Player, class: class.Class): boolean
        subclass: function(self:Player,name:string):  Player
        id: integer
        name: string
        logger: Logger
        world: World | nil
        worldId: integer
        fancyName: string
        connection: Connection
        position: EntityPosition
        MoveTo: function(self:Player, position:EntityPosition, dontReplicate?: boolean, clientMovement?: boolean)
        Spawn: function(self:Player)
        Despawn: function(self:Player)
        SetBlock: function(self:Player, position:EntityPosition, block:Block)
        Chat: function(self:Player, message:string)
        LoadWorld: function(self:Player, world:World)
        Remove: function(self:Player)
        Kick: function(self:Player, reason:string)
        removed: boolean
    end
end

return Entities