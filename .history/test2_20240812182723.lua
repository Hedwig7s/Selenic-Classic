local timer = require("timer")

function helloWorld()
    print("Hello,")
    local co = coroutine.create(doThingAndReturnHelloWorld)
    local success, result
    repeat
        success, result = coroutine.resume(co)
    until not success or coroutine.status(co) == "dead"
    print(result)
    print("World")
end

function doThingAndReturnHelloWorld()
    timer.sleep(3000)
    return "This was awaited for!"
end

helloWorld()
