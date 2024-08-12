local timer = require("timer")

function helloWorld()
    print("Hello,")
    local co = coroutine.create(doThingAndReturnHelloWorld)
    local _, result = coroutine.resume(co)
    print(result)
    print("World!")
end