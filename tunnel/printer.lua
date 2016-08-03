--[[
Multi-threaded exclusive printer
Copyright 2016 Xiang Zhang
--]]

tunnel = tunnel or {}

local Atomic = require('tunnel.atomic')

-- Append an underscore to distinguish between metatable and class name
local Printer_ = torch.class('tunnel.Printer')

-- Constructor
function Printer_:__init()
   self.atomic = Atomic()
end

-- Print information
function Printer_:print(...)
   local arg = {...}
   return self.atomic:write(
      function ()
         print(unpack(arg))
         return true
      end)
end

-- Print information asynchronously
function Printer_:printAsync(...)
   local arg = {...}
   return self.atomic:writeAsync(
      function ()
         print(unpack(arg))
         return true
      end)
end

-- Write information using io.write
function Printer_:write(...)
   local io = require('io')
   local arg = {...}
   return self.atomic:write(
      function ()
         io.write(unpack(arg))
         return true
      end)
end

-- Write information using io.write
function Printer_:writeAsync(...)
   local io = require('io')
   local arg = {...}
   return self.atomic:writeAsync(
      function ()
         io.write(unpack(arg))
         return true
      end)
end

-- Access the printing
function Printer_:access(callback)
   return self.atomic:write(function () return callback() end)
end

-- Access the printing
function Printer_:accessAsync(callback)
   return self.atomic:writeAsync(function () return callback() end)
end

-- Call operator corresponds to print
function Printer_:__call(...)
   self:print(...)
end

-- Serialization of this object
function Printer_:__write(f)
   f:writeObject(self.atomic)
end

-- Deserialization of this object
function Printer_:__read(f)
   self.atomic = f:readObject()
end

-- Return the class, not the metatable
return tunnel.Printer
