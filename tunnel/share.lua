--[[
Multi-threaded shared serialization wrapper
Copyright 2016 Xiang Zhang
--]]

local torch = require('torch')

local Serializer = require('tunnel.serializer')

tunnel = tunnel or {}

-- Append an underscore to distinguish between metatable and class name
local Share_ = torch.class('tunnel.Share')

-- Constructor
-- data: the data to be shared. Must be shared serializable.
function Share_:__init(data)
   self.data = data
   self.serializer = Serializer()
   return self
end

-- Access function
function Share_:access(callback)
   return callback(self.data)
end

-- Serialization of this object
function Share_:__write(f)
   local data = self.serializer:save(self.data)
   f:writeObject(data)
end

-- Deserialization of this object
function Share_:__read(f)
   if not self.serializer then
      self.serializer = Serializer()
   end
   local data = f:readObject()
   self.data = self.serializer:load(data)
end

-- Return the class, not the metatable
return tunnel.Share
