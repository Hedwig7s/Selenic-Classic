local function sleep()
    local time = os.clock()
    while os.clock() - time < 3 do end
    return
end

function helloWorld()
    print("Hello,")
    local co = coroutine.create(doThingAndReturnHelloWorld)
    local _, result = coroutine.resume(co)
    print(result)
    print("World")
end

function doThingAndReturnHelloWorld()
    sleep()
    return "This was awaited for!"
end

local co = coroutine.create(helloWorld)
coroutine.resume(co)
print("Hi")