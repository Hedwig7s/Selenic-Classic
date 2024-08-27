local record tableUtility
    deepCopy: function(t:table): table
end
local module:tableUtility = {}

module.deepCopy = function(t:table): table
    local copy: {any:any} = {}
    for k, v in pairs(t) do
        if v is table then
            copy[k] = module.deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

return module