local require = require("customrequire")
local type Entities = require("entity.types")
local Player = Entities.Player

global record MessageCriteriaData 
    sourcePlayer: Player

end
global type MessageCriteria = function(target:Player, message:string, data:MessageCriteriaData): boolean
    
local criterias: {string:MessageCriteria} = {
    sameWorld = function(target:Player, message:string, data:MessageCriteriaData): boolean
        return data.sourcePlayer and (target.world == data.sourcePlayer.world) or not data.sourcePlayer
    end,
    notSelf = function(target:Player, message:string, data:MessageCriteriaData): boolean
        return data.sourcePlayer and target ~= data.sourcePlayer or not data.sourcePlayer
    end,
}

local function combineCriterias(...:MessageCriteria): MessageCriteria
    local cr = {...}
    return function(target:Player, message:string, data:MessageCriteriaData): boolean
        for _, criteria in ipairs(cr) do
            if not criteria(target, message, data) then
                return false
            end
        end
        return true
    end
end

return {criterias = criterias, combineCriterias = combineCriterias}