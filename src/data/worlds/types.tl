local require = require("customrequire")
local type Vector3 = require("datatypes.vector3")
local type EntityPosition = require("datatypes.entityposition")
local type _ = require("data.blocks")
local type _ = require("networking.protocol.protocol")
local type _ = require("utility.logging")

global record WorldParams
    name: string
    size: Vector3
    spawn: EntityPosition
    blocks: {integer: Block} | nil
end

global type WorldDataParser = function(name: string, data:string): WorldParams
    
global record WorldParser 
    versions: {integer: WorldDataParser}
    getVersion: function(self:WorldParser, data:string): integer
end

global record World 
    __class__: BaseClass
    name: string
    size: Vector3
    spawn: EntityPosition
    blocks: {integer: Block}
    logger: Logger
    Pack: function(self:World, protocol:Protocol): string
    GetBlock: function(self:World, position:Vector3): Block
    SetBlock: function(self:World, position:Vector3, block:Block)
    Save: function(self:World)
end

global record WorldModule
    __class__: BaseClass
    new: function(self:WorldModule, name:string, size:Vector3): World
    load: function(self:WorldModule, name:string, filetype:string): World
    loadOrCreate: function(self:WorldModule, name:string, filetype:string, size:Vector3): World
    saveAll: function()
end