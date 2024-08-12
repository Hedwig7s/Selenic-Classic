local timer = require('timer')

local function sleep(callback)
  -- Little helper func to wait for 3 seconds and then resolve.
  local data
  timer.setTimeout(3000, function()
    data = callback()
  end)
  return data
end

local function helloWorld()
  print("Hello,")
  print(doSomethingAndReturnHelloWorld())
  print("World!")
end

local function doSomethingAndReturnHelloWorld()
    return sleep(function()
        return "This was awaited for!"
    end)
end

helloWorld()
print("Hi")