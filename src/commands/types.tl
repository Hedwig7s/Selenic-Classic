local type Entities = require("entity.types")
local type Player = Entities.Player
local type class = require("middleclass")

local record Commands
    enum CommandParameter
        "string"
        "number"
        "boolean"
        "player"
        "entity"
        "vector"
        "position"
    end
    
    type CommandCallback = function(self:Command, player:Player, args:{any})
    
    record CommandMetadata
        name: string
        description: string
        aliases: {string}
        usage: string
        permission: string
    end
    
    record Command 
        initialize: function(self:Command, data:CommandMetadata, parameters:{CommandParameter}, callback: CommandCallback)
        new: function(self:Command, data:CommandMetadata, parameters:{CommandParameter}, callback: CommandCallback): Command
        static: table
        isSubclassOf: function(self: Command, other:class.Class): boolean
        include: function(self: Command, ...:table): Command
        subclassed: function(self: Command, other:class.Class)
        allocate: function(self: Command): table
        isInstanceOf: function(self: Command, class: class.Class): boolean
        subclass: function(self:Command,name:string): Command
        meta: CommandMetadata
        callback: CommandCallback
        parameters: {CommandParameter}
        parseArgs: function(self:Command, args:{string}): {any}
        execute: function(self:Command, player:Player, args:{string})
    end
    record CommandRegistry
        initialize: function(self:CommandRegistry)
        new: function(self:CommandRegistry): CommandRegistry
        static: table
        isSubclassOf: function(self: CommandRegistry, other:class.Class): boolean
        include: function(self: CommandRegistry, ...:table): CommandRegistry
        subclassed: function(self: CommandRegistry, other:class.Class)
        allocate: function(self: CommandRegistry): table
        isInstanceOf: function(self: CommandRegistry, class: class.Class): boolean
        subclass: function(self:CommandRegistry, name:string): CommandRegistry
        commands: {string: Command}
        Register: function(self:CommandRegistry, command:Command)
        Unregister: function(self:CommandRegistry, command:Command)
        Get: function(self:CommandRegistry, name:string): Command|nil
    end
end

return Commands