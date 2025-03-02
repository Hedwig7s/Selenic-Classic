local require = require("customrequire")
local Entities = require("entity.types")
local Player = Entities.Player

MessageCriteriaData = {}

MessageCriteria = {}

local criterias = {
	sameWorld = function(target, message, data)
		return data.sourcePlayer and (target.world == data.sourcePlayer.world) or not data.sourcePlayer
	end,
	notSelf = function(target, message, data)
		return data.sourcePlayer and target ~= data.sourcePlayer or not data.sourcePlayer
	end,
}

local function combineCriterias(...)
	local cr = { ... }
	return function(target, message, data)
		for _, criteria in ipairs(cr) do
			if not criteria(target, message, data) then
				return false
			end
		end
		return true
	end
end

return { criterias = criterias, combineCriterias = combineCriterias }
