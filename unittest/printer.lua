--[[
Unittest for Printer
Copyright 2016 Xiang Zhang
--]]

local Printer = require('tunnel.printer')

local Block = require('tunnel.block')

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
   print('Creating a block of 5 threads')
   self.block = Block(5)
   print('Creating the printer')
   self.printer = Printer()
   print('Connecting the block with the printer')
   self.block:add(self.printer)
end

function joe:printerTest()
   local block = self.block
   local printer_job = function(printer)
      local ffi = require('ffi')
      ffi.cdef('unsigned int sleep(unsigned int seconds);')
      for i = 1, 4 do
         printer('print', __threadid, i)
         ffi.C.sleep(1)
      end
      for i = 1, 4 do
         printer:write(
            'write', '\t', tostring(__threadid), '\t', tostring(i), '\n')
         ffi.C.sleep(1)
      end
   end
   block:run(printer_job)
end

joe.main()
return joe

