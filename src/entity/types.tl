local require = require("customrequire")
local type _ = require("networking.servertypes")
local type EntityPosition = require("datatypes.entityposition")
local type _ = require("data.worlds.types")
local type Logger = require("utility.logging")
local type _ = require("data.blocks")
local type _ = require("networking.protocol.protocol")

global record Entity
    __class__: BaseClass
    id: integer
    worldId: integer
    logger: Logger
    world: World | nil
    name: string
    position: EntityPosition
    MoveTo: function(self:Entity, position:EntityPosition)
    Spawn: function(self:Entity)
    SetBlock: function(self:Entity, position:EntityPosition, block:Block)
    LoadWorld: function(self:Entity, world:World)
end

global record Player
    __class__: BaseClass
    id: integer
    name: string
    logger: Logger
    world: World | nil
    worldId: integer
    fancyName: string
    connection: Connection
    position: EntityPosition
    MoveTo: function(self:Player)
    Spawn: function(self:Player, position:EntityPosition)
    SetBlock: function(self:Player, position:EntityPosition, block:Block)
    LoadWorld: function(self:Player, world:World)
end