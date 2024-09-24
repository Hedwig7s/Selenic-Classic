local require = require("customrequire")
local class = require("middleclass")
local entityRegistry = require("entity.entityregistry").entityRegistry
local playerRegistry = require("entity.playerregistry")
local Vector3 = require("datatypes.vector3")
local EntityPosition = require("datatypes.entityposition")
local stringUtils = require("utility.string")
local type Entities = require("entity.types")
local type Player = Entities.Player
local type Commands = require("commands.types")
local type Command = Commands.Command
local type CommandMetadata = Commands.CommandMetadata
local type CommandParameter = Commands.CommandParameter
local type CommandCallback = Commands.CommandCallback

local command = class("Command") as Command
function command:initialize(data:CommandMetadata, parameters:{CommandParameter}, callback: CommandCallback)
    self.meta = data
    self.callback = callback
    self.parameters = parameters
end
function command:parseArgs(args:{string}): {any}
    local parsedArgs: {any} = {}
    local mode = "none"
    local parts = {}
    local i = 1
    for j, arg in ipairs(args) do
        local parameter = self.parameters[i]
        if mode == "coord" then
            local subbed = arg:gsub(" ", "")
            if subbed:sub(1,1) == "," then
                table.insert(parts,subbed)
            else
                mode = "none"
                local coordstring = table.concat(parts, ",")
                local coords = stringUtils.split(coordstring, ",")
                if #coords ~= ((parameter == "vector" and 3) or parameter == "position" and 5) then
                    error("Invalid "..parameter.." at position "..i)
                end
                local x = tonumber(coords[1])
                local y = tonumber(coords[2])
                local z = tonumber(coords[3])
                local yaw:integer
                local pitch:integer
                if parameter == "position" then
                    yaw = tonumber(coords[4])
                    pitch = tonumber(coords[5])
                end
                if not x or not y or not z or (parameter == "position" and (not yaw or not pitch)) then
                    error("Invalid "..parameter.." at position "..i)
                end
                if parameter == "vector" then
                    table.insert(parsedArgs, Vector3.new(x, y, z))
                elseif parameter == "position" then
                    table.insert(parsedArgs, EntityPosition.new(x, y, z, yaw, pitch))
                end
                i = i + 1
            end
        end
        if mode == "none" then
            if parameter == "string" then
                table.insert(parsedArgs, arg)
            elseif parameter == "number" then
                local num = tonumber(arg)
                if not num then 
                    error("Invalid number at position "..i)
                end
                table.insert(parsedArgs, num)
            elseif parameter == "boolean" then
                table.insert(parsedArgs, arg == "true")
            elseif parameter == "player" then
                local player = playerRegistry:GetEntityByName(arg) as Player
                if not player then
                    error("Player"..arg .."not found at position "..i)
                end
                table.insert(parsedArgs, player)
            elseif parameter == "entity" then
                local id = math.floor(tonumber(arg))
                if not id then
                    error("Invalid entity id at position "..i)
                end
                local entity = entityRegistry:GetEntity(id)
                if not entity then
                    error("Entity"..arg .."not found at position "..i)
                end
                table.insert(parsedArgs, entity)
            elseif parameter == "vector" or parameter == "position" then
                parts = {}
                table.insert(parts, arg)
                mode = "coord"
            end
            i = i + 1
        end
    end
    return parsedArgs
end
function command:execute(player:Player, args:{string})
    local parsedArgs = self:parseArgs(args)
    self:callback(player, parsedArgs)
end


return command