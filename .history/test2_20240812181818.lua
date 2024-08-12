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
    repeat
        success, result = coroutine.resume(co)
    until success and coroutine.status(co) == "dead"
    print(result)
    print("World")
  end
  
  function doThingAndReturnHelloWorld()
    sleep()
    return "This was awaited for!"
  end

helloWorld()