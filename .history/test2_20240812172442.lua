local timer = require("timer")

local testfunction = function()
    timer.sleep(1000)
    print("Hello World!")
end

local wrapped = coroutine.wrap(testfunction)

wrapped()
print("After")

testfunction()
print("After2")
