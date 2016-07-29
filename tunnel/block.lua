--[[
Thread manager
Copyright 2016 Xiang Zhang
--]]

local threads = require('threads')
local torch = require('torch')

local Vector = require('tunnel.vector')

tunnel = tunnel or {}

-- Append an underscore to distinguish between metatable and class name
local Block_ = torch.class('tunnel.Block')

-- Constructor
-- size: the number of threads in the block
-- callback: a function used to initialize the threads.
function Block_:__init(size, callback)
   self.size = size or 1

   local init_job = self:initJob(callback)
   self.block = threads.Threads(self.size)
   self.block:specific(true)

   self.data = {}
   self.result = Vector()
   self.status = Vector()
end

function Block_:add(...)
   local data_objects = {...}
   for data in ipairs(data_objects) do
      self.data[#self.data + 1] = data
   end
   return self
end

function Block_:run(callback)
   for i = 1, self.size do
      local job = self:runJob(i, callback)
      self.block:addjob(i, job)
   end
end

function Block_:synchronize()
   self.block:synchronize()
   return self.result, self.status
end

function Block_:terminate()
   self.block:terminate()
   return self.result, self.status
end

function Block_:free()
   self.result:free()
   self.status:free()
end

function Block_:initJob(callback)
   return function ()
      require('tunnel')
      if callback ~= nil then
         callback()
      end
   end
end

function Block_:runJob(index, callback)
   local data = self.data
   local result = self.result
   local status = self.status
   return function ()
      -- Execute the callback
      local pack = function (status, ...)
         return status, {...}
      end
      status[index], result[index] = pack(pcall(callback(unpack(data))))

      -- Decrease the count on mutexes and conditions.
      for _, d in ipairs(data) do
         d:free()
      end
      status:free()
      result:free()
   end
end

return tunnel.Block
