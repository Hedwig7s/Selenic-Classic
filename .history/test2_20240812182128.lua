local timer = require("timer")

-- Little helper function to wait for 3 seconds and then resolve.
function sleep()
  timer.sleep(3)
  return
end
  

function helloWorld()
    print("Hello,")
    local co = coroutine.create(doThingAndReturnHelloWorld)
    local success, result
    while coroutine.status(co) ~= "suspended" do
        success, result = coroutine.resume(co)
    end
    print(result)
    print("World")
  end
  
  function doThingAndReturnHelloWorld()
    sleep()
    coroutine.yield("This was awaited for!")
  end

helloWorld()