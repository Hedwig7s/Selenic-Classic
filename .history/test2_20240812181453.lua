local timer = require("timer")

-- Little helper function to wait for 3 seconds and then resolve.
function sleep()
  timer.sleep(3)
  coroutine.yield()
end
  

function helloWorld()
    print("Hello,")
    local co = coroutine.create(doThingAndReturnHelloWorld)
    local success, result = coroutine.resume(co)
    if success then
      print(result)
    else
      print("Error:", result)
    end
    print("World")
  end
  
  function doThingAndReturnHelloWorld()
    sleep()
    return "This was awaited for!"
  end

helloWorld()