local timer = require("timer")

function helloWorld()
    print("Hello,")
    local co = coroutine.create(doThingAndReturnHelloWorld)
    local t = 0
    local success, result
    while coroutine.status(co) ~= "dead" do
        t = t + 1
        if t % 100 == 0 then
          success, result = coroutine.resume(co)
        end
    end
    print(result)
    print("World")
end

function doThingAndReturnHelloWorld()
    timer.sleep(3000)
    coroutine.yield("This was awaited for")
end

helloWorld()
print("Hi")