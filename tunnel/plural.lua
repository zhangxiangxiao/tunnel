--[[
Plural wrapper
Copyright 2016 Xiang Zhang
--]]

tunnel = tunnel or {}

local Counter = require('tunnel.counter')
local Hash = require('tunnel.hash')
local Vector = require('tunnel.vector')

-- Append an underscore to distinguish between metatable and class name
local Plural_ = torch.class('tunnel.Plural')

-- Constructor
function Plural_:__init(size, callback, ...)
   self.data = {}
   for i = 1, size do
      self.data[i] = callback(...)
   end

   return self
end

-- Do something for all of the data object
function Plural_:doAll(callback)
   local ret = {}
   for index, value in ipairs(self.data) do
      ret[index] = callback(index, value)
   end
   return ret
end

-- Get the object
function Plural_:get(index)
   return self.data[index]
end

-- Set the object
function Plural_:set(index, value)
   self.data[index] = value
end

-- The index operator
function Plural_:__index(index)
   if type(index) == 'number' then
      return self:get(index)
   else
      local method = Plural_[index]
      if method then
         return method
      else
         error('Invalid index (number) or method name')
      end
   end
end

-- The new index operator
function Plural_:__newindex(index, value)
   if type(index) == 'number' then
      return self:set(index, value)
   else
      rawset(self, index, value)
   end
end

-- The length operator
function Plural_:__len()
   return #self.data
end

-- Shortcut for counter
function tunnel.Counters(size, ...)
   return tunnel.Plural(size, Counter, ...)
end

-- Shortcut for hash table
function tunnel.Hashes(size, ...)
   return tunnel.Plural(size, Hash, ...)
end

-- Shortcut for vector
function tunnel.Vectors(size, ...)
   return tunnel.Plural(size, Vector, ...)
end

return tunnel.Plural
