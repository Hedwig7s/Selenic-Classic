local timer = require('timer')

local function sleep()
  -- Little helper func to wait for 3 seconds and then resolve.
  return function(callback)
    timer.setTimeout(3000, function()
      callback(nil)
    end)
  end
end

local function helloWorld()
  print("Hello,")
  
  sleep()(function(err, result)
    local doThingAndReturnHelloWorld = function(callback)
      callback(nil, "This was awaited for!")
    end
    
    doThingAndReturnHelloWorld(function(err, result)
      print(result)
      print("World")
    end)
  end)
end

helloWorld()
print("Hi")