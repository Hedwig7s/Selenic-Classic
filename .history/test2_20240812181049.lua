local timer = require("timer")

-- Little helper function to wait for 3 seconds and then resolve.
function sleep()
  timer.sleep(3)
  coroutine.yield()
end

function helloWorld()
  print("Hello,")
  print(coroutine.wrap(doThingAndReturnHelloWorld)())
  print("World")
end

function doThingAndReturnHelloWorld()
  sleep()
  coroutine.yield("This was awaited for!")
end

helloWorld()