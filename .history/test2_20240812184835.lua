local timer = require('timer')

function sleep(callback)
  -- Little helper func to wait for 3 seconds and then resolve.
    local data
    timer.setTimeout(3000, function()
        data = callback()
    end)
    while not data do
        timer.tick()
    end
  return data
end

function helloWorld()
  print("Hello,")
  print(doSomethingAndReturnHelloWorld())
  print("World!")
end

function doSomethingAndReturnHelloWorld()
    return sleep(function()
        return "This was awaited for!"
    end)
end

helloWorld()
print("Hi")