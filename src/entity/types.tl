local require = require("customrequire")
local type _ = require("networking.servertypes")
local type EntityPosition = require("datatypes.entityposition")
local type _ = require("data.worlds.types")
local type _ = require("utility.logging")
local type _ = require("data.blocks")
local type _ = require("networking.protocol.protocol")

global record Entity
    __class__: BaseClass
    id: integer
    logger: Logger
    world: World | nil
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
    fancyName: string
    connection: Connection
    position: EntityPosition
    MoveTo: function(self:Player)
    Spawn: function(self:Player, position:EntityPosition)
    SetBlock: function(self:Player, position:EntityPosition, block:Block)
    LoadWorld: function(self:Player, world:World)
end