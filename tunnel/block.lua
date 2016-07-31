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
   self.block = threads.Threads(self.size, init_job)
   self.block:specific(true)

   self.data = {}
   self.result = {}
   self.status = {}
   self.count = 0
end

function Block_:add(...)
   local data_objects = {...}
   for _, data in ipairs(data_objects) do
      self.data[#self.data + 1] = data
   end
   return self
end

function Block_:run(callback)
   self.count = self.count + 1
   local result, status = Vector(), Vector()
   for i = 1, self.size do
      result[i] = nil
      status[i] = nil
   end
   self.result[self.count] = result
   self.status[self.count] = status
   for i = 1, self.size do
      local job = self:runJob(i, callback)
      self.block:addjob(i, job)
   end
   return self.count
end

function Block_:getResult(count)
   local count = count or self.count
   return self.result[count], self.status[count]
end

function Block_:synchronize()
   self.block:synchronize()
   return self:getResult()
end

function Block_:terminate()
   self.block:terminate()
   return self:getResult()
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
   local result = self.result[self.count]
   local status = self.status[self.count]
   return function ()
      -- Execute the callback
      local pack = function (status, ...)
         return status, {...}
      end
      status[index], result[index] = pack(pcall(callback, unpack(data)))
   end
end

return tunnel.Block
