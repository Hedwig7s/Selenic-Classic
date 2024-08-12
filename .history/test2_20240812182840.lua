local function sleep()
    local time = os.clock()
    while os.clock() - time < 3 do end
    return
end

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
    sleep()
    return "This was awaited for!"
end

helloWorld()
