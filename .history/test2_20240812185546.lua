local timer = require("timer")

function helloWorld()
    print("Hello,")
    local co = coroutine.create(doThingAndReturnHelloWorld)
    local _, result = coroutine.resume(co)
    print(result)
    print("World!")
end

function doThingAndReturnHelloWorld()
    timer.sleep(3000)

    return "This was awaited for!"
end

coroutine.wrap(helloWorld())()
print("Hi")