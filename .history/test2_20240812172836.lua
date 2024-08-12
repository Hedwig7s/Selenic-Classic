local timer = require("timer")

local testfunction = function()
    timer.sleep(1000)
    print("Hello World!")
    return "Hey"
end

local wrapped = coroutine.wrap(testfunction)
local wrapped2 = coroutine.wrap(testfunction)


wrapped()
print("After")

print(testfunction())
print("After2")

local result = wrapped2()
print("After3", result)