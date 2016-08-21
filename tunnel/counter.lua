--[[
Multi-threaded atomic counter
Copyright 2016 Xiang Zhang
--]]

local torch = require('torch')

local Atomic = require('tunnel.atomic')

tunnel = tunnel or {}

-- Append an understore to distinguish between metatable and class name
local Counter_ = torch.class('tunnel.Counter')

-- Constructor
-- value: the initial value of the counter. Default is 0.
function Counter_:__init(value)
   self.count = Atomic(torch.LongTensor(1):fill(value or 0))
   return self
end

-- Increase the counter
-- step: the step to increase. Default is 1.
function Counter_:increase(step)
   return self.count:write(
      function (count)
         count:add(step or 1)
         return count[1]
      end)
end

-- Increase the counter asynchronously
-- step: the step to increase. Default is 1.
function Counter_:increaseAsync(step)
   return self.count:writeAsync(
      function (count)
         count:add(step or 1)
         return count[1]
      end)
end

-- Decrease the counter
-- step: the step to decrease. Default is 1.
function Counter_:decrease(step)
   return self.count:write(
      function (count)
         count:add(-step or -1)
         return count[1]
      end)
end

-- Decrease the counter asynchronously
-- step: the step to decrease. Default is 1.
function Counter_:decreaseAsync(step)
   return self.count:writeAsync(
      function (count)
         count:add(-step or -1)
         return count[1]
      end)
end

-- Get the value of the counter
function Counter_:get()
   return self.count:read(
      function (count)
         return count[1]
      end)
end

-- Get the value of the counter asynchronously
function Counter_:getAsync()
   return self.count:readAsync(
      function (count)
         return count[1]
      end)
end

-- Set the value of the counter
function Counter_:set(value)
   return self.counter:write(
      function (count)
         local old_value = count[1]
         count[1] = value
         return old_value
      end)
end

-- Set the value of the counter asynchronously
function Counter_:setAsync(value)
   return self.counter:writeAsync(
      function (count)
         local old_value = count[1]
         count[1] = value
         return old_value
      end)
end

return tunnel.Counter
