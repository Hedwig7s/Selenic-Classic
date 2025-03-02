local tableUtility = {}

function tableUtility.deepCopy(t)
	local copy = {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			copy[k] = tableUtility.deepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

function tableUtility.find(t, value)
	for k, v in pairs(t) do
		if v == value then
			return k
		end
	end
	return nil
end

return tableUtility
