local record tableUtility
end

function tableUtility.deepCopy(t:table): table
    local copy: {any:any} = {}
    for k, v in pairs(t) do
        if v is table then
            copy[k] = tableUtility.deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function tableUtility.find(t:table, value:any): any
    for k, v in pairs(t) do
        if v == value then
            return k
        end
    end
    return nil
end

return tableUtility