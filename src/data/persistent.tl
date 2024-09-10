local require = require("customrequire")

local salt = {}
for i=1, 32 do
    local t = math.random(1,3)
    local num:integer
    if t == 1 then
        num = math.random(48,57)
    elseif t == 2 then
        num = math.random(65,90)
    else
        num = math.random(97,122)
    end
    salt[i] = string.char(num)
end

local data = {
    Salt = table.concat(salt),
}
return data