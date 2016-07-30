--[[
Unittest for Atomic
Copyright 2016 Xiang Zhang
--]]

local Share = require('tunnel.share')

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
   self.share_data = Share(torch.DoubleTensor(1))
   self.printer = Printer()
   self.printer('main', torch.pointer(self.share_data.data:storage()))
end

function joe:shareTest()
   -- Create a block of 3 threads
   local block = Block(3, function () require('torch') end)
   block:add(self.printer, self.share_data)
   block:run(
      function (printer, share_data)
         local torch = require('torch')
         share_data:access(
            function (data)
               printer('share_access', torch.pointer(data:storage()))
            end)
      end)
   block:synchronize()
end

joe.main()
return joe
