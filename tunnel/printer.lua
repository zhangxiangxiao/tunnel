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
   self.atomic:write(function () print(unpack(arg)) end)
end

-- Write information using io.write
function Printer_:write(...)
   local io = require('io')
   local arg = {...}
   self.atomic:write(function () io.write(unpack(arg)) end)
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
