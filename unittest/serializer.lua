--[[
Unittest for Serializer
Copyright 2016 Xiang Zhang
--]]

local Serializer = require('tunnel.serializer')

local tds = require('tds')
local threads = require('threads')
local torch = require('torch')

local Block = require('tunnel.block')
local Printer = require('tunnel.printer')

-- A Logic Named Joe
local joe = {}

function joe.main()
   if joe.init then
      print('Initializing testing environment')
      joe:init()
   end
   for name, func in pairs(joe) do
      if type(name) == 'string' and type(func) == 'function'
      and name:match('[%g]+Test') then
         print('\nExecuting '..name)
         func(joe)
      end
   end
end

function joe:init()
   print('Creating a serializer')
   self.serializer = Serializer()
end

function joe:hashTest()
   local serializer = self.serializer
   local block = Block(2)
   local printer = Printer()

   local data = tds.Hash()
   printer('Created data', torch.pointer(data))
   local serialized_data = serializer:save(data)
   printer('Serialized data', torch.pointer(serialized_data))
   local deserialized_data = serializer:load(serialized_data)
   printer('Deserialized data', torch.pointer(deserialized_data))

   block:add(serialized_data, printer)
   block:run(self:hashJob())

   local result, status = block:synchronize()
   for i, v in ipairs(status) do
      if status[i] == false then
         printer('Error in thread', i, v, unpack(result[i]))
      end
   end
end

function joe:hashJob()
   return function (serialized_data, printer)
      local torch = require('torch')
      local Serializer = require('tunnel.serializer')
      local serializer = Serializer()
      printer('Obtained serialized data', __threadid,
              torch.pointer(serialized_data));
      local data = serializer:retain(serialized_data)
      printer('Obtained deserialized data', __threadid, torch.pointer(data))
   end
end

function joe:vecTest()
   local serializer = self.serializer
   local block = Block(2)
   local printer = Printer()

   local data = tds.Vec()
   printer('Created data', torch.pointer(data))
   local serialized_data = serializer:save(data)
   printer('Serialized data', torch.pointer(serialized_data))
   local deserialized_data = serializer:load(serialized_data)
   printer('Deserialized data', torch.pointer(deserialized_data))

   block:add(serialized_data, printer)
   block:run(self:vecJob())

   local result, status = block:synchronize()
   for i, v in ipairs(status) do
      if status[i] == false then
         printer('Error in thread', i, v, unpack(result[i]))
      end
   end
end

function joe:vecJob()
   return function (serialized_data, printer)
      local torch = require('torch')
      local Serializer = require('tunnel.serializer')
      local serializer = Serializer()
      printer('Obtained serialized data', __threadid,
              torch.pointer(serialized_data));
      local data = serializer:retain(serialized_data)
      printer('Obtained deserialized data', __threadid, torch.pointer(data))
   end
end

function joe:counterTest()
   local serializer = self.serializer
   local block = Block(2)
   local printer = Printer()

   local data = tds.AtomicCounter()
   printer('Created data', torch.pointer(data))
   local serialized_data = serializer:save(data)
   printer('Serialized data', torch.pointer(serialized_data))
   local deserialized_data = serializer:load(serialized_data)
   printer('Deserialized data', torch.pointer(deserialized_data))

   block:add(serialized_data, printer)
   block:run(self:counterJob())

   local result, status = block:synchronize()
   for i, v in ipairs(status) do
      if status[i] == false then
         printer('Error in thread', i, v, unpack(result[i]))
      end
   end
end

function joe:counterJob()
   return function (serialized_data, printer)
      local torch = require('torch')
      local Serializer = require('tunnel.serializer')
      local serializer = Serializer()
      printer('Obtained serialized data', __threadid,
              torch.pointer(serialized_data));
      local data = serializer:retain(serialized_data)
      printer('Obtained deserialized data', __threadid, torch.pointer(data))
   end
end

function joe:storageTest()
   local serializer = self.serializer
   local block = Block(2)
   local printer = Printer()

   local data = torch.DoubleStorage(5)
   printer('Created data', torch.pointer(data))
   local serialized_data = serializer:save(data)
   printer('Serialized data', torch.pointer(serialized_data))
   local deserialized_data = serializer:load(serialized_data)
   printer('Deserialized data', torch.pointer(deserialized_data))

   block:add(serialized_data, printer)
   block:run(self:storageJob())

   local result, status = block:synchronize()
   for i, v in ipairs(status) do
      if status[i] == false then
         printer('Error in thread', i, v, unpack(result[i]))
      end
   end
end

function joe:storageJob()
   return function (serialized_data, printer)
      local torch = require('torch')
      local Serializer = require('tunnel.serializer')
      local serializer = Serializer()
      printer('Obtained serialized data', __threadid,
              torch.pointer(serialized_data));
      local data = serializer:retain(serialized_data)
      printer('Obtained deserialized data', __threadid, torch.pointer(data))
   end
end

function joe:tensorTest()
   local serializer = self.serializer
   local block = Block(2)
   local printer = Printer()

   local data = torch.DoubleTensor(5)
   printer('Created data', torch.pointer(data))
   local serialized_data = serializer:save(data)
   printer('Serialized data', torch.pointer(serialized_data))
   local deserialized_data = serializer:load(serialized_data)
   printer('Deserialized data', torch.pointer(deserialized_data))

   block:add(serialized_data, printer)
   block:run(self:tensorJob())

   local result, status = block:synchronize()
   for i, v in ipairs(status) do
      if status[i] == false then
         printer('Error in thread', i, v, unpack(result[i]))
      end
   end
end

function joe:tensorJob()
   return function (serialized_data, printer)
      local torch = require('torch')
      local Serializer = require('tunnel.serializer')
      local serializer = Serializer()
      printer('Obtained serialized data', __threadid,
              torch.pointer(serialized_data));
      local data = serializer:retain(serialized_data)
      printer('Obtained deserialized data', __threadid, torch.pointer(data))
   end
end

joe.main()
return joe
