local module = {}

module.split = function(str, sep)
	local t = {}
	for s in str:gmatch("([^" .. sep .. "]+)") do
		table.insert(t, s)
	end
	return t
end

return module
