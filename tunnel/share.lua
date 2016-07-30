--[[
Multi-threaded shared serialization wrapper
Copyright 2016 Xiang Zhang
--]]

local serialize = require('threads.sharedserialize')
local torch = require('torch')

tunnel = tunnel or {}

-- Append an underscore to distinguish between metatable and class name
local Share_ = torch.class('tunnel.Share')

-- Constructor
-- data: the data to be shared. Must be shared serializable.
function Share_:__init(data)
   self.data = data
   return self
end

-- Access function
function Share_:access(callback)
   return callback(self.data)
end

-- Serialization of this object
function Share_:__write(f)
   local data = serialize.save(self.data)
   f:writeObject(data)
end

-- Deserialization of this object
function Share_:__read(f)
   local data = f:readObject()
   self.data = serialize.load(data)
end

-- Return the class, not the metatable
return tunnel.Share
