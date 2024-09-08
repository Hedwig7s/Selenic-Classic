local require = require("customrequire")
local type _ = require("networking.servertypes")
local type EntityPosition = require("datatypes.entityposition")
local type Vector3 = require("datatypes.vector3")
local type _ = require("data.worlds.types")
local type Logger = require("utility.logging")
local type _ = require("data.blocks")
local type _ = require("networking.protocol.protocol")

global record Entity
    initialize: function(self:Entity, name:string)
    new: function(self:Entity, name:string): Entity
    extend: function(self:Entity):  Entity
    id: integer
    worldId: integer
    logger: Logger
    world: World | nil
    name: string
    position: EntityPosition
    MoveTo: function(self:Entity, position:EntityPosition, dontReplicate: boolean | nil)
    Spawn: function(self:Entity)
    SetBlock: function(self:Entity, position:Vector3, block:Block)
    LoadWorld: function(self:Entity, world:World)
end

global record Player
    initialize: function(self:Player, name:string, connection:Connection)
    new: function(self:Player, name:string, connection:Connection): Player
    extend: function(self:Player):  Player
    id: integer
    name: string
    logger: Logger
    world: World | nil
    worldId: integer
    fancyName: string
    connection: Connection
    position: EntityPosition
    MoveTo: function(self:Player, position:EntityPosition, dontReplicate: boolean | nil, clientMovement: boolean | nil)
    Spawn: function(self:Player)
    SetBlock: function(self:Player, position:EntityPosition, block:Block)
    LoadWorld: function(self:Player, world:World)
end