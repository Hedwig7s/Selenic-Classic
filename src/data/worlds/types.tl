local type Vector3 = require("datatypes.vector3")
local type EntityPosition = require("datatypes.entityposition")
local type blocks = require("data.blocks")

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